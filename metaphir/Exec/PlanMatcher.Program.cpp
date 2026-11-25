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
  DenseMap<mlir::Value, int32_t> Registers;

  int32_t reg(mlir::Value V) {
    auto [It, Inserted] = Registers.try_emplace(V, Program.NumRegisters);
    if (Inserted)
      ++Program.NumRegisters;
    return It->second;
  }
  void op(mlir::Operation &Op);
};

void PlanProgram::Builder::block(mlir::Block &Block) {
  for (mlir::Operation &Op : Block)
    op(Op);
}

void PlanProgram::Builder::op(mlir::Operation &Op) {
  Step S;
  auto Emit = [&](Step::Kind K) {
    S.K = K;
    Program.Steps.push_back(std::move(S));
  };
  if (isa<plan::SlotOp>(Op) || isa<mpir_expr::ExprDialect>(Op.getDialect()))
    return;
  if (auto Each = dyn_cast<plan::ForeachInstructionOp>(Op)) {
    S.Dst = reg(Each.getResult());
    return Emit(Step::Foreach);
  }
  if (auto Either = dyn_cast<plan::EitherOp>(Op)) {
    unsigned Index = Program.Steps.size();
    S.A = Program.Regions.size();
    S.B = Either->getNumRegions();
    Emit(Step::Either);
    for (unsigned I = 0; I != unsigned(Program.Steps[Index].B); ++I)
      Program.Regions.push_back({0, 0});
    for (auto [I, Region] : enumerate(Either->getRegions())) {
      unsigned Begin = Program.Steps.size();
      block(Region.front());
      Program.Regions[Program.Steps[Index].A + I] = {
          Begin, unsigned(Program.Steps.size())};
    }
    Program.Steps[Index].After = Program.Steps.size();
    return;
  }
  if (auto Get = dyn_cast<plan::GetOperandOp>(Op)) {
    S.Src = reg(Get.getInstruction());
    S.Dst = reg(Get.getResult());
    S.A = Get.getIndex();
    return Emit(Step::GetOperand);
  }
  if (auto Get = dyn_cast<plan::GetOperandsFromOp>(Op)) {
    S.Src = reg(Get.getInstruction());
    S.Dst = reg(Get.getResult());
    S.A = Get.getIndex();
    S.Flag = Get.getTypes();
    return Emit(Step::GetOperandsFrom);
  }
  if (auto Get = dyn_cast<plan::GetTypeOp>(Op)) {
    S.Src = reg(Get.getValue());
    S.Dst = reg(Get.getResult());
    S.Flag = Get.getOperandOf();
    return Emit(Step::GetType);
  }
  if (auto Get = dyn_cast<plan::GetParentBlockOp>(Op)) {
    S.Src = reg(Get.getInstruction());
    S.Dst = reg(Get.getResult());
    return Emit(Step::GetParentBlock);
  }
  if (auto Get = dyn_cast<plan::GetFlagOp>(Op)) {
    S.Src = reg(Get.getInstruction());
    S.Dst = reg(Get.getResult());
    S.A = Get.getFlag();
    return Emit(Step::GetFlag);
  }
  if (auto Get = dyn_cast<plan::GetKeyedOp>(Op)) {
    S.Src = reg(Get.getInstruction());
    S.Dst = reg(Get.getResult());
    S.A = int32_t(Get.getKind());
    return Emit(Step::GetKeyed);
  }
  if (auto Get = dyn_cast<plan::GetElementOp>(Op)) {
    S.Src = reg(Get.getAggregate());
    S.Dst = reg(Get.getResult());
    S.A = Get.getIndex();
    return Emit(Step::GetElement);
  }
  if (auto Check = dyn_cast<plan::CheckOpcodeOp>(Op)) {
    S.Src = reg(Check.getValue());
    S.Opcode = Check.getOpcode().getValue();
    return Emit(Step::CheckOpcode);
  }
  if (auto Check = dyn_cast<plan::CheckFlagOp>(Op)) {
    S.Src = reg(Check.getInstruction());
    S.A = Check.getFlag();
    S.Flag = Check.getPresent();
    return Emit(Step::CheckFlag);
  }
  if (auto Check = dyn_cast<plan::CheckOperandCountOp>(Op)) {
    S.Src = reg(Check.getInstruction());
    S.A = Check.getCount();
    S.Flag = Check.getAtLeast();
    return Emit(Step::CheckOperandCount);
  }
  if (auto Check = dyn_cast<plan::CheckTypeOp>(Op)) {
    S.Src = reg(Check.getIrType());
    S.Type = Check.getPattern();
    S.Flag = Check.getTreatIntAsVec();
    return Emit(Step::CheckType);
  }
  if (auto Check = dyn_cast<plan::CheckConstantOp>(Op)) {
    S.Src = reg(Check.getValue());
    S.Flag = Check.getTreatIntAsVec();
    mlir::Attribute Constant = Check.getConstant();
    if (Check.getKeyword()) {
      S.A = cast<mlir::IntegerAttr>(Constant).getInt();
      return Emit(Step::CheckKeyword);
    }
    if (auto Int = dyn_cast<mlir::IntegerAttr>(Constant)) {
      S.Integer = APSInt(Int.getValue(), Int.getType().isUnsignedInteger());
      return Emit(Step::CheckInteger);
    }
    if (auto Float = dyn_cast<mlir::FloatAttr>(Constant)) {
      S.Float = Float.getValue();
      return Emit(Step::CheckFloat);
    }
    S.Name = cast<mlir::StringAttr>(Constant).getValue().str();
    return Emit(Step::CheckGlobal);
  }
  if (auto Check = dyn_cast<plan::CheckAggregateOp>(Op)) {
    S.Src = reg(Check.getValue());
    S.A = Check.getDelimiter();
    S.B = Check.getCount();
    return Emit(Step::CheckAggregate);
  }
  if (auto Check = dyn_cast<plan::CheckBoundOp>(Op)) {
    S.A = Check.getSlot();
    S.Flag = Check.getBound();
    return Emit(Step::CheckBound);
  }
  if (isa<plan::FailOp>(Op))
    return Emit(Step::Fail);
  if (auto Bind = dyn_cast<plan::BindOp>(Op)) {
    S.Src = reg(Bind.getValue());
    S.A = Bind.getSlot();
    if (std::optional<uint32_t> Sort = Bind.getSort()) {
      S.BySort = true;
      S.B = *Sort;
    }
    return Emit(Step::Bind);
  }
  if (auto Bind = dyn_cast<plan::BindConstantOp>(Op)) {
    S.A = Bind.getSlot();
    S.Flag = Bind.getValue();
    return Emit(Step::BindConstant);
  }
  if (auto Check = dyn_cast<plan::CheckOp>(Op)) {
    S.Condition = Check.getCondition();
    S.Range = getSourceRange(Check.getLoc());
    S.FromMetaflag = Check.getFromMetaflag();
    return Emit(Step::Check);
  }
  if (auto Let = dyn_cast<plan::LetOp>(Op)) {
    S.A = Let.getSlot();
    S.Assigned = Let.getValue();
    S.Condition = Let.getCondition();
    S.Range = getSourceRange(Let.getLoc());
    return Emit(Step::Let);
  }
  if (isa<plan::EmitOp>(Op))
    return Emit(Step::Emit);
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
