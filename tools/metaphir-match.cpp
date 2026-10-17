#include "metaphir/IR/MIRContext.h"
#include "metaphir/IR/Pattern.h"
#include "metaphir/IR/PatternLowering.h"
#include "metaphir/IR/PatternVariants.h"
#include "metaphir/Index/CorpusIndex.h"
#include "metaphir/Matching/FeatureQuery.h"
#include "metaphir/Matching/PatternMatcher.h"
#include "metaphir/Matching/UseOracle.h"
#include "metaphir/Parser/MIRParser.h"
#include "metaphir/Web/WebIndex.h"
#include "metaphir/Web/WebQuery.h"
#include "llvm/ADT/STLExtras.h"
#include "llvm/ADT/SmallString.h"
#include "llvm/Bitcode/BitcodeReader.h"
#include "llvm/IR/Module.h"
#include "llvm/IR/ModuleSlotTracker.h"
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
#include <numeric>
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
    InputPaths(cl::Positional, cl::ZeroOrMore,
               cl::desc("<llvm-ir file or directory>..."), cl::cat(Category));
static cl::opt<bool> MatchesOnly(
    "matches-only",
    cl::desc("Print only the matches, one per line: the file, @function "
             "and bindings, separated by tabs"),
    cl::cat(Category));
static cl::opt<bool> PrintInstructions(
    "print-instructions",
    cl::desc("Add to each match the instructions it matched: each pattern "
             "instruction (by its result or opcode, and its pattern line) and "
             "the position of the IR instruction it matched in its "
             "function; needs --matches-only"),
    cl::cat(Category));
static cl::opt<unsigned>
    Jobs("j",
         cl::desc("Match this many files (with --packs, functions) at once "
                  "(0: one per hardware thread); needs --matches-only"),
         cl::init(1), cl::cat(Category));
static cl::opt<std::string> IndexFile(
    "index",
    cl::desc("Skip the files and functions this index (from metaphir-index) "
             "shows cannot match; needs --matches-only"),
    cl::value_desc("file"), cl::cat(Category));
static cl::opt<bool> TrustIndex(
    "trust-index",
    cl::desc("Match only the indexed files the index shows may match, without "
             "looking for other files or changes to those (needs --index)"),
    cl::cat(Category));
static cl::opt<std::string> PacksDir(
    "packs",
    cl::desc("Match the corpus published in this directory (by "
             "metaphir-index publish) instead of files; needs --matches-only"),
    cl::value_desc("directory"), cl::cat(Category));
static cl::opt<bool> Explain(
    "explain",
    cl::desc("With each function without a match, print why: the structural "
             "match each rejecting constraint rejected, with the instructions "
             "it matched (as --print-instructions prints them), or what the "
             "function lacks for a structural match; not with --matches-only"),
    cl::cat(Category));
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

/// A function to match, and its features when the index has them.
struct Candidate {
  Function *F;
  std::optional<FunctionFeatures> Features;
};

/// The corpus index a pattern is matched with, and the functions its
/// postings show may match.
struct IndexUse {
  const CorpusIndex &Index;
  /// The ordinals of the candidate functions of each entry, by entry index;
  /// none if the postings do not narrow the functions down.
  std::optional<DenseMap<size_t, SmallVector<unsigned, 4>>> Candidates;

  /// The candidates of Entry, if the postings narrow them down.
  std::optional<ArrayRef<unsigned>>
  candidatesOf(const IndexEntry &Entry) const {
    if (!Candidates)
      return std::nullopt;
    auto It = Candidates->find(Index.getEntryIndex(Entry));
    if (It == Candidates->end())
      return ArrayRef<unsigned>();
    return ArrayRef<unsigned>(It->second);
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
    printLoweringErrors(Lowered.takeError(), Loaded->Source, Loaded->Context,
                        Err, ToolName.data());
    return nullptr;
  }
  Loaded->Variants = std::move(*Lowered);
  Loaded->Query = FeatureQuery::compute(*Loaded->Variants, &Loaded->Context);
  return Loaded;
}

/// The defined functions of File to match, in order: those the index shows
/// may match, or, when it does not cover the file as it is, all of them. The
/// module of the file is loaded into Context, lazily when the index is used.
static Expected<std::unique_ptr<Module>>
loadFunctions(const LoadedPattern &Pattern, const IndexUse *Use, StringRef File,
              StringRef ToolName, LLVMContext &Context,
              SmallVectorImpl<Candidate> &Functions, raw_ostream &Err,
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
        Functions.push_back({&F, std::nullopt});
    Stats.Functions += Functions.size();
    return M;
  };

  if (!Use)
    return LoadAll();
  const CorpusIndex &Index = Use->Index;
  const IndexEntry *Entry = Index.lookup(File);
  if (!Entry || FileStamp::of(File) != Entry->Stamp) {
    Err << ToolName << ": warning: " << File << ": "
        << (Entry ? "changed since indexed" : "not indexed")
        << "; matching it in full\n";
    return LoadAll();
  }
  // A file that does not parse is read, to report why.
  if (!Entry->Parsed)
    return LoadAll();
  Stats.Functions += Entry->NumFunctions;
  // The postings leave out the functions whose coarse features cannot match;
  // without them, the module's summary is checked.
  std::optional<ArrayRef<unsigned>> Listed = Use->candidatesOf(*Entry);
  if (Listed && Listed->empty())
    return nullptr;
  auto MayMatch = [&](const FunctionFeatures &Features) {
    return Pattern.Query.mayMatch(Features);
  };
  if (!Listed) {
    Expected<FunctionFeatures> Summary = Index.readSummary(*Entry, MayMatch);
    if (!Summary)
      return Summary.takeError();
    if (!Summary->Fine || !Pattern.Query.mayMatch(*Summary))
      return nullptr;
  }
  // The fine features are read only where the coarse ones may match.
  unsigned NextOrdinal = 0;
  Expected<std::vector<IndexedFunction>> Indexed =
      Index.readFunctions(*Entry, [&](const FunctionFeatures &Features) {
        unsigned Ordinal = NextOrdinal++;
        return (!Listed || llvm::binary_search(*Listed, Ordinal)) &&
               MayMatch(Features);
      });
  if (!Indexed)
    return Indexed.takeError();
  // The ordinals, among the module's defined functions, of those to match.
  SmallVector<size_t, 8> Candidates;
  for (auto [Ordinal, Function] : enumerate(*Indexed))
    if (Function.Features.Fine && Pattern.Query.mayMatch(Function.Features))
      Candidates.push_back(Ordinal);
  if (Candidates.empty())
    return nullptr;

  std::unique_ptr<Module> M;
  ErrorOr<std::unique_ptr<MemoryBuffer>> Buffer =
      MemoryBuffer::getFile(File, /*IsText=*/false,
                            /*RequiresNullTerminator=*/false);
  if (!Buffer)
    return createFileError(File, Buffer.getError());
  if (isBitcode(
          reinterpret_cast<const unsigned char *>((*Buffer)->getBufferStart()),
          reinterpret_cast<const unsigned char *>((*Buffer)->getBufferEnd()))) {
    // Loaded as for importing, module metadata (mostly debug information) is
    // read only as the materialized functions refer to it.
    Expected<std::unique_ptr<Module>> Lazy = getOwningLazyBitcodeModule(
        std::move(*Buffer), Context, /*ShouldLazyLoadMetadata=*/true,
        /*IsImporting=*/true);
    if (!Lazy)
      return Lazy.takeError();
    M = std::move(*Lazy);
  } else {
    SMDiagnostic Diag;
    M = parseIR((*Buffer)->getMemBufferRef(), Diag, Context);
    if (!M) {
      std::string Message;
      raw_string_ostream OS(Message);
      Diag.print(ToolName.data(), OS);
      return createStringError(inconvertibleErrorCode(), Message);
    }
  }
  ++Stats.ReadFiles;
  // Before a function is materialized, it is defined but empty.
  SmallVector<Function *, 64> Defined;
  for (Function &F : *M)
    if (!F.isDeclaration())
      Defined.push_back(&F);
  if (Defined.size() != Indexed->size() ||
      any_of(Candidates, [&](size_t Ordinal) {
        return IndexedFunction::hashName(Defined[Ordinal]->getName()) !=
               (*Indexed)[Ordinal].NameHash;
      })) {
    // The file is not what was indexed after all.
    Err << ToolName << ": warning: " << File
        << ": differs from its index entry; matching it in full\n";
    Stats.Functions -= Entry->NumFunctions;
    --Stats.ReadFiles;
    M.reset();
    return LoadAll();
  }
  for (size_t Ordinal : Candidates)
    Functions.push_back(
        {Defined[Ordinal], std::move((*Indexed)[Ordinal].Features)});
  for (Candidate &Function : Functions)
    if (Error E = Function.F->materialize())
      return E;
  return M;
}

/// With a trusted index, adds the indexed files under Input that may match:
/// those with candidate functions, and those that do not parse, to report
/// them. Returns false if Input is not under the index's root.
static bool collectIndexedFiles(StringRef Input, const IndexUse &Use,
                                SmallVectorImpl<std::string> &Files) {
  std::optional<std::string> Prefix = Use.Index.getRelativePath(Input);
  if (!Prefix)
    return false;
  for (size_t I = 0; I != Use.Index.size(); ++I) {
    const IndexEntry &Entry = Use.Index.getEntry(I);
    StringRef Path = Entry.Path;
    // Input itself, or a file under it.
    if (!Path.consume_front(*Prefix) ||
        !(Path.empty() || Prefix->empty() ||
          Path.consume_front(sys::path::get_separator())))
      continue;
    std::optional<ArrayRef<unsigned>> Listed = Use.candidatesOf(Entry);
    if (Entry.Parsed && Listed && Listed->empty())
      continue;
    SmallString<256> File(Input);
    if (!Path.empty())
      sys::path::append(File, Path);
    Files.push_back(std::string(File));
  }
  return true;
}

/// Matches the pattern against the functions of one file. Unless only matches
/// are printed, each function is reported as the next target.
static void matchFile(LoadedPattern &Pattern, const IndexUse *Use,
                      StringRef File, StringRef ToolName, raw_ostream &Out,
                      raw_ostream &Err, MatchStats &Stats,
                      unsigned &TargetIndex) {
  ++Stats.Files;
  LLVMContext IRContext;
  SmallVector<Candidate, 64> Functions;
  Expected<std::unique_ptr<Module>> M = loadFunctions(
      Pattern, Use, File, ToolName, IRContext, Functions, Err, Stats);
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
  // Uses of globals in functions not read yet count too.
  std::optional<MaterializingUseOracle> Uses;
  if (*M && (*M)->getMaterializer()) {
    Uses.emplace(**M);
    Matcher.setUseOracle(&*Uses);
  }
  // Numbers the unnamed values of the function whose matches are printed; one
  // per module, as numbering the module's globals is costly.
  std::optional<ModuleSlotTracker> Slots;
  auto SlotsFor = [&](const Function &F) {
    if (!Slots)
      Slots.emplace(F.getParent(), /*ShouldInitializeAllMetadata=*/false);
    if (Slots->getCurrentFunction() != &F)
      Slots->incorporateFunction(F);
    return &*Slots;
  };
  auto PrintMatch = [&](const Function &F, const Instantiation &Match) {
    Match.print(Out, SlotsFor(F));
  };
  for (const Candidate &Function : Functions) {
    const llvm::Function *F = Function.F;
    ++Stats.MatchedFunctions;
    Target Program(*F, Function.Features ? &*Function.Features : nullptr);
    bool HadStructuralMatch = false;
    SmallVector<UnsatisfiedConstraint, 4> Unsatisfied;
    // Only the full output reports the constraints rejecting structural
    // matches; without it, the filter can skip variants by them too.
    MatchResults Matches = Matcher.match(
        *Pattern.Variants, Program, MatchesOnly ? nullptr : &Unsatisfied,
        MatchesOnly ? nullptr : &HadStructuralMatch, Pattern.getFilter());
    if (MatchesOnly) {
      for (const Instantiation &Match : Matches)
        Match.printLine(Out, File, *F, SlotsFor(*F),
                        PrintInstructions ? &Pattern.Source : nullptr);
      continue;
    }
    Out << "target " << TargetIndex++ << ": @" << F->getName() << '\n';
    if (Matches.empty()) {
      Out << "  no match\n";
      if (HadStructuralMatch) {
        for (const UnsatisfiedConstraint &U : Unsatisfied) {
          Out << "  constraint not satisfied: " << *U.Expression;
          if (!U.Reason.empty())
            Out << " (cannot evaluate: " << U.Reason << ")";
          Out << '\n';
          if (Explain) {
            Out << "    rejected: ";
            PrintMatch(*F, U.Rejected);
            Out << '\t';
            U.Rejected.printInstructions(Out, Pattern.Source);
            Out << '\n';
          }
        }
      } else if (Explain) {
        // A variable that would be bound to two values says the most.
        SmallVector<Instantiation::Conflict, 1> Conflicts =
            Matcher.findConflicts(*Pattern.Variants, Program);
        for (const Instantiation::Conflict &C : Conflicts) {
          Out << "  no structural match: ";
          Instantiation::printConflict(Out, C, SlotsFor(*F));
          Out << '\n';
        }
        if (!Conflicts.empty())
          continue;
        FunctionFeatures Features = Function.Features && Function.Features->Fine
                                        ? *Function.Features
                                        : FunctionFeatures::compute(*F);
        for (const std::string &Reason :
             Pattern.Query.explainNoStructure(Features))
          Out << "  no structural match: " << Reason << '\n';
      }
      continue;
    }
    for (auto [Index, Match] : enumerate(Matches)) {
      Out << "  match " << Index << ":\n    ";
      PrintMatch(*F, Match);
      Out << '\n';
    }
  }
}

/// Matches the files on Threads threads, printing each file's output in the
/// order of Files as soon as it and the ones before it are done.
static MatchStats matchInParallel(ArrayRef<std::string> Files,
                                  const IndexUse *Use, unsigned Threads,
                                  StringRef ToolName) {
  std::vector<FileOutput> Outputs(Files.size());
  std::vector<bool> Done(Files.size());
  std::mutex Mutex;
  std::condition_variable FileDone;
  std::atomic<size_t> NextFile{0};
  // The largest files to load go first, so that none is left for the end,
  // alone; the files are looked up in the index on all threads.
  std::vector<size_t> Order(Files.size());
  std::iota(Order.begin(), Order.end(), 0);
  if (Use) {
    std::vector<uint64_t> Sizes(Files.size());
    std::atomic<size_t> NextLookup{0};
    auto LookUp = [&] {
      for (size_t I; (I = NextLookup++) < Files.size();)
        if (const IndexEntry *Entry = Use->Index.lookup(Files[I])) {
          std::optional<ArrayRef<unsigned>> Listed = Use->candidatesOf(*Entry);
          if (!Listed || !Listed->empty())
            Sizes[I] = Entry->Stamp.Size;
        }
    };
    std::vector<std::thread> LookUps;
    for (unsigned I = 0; I != Threads; ++I)
      LookUps.emplace_back(LookUp);
    for (std::thread &LookUpThread : LookUps)
      LookUpThread.join();
    // Order starts as the files' indices, so they break ties stably (without
    // std::stable_sort's temporary buffer, deprecated in newer libstdc++).
    llvm::sort(Order, [&](size_t L, size_t R) {
      return Sizes[L] != Sizes[R] ? Sizes[L] > Sizes[R] : L < R;
    });
  }

  auto Work = [&] {
    std::string PatternErrors;
    raw_string_ostream PatternErr(PatternErrors);
    // The pattern parsed on the main thread, which printed its warnings, so
    // it parses here too.
    std::unique_ptr<LoadedPattern> Pattern =
        loadPattern(ToolName, PatternErr, /*Quiet=*/true);
    for (size_t Next; (Next = NextFile++) < Files.size();) {
      size_t FileIndex = Order[Next];
      FileOutput Output;
      if (Pattern) {
        raw_string_ostream Out(Output.Out), Err(Output.Err);
        unsigned TargetIndex = 0;
        matchFile(*Pattern, Use, Files[FileIndex], ToolName, Out, Err,
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

/// Maps the published file Name in PacksDir, reporting an error.
static std::unique_ptr<MemoryBuffer> mapPublished(StringRef Name,
                                                  StringRef ToolName) {
  SmallString<256> Path(PacksDir);
  sys::path::append(Path, Name);
  ErrorOr<std::unique_ptr<MemoryBuffer>> Buffer =
      MemoryBuffer::getFile(Path, /*IsText=*/false,
                            /*RequiresNullTerminator=*/false);
  if (!Buffer) {
    errs() << ToolName << ": error: " << Path << ": "
           << Buffer.getError().message() << '\n';
    return nullptr;
  }
  return std::move(*Buffer);
}

/// Matches the pattern against the corpus published in PacksDir, as the
/// website does, with the files read whole.
static int matchPacks(StringRef ToolName) {
  auto Fail = [&](Error E) {
    logAllUnhandledErrors(std::move(E), errs(), Twine(ToolName) + ": error: ");
    return 1;
  };
  std::unique_ptr<MemoryBuffer> Header =
      mapPublished(WebHeaderFileName, ToolName);
  if (!Header)
    return 1;
  Expected<std::unique_ptr<WebIndex>> Index =
      WebIndex::read(Header->getBuffer());
  if (!Index)
    return Fail(Index.takeError());
  std::unique_ptr<MemoryBuffer> Files[NumWebFiles];
  ByteCache Cache;
  for (unsigned File = 0; File != NumWebFiles; ++File) {
    Files[File] = mapPublished(getWebFileName(WebFile(File)), ToolName);
    if (!Files[File])
      return 1;
    Cache.addBorrowed(WebFile(File), 0, Files[File]->getBuffer());
  }
  ErrorOr<std::unique_ptr<MemoryBuffer>> Source =
      MemoryBuffer::getFile(PatternFilename);
  if (!Source)
    return Fail(createFileError(PatternFilename, Source.getError()));
  auto Compile = [&] {
    return WebQuery::compile(**Index, (*Source)->getBuffer(), PatternFilename);
  };
  Expected<std::unique_ptr<WebQuery>> Query = Compile();
  if (!Query)
    return Fail(Query.takeError());
  using Stage =
      Expected<std::vector<ByteRange>> (WebQuery::*)(const ByteCache &);
  for (Stage Next : {&WebQuery::findLists, &WebQuery::findCandidates,
                     &WebQuery::findFeatures, &WebQuery::filterCandidates})
    if (Expected<std::vector<ByteRange>> Needed = ((**Query).*Next)(Cache);
        !Needed)
      return Fail(Needed.takeError());

  // The matches of each function, printed in order as they are done.
  ArrayRef<uint32_t> Matchable = (*Query)->getMatchable();
  struct Output {
    std::string Out, Err;
  };
  std::vector<Output> Outputs(Matchable.size());
  std::vector<bool> Done(Matchable.size());
  std::mutex Mutex;
  std::condition_variable FunctionDone;
  std::atomic<size_t> Next{0};
  std::atomic<bool> Failed{false};
  auto Work = [&] {
    // Each thread matches with its own pattern.
    Expected<std::unique_ptr<WebQuery>> Own = Compile();
    // A pattern that does not compile is reported once, with the first
    // function this thread takes; the functions it takes are still done.
    std::optional<std::string> CompileError;
    if (!Own)
      CompileError = toString(Own.takeError());
    for (size_t I; (I = Next++) < Matchable.size();) {
      Output Matched;
      raw_string_ostream Out(Matched.Out);
      Error E = [&]() -> Error {
        if (Own) {
          PackLocation Pack = (*Query)->getPackLocation(Matchable[I]);
          return (*Own)->match(Matchable[I], *Cache.get(Pack.Frame), Pack.Slot,
                               Out, PrintInstructions);
        }
        Failed = true;
        if (!CompileError)
          return Error::success();
        Error First = createStringError(*CompileError);
        CompileError.reset();
        return First;
      }();
      if (E) {
        Failed = true;
        raw_string_ostream(Matched.Err)
            << ToolName << ": error: " << toString(std::move(E)) << '\n';
      }
      std::lock_guard<std::mutex> Lock(Mutex);
      Outputs[I] = std::move(Matched);
      Done[I] = true;
      FunctionDone.notify_all();
    }
  };
  unsigned Threads =
      Jobs ? Jobs.getValue() : hardware_concurrency().compute_thread_count();
  std::vector<std::thread> Workers;
  for (unsigned I = 0; I != std::max(Threads, 1u); ++I)
    Workers.emplace_back(Work);
  for (size_t I = 0; I != Matchable.size(); ++I) {
    Output Matched;
    {
      std::unique_lock<std::mutex> Lock(Mutex);
      FunctionDone.wait(Lock, [&] { return bool(Done[I]); });
      Matched = std::move(Outputs[I]);
    }
    outs() << Matched.Out;
    errs() << Matched.Err;
  }
  for (std::thread &Worker : Workers)
    Worker.join();
  if (PrintSummary)
    errs() << "matched " << Matchable.size() << " of "
           << (*Index)->getNumFunctions() << " functions ("
           << (*Query)->getCandidates().size() << " on the posting lists)\n";
  return Failed ? 1 : 0;
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
  if (Explain && MatchesOnly) {
    errs() << ToolName << ": error: --explain is not for --matches-only\n";
    return 1;
  }
  if (PrintInstructions && !MatchesOnly) {
    errs() << ToolName
           << ": error: --print-instructions needs --matches-only\n";
    return 1;
  }
  if (!IndexFile.empty() && !MatchesOnly) {
    errs() << ToolName << ": error: --index needs --matches-only\n";
    return 1;
  }
  if (TrustIndex && IndexFile.empty()) {
    errs() << ToolName << ": error: --trust-index needs --index\n";
    return 1;
  }
  if (!PacksDir.empty()) {
    if (!MatchesOnly || !IndexFile.empty() || !InputPaths.empty()) {
      errs() << ToolName
             << ": error: --packs needs --matches-only, and no --index or "
                "input files\n";
      return 1;
    }
    // Report the pattern's errors and warnings as for files.
    if (!loadPattern(ToolName, errs()))
      return 1;
    return matchPacks(ToolName);
  }
  if (InputPaths.empty()) {
    errs() << ToolName
           << ": error: expected LLVM IR files or directories to match\n";
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
  std::optional<IndexUse> Use;
  if (Index) {
    Expected<std::optional<std::vector<FunctionLocation>>> Found =
        Index->findCandidates(Pattern->Query);
    if (!Found) {
      logAllUnhandledErrors(Found.takeError(), errs(),
                            Twine(ToolName) + ": error: ");
      return 1;
    }
    Use.emplace(IndexUse{*Index, std::nullopt});
    if (*Found) {
      Use->Candidates.emplace();
      for (const FunctionLocation &Location : **Found)
        (*Use->Candidates)[Location.Entry].push_back(Location.Ordinal);
    }
  }
  const IndexUse *UsePtr = Use ? &*Use : nullptr;

  SmallVector<std::string, 16> InputFiles;
  for (const std::string &Input : InputPaths)
    if (!(TrustIndex && collectIndexedFiles(Input, *Use, InputFiles)) &&
        !collectLLVMIRFiles(Input, InputFiles, errs()))
      return 1;

  unsigned Threads =
      Jobs ? Jobs.getValue() : hardware_concurrency().compute_thread_count();
  MatchStats Stats;
  if (Threads > 1) {
    Stats = matchInParallel(InputFiles, UsePtr, Threads, ToolName);
  } else {
    unsigned TargetIndex = 0;
    for (const std::string &InputFile : InputFiles)
      matchFile(*Pattern, UsePtr, InputFile, ToolName, outs(), errs(), Stats,
                TargetIndex);
  }
  if (PrintSummary)
    errs() << "matched " << Stats.MatchedFunctions << " of " << Stats.Functions
           << " functions (in " << Stats.ReadFiles << " of " << Stats.Files
           << " files)\n";
  return Stats.Failed ? 1 : 0;
}
