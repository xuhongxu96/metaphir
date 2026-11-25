//===- PlanMatcher.Program.cpp - Compile match plans to steps -------------===//
//
// A plan's steps are laid out in order, each either's alternatives after it:
//
//   [either] [alternative 0 ...] [alternative 1 ...] [rest of the path ...]
//
//===----------------------------------------------------------------------===//

#include "metaphir/Exec/PlanMatcher.h"

#include "metaphir/Dialect/Expr/ExprDialect.h"
#include "metaphir/Dialect/Pattern/SourceLocation.h"
#include "metaphir/Dialect/Plan/PlanDialect.h"

namespace llvm {
namespace metaphir {

namespace plan = mpir_plan;

/// Compiles a plan's operations into a program's steps.
class PlanProgram::Builder {
public:
  explicit Builder(PlanProgram &Program) : Program(Program) {}

  void block(mlir::Block &Block);

private:
  PlanProgram &Program;
  DenseMap<mlir::Value, plan_step::Register> Registers;

  plan_step::Register reg(mlir::Value V) {
    auto [It, Inserted] = Registers.try_emplace(V, Program.NumRegisters);
    if (Inserted)
      ++Program.NumRegisters;
    return It->second;
  }
  void emit(Step S) { Program.Steps.push_back(std::move(S)); }
  void either(plan::EitherOp Either);
  void op(mlir::Operation &Op);
};

void PlanProgram::Builder::block(mlir::Block &Block) {
  for (mlir::Operation &Op : Block)
    op(Op);
}

void PlanProgram::Builder::either(plan::EitherOp EitherOp) {
  // The either goes before its alternatives, which say what it is: hold its
  // place until they are laid out, then put it there whole.
  unsigned Index = Program.Steps.size();
  emit(std::monostate());
  plan_step::Either EitherStep;
  for (mlir::Region &Alternative : EitherOp->getRegions()) {
    unsigned Begin = Program.Steps.size();
    block(Alternative.front());
    EitherStep.Alternatives.push_back({Begin, unsigned(Program.Steps.size())});
  }
  EitherStep.After = Program.Steps.size();
  Program.Steps[Index] = std::move(EitherStep);
}

void PlanProgram::Builder::op(mlir::Operation &Op) {
  using namespace plan_step;
  // Operands are read in order, which numbers the registers in that order.
  if (isa<plan::SlotOp>(Op) || isa<mpir_expr::ExprDialect>(Op.getDialect()))
    return;
  if (auto Each = dyn_cast<plan::ForeachInstructionOp>(Op))
    return emit(Foreach{reg(Each.getResult())});
  if (auto Either = dyn_cast<plan::EitherOp>(Op))
    return either(Either);
  if (auto Get = dyn_cast<plan::GetOperandOp>(Op))
    return emit(GetOperand{reg(Get.getInstruction()), reg(Get.getResult()),
                           Get.getIndex()});
  if (auto Get = dyn_cast<plan::GetOperandsFromOp>(Op))
    return emit(GetOperandsFrom{reg(Get.getInstruction()), reg(Get.getResult()),
                                Get.getIndex(), Get.getTypes()});
  if (auto Get = dyn_cast<plan::GetTypeOp>(Op))
    return emit(
        GetType{reg(Get.getValue()), reg(Get.getResult()), Get.getOperandOf()});
  if (auto Get = dyn_cast<plan::GetParentBlockOp>(Op))
    return emit(
        GetParentBlock{reg(Get.getInstruction()), reg(Get.getResult())});
  if (auto Get = dyn_cast<plan::GetFlagOp>(Op))
    return emit(GetFlag{reg(Get.getInstruction()), reg(Get.getResult()),
                        Get.getFlag()});
  if (auto Get = dyn_cast<plan::GetKeyedOp>(Op))
    return emit(GetKeyed{reg(Get.getInstruction()), reg(Get.getResult()),
                         Get.getKind()});
  if (auto Get = dyn_cast<plan::GetElementOp>(Op))
    return emit(GetElement{reg(Get.getAggregate()), reg(Get.getResult()),
                           Get.getIndex()});
  if (auto Check = dyn_cast<plan::CheckOpcodeOp>(Op))
    return emit(
        CheckOpcode{reg(Check.getValue()), Check.getOpcode().getValue()});
  if (auto Check = dyn_cast<plan::CheckFlagOp>(Op))
    return emit(CheckFlag{reg(Check.getInstruction()), Check.getFlag(),
                          Check.getPresent()});
  if (auto Check = dyn_cast<plan::CheckOperandCountOp>(Op))
    return emit(CheckOperandCount{reg(Check.getInstruction()), Check.getCount(),
                                  Check.getAtLeast()});
  if (auto Check = dyn_cast<plan::CheckTypeOp>(Op))
    return emit(CheckType{reg(Check.getIrType()), Check.getPattern(),
                          Check.getTreatIntAsVec()});
  if (auto Check = dyn_cast<plan::CheckConstantOp>(Op)) {
    Register Value = reg(Check.getValue());
    mlir::Attribute Constant = Check.getConstant();
    if (Check.getKeyword())
      return emit(
          CheckKeyword{Value, keyword_constant::KeywordID(
                                  cast<mlir::IntegerAttr>(Constant).getInt())});
    if (auto Int = dyn_cast<mlir::IntegerAttr>(Constant))
      return emit(CheckInteger{
          Value, APSInt(Int.getValue(), Int.getType().isUnsignedInteger()),
          Check.getTreatIntAsVec()});
    if (auto Float = dyn_cast<mlir::FloatAttr>(Constant))
      return emit(CheckFloat{Value, Float.getValue()});
    return emit(
        CheckGlobal{Value, cast<mlir::StringAttr>(Constant).getValue().str()});
  }
  if (auto Check = dyn_cast<plan::CheckAggregateOp>(Op))
    return emit(CheckAggregate{reg(Check.getValue()), Check.getDelimiter(),
                               Check.getCount()});
  if (auto Check = dyn_cast<plan::CheckBoundOp>(Op))
    return emit(CheckBound{Check.getSlot(), Check.getBound()});
  if (isa<plan::FailOp>(Op))
    return emit(Fail());
  if (auto B = dyn_cast<plan::BindOp>(Op)) {
    std::optional<Sort> BySort;
    if (std::optional<uint32_t> S = B.getSort())
      BySort = Sort(*S);
    return emit(Bind{reg(B.getValue()), B.getSlot(), BySort});
  }
  if (auto B = dyn_cast<plan::BindConstantOp>(Op))
    return emit(BindConstant{B.getSlot(), B.getValue()});
  if (auto C = dyn_cast<plan::CheckOp>(Op))
    return emit(Check{{C.getCondition(), getSourceRange(C.getLoc())},
                      C.getFromMetaflag()});
  if (auto L = dyn_cast<plan::LetOp>(Op))
    return emit(Let{{L.getCondition(), getSourceRange(L.getLoc())},
                    L.getSlot(),
                    L.getValue()});
  if (isa<plan::EmitOp>(Op))
    return emit(Emit());
  llvm_unreachable("unknown plan step");
}

std::unique_ptr<PlanProgram> PlanProgram::compile(plan::MatcherOp Matcher) {
  std::unique_ptr<PlanProgram> Program(new PlanProgram());
  for (auto [Name, Kind, S, Loc] :
       zip(Matcher.getSlotNames(), Matcher.getSlotKinds(),
           Matcher.getSlotSorts(), Matcher.getSlotLocs())) {
    SlotInfo Info;
    Info.Name = cast<mlir::StringAttr>(Name).getValue().str();
    Info.IsInstruction = Kind == plan::SlotKind::Instruction;
    Info.VariableSort = S;
    Info.Loc = getOutermostSourceRange(cast<mlir::LocationAttr>(Loc)).Start;
    Program->Slots.push_back(std::move(Info));
  }
  Builder(*Program).block(Matcher.getBody().front());
  return Program;
}

} // namespace metaphir
} // namespace llvm
