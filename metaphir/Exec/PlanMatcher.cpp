//===- PlanMatcher.cpp - Run match plans on LLVM IR -----------------------===//
//
// The interpreter runs a range of steps; a choice runs the rest of its range
// once per choice, with the slots it bound undone between them. When an
// alternative's range ends, the path goes on after its either: the ranges
// still to run are kept on a continuation stack.
//
//===----------------------------------------------------------------------===//

#include "metaphir/Exec/PlanMatcher.h"
#include "metaphir/Dialect/Pattern/PatternDialect.h"
#include "metaphir/Exec/KeywordConstantMatch.h"
#include "metaphir/Exec/TypePattern.h"
#include "metaphir/IR/PredicateKeyword.h"
#include "metaphir/Matching/ConstantInteger.h"
#include "metaphir/Matching/ConstraintCoercion.h"
#include "metaphir/Matching/OpcodePredicates.h"
#include "llvm/IR/BasicBlock.h"
#include "llvm/IR/ConstantRange.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/DerivedTypes.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/InstIterator.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/Intrinsics.h"
#include "llvm/IR/Operator.h"

namespace llvm {
namespace metaphir {

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

/// What a variable of sort S is bound to when a constraint expression gives
/// V, if a match can bind that.
static std::optional<Binding> toBinding(const ConstraintValue &V, Sort S) {
  switch (resolveSort(S)) {
  case Sort::Nat:
    if (V.getKind() == ConstraintValue::Integer && !V.getInteger().isNegative())
      return Binding(APInt(V.getInteger()));
    return std::nullopt;
  case Sort::Integer:
    if (V.getKind() == ConstraintValue::Integer)
      return Binding(V.getInteger());
    return std::nullopt;
  case Sort::Boolean:
    if (V.getKind() == ConstraintValue::Boolean)
      return Binding(V.getBoolean());
    return std::nullopt;
  case Sort::CmpPredicate: {
    if (V.getKind() != ConstraintValue::String)
      return std::nullopt;
    for (unsigned P = CmpInst::FIRST_ICMP_PREDICATE;
         P <= CmpInst::LAST_ICMP_PREDICATE; ++P)
      if (CmpInst::getPredicateName(CmpInst::Predicate(P)) == V.getString())
        return Binding(CmpInst::Predicate(P));
    for (unsigned P = CmpInst::FIRST_FCMP_PREDICATE;
         P <= CmpInst::LAST_FCMP_PREDICATE; ++P)
      if (CmpInst::getPredicateName(CmpInst::Predicate(P)) == V.getString())
        return Binding(CmpInst::Predicate(P));
    return std::nullopt;
  }
  case Sort::IntrinsicID: {
    if (V.getKind() != ConstraintValue::String)
      return std::nullopt;
    Intrinsic::ID ID = Intrinsic::lookupIntrinsicID(V.getString());
    if (ID == Intrinsic::not_intrinsic)
      return std::nullopt;
    return Binding(ID);
  }
  case Sort::Type:
    if (V.getKind() == ConstraintValue::Type)
      return Binding(V.getType());
    return std::nullopt;
  case Sort::TypeArray:
    if (V.getKind() == ConstraintValue::TypeArray)
      return Binding(V.getTypeArray());
    return std::nullopt;
  case Sort::ValueArray:
    if (V.getKind() == ConstraintValue::ValueArray)
      return Binding(V.getValueArray());
    return std::nullopt;
  case Sort::Value:
  case Sort::Instruction:
  case Sort::Function:
  case Sort::BasicBlock:
    if (V.getKind() == ConstraintValue::Value)
      return Binding(V.getValue());
    return std::nullopt;
  default:
    return std::nullopt;
  }
}

class PlanMatcher::Run {
public:
  Run(const PlanProgram &Program, ConcreteEvaluator &Evaluator,
      const llvm::Function &F, bool Relaxed, bool Explaining)
      : P(Program), Evaluator(Evaluator), Relaxed(Relaxed),
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
  ConcreteEvaluator &Evaluator;
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

  bool step(const Step &S);
  void exec(unsigned PC, unsigned End);
  void emit();
};

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
        hasSemanticFlag(instruction_flag::FlagID(S.A), *instruction(S.Src)));
    return true;
  case Step::GetKeyed: {
    const llvm::Instruction &I = *instruction(S.Src);
    switch (mpir::OperandKind(S.A)) {
    case mpir::OperandKind::Predicate: {
      const auto &Compare = cast<CmpInst>(I);
      Registers[S.Dst] = Binding(Compare.getPredicate());
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
    return hasSemanticFlag(instruction_flag::FlagID(S.A),
                           *instruction(S.Src)) == S.Flag;
  case Step::CheckOperandCount: {
    size_t Count = operandsOf(*instruction(S.Src)).size();
    return S.Flag ? Count >= unsigned(S.A) : Count == unsigned(S.A);
  }
  case Step::CheckType:
    return matchTypePattern(
        S.Type, **std::get_if<const llvm::Type *>(&Registers[S.Src].Data),
        S.Flag,
        [&](unsigned Slot, const Binding &B) { return unify(Slot, B); });
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
    auto ID = keyword_constant::KeywordID(S.A);
    if (const auto *Predicate =
            std::get_if<CmpInst::Predicate>(&Registers[S.Src].Data))
      return keyword_constant::getPredicateKeyword(*Predicate) == ID;
    const llvm::Value *V = value(S.Src);
    return keyword_constant::matches(ID, *V);
  }
  case Step::CheckGlobal:
    return isGlobalNamed(S.Name, *value(S.Src));
  case Step::CheckAggregate: {
    const auto *Constant = dyn_cast<llvm::Constant>(value(S.Src));
    if (!Constant)
      return false;
    const llvm::Type *T = Constant->getType();
    uint64_t Count = 0;
    switch (aggregate_constant::Delimiter(S.A)) {
    case aggregate_constant::Square:
      if (!isa<llvm::ArrayType>(T))
        return false;
      Count = cast<llvm::ArrayType>(T)->getNumElements();
      break;
    case aggregate_constant::Brace:
      if (!isa<llvm::StructType>(T))
        return false;
      Count = cast<llvm::StructType>(T)->getNumElements();
      break;
    case aggregate_constant::Angle:
      if (!isa<FixedVectorType>(T))
        return false;
      Count = cast<FixedVectorType>(T)->getNumElements();
      break;
    }
    return Count == uint64_t(S.B);
  }
  case Step::CheckBound:
    return isBound(S.A) == S.Flag;
  case Step::Fail:
    return false;
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
  case Step::Let:
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
  // Constraints a metaflag says go first, as what they say a binding is
  // decides whether the others can be evaluated. A let comes before the
  // other constraints, which may read what it binds: it reads only what is
  // written before it.
  SmallVector<const Step *, 8> Ordered;
  for (const Step *C : Checks)
    if (C->K == Step::Check && C->FromMetaflag)
      Ordered.push_back(C);
  for (const Step *C : Checks)
    if (C->K == Step::Let)
      Ordered.push_back(C);
  for (const Step *C : Checks)
    if (C->K == Step::Check && !C->FromMetaflag)
      Ordered.push_back(C);
  auto Record = [&](const Step &C, std::string Reason) {
    if (!Explaining)
      return;
    if (none_of(Rejections, [&](const PlanRejection &R) {
          return R.Range.Start == C.Range.Start && R.Range.End == C.Range.End;
        }))
      Rejections.push_back(
          {C.Condition, C.Range, std::move(Reason), PlanMatch(P, Slots)});
  };
  auto Slot = [&](unsigned Slot) -> const Binding * {
    return isBound(Slot) ? &Slots[Slot] : nullptr;
  };
  auto Message = [](Error E) {
    std::string Reason = "constraint could not be evaluated";
    handleAllErrors(
        std::move(E),
        [&](const detail::ConstraintEvaluationError &E) { Reason = E.Message; },
        [&](const ErrorInfoBase &E) { Reason = E.message(); });
    return Reason;
  };
  // Whether the let holds: it binds its variable, or the value is the one the
  // variable is bound to.
  auto Holds = [&](const Step &C) -> Expected<bool> {
    if (C.K != Step::Let || isBound(C.A)) {
      Expected<ConstraintValue> Result = Evaluator.evaluate(C.Condition, Slot);
      if (!Result)
        return Result.takeError();
      return detail::requireBoolean(*Result, C.Condition);
    }
    Expected<ConstraintValue> Result = Evaluator.evaluate(C.Assigned, Slot);
    if (!Result)
      return Result.takeError();
    std::optional<Binding> Target =
        toBinding(*Result, P.Slots[C.A].VariableSort);
    if (!Target)
      return make_error<detail::ConstraintEvaluationError>(
          C.Assigned,
          "'" + P.Slots[C.A].Name + "' cannot be bound to this value");
    return unify(C.A, *Target);
  };
  bool Satisfies = true;
  for (const Step *C : Ordered) {
    Expected<bool> Result = Holds(*C);
    if (!Result) {
      if (Satisfies)
        Record(*C, Message(Result.takeError()));
      Satisfies = false;
      break;
    }
    if (!*Result) {
      Record(*C, "");
      Satisfies = false;
      if (!Explaining)
        break;
    }
  }
  PlanMatch Candidate(P, Slots);
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
