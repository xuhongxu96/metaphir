//===- PlanMatcher.cpp - Run match plans on LLVM IR -----------------------===//
//
// A plan's steps are laid out in order, each either's alternatives after it:
//
//   [either] [alternative 0 ...] [alternative 1 ...] [rest of the path ...]
//
// The interpreter runs a range of steps; a choice runs the rest of its range
// once per choice, with the slots it bound undone between them. When an
// alternative's range ends, the path goes on after its either: the ranges
// still to run are kept on a continuation stack.
//
//===----------------------------------------------------------------------===//

#include "metaphir/Exec/PlanMatcher.h"
#include "metaphir/Dialect/Expr/ExprDialect.h"
#include "metaphir/Dialect/Pattern/PatternDialect.h"
#include "metaphir/Dialect/Pattern/SourceLocation.h"
#include "metaphir/Dialect/Plan/PlanDialect.h"
#include "metaphir/Exec/TypePattern.h"
#include "metaphir/IR/Constants.h"
#include "metaphir/Matching/ConstantInteger.h"
#include "metaphir/Matching/ConstraintCoercion.h"
#include "metaphir/Matching/OpcodePredicates.h"
#include "llvm/ADT/StringSet.h"
#include "llvm/IR/BasicBlock.h"
#include "llvm/IR/ConstantRange.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/DerivedTypes.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/InstIterator.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/Intrinsics.h"
#include "llvm/IR/ModuleSlotTracker.h"
#include "llvm/IR/Operator.h"
#include "llvm/Support/raw_ostream.h"

namespace llvm {
namespace metaphir {

namespace plan = mpir_plan;

//===----------------------------------------------------------------------===//
// The program
//===----------------------------------------------------------------------===//

struct PlanProgram::Step {
  enum Kind : uint8_t {
    Foreach,
    Either,
    GetOperand,
    GetOperandsFrom,
    GetType,
    GetParentBlock,
    GetFlag,
    GetKeyed,
    GetElement,
    CheckOpcode,
    CheckFlag,
    CheckOperandCount,
    CheckType,
    CheckInteger,
    CheckFloat,
    CheckKeyword,
    CheckGlobal,
    CheckAggregate,
    CheckBound,
    Bind,
    BindConstant,
    Check,
    Emit,
  };
  Kind K;
  int32_t Dst = -1;
  int32_t Src = -1;
  int32_t A = 0;
  int32_t B = 0;
  /// A flag of the step: present, at least, types, of an operand, swapped,
  /// bound, treat integers as vectors.
  bool Flag = false;
  /// Bind: whether to bind by sort, A being the slot and B the sort.
  bool BySort = false;
  /// Either: its alternatives, Regions[A, A + B), and where the path goes on.
  unsigned After = 0;
  Instruction::InstructionID Opcode = Instruction::InstructionID(0);
  std::optional<APSInt> Integer;
  std::optional<APFloat> Float;
  std::string Name;
  /// Check: the condition, where it is written, and whether a metaflag says
  /// it.
  mlir::Value Condition;
  SMRange Written;
  bool FromMetaflag = false;
};

PlanProgram::PlanProgram() = default;
PlanProgram::~PlanProgram() = default;

namespace {
/// Compiles a plan's operations into steps.
class ProgramBuilder {
public:
  explicit ProgramBuilder(PlanProgram &Program,
                          std::vector<PlanProgram::Step> &Steps,
                          std::vector<std::pair<unsigned, unsigned>> &Regions,
                          TypePatterns &Types)
      : Steps(Steps), Regions(Regions), Types(Types) {}

  void block(mlir::Block &Block);
  unsigned NumRegisters = 0;

private:
  std::vector<PlanProgram::Step> &Steps;
  std::vector<std::pair<unsigned, unsigned>> &Regions;
  TypePatterns &Types;
  DenseMap<mlir::Value, int32_t> Registers;

  int32_t reg(mlir::Value V) {
    auto [It, Inserted] = Registers.try_emplace(V, NumRegisters);
    if (Inserted)
      ++NumRegisters;
    return It->second;
  }
  unsigned typeNode(mlir::ArrayAttr Pattern);
  void op(mlir::Operation &Op);
};
} // namespace

unsigned ProgramBuilder::typeNode(mlir::ArrayAttr Pattern) {
  return Types.add(Pattern);
}

void ProgramBuilder::block(mlir::Block &Block) {
  for (mlir::Operation &Op : Block)
    op(Op);
}

void ProgramBuilder::op(mlir::Operation &Op) {
  using Step = PlanProgram::Step;
  Step S;
  auto Emit = [&](Step::Kind K) {
    S.K = K;
    Steps.push_back(std::move(S));
  };
  if (isa<plan::YieldOp, plan::SlotOp>(Op) ||
      isa<mpir_expr::ExprDialect>(Op.getDialect()))
    return;
  if (auto Each = dyn_cast<plan::ForeachInstructionOp>(Op)) {
    S.Dst = reg(Each.getResult());
    return Emit(Step::Foreach);
  }
  if (auto Either = dyn_cast<plan::EitherOp>(Op)) {
    unsigned Index = Steps.size();
    S.A = Regions.size();
    S.B = Either->getNumRegions();
    Emit(Step::Either);
    for (unsigned I = 0; I != unsigned(Steps[Index].B); ++I)
      Regions.push_back({0, 0});
    for (auto [I, Region] : enumerate(Either->getRegions())) {
      unsigned Begin = Steps.size();
      block(Region.front());
      Regions[Steps[Index].A + I] = {Begin, unsigned(Steps.size())};
    }
    Steps[Index].After = Steps.size();
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
    S.A = Get.getKind();
    S.Flag = Get.getSwapped();
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
    S.A = typeNode(Check.getPattern());
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
    S.Written = getSourceRange(Check.getLoc());
    S.FromMetaflag = Check.getFromMetaflag();
    return Emit(Step::Check);
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
    Info.IsInstruction = Kind == int32_t(plan::SlotKind::Instruction);
    Info.VariableSort = Sort(S);
    Info.Written = getOutermostSourceRange(cast<mlir::LocationAttr>(Loc)).Start;
    Program->Slots.push_back(std::move(Info));
  }
  ProgramBuilder Builder(*Program, Program->Steps, Program->Regions,
                         Program->Types);
  Builder.block(Matcher.getBody().front());
  Program->NumRegisters = Builder.NumRegisters;
  return Program;
}

//===----------------------------------------------------------------------===//
// Matches
//===----------------------------------------------------------------------===//

/// Whether a slot is a named meta variable, which a match reports.
static bool isReported(const SlotInfo &Slot) {
  return !Slot.IsInstruction && !Slot.Name.empty() &&
         !StringRef(Slot.Name).starts_with("_");
}

void PlanMatch::print(raw_ostream &OS, ModuleSlotTracker *Slots) const {
  SmallVector<std::pair<StringRef, const Binding *>, 8> Named;
  StringSet<> SeenNames;
  for (auto [Index, Slot] : enumerate(Program->getSlots()))
    if (isReported(Slot) && lookup(Index) && SeenNames.insert(Slot.Name).second)
      Named.emplace_back(Slot.Name, lookup(Index));
  llvm::sort(Named,
             [](const auto &L, const auto &R) { return L.first < R.first; });
  OS << '{';
  for (auto [Index, Each] : enumerate(Named)) {
    if (Index)
      OS << ", ";
    OS << '?' << Each.first << " = ";
    printBinding(OS, *Each.second, Slots);
  }
  OS << '}';
}

void PlanMatch::printInstructions(raw_ostream &OS,
                                  const SourceMgr &Source) const {
  struct Matched {
    std::optional<unsigned> Line;
    std::string Name;
    const llvm::Instruction *Target;
  };
  SmallVector<Matched, 8> All;
  for (auto [Index, Slot] : enumerate(Program->getSlots())) {
    if (!Slot.IsInstruction)
      continue;
    const Binding *B = lookup(Index);
    const auto *const *Value =
        B ? std::get_if<const llvm::Value *>(&B->Data) : nullptr;
    const auto *Target = Value ? dyn_cast<llvm::Instruction>(*Value) : nullptr;
    if (!Target)
      continue;
    // An unnamed matcher is named by its opcode: that of the instruction it
    // matched.
    std::string Name = Slot.Name.empty() ? Target->getOpcodeName() : Slot.Name;
    All.push_back({getMainFileLine(Source, Slot.Written), Name, Target});
  }
  if (All.empty()) {
    OS << "{}";
    return;
  }
  DenseMap<const llvm::Instruction *, unsigned> Positions;
  for (const llvm::Instruction &I :
       instructions(*All.front().Target->getFunction()))
    Positions[&I] = Positions.size();
  llvm::sort(All, [&](const Matched &L, const Matched &R) {
    return std::make_tuple(L.Line.value_or(~0u), L.Name, Positions[L.Target]) <
           std::make_tuple(R.Line.value_or(~0u), R.Name, Positions[R.Target]);
  });
  OS << '{';
  for (auto [Index, Each] : enumerate(All)) {
    if (Index)
      OS << ", ";
    OS << Each.Name;
    if (Each.Line)
      OS << '@' << *Each.Line;
    OS << " = #" << Positions[Each.Target];
  }
  OS << '}';
}

void PlanMatch::printLine(raw_ostream &OS, StringRef Module,
                          const llvm::Function &F, ModuleSlotTracker *Slots,
                          const SourceMgr *Source) const {
  OS << Module << "\t@" << F.getName() << '\t';
  print(OS, Slots);
  if (Source) {
    OS << '\t';
    printInstructions(OS, *Source);
  }
  OS << '\n';
}

bool PlanMatch::operator==(const PlanMatch &Other) const {
  return Bindings == Other.Bindings;
}

void PlanConflict::print(raw_ostream &OS, ModuleSlotTracker *Slots) const {
  OS << '?' << Variable << " would be both ";
  printBinding(OS, First, Slots);
  OS << " and ";
  printBinding(OS, Second, Slots);
}

//===----------------------------------------------------------------------===//
// The interpreter
//===----------------------------------------------------------------------===//

/// The binding of an IR value to a meta variable of sort S; none if a
/// variable of that sort cannot be bound to the value.
static std::optional<Binding> bindingBySort(const llvm::Value &Target, Sort S) {
  switch (S) {
  case Sort::Value:
    return Binding(&Target);
  case Sort::Nat:
    if (std::optional<APInt> Integer = getConstantInteger(Target))
      return Binding(*Integer);
    return std::nullopt;
  case Sort::Boolean:
    if (!Target.getType()->isIntegerTy(1))
      return std::nullopt;
    return Binding(&Target);
  case Sort::Instruction:
    if (!isa<llvm::Instruction>(Target))
      return std::nullopt;
    return Binding(&Target);
  case Sort::Function:
    if (!isa<llvm::Function>(Target))
      return std::nullopt;
    return Binding(&Target);
  case Sort::IntrinsicID: {
    const auto *Function = dyn_cast<llvm::Function>(&Target);
    if (!Function || !Function->isIntrinsic())
      return std::nullopt;
    return Binding(Function->getIntrinsicID());
  }
  case Sort::BasicBlock:
    if (!isa<llvm::BasicBlock>(Target))
      return std::nullopt;
    return Binding(&Target);
  default:
    return std::nullopt;
  }
}

class PlanMatcher::Run {
public:
  Run(const PlanProgram &Program, ExprEvaluator &Evaluator,
      const llvm::Function &F, bool Relaxed, bool Explaining)
      : P(Program), Evaluator(Evaluator), F(F), Relaxed(Relaxed),
        Explaining(Explaining), Registers(Program.NumRegisters),
        Slots(Program.Slots.size()) {
    for (const llvm::Instruction &I : instructions(F))
      Instructions.push_back(&I);
  }

  void run() { exec(0, P.Steps.size()); }

  std::vector<PlanMatch> Matches;
  SmallVector<PlanRejection, 4> Rejections;
  bool HadStructuralMatch = false;
  /// Relaxed: the structural match with the fewest conflicts, if any.
  std::optional<SmallVector<PlanConflict, 1>> Closest;

private:
  using Step = PlanProgram::Step;
  const PlanProgram &P;
  ExprEvaluator &Evaluator;
  const llvm::Function &F;
  bool Relaxed;
  bool Explaining;
  SmallVector<const llvm::Instruction *, 64> Instructions;
  std::vector<Binding> Registers;
  std::vector<Binding> Slots;
  SmallVector<unsigned, 32> Trail;
  SmallVector<const Step *, 8> Checks;
  SmallVector<PlanConflict, 2> Conflicts;
  SmallVector<std::pair<unsigned, unsigned>, 8> Continuations;
  DenseMap<const llvm::Instruction *, SmallVector<const llvm::Value *, 4>>
      Operands;

  struct Mark {
    size_t Trail, Checks, Conflicts;
  };
  Mark mark() const { return {Trail.size(), Checks.size(), Conflicts.size()}; }
  void undo(Mark M) {
    while (Trail.size() > M.Trail)
      Slots[Trail.pop_back_val()] = Binding();
    Checks.truncate(M.Checks);
    Conflicts.truncate(M.Conflicts);
  }

  bool isBound(unsigned Slot) const {
    return !std::holds_alternative<std::monostate>(Slots[Slot].Data);
  }

  /// Binds Slot to Target if it is unbound; otherwise whether its binding is
  /// Target, or, relaxed, records a meta variable bound to another target.
  bool unify(unsigned Slot, const Binding &Target) {
    if (!isBound(Slot)) {
      Slots[Slot] = Target;
      Trail.push_back(Slot);
      return true;
    }
    if (Slots[Slot] == Target)
      return true;
    if (!Relaxed || P.Slots[Slot].IsInstruction)
      return false;
    const std::string &Name = P.Slots[Slot].Name;
    if (none_of(Conflicts, [&](const PlanConflict &C) {
          return C.Variable == Name && C.First == Slots[Slot] &&
                 C.Second == Target;
        }))
      Conflicts.push_back({Name, Slots[Slot], Target});
    return true;
  }

  const llvm::Value *value(int32_t Reg) const {
    const auto *V = std::get_if<const llvm::Value *>(&Registers[Reg].Data);
    return V ? *V : nullptr;
  }
  const llvm::Instruction *instruction(int32_t Reg) const {
    return dyn_cast_or_null<llvm::Instruction>(value(Reg));
  }
  ArrayRef<const llvm::Value *> operandsOf(const llvm::Instruction &I) {
    auto [It, Inserted] = Operands.try_emplace(&I);
    if (Inserted)
      collectMatcherOperands(I, It->second);
    return It->second;
  }

  bool matchType(unsigned Node, const llvm::Type &Target, bool TreatIntAsVec);
  bool step(const Step &S);
  void exec(unsigned PC, unsigned End);
  void emit();
};

bool PlanMatcher::Run::matchType(unsigned Index, const llvm::Type &Target,
                                 bool TreatIntAsVec) {
  return P.Types.match(
      Index, Target, TreatIntAsVec,
      [&](unsigned Slot, const Binding &B) { return unify(Slot, B); });
}

/// Whether Target is the global Name names: 'llvm.*' an intrinsic by its
/// base name, anything else the global of the name.
static bool isGlobalNamed(StringRef Name, const llvm::Value &Target) {
  const auto *Global = dyn_cast<llvm::GlobalValue>(&Target);
  if (!Global)
    return false;
  if (Name.starts_with("llvm.")) {
    const auto *Function = dyn_cast<llvm::Function>(Global);
    return Function && Function->isIntrinsic() &&
           Intrinsic::getBaseName(Function->getIntrinsicID()) == Name;
  }
  return Name == Global->getName();
}

bool PlanMatcher::Run::step(const Step &S) {
  switch (S.K) {
  case Step::GetOperand: {
    const llvm::Instruction *I = instruction(S.Src);
    ArrayRef<const llvm::Value *> Ops = operandsOf(*I);
    if (unsigned(S.A) >= Ops.size())
      return false;
    Registers[S.Dst] = Binding(Ops[S.A]);
    return true;
  }
  case Step::GetOperandsFrom: {
    ArrayRef<const llvm::Value *> Ops = operandsOf(*instruction(S.Src));
    if (S.Flag) {
      Binding::TypeArray Types;
      for (const llvm::Value *V : Ops.drop_front(S.A))
        Types.push_back(V->getType());
      Registers[S.Dst] = Binding(std::move(Types));
    } else {
      Registers[S.Dst] = Binding(Binding::ValueArray(
          Ops.drop_front(S.A).begin(), Ops.drop_front(S.A).end()));
    }
    return true;
  }
  case Step::GetType: {
    const llvm::Value *V = value(S.Src);
    const llvm::Type *T = V->getType();
    if (S.Flag) {
      if (const auto *Alloca = dyn_cast<AllocaInst>(V))
        T = Alloca->getAllocatedType();
      else if (const auto *GEP = dyn_cast<GetElementPtrInst>(V))
        T = GEP->getSourceElementType();
    }
    Registers[S.Dst] = Binding(T);
    return true;
  }
  case Step::GetParentBlock:
    Registers[S.Dst] = Binding(
        static_cast<const llvm::Value *>(instruction(S.Src)->getParent()));
    return true;
  case Step::GetFlag:
    Registers[S.Dst] = Binding(
        hasSemanticFlag(InstructionFlag::FlagID(S.A), *instruction(S.Src)));
    return true;
  case Step::GetKeyed: {
    const llvm::Instruction &I = *instruction(S.Src);
    switch (mpir::OperandKind(S.A)) {
    case mpir::OperandKind::Predicate: {
      const auto &Compare = cast<CmpInst>(I);
      Registers[S.Dst] = Binding(S.Flag ? Compare.getSwappedPredicate()
                                        : Compare.getPredicate());
      return true;
    }
    case mpir::OperandKind::Alignment:
      if (const auto *Alloca = dyn_cast<AllocaInst>(&I))
        Registers[S.Dst] =
            Binding(APSInt::getUnsigned(Alloca->getAlign().value()));
      else if (const auto *Load = dyn_cast<LoadInst>(&I))
        Registers[S.Dst] =
            Binding(APSInt::getUnsigned(Load->getAlign().value()));
      else
        Registers[S.Dst] =
            Binding(APSInt::getUnsigned(cast<StoreInst>(I).getAlign().value()));
      return true;
    case mpir::OperandKind::AddressSpace:
      Registers[S.Dst] =
          Binding(APSInt::getUnsigned(cast<AllocaInst>(I).getAddressSpace()));
      return true;
    case mpir::OperandKind::InRangeLower:
    case mpir::OperandKind::InRangeUpper: {
      std::optional<ConstantRange> Range = cast<GEPOperator>(I).getInRange();
      if (!Range)
        return false;
      Registers[S.Dst] = Binding(
          APSInt(mpir::OperandKind(S.A) == mpir::OperandKind::InRangeLower
                     ? Range->getLower()
                     : Range->getUpper(),
                 false));
      return true;
    }
    default:
      llvm_unreachable("not a keyed operand");
    }
  }
  case Step::GetElement: {
    const auto *Constant = cast<llvm::Constant>(value(S.Src));
    const llvm::Constant *Element = Constant->getAggregateElement(S.A);
    if (!Element)
      return false;
    Registers[S.Dst] = Binding(static_cast<const llvm::Value *>(Element));
    return true;
  }
  case Step::CheckOpcode: {
    const llvm::Instruction *I = instruction(S.Src);
    return I && matchesInstructionID(S.Opcode, *I);
  }
  case Step::CheckFlag:
    return hasSemanticFlag(InstructionFlag::FlagID(S.A), *instruction(S.Src)) ==
           S.Flag;
  case Step::CheckOperandCount: {
    size_t Count = operandsOf(*instruction(S.Src)).size();
    return S.Flag ? Count >= unsigned(S.A) : Count == unsigned(S.A);
  }
  case Step::CheckType:
    return matchType(
        S.A, **std::get_if<const llvm::Type *>(&Registers[S.Src].Data), S.Flag);
  case Step::CheckInteger: {
    const Binding &R = Registers[S.Src];
    if (const auto *Keyed = std::get_if<APSInt>(&R.Data))
      return APSInt::isSameValue(*S.Integer, *Keyed);
    const llvm::Value *V = value(S.Src);
    if (const auto *Integer = dyn_cast<ConstantInt>(V))
      return APSInt::isSameValue(
          *S.Integer, APSInt(Integer->getValue(), S.Integer->isUnsigned()));
    // Under treatIntAsVec, a scalar integer also matches a vector splat of
    // it, poison lanes allowed.
    if (S.Flag && V->getType()->isVectorTy())
      if (std::optional<APInt> Splat = getConstantInteger(*V))
        return APSInt::isSameValue(*S.Integer,
                                   APSInt(*Splat, S.Integer->isUnsigned()));
    return false;
  }
  case Step::CheckFloat: {
    const auto *Floating = dyn_cast<ConstantFP>(value(S.Src));
    if (!Floating)
      return false;
    APFloat Converted = *S.Float;
    bool LosesInfo;
    Converted.convert(Floating->getValueAPF().getSemantics(),
                      APFloat::rmNearestTiesToEven, &LosesInfo);
    return Converted.bitwiseIsEqual(Floating->getValueAPF());
  }
  case Step::CheckKeyword: {
    auto ID = KeywordConstant::KeywordID(S.A);
    if (const auto *Predicate =
            std::get_if<CmpInst::Predicate>(&Registers[S.Src].Data))
      return KeywordConstant::getKeywordName(ID) ==
             CmpInst::getPredicateName(*Predicate);
    const llvm::Value *V = value(S.Src);
    switch (ID) {
#define MIR_MATCHABLE_CONSTANT_KEYWORD(Name, Spelling, LLVMClass)              \
  case KeywordConstant::K_##Name:                                              \
    return isa<LLVMClass>(V);
#include "metaphir/IR/KeywordConstants.def"
    default:
      return false;
    }
  }
  case Step::CheckGlobal:
    return isGlobalNamed(S.Name, *value(S.Src));
  case Step::CheckAggregate: {
    const auto *Constant = dyn_cast<llvm::Constant>(value(S.Src));
    if (!Constant)
      return false;
    const llvm::Type *T = Constant->getType();
    uint64_t Count = 0;
    switch (AggregateConstant::Delimiter(S.A)) {
    case AggregateConstant::Square:
      if (!isa<llvm::ArrayType>(T))
        return false;
      Count = cast<llvm::ArrayType>(T)->getNumElements();
      break;
    case AggregateConstant::Brace:
      if (!isa<llvm::StructType>(T))
        return false;
      Count = cast<llvm::StructType>(T)->getNumElements();
      break;
    case AggregateConstant::Angle:
      if (!isa<FixedVectorType>(T))
        return false;
      Count = cast<FixedVectorType>(T)->getNumElements();
      break;
    }
    return Count == uint64_t(S.B);
  }
  case Step::CheckBound:
    return isBound(S.A) == S.Flag;
  case Step::Bind: {
    if (!S.BySort)
      return unify(S.A, Registers[S.Src]);
    const llvm::Value *V = value(S.Src);
    std::optional<Binding> B = V ? bindingBySort(*V, Sort(S.B)) : std::nullopt;
    return B && unify(S.A, *B);
  }
  case Step::BindConstant:
    return unify(S.A, Binding(S.Flag));
  case Step::Check:
    Checks.push_back(&S);
    return true;
  case Step::Emit:
  case Step::Foreach:
  case Step::Either:
    break;
  }
  llvm_unreachable("a choice is not a guard");
}

void PlanMatcher::Run::exec(unsigned PC, unsigned End) {
  for (; PC != End; ++PC) {
    const Step &S = P.Steps[PC];
    switch (S.K) {
    case Step::Foreach:
      for (const llvm::Instruction *I : Instructions) {
        Registers[S.Dst] = Binding(static_cast<const llvm::Value *>(I));
        Mark M = mark();
        exec(PC + 1, End);
        undo(M);
      }
      return;
    case Step::Either:
      Continuations.push_back({S.After, End});
      for (unsigned R = 0; R != unsigned(S.B); ++R) {
        auto [Begin, RegionEnd] = P.Regions[S.A + R];
        Mark M = mark();
        exec(Begin, RegionEnd);
        undo(M);
      }
      Continuations.pop_back();
      return;
    case Step::Emit:
      emit();
      continue;
    default:
      if (!step(S))
        return;
      continue;
    }
  }
  // The path goes on after the either it was an alternative of.
  if (Continuations.empty())
    return;
  std::pair<unsigned, unsigned> Next = Continuations.pop_back_val();
  exec(Next.first, Next.second);
  Continuations.push_back(Next);
}

void PlanMatcher::Run::emit() {
  HadStructuralMatch = true;
  if (Relaxed) {
    if (!Conflicts.empty() && (!Closest || Conflicts.size() < Closest->size()))
      Closest =
          SmallVector<PlanConflict, 1>(Conflicts.begin(), Conflicts.end());
    return;
  }
  PlanMatch Candidate(P, Slots);
  // Constraints a metaflag says go first, as what they say a binding is
  // decides whether the others can be evaluated.
  SmallVector<const Step *, 8> Ordered;
  for (const Step *C : Checks)
    if (C->FromMetaflag)
      Ordered.push_back(C);
  for (const Step *C : Checks)
    if (!C->FromMetaflag)
      Ordered.push_back(C);
  auto Record = [&](const Step &C, std::string Reason) {
    if (!Explaining)
      return;
    if (none_of(Rejections, [&](const PlanRejection &R) {
          return R.Written.Start == C.Written.Start &&
                 R.Written.End == C.Written.End;
        }))
      Rejections.push_back(
          {C.Condition, C.Written, std::move(Reason), Candidate});
  };
  bool Satisfies = true;
  for (const Step *C : Ordered) {
    Expected<ConstraintValue> Result =
        Evaluator.evaluate(C->Condition, [&](unsigned Slot) -> const Binding * {
          return isBound(Slot) ? &Slots[Slot] : nullptr;
        });
    mlir::Value Expression = C->Condition;
    Expected<bool> Holds = Result ? detail::requireBoolean(*Result, Expression)
                                  : Expected<bool>(Result.takeError());
    if (!Holds) {
      std::string Reason = "constraint could not be evaluated";
      handleAllErrors(
          Holds.takeError(),
          [&](const detail::ConstraintEvaluationError &E) {
            Reason = E.Message;
          },
          [&](const ErrorInfoBase &E) { Reason = E.message(); });
      if (Satisfies)
        Record(*C, std::move(Reason));
      Satisfies = false;
      break;
    }
    if (!*Holds) {
      Record(*C, "");
      Satisfies = false;
      if (!Explaining)
        break;
    }
  }
  if (Satisfies &&
      none_of(Matches, [&](const PlanMatch &M) { return M == Candidate; }))
    Matches.push_back(std::move(Candidate));
}

PlanMatcher::PlanMatcher(const PlanProgram &Program) : Program(Program) {}
PlanMatcher::~PlanMatcher() = default;

std::vector<PlanMatch>
PlanMatcher::match(const llvm::Function &F,
                   SmallVectorImpl<PlanRejection> *Unsatisfied,
                   bool *HadStructuralMatch) {
  // Analyses cached for an earlier function may belong to a freed one.
  Evaluator.resetAnalyses();
  Run R(Program, Evaluator, F, /*Relaxed=*/false,
        /*Explaining=*/Unsatisfied != nullptr);
  R.run();
  if (HadStructuralMatch)
    *HadStructuralMatch = R.HadStructuralMatch;
  if (Unsatisfied && R.Matches.empty())
    Unsatisfied->append(R.Rejections.begin(), R.Rejections.end());
  return std::move(R.Matches);
}

SmallVector<PlanConflict, 1>
PlanMatcher::findConflicts(const llvm::Function &F) {
  Evaluator.resetAnalyses();
  Run R(Program, Evaluator, F, /*Relaxed=*/true, /*Explaining=*/false);
  R.run();
  if (!R.Closest)
    return {};
  return *R.Closest;
}

} // namespace metaphir
} // namespace llvm
