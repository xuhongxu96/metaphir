#include "metaphir/IR/Pattern.h"
#include "metaphir/IR/MIRContext.h"
#include "metaphir/IR/MIRContextImpl.h"
#include "llvm/ADT/SmallPtrSet.h"
#include "llvm/Support/raw_ostream.h"

namespace llvm {
namespace metaphir {

Pattern::~Pattern() { Context.pImpl->OwnedPatterns.erase(this); }

Pattern *Pattern::create(MIRContext &Context) {
  auto *Result = new Pattern(Context);
  Context.pImpl->OwnedPatterns.insert(Result);
  return Result;
}

Pattern *Pattern::copy() const {
  Pattern *Result = create(Context);
  Result->Instructions = Instructions;
  Result->Constraints = Constraints;
  Result->MetaVariables = MetaVariables;
  Result->FixedFlags = FixedFlags;
  return Result;
}

SmallVector<Instruction *, 4> Pattern::getRoots() const {
  SmallPtrSet<Instruction *, 16> Children;
  for (Instruction *I : Instructions)
    for (const MatcherOperand &Operand : I->getUnkeyedOperands())
      if (Operand.IsInstructionOperand)
        if (auto *Child = dyn_cast_or_null<Instruction>(Operand.Val))
          Children.insert(Child);

  SmallVector<Instruction *, 4> Roots;
  for (Instruction *I : Instructions)
    if (!Children.contains(I))
      Roots.push_back(I);
  return Roots;
}

raw_ostream &operator<<(raw_ostream &OS, const Pattern &P) {
  OS << "pattern instructions=" << P.getInstructions().size()
     << " constraints=" << P.getConstraints().size() << '\n';
  const MetaVariable *CurrentBlock = nullptr;
  for (const Instruction *I : P.getInstructions()) {
    if (I->getParentBlock() != CurrentBlock) {
      CurrentBlock = I->getParentBlock();
      if (CurrentBlock && !CurrentBlock->getName().empty())
        OS << *CurrentBlock << ":\n";
    }
    OS << *I << '\n';
  }
  for (const Constraint *C : P.getConstraints()) {
    OS << "constraint " << *C << '\n';
  }
  for (const MetaVariable *M : P.getMetaVariables())
    OS << "meta " << *M << " type=" << M->getSort() << '\n';
  return OS;
}

} // namespace metaphir
} // namespace llvm
