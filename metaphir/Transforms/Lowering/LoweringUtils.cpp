//===- LoweringUtils.cpp - What the lowering passes share -----------------===//
//
// See LoweringUtils.h.
//
//===----------------------------------------------------------------------===//

#include "metaphir/Transforms/Lowering/LoweringUtils.h"

namespace llvm {
namespace metaphir {
namespace lowering {

MatcherParts MatcherParts::of(MatcherUse U) {
  MatcherParts P;
  if (std::optional<StringRef> Name = U.getResultName()) {
    P.ResultName = Name->str();
    P.HasResultName = true;
  }
  P.Flags.assign(U.getFlags().begin(), U.getFlags().end());
  P.Modes.assign(U.getFlagModes().begin(), U.getFlagModes().end());
  for (Value V : U.getFlagCaptures())
    P.FlagCaptures.push_back(V);
  P.Operands = getMatcherOperands(U.Op);
  if (std::optional<mlir::ArrayAttr> Flags = U.getMetaflags())
    P.MetaFlags.assign(Flags->begin(), Flags->end());
  if (std::optional<mlir::ArrayAttr> Flags = U.getOperandMetaflags())
    P.OperandMetaFlags.assign(Flags->begin(), Flags->end());
  P.TreatIntAsVec = U.getTreatIntAsVec();
  P.Capture = U.getCapture();
  P.ParentBlock = U.getParentBlock();
  return P;
}

Operation *MatcherParts::build(OpBuilder &Builder, Location Loc,
                               StringRef OpName, mlir::NamedAttribute Key,
                               bool SwappedPredicate) {
  mlir::MLIRContext *Context = Builder.getContext();
  mlir::OperationState State(Loc, OpName);
  State.addAttribute(Key.getName(), Key.getValue());
  if (HasResultName)
    State.addAttribute("result_name", Builder.getStringAttr(ResultName));
  SmallVector<OperandKind, 8> Kinds;
  SmallVector<Value, 8> Values;
  for (const MatcherOperandView &Op : Operands) {
    Kinds.push_back(Op.Kind);
    if (Op.Type)
      Values.push_back(Op.Type);
    if (Op.Val)
      Values.push_back(Op.Val);
  }
  setMatcherProperties(Builder, State, Flags, Modes, Kinds);
  if (!MetaFlags.empty())
    State.addAttribute("metaflags", Builder.getArrayAttr(MetaFlags));
  if (any_of(OperandMetaFlags,
             [](Attribute A) { return !cast<mlir::ArrayAttr>(A).empty(); }))
    State.addAttribute("operand_metaflags",
                       Builder.getArrayAttr(OperandMetaFlags));
  if (TreatIntAsVec)
    State.addAttribute("treat_int_as_vec", Builder.getBoolAttr(*TreatIntAsVec));
  if (SwappedPredicate)
    State.addAttribute("swapped_predicate", Builder.getUnitAttr());
  if (Capture)
    State.addOperands(Capture);
  if (ParentBlock)
    State.addOperands(ParentBlock);
  State.addOperands(FlagCaptures);
  State.addOperands(Values);
  State.addAttribute(
      "operandSegmentSizes",
      Builder.getDenseI32ArrayAttr({Capture ? 1 : 0, ParentBlock ? 1 : 0,
                                    int32_t(FlagCaptures.size()),
                                    int32_t(Values.size())}));
  State.addTypes(sortType(Context, Sort::Instruction));
  return Builder.create(State);
}

} // namespace lowering
} // namespace metaphir
} // namespace llvm
