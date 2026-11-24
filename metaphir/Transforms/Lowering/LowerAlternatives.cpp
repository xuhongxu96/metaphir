//===- LowerAlternatives.cpp - mpir-lower-alternatives --------------------===//
//
// See Passes.td: ':c' and ':o' become mpir.alt.
//
//===----------------------------------------------------------------------===//

#include "metaphir/Dialect/Expr/ExprDialect.h"
#include "metaphir/Dialect/Pattern/PatternDialect.h"
#include "metaphir/Dialect/Surface/SurfacePrinter.h"
#include "metaphir/IR/PredicateKeyword.h"
#include "metaphir/Transforms/Lowering/Passes.h"
#include "mlir/IR/BuiltinOps.h"
#include "llvm/IR/InstrTypes.h"

namespace llvm {
namespace metaphir {

#define GEN_PASS_DEF_LOWERALTERNATIVESPASS
#include "metaphir/Transforms/Lowering/Passes.h.inc"
namespace lowering {

using mlir::Location;
using mlir::OpBuilder;
using mlir::Value;
using namespace mpir;

//===----------------------------------------------------------------------===//
// mpir-lower-alternatives
//===----------------------------------------------------------------------===//

namespace {
/// The predicate of a compare matched with its operands swapped, when the
/// pattern names it by a variable: the variable, and the fresh one the
/// swapped compare matches the instruction's predicate with.
struct SwappedPredicate {
  Value Named;
  Value Matched;
};
} // namespace

/// Makes the predicate of Parts, a compare of floating-point values
/// (FloatingPoint) or of integers, the one of the compare with its operands
/// swapped: the swapped keyword for one the pattern spells, or a fresh
/// variable for one it names by a variable, which bindSwappedPredicate binds
/// it to.
static std::optional<SwappedPredicate> swapPredicate(OpBuilder &Builder,
                                                     Location Loc,
                                                     MatcherParts &Parts,
                                                     bool FloatingPoint) {
  for (MatcherOperandView &Op : Parts.Operands) {
    if (Op.Kind != OperandKind::Predicate)
      continue;
    if (auto Keyword = Op.Val.getDefiningOp<KeywordOp>()) {
      // A keyword the compare cannot have ('icmp oeq') matches nothing,
      // swapped or not.
      if (std::optional<CmpInst::Predicate> Predicate =
              keyword_constant::getPredicate(Keyword.getKeyword(),
                                             FloatingPoint))
        Op.Val =
            KeywordOp::create(Builder, Keyword.getLoc(), Keyword.getType(),
                              *keyword_constant::getPredicateKeyword(
                                  CmpInst::getSwappedPredicate(*Predicate)));
      return std::nullopt;
    }
    SwappedPredicate Swapped{
        Op.Val,
        VarOp::create(
            Builder, Loc,
            SortType::get(Builder.getContext(), Sort::CmpPredicate),
            Builder.getStringAttr("_swapped$" + getMetaVariableName(Op.Val)))};
    Op.Val = Swapped.Matched;
    return Swapped;
  }
  return std::nullopt;
}

/// Binds the variable naming the predicate to the swapped predicate of what
/// the swapped compare matched: 'let ?pred = swappedPredicate(?matched)'.
static void bindSwappedPredicate(OpBuilder &Builder, Location Loc,
                                 const SwappedPredicate &Swapped) {
  mlir::MLIRContext *Context = Builder.getContext();
  Value Read = mpir_expr::ReadOp::create(
      Builder, Loc, SortType::get(Context, Sort::String), Swapped.Matched);
  Value Predicate = mpir_expr::CallOp::create(
      Builder, Loc, SortType::get(Context, Sort::CmpPredicate),
      unsigned(constraint::O_SwappedPredicate), unsigned(constraint::Call),
      mlir::ValueRange(Read), Value());
  LetOp::create(Builder, Loc, Swapped.Named, Predicate);
}

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
    else
      llvm_unreachable(
          "commutative instruction with unexpected number of operands");
  }

  // A compare with its operands swapped matches the instruction with the
  // swapped predicate.
  instruction::InstructionID ID = Inst.getOpcode().getValue();
  bool IsCompare = ID == instruction::I_icmp || ID == instruction::I_fcmp;
  auto Build = [&](bool Swap) -> Value {
    MatcherParts P = Parts;
    std::optional<SwappedPredicate> Predicate;
    if (Swap) {
      std::swap(P.Operands[ValuePositions[Swapped->first]],
                P.Operands[ValuePositions[Swapped->second]]);
      if (IsCompare)
        Predicate = swapPredicate(Builder, Loc, P, ID == instruction::I_fcmp);
    }
    Value Result = P.buildInst(Builder, Loc, Inst.getOpcodeAttr()).getResult();
    if (Predicate)
      bindSwappedPredicate(Builder, Loc, *Predicate);
    return Result;
  };

  auto MakeAlt = [&](unsigned NumRegions) {
    mlir::StringAttr Name;
    if (std::optional<StringRef> N = Inst.getResultName())
      Name = Builder.getStringAttr(*N);
    return AltOp::create(Builder, Loc, Inst.getType(), Name, NumRegions);
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
    Result = Alt.getResult();
  } else {
    Result = Itself();
  }
  Inst.getResult().replaceAllUsesWith(Result);
  Inst.erase();
}

namespace {
struct LowerAlternativesPass
    : impl::LowerAlternativesPassBase<LowerAlternativesPass> {
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

} // namespace metaphir
} // namespace llvm
