#include "metaphir/IR/MIRContext.h"
#include "metaphir/IR/Pattern.h"
#include "metaphir/IR/PatternLowering.h"
#include "metaphir/IR/PatternVariants.h"
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
#include "llvm/Support/raw_ostream.h"
#include <string>
#include <utility>

using namespace llvm;
using namespace llvm::metaphir;

static cl::OptionCategory Category("metaphir-match options");
static cl::opt<std::string> PatternFilename(cl::Positional, cl::Required,
                                            cl::desc("<pattern>"),
                                            cl::cat(Category));
static cl::list<std::string>
    InputPaths(cl::Positional, cl::OneOrMore,
               cl::desc("<llvm-ir file or directory>..."), cl::cat(Category));

static bool collectLLVMIRFiles(StringRef Input,
                               SmallVectorImpl<std::string> &Files) {
  bool IsDirectory = false;
  if (std::error_code EC = sys::fs::is_directory(Input, IsDirectory)) {
    errs() << Input << ": " << EC.message() << '\n';
    return false;
  }

  if (!IsDirectory) {
    Files.push_back(Input.str());
    return true;
  }

  SmallVector<std::string, 16> DirectoryFiles;
  std::error_code EC;
  for (sys::fs::recursive_directory_iterator I(Input, EC, false), E;
       I != E && !EC; I.increment(EC)) {
    StringRef Path = I->path();
    if (!sys::fs::is_regular_file(Path))
      continue;

    StringRef Extension = sys::path::extension(Path);
    if (Extension == ".ll" || Extension == ".bc")
      DirectoryFiles.push_back(Path.str());
  }

  if (EC) {
    errs() << Input << ": " << EC.message() << '\n';
    return false;
  }

  llvm::sort(DirectoryFiles);
  Files.append(DirectoryFiles);
  return true;
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

  SourceMgr PatternSource;
  MIRContext Context;
  Pattern *RawPattern = nullptr;
  SMDiagnostic Diag;
  if (parseMIRFile(PatternFilename, PatternSource, Context, RawPattern, Diag)) {
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

  SmallVector<std::string, 16> InputFiles;
  for (const std::string &Input : InputPaths)
    if (!collectLLVMIRFiles(Input, InputFiles))
      return 1;

  PatternMatcher Matcher(&Context);
  unsigned TargetIndex = 0;
  int ExitCode = 0;
  for (const std::string &InputFile : InputFiles) {
    LLVMContext IRContext;
    SMDiagnostic IRDiag;
    std::unique_ptr<Module> M = parseIRFile(InputFile, IRDiag, IRContext);
    if (!M) {
      // Report the module and go on with the others.
      outs().flush();
      IRDiag.print(ToolName.data(), errs());
      ExitCode = 1;
      continue;
    }

    for (const Function &F : *M) {
      if (F.isDeclaration())
        continue;
      Target Program(F);
      bool HadStructuralMatch = false;
      SmallVector<UnsatisfiedConstraint, 4> Unsatisfied;
      MatchResults Matches =
          Matcher.match(*Lowered, Program, &Unsatisfied, &HadStructuralMatch);
      outs() << "target " << TargetIndex++ << ": @" << F.getName() << '\n';
      if (Matches.empty()) {
        outs() << "  no match\n";
        if (HadStructuralMatch)
          for (const UnsatisfiedConstraint &U : Unsatisfied) {
            outs() << "  constraint not satisfied: " << *U.Expression;
            if (!U.Reason.empty())
              outs() << " (cannot evaluate: " << U.Reason << ")";
            outs() << '\n';
          }
        continue;
      }
      for (auto [Index, Match] : enumerate(Matches))
        outs() << "  match " << Index << ":\n    " << Match << '\n';
    }
  }
  return ExitCode;
}
