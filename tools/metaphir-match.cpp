#include "metaphir/IR/MIRContext.h"
#include "metaphir/IR/Pattern.h"
#include "metaphir/IR/PatternLowering.h"
#include "metaphir/IR/PatternVariants.h"
#include "metaphir/Index/CorpusIndex.h"
#include "metaphir/Matching/Features.h"
#include "metaphir/Matching/PatternMatcher.h"
#include "metaphir/Parser/MIRParser.h"
#include "llvm/ADT/STLExtras.h"
#include "llvm/IR/Module.h"
#include "llvm/IRReader/IRReader.h"
#include "llvm/Support/CommandLine.h"
#include "llvm/Support/Error.h"
#include "llvm/Support/FileSystem.h"
#include "llvm/Support/InitLLVM.h"
#include "llvm/Support/Path.h"
#include "llvm/Support/SourceMgr.h"
#include "llvm/Support/Threading.h"
#include "llvm/Support/raw_ostream.h"
#include <atomic>
#include <condition_variable>
#include <memory>
#include <mutex>
#include <optional>
#include <string>
#include <thread>
#include <utility>
#include <vector>

using namespace llvm;
using namespace llvm::metaphir;

static cl::OptionCategory Category("metaphir-match options");
static cl::opt<std::string> PatternFilename(cl::Positional, cl::Required,
                                            cl::desc("<pattern>"),
                                            cl::cat(Category));
static cl::list<std::string>
    InputPaths(cl::Positional, cl::OneOrMore,
               cl::desc("<llvm-ir file or directory>..."), cl::cat(Category));
static cl::opt<bool> MatchesOnly(
    "matches-only",
    cl::desc("Print only the matches, one per line: the file, @function "
             "and bindings, separated by tabs"),
    cl::cat(Category));
static cl::opt<unsigned>
    Jobs("j",
         cl::desc("Match this many files at once (0: one per hardware "
                  "thread); needs --matches-only"),
         cl::init(1), cl::cat(Category));
static cl::opt<std::string> IndexFile(
    "index",
    cl::desc("Skip the files and functions this index (from metaphir-index) "
             "shows cannot match; needs --matches-only"),
    cl::value_desc("file"), cl::cat(Category));
static cl::opt<bool>
    PrintSummary("summary",
                 cl::desc("Print how many functions and files were matched "
                          "to stderr"),
                 cl::cat(Category));
static cl::opt<bool>
    NoPrefilter("no-prefilter", cl::Hidden,
                cl::desc("Match every variant, even in functions that lack "
                         "the instructions it needs (for testing)"),
                cl::cat(Category));

namespace {

/// A parsed and lowered pattern. Matching may evaluate the pattern's
/// constraint definitions, so each thread has its own.
struct LoadedPattern {
  SourceMgr Source;
  MIRContext Context;
  std::optional<PatternVariants> Variants;
  FeatureQuery Query;

  const FeatureQuery *getFilter() const {
    return NoPrefilter ? nullptr : &Query;
  }
};

/// What matching one or more files found.
struct MatchStats {
  bool Failed = false;
  uint64_t Files = 0;
  uint64_t ReadFiles = 0;
  uint64_t Functions = 0;
  uint64_t MatchedFunctions = 0;

  void add(const MatchStats &Other) {
    Failed |= Other.Failed;
    Files += Other.Files;
    ReadFiles += Other.ReadFiles;
    Functions += Other.Functions;
    MatchedFunctions += Other.MatchedFunctions;
  }
};

/// What matching one file printed, to be shown in the order of the files.
struct FileOutput {
  std::string Out;
  std::string Err;
  MatchStats Stats;
};

} // namespace

/// Parses and lowers the pattern, printing any error to Err. Warnings are
/// printed to stderr unless Quiet.
static std::unique_ptr<LoadedPattern>
loadPattern(StringRef ToolName, raw_ostream &Err, bool Quiet = false) {
  auto Loaded = std::make_unique<LoadedPattern>();
  if (Quiet)
    Loaded->Source.setDiagHandler([](const SMDiagnostic &, void *) {});
  Pattern *RawPattern = nullptr;
  SMDiagnostic Diag;
  if (parseMIRFile(PatternFilename, Loaded->Source, Loaded->Context, RawPattern,
                   Diag)) {
    Diag.print(ToolName.data(), Err);
    return nullptr;
  }
  Expected<PatternVariants> Lowered =
      PatternLowering(Loaded->Context).lower(RawPattern);
  if (!Lowered) {
    logAllUnhandledErrors(Lowered.takeError(), Err,
                          Twine(ToolName) + ": error: ");
    return nullptr;
  }
  Loaded->Variants = std::move(*Lowered);
  Loaded->Query = FeatureQuery::compute(*Loaded->Variants);
  return Loaded;
}

/// The defined functions of File to match, in order: those the index shows
/// may match, or, when it does not cover the file as it is, all of them. The
/// module of the file is loaded into Context, lazily when the index is used.
static Expected<std::unique_ptr<Module>>
loadFunctions(const LoadedPattern &Pattern, const CorpusIndex *Index,
              StringRef File, StringRef ToolName, LLVMContext &Context,
              SmallVectorImpl<Function *> &Functions, raw_ostream &Err,
              MatchStats &Stats) {
  auto LoadAll = [&]() -> Expected<std::unique_ptr<Module>> {
    SMDiagnostic Diag;
    std::unique_ptr<Module> M = parseIRFile(File, Diag, Context);
    if (!M) {
      std::string Message;
      raw_string_ostream OS(Message);
      Diag.print(ToolName.data(), OS);
      return createStringError(inconvertibleErrorCode(), Message);
    }
    ++Stats.ReadFiles;
    for (Function &F : *M)
      if (!F.isDeclaration())
        Functions.push_back(&F);
    Stats.Functions += Functions.size();
    return M;
  };

  if (!Index)
    return LoadAll();
  const IndexedModule *Entry = Index->lookup(File);
  if (!Entry || !CorpusIndex::isCurrent(*Entry, File)) {
    Err << ToolName << ": warning: " << File << ": "
        << (Entry ? "changed since indexed" : "not indexed")
        << "; matching it in full\n";
    return LoadAll();
  }
  // A file that does not parse is read, to report why.
  if (!Entry->Parsed)
    return LoadAll();
  Stats.Functions += Index->getNumFunctions(*Entry);
  if (!Pattern.Query.mayMatch(Entry->Summary))
    return nullptr;
  Expected<std::vector<IndexedFunction>> Indexed = Index->readFunctions(*Entry);
  if (!Indexed)
    return Indexed.takeError();
  SmallVector<const IndexedFunction *, 8> Candidates;
  for (const IndexedFunction &Function : *Indexed)
    if (Pattern.Query.mayMatch(Function.Features))
      Candidates.push_back(&Function);
  if (Candidates.empty())
    return nullptr;

  SMDiagnostic Diag;
  std::unique_ptr<Module> M = getLazyIRFileModule(File, Diag, Context);
  if (!M) {
    std::string Message;
    raw_string_ostream OS(Message);
    Diag.print(ToolName.data(), OS);
    return createStringError(inconvertibleErrorCode(), Message);
  }
  ++Stats.ReadFiles;
  // Before a function is materialized, it is defined but empty.
  SmallVector<Function *, 64> Defined;
  for (Function &F : *M)
    if (!F.isDeclaration())
      Defined.push_back(&F);
  for (const IndexedFunction *Candidate : Candidates) {
    if (Candidate->Ordinal >= Defined.size() ||
        Defined[Candidate->Ordinal]->getName() != Candidate->Name) {
      // The file is not what was indexed after all.
      Err << ToolName << ": warning: " << File
          << ": differs from its index entry; matching it in full\n";
      Stats.Functions -= Index->getNumFunctions(*Entry);
      --Stats.ReadFiles;
      Functions.clear();
      M.reset();
      return LoadAll();
    }
    Functions.push_back(Defined[Candidate->Ordinal]);
  }
  for (Function *F : Functions)
    if (Error E = F->materialize())
      return E;
  return M;
}

/// Matches the pattern against the functions of one file. Unless only matches
/// are printed, each function is reported as the next target.
static void matchFile(LoadedPattern &Pattern, const CorpusIndex *Index,
                      StringRef File, StringRef ToolName, raw_ostream &Out,
                      raw_ostream &Err, MatchStats &Stats,
                      unsigned &TargetIndex) {
  ++Stats.Files;
  LLVMContext IRContext;
  SmallVector<Function *, 64> Functions;
  Expected<std::unique_ptr<Module>> M = loadFunctions(
      Pattern, Index, File, ToolName, IRContext, Functions, Err, Stats);
  if (!M) {
    // Report the module and go on with the others.
    Out.flush();
    handleAllErrors(M.takeError(), [&](const ErrorInfoBase &E) {
      std::string Message = E.message();
      // Parse errors come printed; others need the tool name and file.
      if (!StringRef(Message).starts_with(ToolName))
        Err << ToolName << ": error: " << File << ": ";
      Err << Message;
      if (!StringRef(Message).ends_with("\n"))
        Err << '\n';
    });
    Stats.Failed = true;
    return;
  }

  // A matcher per module: its cached analyses belong to the module's
  // functions.
  PatternMatcher Matcher(&Pattern.Context);
  bool Materialized = false;
  if (*M && (*M)->getMaterializer())
    // Uses of globals in functions not read yet count too.
    Matcher.setUseListCompleter([&] {
      if (Materialized)
        return;
      Materialized = true;
      if (Error E = (**M).materializeAll())
        report_fatal_error(Twine(File) + ": " + toString(std::move(E)));
    });
  for (const Function *F : Functions) {
    ++Stats.MatchedFunctions;
    Target Program(*F);
    bool HadStructuralMatch = false;
    SmallVector<UnsatisfiedConstraint, 4> Unsatisfied;
    MatchResults Matches =
        Matcher.match(*Pattern.Variants, Program, &Unsatisfied,
                      &HadStructuralMatch, Pattern.getFilter());
    if (MatchesOnly) {
      for (const Instantiation &Match : Matches)
        Out << File << "\t@" << F->getName() << '\t' << Match << '\n';
      continue;
    }
    Out << "target " << TargetIndex++ << ": @" << F->getName() << '\n';
    if (Matches.empty()) {
      Out << "  no match\n";
      if (HadStructuralMatch)
        for (const UnsatisfiedConstraint &U : Unsatisfied) {
          Out << "  constraint not satisfied: " << *U.Expression;
          if (!U.Reason.empty())
            Out << " (cannot evaluate: " << U.Reason << ")";
          Out << '\n';
        }
      continue;
    }
    for (auto [Index, Match] : enumerate(Matches))
      Out << "  match " << Index << ":\n    " << Match << '\n';
  }
}

/// Matches the files on Threads threads, printing each file's output in the
/// order of Files as soon as it and the ones before it are done.
static MatchStats matchInParallel(ArrayRef<std::string> Files,
                                  const CorpusIndex *Index, unsigned Threads,
                                  StringRef ToolName) {
  std::vector<FileOutput> Outputs(Files.size());
  std::vector<bool> Done(Files.size());
  std::mutex Mutex;
  std::condition_variable FileDone;
  std::atomic<size_t> NextFile{0};

  auto Work = [&] {
    std::string PatternErrors;
    raw_string_ostream PatternErr(PatternErrors);
    // The pattern parsed on the main thread, which printed its warnings, so
    // it parses here too.
    std::unique_ptr<LoadedPattern> Pattern =
        loadPattern(ToolName, PatternErr, /*Quiet=*/true);
    for (size_t FileIndex; (FileIndex = NextFile++) < Files.size();) {
      FileOutput Output;
      if (Pattern) {
        raw_string_ostream Out(Output.Out), Err(Output.Err);
        unsigned TargetIndex = 0;
        matchFile(*Pattern, Index, Files[FileIndex], ToolName, Out, Err,
                  Output.Stats, TargetIndex);
      } else {
        Output.Err = PatternErrors;
        Output.Stats.Failed = true;
      }
      std::lock_guard<std::mutex> Lock(Mutex);
      Outputs[FileIndex] = std::move(Output);
      Done[FileIndex] = true;
      FileDone.notify_all();
    }
  };

  std::vector<std::thread> Workers;
  for (unsigned I = 0; I != Threads; ++I)
    Workers.emplace_back(Work);

  MatchStats Stats;
  for (size_t FileIndex = 0; FileIndex != Files.size(); ++FileIndex) {
    FileOutput Output;
    {
      std::unique_lock<std::mutex> Lock(Mutex);
      FileDone.wait(Lock, [&] { return Done[FileIndex]; });
      Output = std::move(Outputs[FileIndex]);
    }
    outs() << Output.Out;
    outs().flush();
    errs() << Output.Err;
    Stats.add(Output.Stats);
  }
  for (std::thread &Worker : Workers)
    Worker.join();
  return Stats;
}

int main(int Argc, char **Argv) {
  InitLLVM X(Argc, Argv);
  cl::HideUnrelatedOptions(Category);
  cl::SetVersionPrinter(
      [](raw_ostream &OS) { OS << "MetaphIR " METAPHIR_VERSION "\n"; });
  StringRef ToolName = sys::path::filename(Argv[0]);
  cl::ParseCommandLineOptions(
      Argc, Argv,
      "Match a MetaphIR pattern against the functions of LLVM IR modules\n");

  if (Jobs != 1 && !MatchesOnly) {
    errs() << ToolName << ": error: -j needs --matches-only\n";
    return 1;
  }
  if (!IndexFile.empty() && !MatchesOnly) {
    errs() << ToolName << ": error: --index needs --matches-only\n";
    return 1;
  }

  std::unique_ptr<LoadedPattern> Pattern = loadPattern(ToolName, errs());
  if (!Pattern)
    return 1;

  std::optional<CorpusIndex> Index;
  if (!IndexFile.empty()) {
    Expected<CorpusIndex> Read = CorpusIndex::read(IndexFile);
    if (!Read) {
      logAllUnhandledErrors(Read.takeError(), errs(),
                            Twine(ToolName) + ": error: ");
      return 1;
    }
    Index = std::move(*Read);
  }
  const CorpusIndex *IndexPtr = Index ? &*Index : nullptr;

  SmallVector<std::string, 16> InputFiles;
  for (const std::string &Input : InputPaths)
    if (!collectLLVMIRFiles(Input, InputFiles, errs()))
      return 1;

  unsigned Threads =
      Jobs ? Jobs.getValue() : hardware_concurrency().compute_thread_count();
  MatchStats Stats;
  if (Threads > 1) {
    Stats = matchInParallel(InputFiles, IndexPtr, Threads, ToolName);
  } else {
    unsigned TargetIndex = 0;
    for (const std::string &InputFile : InputFiles)
      matchFile(*Pattern, IndexPtr, InputFile, ToolName, outs(), errs(), Stats,
                TargetIndex);
  }
  if (PrintSummary)
    errs() << "matched " << Stats.MatchedFunctions << " of " << Stats.Functions
           << " functions (in " << Stats.ReadFiles << " of " << Stats.Files
           << " files)\n";
  return Stats.Failed ? 1 : 0;
}
