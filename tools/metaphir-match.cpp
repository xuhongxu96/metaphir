#include "metaphir/IR/MIRContext.h"
#include "metaphir/IR/MetaVariable.h"
#include "metaphir/IR/Pattern.h"
#include "metaphir/Matching/ConstraintInterpreter.h"
#include "metaphir/Matching/NaiveMatcher.h"
#include "metaphir/Parser/MIRParser.h"
#include "llvm/ADT/STLExtras.h"
#include "llvm/IRReader/IRReader.h"
#include "llvm/IR/Module.h"
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

  std::error_code EC;
  for (sys::fs::recursive_directory_iterator I(Input, EC, false), E;
       I != E && !EC; I.increment(EC)) {
    StringRef Path = I->path();
    if (!sys::fs::is_regular_file(Path))
      continue;

    StringRef Extension = sys::path::extension(Path);
    if (Extension == ".ll" || Extension == ".bc")
      Files.push_back(Path.str());
  }

  if (EC) {
    errs() << Input << ": " << EC.message() << '\n';
    return false;
  }

  return true;
}

static Expected<MatchResults>
applyConstraints(const Pattern &Pattern, MatchResults Matches,
                 SmallVectorImpl<const Constraint *> &Unsatisfied) {
  ConstraintInterpreter Interpreter;
  MatchResults Filtered;
  for (Instantiation &Match : Matches) {
    bool Satisfies = true;
    for (const Constraint *Expression : Pattern.getConstraints()) {
      Expected<ConstraintValue> Result =
          Interpreter.evaluate(*Expression, Match);
      if (!Result)
        return Result.takeError();
      if (!Result->getBoolean()) {
        Satisfies = false;
        if (llvm::find(Unsatisfied, Expression) == Unsatisfied.end())
          Unsatisfied.push_back(Expression);
      }
    }
    if (Satisfies)
      Filtered.push_back(std::move(Match));
  }
  return Filtered;
}

int main(int Argc, char **Argv) {
  if (Argc < 3) {
    errs() << "usage: metaphir-match <pattern> <llvm-ir>...\n";
    return 1;
  }

  SourceMgr PatternSource;
  MIRContext Context;
  Pattern *Pattern = nullptr;
  if (!parsePattern(Argv[1], PatternSource, Context, Pattern))
    return 1;

  SmallVector<std::string, 16> InputFiles;
  for (int Argument = 2; Argument != Argc; ++Argument)
    if (!collectLLVMIRFiles(Argv[Argument], InputFiles))
      return 1;
  llvm::sort(InputFiles);

  NaiveMatcher Matcher;
  unsigned TargetIndex = 0;
  for (const std::string &InputFile : InputFiles) {
    LLVMContext LLVMContext;
    SMDiagnostic Error;
    std::unique_ptr<Module> Module =
        parseIRFile(InputFile, Error, LLVMContext);
    if (!Module) {
      Error.print(Argv[0], errs());
      return 1;
    }

    for (const Function &Function : *Module) {
      if (Function.isDeclaration())
        continue;
      Target Program(Function);
      MatchResults Matches = Matcher.matchInstantiations(*Pattern, Program);
      bool HadGraphMatch = !Matches.empty();
      SmallVector<const Constraint *, 4> Unsatisfied;
      Expected<MatchResults> ConstrainedMatches =
          applyConstraints(*Pattern, std::move(Matches), Unsatisfied);
      if (!ConstrainedMatches) {
        logAllUnhandledErrors(ConstrainedMatches.takeError(), errs(),
                              "metaphir-match: ");
        return 1;
      }
      Matches = std::move(*ConstrainedMatches);
      outs() << "target " << TargetIndex++ << ": @" << Function.getName()
             << '\n';
      if (Matches.empty()) {
        outs() << "  no match\n";
        if (HadGraphMatch)
          for (const Constraint *Expression : Unsatisfied)
            outs() << "  constraint not satisfied: " << *Expression << '\n';
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
