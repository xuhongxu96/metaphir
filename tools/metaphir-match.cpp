#include "metaphir/IR/MIRContext.h"
#include "metaphir/IR/MetaVariable.h"
#include "metaphir/IR/Pattern.h"
#include "metaphir/Matching/ConstraintInterpreter.h"
#include "metaphir/Matching/NaiveMatcher.h"
#include "metaphir/Parser/MIRParser.h"
#include "llvm/AsmParser/Parser.h"
#include "llvm/ADT/STLExtras.h"
#include "llvm/IR/Module.h"
#include "llvm/Support/Error.h"
#include "llvm/Support/MemoryBuffer.h"
#include "llvm/Support/SourceMgr.h"
#include "llvm/Support/raw_ostream.h"
#include <cassert>
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

  NaiveMatcher Matcher;
  unsigned TargetIndex = 0;
  for (int Argument = 2; Argument != Argc; ++Argument) {
    LLVMContext LLVMContext;
    SMDiagnostic Error;
    std::unique_ptr<Module> Module =
        parseAssemblyFile(Argv[Argument], Error, LLVMContext);
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
