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
#include "llvm/ADT/PointerUnion.h"
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

  void run() { exec(0, P.Steps.size(), NoContinuation); }

  std::vector<PlanMatch> Matches;
  SmallVector<PlanRejection, 4> Rejections;
  bool HadStructuralMatch = false;
  /// Relaxed: the structural match with the fewest conflicts, if any.
  std::optional<SmallVector<PlanConflict, 1>> Closest;

private:
  using Constraint =
      PointerUnion<const plan_step::Check *, const plan_step::Let *>;
  const PlanProgram &P;
  ConcreteEvaluator &Evaluator;
  bool Relaxed;
  bool Explaining;
  SmallVector<const llvm::Instruction *, 64> Instructions;
  std::vector<Binding> Registers;
  std::vector<Binding> Slots;
  SmallVector<unsigned, 32> Trail;
  /// The constraints of the path so far, to evaluate at emit.
  SmallVector<Constraint, 8> Constraints;
  SmallVector<PlanConflict, 2> Conflicts;
  /// Where a path goes on once an alternative's range ends: the steps
  /// [PC, End), then the continuation Parent.
  struct ContinuationRange {
    unsigned PC, End, Parent;
  };
  static constexpr unsigned NoContinuation = ~0u;
  /// The continuations of the eithers being run, innermost last.
  SmallVector<ContinuationRange, 8> Continuations;
  DenseMap<const llvm::Instruction *, SmallVector<const llvm::Value *, 4>>
      Operands;

  struct Mark {
    size_t Trail, Constraints, Conflicts;
  };
  Mark mark() const {
    return {Trail.size(), Constraints.size(), Conflicts.size()};
  }
  void undo(Mark M) {
    while (Trail.size() > M.Trail)
      Slots[Trail.pop_back_val()] = Binding();
    Constraints.truncate(M.Constraints);
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

  const llvm::Value *value(plan_step::Register Reg) const {
    const auto *V = std::get_if<const llvm::Value *>(&Registers[Reg].Data);
    return V ? *V : nullptr;
  }
  const llvm::Instruction *instruction(plan_step::Register Reg) const {
    return dyn_cast_or_null<llvm::Instruction>(value(Reg));
  }
  ArrayRef<const llvm::Value *> operandsOf(const llvm::Instruction &I) {
    auto [It, Inserted] = Operands.try_emplace(&I);
    if (Inserted)
      collectMatcherOperands(I, It->second);
    return It->second;
  }

  /// Runs the steps [PC, End), then the continuation Continuation.
  void exec(unsigned PC, unsigned End, unsigned Continuation);
  /// Runs the rest of the path, from the step after PC, once per choice.
  void choose(const plan_step::Foreach &S, unsigned PC, unsigned End,
              unsigned Continuation);
  void choose(const plan_step::Either &S, unsigned PC, unsigned End,
              unsigned Continuation);
  /// Whether the path goes on after a step that is not a choice.
  bool step(const plan_step::GetOperand &S);
  bool step(const plan_step::GetOperandsFrom &S);
  bool step(const plan_step::GetType &S);
  bool step(const plan_step::GetParentBlock &S);
  bool step(const plan_step::GetFlag &S);
  bool step(const plan_step::GetKeyed &S);
  bool step(const plan_step::GetElement &S);
  bool step(const plan_step::CheckOpcode &S);
  bool step(const plan_step::CheckFlag &S);
  bool step(const plan_step::CheckOperandCount &S);
  bool step(const plan_step::CheckType &S);
  bool step(const plan_step::CheckInteger &S);
  bool step(const plan_step::CheckFloat &S);
  bool step(const plan_step::CheckKeyword &S);
  bool step(const plan_step::CheckGlobal &S);
  bool step(const plan_step::CheckAggregate &S);
  bool step(const plan_step::CheckBound &S);
  bool step(std::monostate) {
    llvm_unreachable("a placeholder is left in the program");
  }
  bool step(const plan_step::Fail &) { return false; }
  bool step(const plan_step::Bind &S);
  bool step(const plan_step::BindConstant &S);
  bool step(const plan_step::Check &S);
  bool step(const plan_step::Let &S);
  bool step(const plan_step::Emit &);
  /// Reports the path as a match if its constraints hold.
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

using namespace plan_step;

bool PlanMatcher::Run::step(const GetOperand &S) {
  ArrayRef<const llvm::Value *> Ops = operandsOf(*instruction(S.Instruction));
  if (S.Index >= Ops.size())
    return false;
  Registers[S.Result] = Binding(Ops[S.Index]);
  return true;
}

bool PlanMatcher::Run::step(const GetOperandsFrom &S) {
  ArrayRef<const llvm::Value *> Ops =
      operandsOf(*instruction(S.Instruction)).drop_front(S.First);
  if (S.Types) {
    Binding::TypeArray Types;
    for (const llvm::Value *V : Ops)
      Types.push_back(V->getType());
    Registers[S.Result] = Binding(std::move(Types));
  } else {
    Registers[S.Result] = Binding(Binding::ValueArray(Ops.begin(), Ops.end()));
  }
  return true;
}

bool PlanMatcher::Run::step(const GetType &S) {
  const llvm::Value *V = value(S.Value);
  const llvm::Type *T = V->getType();
  if (S.OperandOf) {
    if (const auto *Alloca = dyn_cast<AllocaInst>(V))
      T = Alloca->getAllocatedType();
    else if (const auto *GEP = dyn_cast<GetElementPtrInst>(V))
      T = GEP->getSourceElementType();
  }
  Registers[S.Result] = Binding(T);
  return true;
}

bool PlanMatcher::Run::step(const GetParentBlock &S) {
  Registers[S.Result] = Binding(static_cast<const llvm::Value *>(
      instruction(S.Instruction)->getParent()));
  return true;
}

bool PlanMatcher::Run::step(const GetFlag &S) {
  Registers[S.Result] =
      Binding(hasSemanticFlag(S.Flag, *instruction(S.Instruction)));
  return true;
}

bool PlanMatcher::Run::step(const GetKeyed &S) {
  const llvm::Instruction &I = *instruction(S.Instruction);
  switch (S.Kind) {
  case mpir::OperandKind::Predicate: {
    const auto &Compare = cast<CmpInst>(I);
    Registers[S.Result] = Binding(Compare.getPredicate());
    return true;
  }
  case mpir::OperandKind::Alignment:
    if (const auto *Alloca = dyn_cast<AllocaInst>(&I))
      Registers[S.Result] =
          Binding(APSInt::getUnsigned(Alloca->getAlign().value()));
    else if (const auto *Load = dyn_cast<LoadInst>(&I))
      Registers[S.Result] =
          Binding(APSInt::getUnsigned(Load->getAlign().value()));
    else
      Registers[S.Result] =
          Binding(APSInt::getUnsigned(cast<StoreInst>(I).getAlign().value()));
    return true;
  case mpir::OperandKind::AddressSpace:
    Registers[S.Result] =
        Binding(APSInt::getUnsigned(cast<AllocaInst>(I).getAddressSpace()));
    return true;
  case mpir::OperandKind::InRangeLower:
  case mpir::OperandKind::InRangeUpper: {
    std::optional<ConstantRange> Range = cast<GEPOperator>(I).getInRange();
    if (!Range)
      return false;
    Registers[S.Result] = Binding(
        APSInt(S.Kind == mpir::OperandKind::InRangeLower ? Range->getLower()
                                                         : Range->getUpper(),
               false));
    return true;
  }
  default:
    llvm_unreachable("not a keyed operand");
  }
}

bool PlanMatcher::Run::step(const GetElement &S) {
  const auto *Constant = cast<llvm::Constant>(value(S.Aggregate));
  const llvm::Constant *Element = Constant->getAggregateElement(S.Index);
  if (!Element)
    return false;
  Registers[S.Result] = Binding(static_cast<const llvm::Value *>(Element));
  return true;
}

bool PlanMatcher::Run::step(const CheckOpcode &S) {
  const llvm::Instruction *I = instruction(S.Value);
  return I && matchesInstructionID(S.Opcode, *I);
}

bool PlanMatcher::Run::step(const CheckFlag &S) {
  return hasSemanticFlag(S.Flag, *instruction(S.Instruction)) == S.Present;
}

bool PlanMatcher::Run::step(const CheckOperandCount &S) {
  size_t Count = operandsOf(*instruction(S.Instruction)).size();
  return S.AtLeast ? Count >= S.Count : Count == S.Count;
}

bool PlanMatcher::Run::step(const CheckType &S) {
  return matchTypePattern(
      S.Pattern, **std::get_if<const llvm::Type *>(&Registers[S.IRType].Data),
      S.TreatIntAsVec,
      [&](unsigned Slot, const Binding &B) { return unify(Slot, B); });
}

bool PlanMatcher::Run::step(const CheckInteger &S) {
  const Binding &R = Registers[S.Value];
  if (const auto *Keyed = std::get_if<APSInt>(&R.Data))
    return APSInt::isSameValue(S.Integer, *Keyed);
  const llvm::Value *V = value(S.Value);
  if (const auto *Integer = dyn_cast<ConstantInt>(V))
    return APSInt::isSameValue(
        S.Integer, APSInt(Integer->getValue(), S.Integer.isUnsigned()));
  // Under treatIntAsVec, a scalar integer also matches a vector splat of it,
  // poison lanes allowed.
  if (S.TreatIntAsVec && V->getType()->isVectorTy())
    if (std::optional<APInt> Splat = getConstantInteger(*V))
      return APSInt::isSameValue(S.Integer,
                                 APSInt(*Splat, S.Integer.isUnsigned()));
  return false;
}

bool PlanMatcher::Run::step(const CheckFloat &S) {
  const auto *Floating = dyn_cast<ConstantFP>(value(S.Value));
  if (!Floating)
    return false;
  APFloat Converted = S.Float;
  bool LosesInfo;
  Converted.convert(Floating->getValueAPF().getSemantics(),
                    APFloat::rmNearestTiesToEven, &LosesInfo);
  return Converted.bitwiseIsEqual(Floating->getValueAPF());
}

bool PlanMatcher::Run::step(const CheckKeyword &S) {
  if (const auto *Predicate =
          std::get_if<CmpInst::Predicate>(&Registers[S.Value].Data))
    return keyword_constant::getPredicateKeyword(*Predicate) == S.Keyword;
  return keyword_constant::matches(S.Keyword, *value(S.Value));
}

bool PlanMatcher::Run::step(const CheckGlobal &S) {
  return isGlobalNamed(S.Name, *value(S.Value));
}

bool PlanMatcher::Run::step(const CheckAggregate &S) {
  const auto *Constant = dyn_cast<llvm::Constant>(value(S.Value));
  if (!Constant)
    return false;
  const llvm::Type *T = Constant->getType();
  uint64_t Count = 0;
  switch (S.Delimiter) {
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
  return Count == S.Count;
}

bool PlanMatcher::Run::step(const CheckBound &S) {
  return isBound(S.Slot) == S.Bound;
}

bool PlanMatcher::Run::step(const Bind &S) {
  if (!S.BySort)
    return unify(S.Slot, Registers[S.Value]);
  const llvm::Value *V = value(S.Value);
  std::optional<Binding> B = V ? bindingBySort(*V, *S.BySort) : std::nullopt;
  return B && unify(S.Slot, *B);
}

bool PlanMatcher::Run::step(const BindConstant &S) {
  return unify(S.Slot, Binding(S.Value));
}

bool PlanMatcher::Run::step(const Check &S) {
  Constraints.push_back(&S);
  return true;
}

bool PlanMatcher::Run::step(const Let &S) {
  Constraints.push_back(&S);
  return true;
}

bool PlanMatcher::Run::step(const Emit &) {
  emit();
  return true;
}

void PlanMatcher::Run::choose(const Foreach &S, unsigned PC, unsigned End,
                              unsigned Continuation) {
  for (const llvm::Instruction *I : Instructions) {
    Registers[S.Result] = Binding(static_cast<const llvm::Value *>(I));
    Mark M = mark();
    exec(PC + 1, End, Continuation);
    undo(M);
  }
}

void PlanMatcher::Run::choose(const Either &S, unsigned PC, unsigned End,
                              unsigned Continuation) {
  // Each alternative goes on after the either, then where the either does.
  Continuations.push_back({S.After, End, Continuation});
  unsigned After = Continuations.size() - 1;
  for (auto [Begin, AlternativeEnd] : S.Alternatives) {
    Mark M = mark();
    exec(Begin, AlternativeEnd, After);
    undo(M);
  }
  Continuations.pop_back();
}

void PlanMatcher::Run::exec(unsigned PC, unsigned End, unsigned Continuation) {
  for (;;) {
    for (; PC != End; ++PC) {
      bool GoesOn = std::visit(
          [&](const auto &S) {
            using Kind = std::decay_t<decltype(S)>;
            if constexpr (std::is_same_v<Kind, Foreach> ||
                          std::is_same_v<Kind, Either>) {
              // A choice runs the rest of the path itself.
              choose(S, PC, End, Continuation);
              return false;
            } else {
              return step(S);
            }
          },
          P.Steps[PC]);
      if (!GoesOn)
        return;
    }
    if (Continuation == NoContinuation)
      return;
    // The path goes on after the either it was an alternative of.
    ContinuationRange C = Continuations[Continuation];
    PC = C.PC;
    End = C.End;
    Continuation = C.Parent;
  }
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
  SmallVector<Constraint, 8> Ordered;
  for (Constraint C : Constraints)
    if (const auto *Ch = dyn_cast<const Check *>(C); Ch && Ch->FromMetaflag)
      Ordered.push_back(C);
  for (Constraint C : Constraints)
    if (isa<const Let *>(C))
      Ordered.push_back(C);
  for (Constraint C : Constraints)
    if (const auto *Ch = dyn_cast<const Check *>(C); Ch && !Ch->FromMetaflag)
      Ordered.push_back(C);
  auto Base = [](Constraint C) -> const plan_step::Constraint & {
    if (const auto *L = dyn_cast<const Let *>(C))
      return *L;
    return *cast<const Check *>(C);
  };
  auto Record = [&](const plan_step::Constraint &C, std::string Reason) {
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
  // Whether the constraint holds: a let binds its variable if it is unbound;
  // otherwise its condition holds.
  auto Holds = [&](Constraint C) -> Expected<bool> {
    const auto *L = dyn_cast<const Let *>(C);
    if (!L || isBound(L->Slot)) {
      mlir::Value Condition = Base(C).Condition;
      Expected<ConstraintValue> Result = Evaluator.evaluate(Condition, Slot);
      if (!Result)
        return Result.takeError();
      return detail::requireBoolean(*Result, Condition);
    }
    Expected<ConstraintValue> Result = Evaluator.evaluate(L->Assigned, Slot);
    if (!Result)
      return Result.takeError();
    std::optional<Binding> Target =
        toBinding(*Result, P.Slots[L->Slot].VariableSort);
    if (!Target)
      return make_error<detail::ConstraintEvaluationError>(
          L->Assigned,
          "'" + P.Slots[L->Slot].Name + "' cannot be bound to this value");
    return unify(L->Slot, *Target);
  };
  bool Satisfies = true;
  for (Constraint C : Ordered) {
    Expected<bool> Result = Holds(C);
    if (!Result) {
      if (Satisfies)
        Record(Base(C), Message(Result.takeError()));
      Satisfies = false;
      break;
    }
    if (!*Result) {
      Record(Base(C), "");
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
