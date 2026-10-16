#include "metaphir/IR/MIRContext.h"
#include "metaphir/IR/Pattern.h"
#include "metaphir/IR/PatternLowering.h"
#include "metaphir/IR/PatternVariants.h"
#include "metaphir/Index/CorpusIndex.h"
#include "metaphir/Matching/FeatureQuery.h"
#include "metaphir/Parser/MIRParser.h"
#include "metaphir/Web/WebPublisher.h"
#include "llvm/ADT/STLExtras.h"
#include "llvm/ADT/SmallString.h"
#include "llvm/Support/CommandLine.h"
#include "llvm/Support/Error.h"
#include "llvm/Support/Format.h"
#include "llvm/Support/InitLLVM.h"
#include "llvm/Support/Path.h"
#include "llvm/Support/SourceMgr.h"
#include "llvm/Support/Threading.h"
#include "llvm/Support/raw_ostream.h"
#include <atomic>
#include <optional>
#include <string>
#include <thread>
#include <vector>

using namespace llvm;
using namespace llvm::metaphir;

static cl::OptionCategory Category("metaphir-index options");

static cl::SubCommand Build("build",
                            "Index the LLVM IR files under a directory");
static cl::opt<std::string> CorpusDir(cl::Positional, cl::Required,
                                      cl::desc("<corpus directory>"),
                                      cl::sub(Build), cl::cat(Category));
static cl::opt<std::string> OutputFile("o", cl::Required,
                                       cl::desc("The index file to write"),
                                       cl::value_desc("file"), cl::sub(Build),
                                       cl::cat(Category));
static cl::opt<unsigned>
    Jobs("j",
         cl::desc("Index this many files at once (0: one per hardware "
                  "thread)"),
         cl::init(0), cl::sub(Build), cl::cat(Category));

static cl::opt<bool> NoValueFacts(
    "no-value-facts",
    cl::desc("Do not record value-tracking facts (faster, prunes less)"),
    cl::sub(Build), cl::cat(Category));

static cl::SubCommand Dump("dump", "Print the features in an index");
static cl::opt<std::string> DumpIndex(cl::Positional, cl::Required,
                                      cl::desc("<index>"), cl::sub(Dump),
                                      cl::cat(Category));

static cl::SubCommand
    Stats("stats",
          "Count the modules and functions of an index a pattern may match");
static cl::opt<std::string> StatsPattern(cl::Positional, cl::Required,
                                         cl::desc("<pattern>"), cl::sub(Stats),
                                         cl::cat(Category));
static cl::opt<std::string> StatsIndex(cl::Positional, cl::Required,
                                       cl::desc("<index>"), cl::sub(Stats),
                                       cl::cat(Category));

static cl::SubCommand
    Publish("publish",
            "Publish an indexed corpus for matching over HTTP, as the website "
            "and metaphir-match --packs do");
static cl::opt<std::string> PublishIndex(cl::Positional, cl::Required,
                                         cl::desc("<index>"), cl::sub(Publish),
                                         cl::cat(Category));
static cl::opt<std::string>
    PublishOutput("o", cl::Required,
                  cl::desc("The directory to write the published files to"),
                  cl::value_desc("directory"), cl::sub(Publish),
                  cl::cat(Category));
static cl::opt<unsigned>
    PublishJobs("j",
                cl::desc("Pack this many modules at once (0: one per "
                         "hardware thread)"),
                cl::init(0), cl::sub(Publish), cl::cat(Category));

static int build(StringRef ToolName) {
  SmallVector<std::string, 16> Files;
  if (!collectLLVMIRFiles(CorpusDir, Files, errs()))
    return 1;

  std::vector<std::optional<IndexedModule>> Modules(Files.size());
  std::atomic<size_t> NextFile{0};
  std::atomic<bool> Failed{false};
  auto Work = [&] {
    for (size_t Index; (Index = NextFile++) < Files.size();) {
      SmallString<256> Relative(Files[Index]);
      sys::path::replace_path_prefix(Relative, CorpusDir, "");
      StringRef Path = sys::path::relative_path(Relative);
      Expected<IndexedModule> Module = CorpusIndex::indexFile(
          CorpusDir, Path, FeatureOptions{/*ValueFacts=*/!NoValueFacts});
      if (!Module) {
        logAllUnhandledErrors(Module.takeError(), errs(),
                              Twine(ToolName) + ": error: ");
        Failed = true;
        continue;
      }
      Modules[Index] = std::move(*Module);
    }
  };
  unsigned Threads =
      Jobs ? Jobs.getValue() : hardware_concurrency().compute_thread_count();
  std::vector<std::thread> Workers;
  for (unsigned I = 0; I != std::max(Threads, 1u); ++I)
    Workers.emplace_back(Work);
  for (std::thread &Worker : Workers)
    Worker.join();
  if (Failed)
    return 1;

  std::vector<IndexedModule> Indexed;
  unsigned Unparsed = 0;
  for (std::optional<IndexedModule> &Module : Modules) {
    Unparsed += !Module->Parsed;
    Indexed.push_back(std::move(*Module));
  }
  if (Error E = CorpusIndex::write(OutputFile, CorpusDir, Indexed)) {
    logAllUnhandledErrors(std::move(E), errs(), Twine(ToolName) + ": error: ");
    return 1;
  }
  errs() << "indexed " << Indexed.size() << " files";
  if (Unparsed)
    errs() << ", " << Unparsed << " of which do not parse";
  errs() << '\n';
  return 0;
}

static void printFeatures(raw_ostream &OS, const FunctionFeatures &Features) {
  for (unsigned ID = 0; ID != 64; ++ID)
    if (Features.Instructions >> ID & 1)
      OS << ' '
         << metaphir::Instruction::getOpcodeName(
                metaphir::Instruction::InstructionID(ID));
  OS << ';';
  for (uint16_t Edge : Features.Edges)
    OS << ' '
       << metaphir::Instruction::getOpcodeName(
              metaphir::Instruction::InstructionID(Edge / 64))
       << '-'
       << metaphir::Instruction::getOpcodeName(
              metaphir::Instruction::InstructionID(Edge % 64));
  OS << "; " << Features.Globals.size() << " globals\n";
}

static void logError(Error E, StringRef ToolName) {
  logAllUnhandledErrors(std::move(E), errs(), Twine(ToolName) + ": error: ");
}

static int dump(StringRef ToolName) {
  Expected<CorpusIndex> Index = CorpusIndex::read(DumpIndex);
  if (!Index) {
    logAllUnhandledErrors(Index.takeError(), errs(),
                          Twine(ToolName) + ": error: ");
    return 1;
  }
  for (size_t I = 0; I != Index->size(); ++I) {
    const IndexEntry &Entry = Index->getEntry(I);
    outs() << "module " << Entry.Path;
    if (!Entry.Parsed) {
      outs() << ": does not parse\n";
      continue;
    }
    Expected<FunctionFeatures> Summary = Index->readSummary(Entry);
    if (!Summary) {
      logError(Summary.takeError(), ToolName);
      return 1;
    }
    outs() << ':';
    printFeatures(outs(), *Summary);
    Expected<std::vector<IndexedFunction>> Functions =
        Index->readFunctions(Entry);
    if (!Functions) {
      logError(Functions.takeError(), ToolName);
      return 1;
    }
    for (auto [Ordinal, Function] : enumerate(*Functions)) {
      outs() << "  " << Ordinal << ':';
      printFeatures(outs(), Function.Features);
    }
  }
  return 0;
}

static void printShare(StringRef What, uint64_t Part, uint64_t Whole) {
  outs() << What << ": " << Part << " of " << Whole << " ("
         << format("%.2f", Whole ? 100.0 * Part / Whole : 0.0) << "%)\n";
}

static int stats(StringRef ToolName) {
  SourceMgr Source;
  MIRContext Context;
  Pattern *RawPattern = nullptr;
  SMDiagnostic Diag;
  if (parseMIRFile(StatsPattern, Source, Context, RawPattern, Diag)) {
    Diag.print(ToolName.data(), errs());
    return 1;
  }
  Expected<PatternVariants> Lowered =
      PatternLowering(Context).lower(RawPattern);
  if (!Lowered) {
    printLoweringErrors(Lowered.takeError(), Source, Context, errs(),
                        ToolName.data());
    return 1;
  }
  FeatureQuery Query = FeatureQuery::compute(*Lowered, &Context);

  Expected<CorpusIndex> Index = CorpusIndex::read(StatsIndex);
  if (!Index) {
    logAllUnhandledErrors(Index.takeError(), errs(),
                          Twine(ToolName) + ": error: ");
    return 1;
  }
  uint64_t Modules = 0, Bytes = 0, Functions = 0;
  uint64_t MatchedModules = 0, MatchedBytes = 0, MatchedFunctions = 0;
  for (size_t I = 0; I != Index->size(); ++I) {
    const IndexEntry &Entry = Index->getEntry(I);
    ++Modules;
    Bytes += Entry.Stamp.Size;
    Functions += Entry.NumFunctions;
    // As metaphir-match reads them: the fine features only where the coarse
    // ones may match.
    auto MayMatch = [&](const FunctionFeatures &Features) {
      return Query.mayMatch(Features);
    };
    Expected<FunctionFeatures> Summary = Index->readSummary(Entry, MayMatch);
    Expected<std::vector<IndexedFunction>> ModuleFunctions =
        Index->readFunctions(Entry, MayMatch);
    if (!Summary || !ModuleFunctions) {
      logError(joinErrors(Summary.takeError(), ModuleFunctions.takeError()),
               ToolName);
      return 1;
    }
    // A module that does not parse is matched, to report the error.
    if (Entry.Parsed && (!Summary->Fine || !Query.mayMatch(*Summary)))
      continue;
    ++MatchedModules;
    MatchedBytes += Entry.Stamp.Size;
    MatchedFunctions +=
        count_if(*ModuleFunctions, [&](const IndexedFunction &Function) {
          return Function.Features.Fine && Query.mayMatch(Function.Features);
        });
  }
  printShare("modules", MatchedModules, Modules);
  printShare("bytes", MatchedBytes, Bytes);
  printShare("functions", MatchedFunctions, Functions);
  return 0;
}

static int publish(StringRef ToolName) {
  Expected<CorpusIndex> Index = CorpusIndex::read(PublishIndex);
  if (!Index) {
    logAllUnhandledErrors(Index.takeError(), errs(),
                          Twine(ToolName) + ": error: ");
    return 1;
  }
  PublishOptions Options;
  Options.Jobs = PublishJobs;
  Options.Progress = &errs();
  if (Error E = publishCorpus(*Index, PublishOutput, Options)) {
    logAllUnhandledErrors(std::move(E), errs(), Twine(ToolName) + ": error: ");
    return 1;
  }
  errs() << "published " << Index->size() << " files ("
         << Index->getNumFunctions() << " functions) to " << PublishOutput
         << '\n';
  return 0;
}

int main(int Argc, char **Argv) {
  InitLLVM X(Argc, Argv);
  cl::HideUnrelatedOptions(Category);
  cl::SetVersionPrinter(
      [](raw_ostream &OS) { OS << "MetaphIR " METAPHIR_VERSION "\n"; });
  StringRef ToolName = sys::path::filename(Argv[0]);
  cl::ParseCommandLineOptions(
      Argc, Argv,
      "Index LLVM IR modules for matching MetaphIR patterns faster\n");

  if (Build)
    return build(ToolName);
  if (Dump)
    return dump(ToolName);
  if (Stats)
    return stats(ToolName);
  if (Publish)
    return publish(ToolName);
  errs() << ToolName
         << ": error: expected a subcommand: build, dump, stats or publish\n";
  return 1;
}
