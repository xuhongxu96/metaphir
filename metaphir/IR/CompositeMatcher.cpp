#include "metaphir/IR/CompositeMatcher.h"
#include "metaphir/IR/LibraryDefs.h"
#include "metaphir/IR/MIRContext.h"
#include "metaphir/IR/MIRContextImpl.h"

namespace llvm {
namespace metaphir {

CompositeMatcher *CompositeMatcher::create(
    MIRContext &Context, StringRef Name, bool IsCommutative,
    ArrayRef<InstructionFlag::FlagID> SupportedFlags,
    Instruction::OperandSyntax Syntax, unsigned Arity,
    ArrayRef<ParameterDef> Parameters, ArrayRef<Branch> Branches) {
  MIRContextImpl &Impl = *Context.pImpl;
  SmallVector<ParameterDef, 4> OwnedParameters(Parameters);
  for (ParameterDef &P : OwnedParameters)
    P.Name = Impl.Saver.save(P.Name);
  SmallVector<Branch, 2> OwnedBranches;
  for (const Branch &B : Branches) {
    Branch Copy = B;
    Copy.Instructions = Impl.copyArray(B.Instructions);
    Copy.Constraints = Impl.copyArray(B.Constraints);
    Copy.FixedFlags = Impl.copyArray(B.FixedFlags);
    Copy.ParameterVars = Impl.copyArray(B.ParameterVars);
    Copy.LocalVariables = Impl.copyArray(B.LocalVariables);
    OwnedBranches.push_back(Copy);
  }
  return new (Impl.Alloc) CompositeMatcher(
      Impl.Saver.save(Name), IsCommutative, Impl.copyArray(SupportedFlags),
      Syntax, Arity, Impl.copyArray(ArrayRef<ParameterDef>(OwnedParameters)),
      Impl.copyArray(ArrayRef<Branch>(OwnedBranches)));
}

/// Copies Strings, and the text of each, into the context.
static ArrayRef<StringRef> saveStrings(MIRContextImpl &Impl,
                                       ArrayRef<StringRef> Strings) {
  SmallVector<StringRef, 4> Saved;
  for (StringRef S : Strings)
    Saved.push_back(Impl.Saver.save(S));
  return Impl.copyArray(ArrayRef<StringRef>(Saved));
}

ConstraintDef *ConstraintDef::create(MIRContext &Context, StringRef Name,
                                     ArrayRef<StringRef> Parameters,
                                     ArrayRef<MetaVariable *> ParameterVars,
                                     Constraint *Body) {
  MIRContextImpl &Impl = *Context.pImpl;
  return new (Impl.Alloc)
      ConstraintDef(Impl.Saver.save(Name), saveStrings(Impl, Parameters),
                    Impl.copyArray(ParameterVars), Body);
}

MetaFlagDef *MetaFlagDef::create(MIRContext &Context, StringRef Name,
                                 MetaFlag::Placement Placement,
                                 ArrayRef<StringRef> Parameters,
                                 ArrayRef<MetaVariable *> ParameterVars,
                                 Constraint *Body) {
  MIRContextImpl &Impl = *Context.pImpl;
  return new (Impl.Alloc) MetaFlagDef(Impl.Saver.save(Name), Placement,
                                      saveStrings(Impl, Parameters),
                                      Impl.copyArray(ParameterVars), Body);
}

} // namespace metaphir
} // namespace llvm
