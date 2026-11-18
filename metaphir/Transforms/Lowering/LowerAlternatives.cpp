//===- LowerAlternatives.cpp - mpir-lower-alternatives --------------------===//
//
// See Lowering.h: ':c' and ':o' become mpir.alt.
//
//===----------------------------------------------------------------------===//

#include "metaphir/Transforms/Lowering/LowerAlternatives.h"
#include "metaphir/Dialect/Pattern/PatternDialect.h"
#include "mlir/IR/BuiltinOps.h"

namespace llvm {
namespace metaphir {
namespace lowering {

using mlir::Location;
using mlir::OpBuilder;
using mlir::Value;
using namespace mpir;

//===----------------------------------------------------------------------===//
// mpir-lower-alternatives
//===----------------------------------------------------------------------===//

/// Replaces ':c' and ':o' on Inst by mpir.alt.
static void lowerAlternatives(InstOp Inst) {
  bool Commutative = Inst.isCommutative();
  std::optional<unsigned> OrSelf = Inst.getOrSelfIndex();
  if (!Commutative && !OrSelf)
    return;
  OpBuilder Builder(Inst);
  Location Loc = Inst.getLoc();
  MatcherParts Parts = MatcherParts::of(Inst);
  Parts.MetaFlags.clear();
  Parts.OperandMetaFlags.clear();

  // The value operands, by their position among them.
  SmallVector<unsigned, 4> ValuePositions;
  for (auto [Index, Op] : enumerate(Parts.Operands))
    if (isValueOperand(Op.Kind))
      ValuePositions.push_back(Index);
  std::optional<std::pair<unsigned, unsigned>> Swapped;
  if (Commutative) {
    unsigned NumOperands = ValuePositions.size();
    if (Inst.getOpcode().getValue() == instruction::I_call && NumOperands == 3)
      Swapped = {1u, 2u};
    else if (NumOperands == 2)
      Swapped = {0u, 1u};
  }
  auto Build = [&](bool Swap) -> Value {
    MatcherParts P = Parts;
    bool SwappedPredicate = false;
    if (Swap) {
      std::swap(P.Operands[ValuePositions[Swapped->first]],
                P.Operands[ValuePositions[Swapped->second]]);
      instruction::InstructionID ID = Inst.getOpcode().getValue();
      SwappedPredicate = ID == instruction::I_icmp || ID == instruction::I_fcmp;
    }
    return P.buildInst(Builder, Loc, Inst.getOpcodeAttr(), SwappedPredicate)
        .getResult();
  };

  auto MakeAlt = [&](unsigned NumRegions) {
    mlir::StringAttr Name;
    if (std::optional<StringRef> N = Inst.getResultName())
      Name = Builder.getStringAttr(*N);
    return AltOp::create(Builder, Loc, Inst.getType(), Name, /*commuted=*/false,
                         mlir::StringAttr(), mlir::IntegerAttr(), NumRegions);
  };
  auto Fill = [&](AltOp Alt, unsigned Index, function_ref<Value()> Body) {
    mlir::Block &Block = Alt->getRegion(Index).emplaceBlock();
    OpBuilder::InsertionGuard Guard(Builder);
    Builder.setInsertionPointToEnd(&Block);
    YieldOp::create(Builder, Loc, Body());
  };

  // The instruction itself: in its order, or (with ':c') either.
  auto Itself = [&]() -> Value {
    if (!Swapped)
      return Build(false);
    AltOp Orders = MakeAlt(2);
    Orders.setCommuted(true);
    Fill(Orders, 0, [&] { return Build(false); });
    Fill(Orders, 1, [&] { return Build(true); });
    return Orders.getResult();
  };
  Value Result;
  if (OrSelf) {
    // Its operand first, then itself, so matches come in that order.
    AltOp Alt = MakeAlt(2);
    Fill(Alt, 1, Itself);
    Fill(Alt, 0, [&]() -> Value {
      Value Operand;
      unsigned Position = *OrSelf;
      for (const MatcherOperandView &Op : Parts.Operands)
        if (isValueOperand(Op.Kind) && Position-- == 0) {
          Operand = Op.Val;
          break;
        }
      if (Parts.Capture)
        BindOp::create(Builder, Loc, Parts.Capture, Operand);
      return Operand;
    });
    Alt.setOrSelfOfAttr(Builder.getStringAttr(
        instruction::getOpcodeName(Inst.getOpcode().getValue())));
    Alt.setOrSelfRegionAttr(Builder.getI32IntegerAttr(0));
    Result = Alt.getResult();
  } else {
    Result = Itself();
  }
  Inst.getResult().replaceAllUsesWith(Result);
  Inst.erase();
}

namespace {
struct LowerAlternativesPass
    : public mlir::PassWrapper<LowerAlternativesPass,
                               mlir::OperationPass<mlir::ModuleOp>> {
  MLIR_DEFINE_EXPLICIT_INTERNAL_INLINE_TYPE_ID(LowerAlternativesPass)
  StringRef getArgument() const override { return "mpir-lower-alternatives"; }
  StringRef getDescription() const override {
    return "Turn ':c' and ':o' into mpir.alt";
  }
  void runOnOperation() override {
    for (PatternOp Pattern : getOperation().getOps<PatternOp>()) {
      SmallVector<InstOp, 16> Insts;
      Pattern.walk([&](InstOp Inst) {
        if (Inst.getMetaflags())
          Insts.push_back(Inst);
      });
      for (InstOp Inst : Insts)
        lowerAlternatives(Inst);
    }
  }
};
} // namespace

} // namespace lowering

std::unique_ptr<mlir::Pass> createLowerAlternativesPass() {
  return std::make_unique<lowering::LowerAlternativesPass>();
}

} // namespace metaphir
} // namespace llvm
