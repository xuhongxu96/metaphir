#include "metaphir/IR/MIRContext.h"
#include "metaphir/IR/Pattern.h"
#include "metaphir/IR/PatternLowering.h"
#include "metaphir/IR/PatternVariants.h"
#include "metaphir/Index/CorpusIndex.h"
#include "metaphir/Matching/Features.h"
#include "metaphir/Parser/MIRParser.h"
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
      Expected<IndexedModule> Module = CorpusIndex::indexFile(CorpusDir, Path);
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
      OS << ' ' << Instruction::getOpcodeName(Instruction::InstructionID(ID));
  OS << "; " << Features.Globals.size() << " globals\n";
}

static int dump(StringRef ToolName) {
  Expected<CorpusIndex> Index = CorpusIndex::read(DumpIndex);
  if (!Index) {
    logAllUnhandledErrors(Index.takeError(), errs(),
                          Twine(ToolName) + ": error: ");
    return 1;
  }
  for (size_t I = 0; I != Index->size(); ++I) {
    const IndexedModule &Module = Index->getModule(I);
    outs() << "module " << Module.Path;
    if (!Module.Parsed) {
      outs() << ": does not parse\n";
      continue;
    }
    outs() << ':';
    printFeatures(outs(), Module.Summary);
    Expected<std::vector<IndexedFunction>> Functions =
        Index->readFunctions(Module);
    if (!Functions) {
      logAllUnhandledErrors(Functions.takeError(), errs(),
                            Twine(ToolName) + ": error: ");
      return 1;
    }
    for (const IndexedFunction &Function : *Functions) {
      outs() << "  " << Function.Ordinal << " @" << Function.Name << ':';
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
    logAllUnhandledErrors(Lowered.takeError(), errs(),
                          Twine(ToolName) + ": error: ");
    return 1;
  }
  FeatureQuery Query = FeatureQuery::compute(*Lowered);

  Expected<CorpusIndex> Index = CorpusIndex::read(StatsIndex);
  if (!Index) {
    logAllUnhandledErrors(Index.takeError(), errs(),
                          Twine(ToolName) + ": error: ");
    return 1;
  }
  uint64_t Modules = 0, Bytes = 0, Functions = 0;
  uint64_t MatchedModules = 0, MatchedBytes = 0, MatchedFunctions = 0;
  for (size_t I = 0; I != Index->size(); ++I) {
    const IndexedModule &Module = Index->getModule(I);
    Expected<std::vector<IndexedFunction>> ModuleFunctions =
        Index->readFunctions(Module);
    if (!ModuleFunctions) {
      logAllUnhandledErrors(ModuleFunctions.takeError(), errs(),
                            Twine(ToolName) + ": error: ");
      return 1;
    }
    ++Modules;
    Bytes += Module.Size;
    Functions += ModuleFunctions->size();
    // A module that does not parse is matched, to report the error.
    if (Module.Parsed && !Query.mayMatch(Module.Summary))
      continue;
    ++MatchedModules;
    MatchedBytes += Module.Size;
    MatchedFunctions +=
        count_if(*ModuleFunctions, [&](const IndexedFunction &Function) {
          return Query.mayMatch(Function.Features);
        });
  }
  printShare("modules", MatchedModules, Modules);
  printShare("bytes", MatchedBytes, Bytes);
  printShare("functions", MatchedFunctions, Functions);
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
  errs() << ToolName
         << ": error: expected a subcommand: build, dump or stats\n";
  return 1;
}
