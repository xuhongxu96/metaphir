#include "metaphir/IR/MIRContext.h"
#include "metaphir/IR/MetaVariable.h"
#include "metaphir/IR/Pattern.h"
#include "metaphir/IR/PatternLowering.h"
#include "metaphir/IR/PatternVariants.h"
#include "metaphir/Matching/ConstraintInterpreter.h"
#include "metaphir/Matching/ConstraintOps.h"
#include "metaphir/Matching/PatternMatcher.h"
#include "metaphir/Parser/MIRParser.h"
#include "llvm/ADT/STLExtras.h"
#include "llvm/IR/Module.h"
#include "llvm/IRReader/IRReader.h"
#include "llvm/Support/Error.h"
#include "llvm/Support/FileSystem.h"
#include "llvm/Support/MemoryBuffer.h"
#include "llvm/Support/Path.h"
#include "llvm/Support/SourceMgr.h"
#include "llvm/Support/raw_ostream.h"
#include <cassert>
#include <string>
#include <utility>

using namespace llvm;
using namespace llvm::metaphir;

static bool parsePattern(StringRef Filename, SourceMgr &SM, MIRContext &Context,
                         Pattern *&Result) {
  ErrorOr<std::unique_ptr<MemoryBuffer>> Buffer =
      MemoryBuffer::getFile(Filename);
  if (!Buffer) {
    errs() << Filename << ": " << Buffer.getError().message() << '\n';
    return false;
  }
  SM.AddNewSourceBuffer(std::move(*Buffer), SMLoc());
  SMDiagnostic Error;
  MIRParser Parser(SM.getMemoryBuffer(SM.getMainFileID())->getBuffer(), SM,
                   Error, Context);
  if (!Parser.parse(Result))
    return true;
  Error.print("metaphir-match", errs());
  return false;
}

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

struct UnsatisfiedConstraint {
  const Constraint *Expression;
  std::string Reason; // empty unless the constraint could not be evaluated
};

static MatchResults
applyConstraints(const Pattern &Pattern, MatchResults Matches,
                 SmallVectorImpl<UnsatisfiedConstraint> &Unsatisfied,
                 MIRContext &Context) {
  ConstraintInterpreter Interpreter(&Context);
  MatchResults Filtered;
  for (Instantiation &Match : Matches) {
    bool Satisfies = true;
    for (const Constraint *Expression : Pattern.getConstraints()) {
      Expected<ConstraintValue> Result =
          Interpreter.evaluate(*Expression, Match);
      if (!Result) {
        // A constraint that cannot be evaluated for a particular binding
        // (e.g. arithmetic on a non-constant value) is recorded as
        // unsatisfied, carrying the evaluation reason (the constraint itself
        // indicates the error position).
        std::string Reason = "constraint could not be evaluated";
        handleAllErrors(
            Result.takeError(),
            [&](const metaphir::detail::ConstraintEvaluationError &E) {
              Reason = E.Message;
            },
            [&](const ErrorInfoBase &E) { Reason = E.message(); });
        Satisfies = false;
        if (llvm::find_if(Unsatisfied, [&](const UnsatisfiedConstraint &U) {
              return U.Expression == Expression;
            }) == Unsatisfied.end())
          Unsatisfied.push_back({Expression, std::move(Reason)});
        break;
      }
      if (!Result->getBoolean()) {
        Satisfies = false;
        if (llvm::find_if(Unsatisfied, [&](const UnsatisfiedConstraint &U) {
              return U.Expression == Expression;
            }) == Unsatisfied.end())
          Unsatisfied.push_back({Expression, ""});
      }
    }
    if (Satisfies)
      Filtered.push_back(std::move(Match));
  }
  return Filtered;
}

static MatchResults
matchAndFilterPattern(const PatternVariants &Variants, const Target &Program,
                      PatternMatcher &Matcher, MIRContext &Context,
                      SmallVectorImpl<UnsatisfiedConstraint> &Unsatisfied,
                      bool &HadGraphMatch) {
  MatchResults Combined;
  for (const Pattern *Variant : Variants) {
    MatchResults VarMatches = Matcher.match(*Variant, Program);
    if (!VarMatches.empty())
      HadGraphMatch = true;
    SmallVector<UnsatisfiedConstraint, 4> VarUnsatisfied;
    VarMatches = applyConstraints(*Variant, std::move(VarMatches),
                                  VarUnsatisfied, Context);
    Combined.append(VarMatches.begin(), VarMatches.end());
    if (Combined.empty()) {
      for (const auto &U : VarUnsatisfied)
        Unsatisfied.push_back(U);
    }
  }
  return Combined;
}

int main(int Argc, char **Argv) {
  if (Argc < 3) {
    errs() << "usage: metaphir-match <pattern> <llvm-ir>...\n";
    return 1;
  }

  SourceMgr PatternSource;
  MIRContext Context;
  Pattern *RawPattern = nullptr;
  if (!parsePattern(Argv[1], PatternSource, Context, RawPattern))
    return 1;
  Expected<PatternVariants> Lowered = PatternLowering(Context).lower(RawPattern);
  if (!Lowered) {
    logAllUnhandledErrors(Lowered.takeError(), errs(), "metaphir-match: ");
    return 1;
  }
  PatternVariants Patterns = std::move(*Lowered);

  SmallVector<std::string, 16> InputFiles;
  for (int Argument = 2; Argument != Argc; ++Argument)
    if (!collectLLVMIRFiles(Argv[Argument], InputFiles))
      return 1;

  PatternMatcher Matcher;
  unsigned TargetIndex = 0;
  for (const std::string &InputFile : InputFiles) {
    LLVMContext LLVMContext;
    SMDiagnostic Error;
    std::unique_ptr<Module> Module = parseIRFile(InputFile, Error, LLVMContext);
    if (!Module) {
      Error.print(Argv[0], errs());
      return 1;
    }

    for (const Function &Function : *Module) {
      if (Function.isDeclaration())
        continue;
      Target Program(Function);
      bool HadGraphMatch = false;
      SmallVector<UnsatisfiedConstraint, 4> Unsatisfied;
      MatchResults Matches = matchAndFilterPattern(
          Patterns, Program, Matcher, Context, Unsatisfied, HadGraphMatch);
      outs() << "target " << TargetIndex++ << ": @" << Function.getName()
             << '\n';
      if (Matches.empty()) {
        outs() << "  no match\n";
        if (HadGraphMatch)
          for (const UnsatisfiedConstraint &U : Unsatisfied) {
            outs() << "  constraint not satisfied: " << *U.Expression;
            if (!U.Reason.empty())
              outs() << " (cannot evaluate: " << U.Reason << ")";
            outs() << '\n';
          }
        continue;
      }
      for (unsigned MatchIndex = 0; MatchIndex != Matches.size();
           ++MatchIndex) {
        outs() << "  match " << MatchIndex << ":\n";
        outs() << "    " << Matches[MatchIndex] << '\n';
      }
    }
  }
  return 0;
}
