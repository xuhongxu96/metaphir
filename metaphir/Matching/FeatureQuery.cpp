#include "metaphir/Matching/FeatureQuery.h"
#include "metaphir/IR/Constants.h"
#include "metaphir/IR/DerivedTypes.h"
#include "metaphir/IR/MetaVariable.h"
#include "metaphir/IR/Pattern.h"
#include "metaphir/IR/PatternVariants.h"
#include "metaphir/Matching/ConstraintCoercion.h"
#include "metaphir/Matching/ConstraintEvaluator.h"
#include "metaphir/Matching/ConstraintInterpreter.h"
#include "metaphir/Matching/Instantiation.h"
#include "metaphir/Matching/TypeMatcher.h"
#include "llvm/ADT/DenseMap.h"
#include "llvm/ADT/STLExtras.h"
#include "llvm/ADT/SmallPtrSet.h"
#include <algorithm>
#include <iterator>

namespace llvm {
namespace metaphir {

static uint64_t bit(Instruction::InstructionID ID) { return uint64_t(1) << ID; }
static uint32_t flagBit(unsigned Flag) { return uint32_t(1) << Flag; }

template <typename T> static void sortUnique(SmallVectorImpl<T> &Values) {
  llvm::sort(Values);
  Values.erase(std::unique(Values.begin(), Values.end()), Values.end());
}

template <typename T>
static void appendUnique(SmallVectorImpl<T> &Values, ArrayRef<T> Other) {
  Values.append(Other.begin(), Other.end());
  sortUnique(Values);
}

template <typename T>
static void intersectSorted(SmallVectorImpl<T> &Values, ArrayRef<T> Other) {
  SmallVector<T, 4> Common;
  std::set_intersection(Values.begin(), Values.end(), Other.begin(),
                        Other.end(), std::back_inserter(Common));
  Values.assign(Common.begin(), Common.end());
}

bool ShapeRequirement::isSatisfiedBy(const FunctionFeatures &Features) const {
  Signature First;
  First.ID = ID;
  for (auto It = llvm::lower_bound(
           Features.Signatures, First,
           [](const Signature &L, const Signature &R) { return L.ID < R.ID; });
       It != Features.Signatures.end() && It->ID == ID; ++It)
    if ((It->Flags & Present) == Present && (It->Flags & Absent) == 0 &&
        (!Width || getIntegerElementWidth(It->Result) == Width))
      return true;
  return false;
}

/// Whether some slot of S has fact A.
static bool hasSiteFact(const FunctionFeatures &Features, const Site &S,
                        Atom A) {
  for (unsigned Slots = S.Slots; Slots; Slots &= Slots - 1)
    if (Features.hasFact(S.Parent->getInstructionID(), llvm::countr_zero(Slots),
                         A))
      return true;
  return false;
}

bool FeatureRequirement::isSatisfiedBy(const FunctionFeatures &Features) const {
  if ((Instructions & ~Features.Instructions) != 0)
    return false;
  for (auto [User, Operand] : Edges)
    if (!Features.mayHaveEdge(User, Operand))
      return false;
  for (uint16_t Sibling : Siblings)
    if (!std::binary_search(Features.Siblings.begin(), Features.Siblings.end(),
                            Sibling))
      return false;
  if (!all_of(Globals, [&](uint64_t Hash) { return Features.hasGlobal(Hash); }))
    return false;
  if (!Features.Fine)
    return true;
  for (const ShapeRequirement &Shape : Shapes)
    if (!Shape.isSatisfiedBy(Features))
      return false;
  for (const auto &[S, A] : SiteFacts)
    if (!hasSiteFact(Features, S, A))
      return false;
  return true;
}

void FeatureRequirement::unite(const FeatureRequirement &Other) {
  Instructions |= Other.Instructions;
  appendUnique<ShapeRequirement>(Shapes, Other.Shapes);
  appendUnique<decltype(Edges)::value_type>(Edges, Other.Edges);
  appendUnique<uint16_t>(Siblings, Other.Siblings);
  appendUnique<uint64_t>(Globals, Other.Globals);
  appendUnique<decltype(SiteFacts)::value_type>(SiteFacts, Other.SiteFacts);
  appendUnique<decltype(Uses)::value_type>(Uses, Other.Uses);
  appendUnique<decltype(OperandSites)::value_type>(OperandSites,
                                                   Other.OperandSites);
  appendUnique<const Instruction *>(Selves, Other.Selves);
}

void FeatureRequirement::intersect(const FeatureRequirement &Other) {
  Instructions &= Other.Instructions;
  intersectSorted<ShapeRequirement>(Shapes, Other.Shapes);
  intersectSorted<decltype(Edges)::value_type>(Edges, Other.Edges);
  intersectSorted<uint16_t>(Siblings, Other.Siblings);
  intersectSorted<uint64_t>(Globals, Other.Globals);
  intersectSorted<decltype(SiteFacts)::value_type>(SiteFacts, Other.SiteFacts);
  intersectSorted<decltype(Uses)::value_type>(Uses, Other.Uses);
  intersectSorted<decltype(OperandSites)::value_type>(OperandSites,
                                                      Other.OperandSites);
  intersectSorted<const Instruction *>(Selves, Other.Selves);
}

static FeatureRequirement
requirementOf(const Value &Node, SmallPtrSetImpl<const Instruction *> &OnStack);

/// The width a pattern type fixes for the integers of the value it matches:
/// an integer type matches integers, or vectors of them, of its width.
static unsigned fixedWidth(const Type *Ty) {
  if (const auto *Integer = dyn_cast_or_null<IntegerType>(Ty))
    return Integer->getNumBits();
  return 0;
}

/// The shape of the instructions Node matches.
static ShapeRequirement shapeOf(const Instruction &Node) {
  Instruction::InstructionID ID = Node.getInstructionID();
  ShapeRequirement Shape{ID};
  // The matcher requires the flags it writes and the absence of those it
  // negates; it accepts either for the rest.
  for (const InstructionFlag &Flag : Node.getFlags()) {
    if (Flag.Capture)
      continue;
    (Flag.Negated ? Shape.Absent : Shape.Present) |= flagBit(Flag.ID);
  }

  // A type-only operand is matched against the result type, except for
  // alloca's and getelementptr's; a binary operator's operands have the type
  // of its result.
  for (const MatcherOperand &Operand : Node.getUnkeyedOperands()) {
    bool OfResult =
        Operand.IsInstructionOperand
            ? Instruction::getOperandSyntax(ID) ==
                  Instruction::OperandSyntax::Binary
            : ID != Instruction::I_alloca && ID != Instruction::I_getelementptr;
    if (!Operand.IsArray && OfResult && fixedWidth(Operand.Ty)) {
      Shape.Width = fixedWidth(Operand.Ty);
      break;
    }
  }
  return Shape;
}

/// The slots the Position-th of NumOperands matcher operands of Node can be
/// in: its own, or with ':c' the one it swaps with (as InstructionMatcher
/// does: the first two operands, or a two-argument call's arguments).
static uint8_t operandSlots(const Instruction &Node, unsigned Position,
                            unsigned NumOperands) {
  auto SlotBit = [](unsigned P) {
    return uint8_t(1) << std::min(P, NumOperandSlots - 1);
  };
  uint8_t Slots = SlotBit(Position);
  if (!Node.hasMetaFlag(MetaFlag::MF_c))
    return Slots;
  unsigned First =
      Node.getInstructionID() == Instruction::I_call && NumOperands == 3 ? 1
                                                                         : 0;
  if ((NumOperands == 2 || First == 1) &&
      (Position == First || Position == First + 1))
    Slots |= SlotBit(Position == First ? First + 1 : First);
  return Slots;
}

/// What a match of Node needs. A node already being visited (a cycle in the
/// pattern) adds nothing; its features are required where the visit began.
static FeatureRequirement
requirementOfInstruction(const Instruction &Node,
                         SmallPtrSetImpl<const Instruction *> &OnStack) {
  if (Node.isComposite() || !OnStack.insert(&Node).second)
    return {};

  SmallVector<const MatcherOperand *, 4> ValueOperands;
  for (const MatcherOperand &Operand : Node.getUnkeyedOperands())
    if (Operand.IsInstructionOperand)
      ValueOperands.push_back(&Operand);

  FeatureRequirement Direct;
  Direct.Instructions = bit(Node.getInstructionID());
  Direct.Selves.push_back(&Node);
  ShapeRequirement Shape = shapeOf(Node);
  if (Shape.Present || Shape.Absent || Shape.Width)
    Direct.Shapes.push_back(Shape);
  // The matcher takes the operands of these from elsewhere than operands().
  bool UsesOperands = Node.getInstructionID() != Instruction::I_phi &&
                      Node.getInstructionID() != Instruction::I_extractvalue &&
                      Node.getInstructionID() != Instruction::I_insertvalue;
  for (auto [Position, Operand] : enumerate(ValueOperands)) {
    if (Operand->IsArray || !Operand->Val)
      continue;
    Direct.unite(requirementOf(*Operand->Val, OnStack));
    Site S{&Node, operandSlots(Node, Position, ValueOperands.size())};
    if (isa<MetaVariable, Instruction>(Operand->Val))
      Direct.OperandSites.push_back({Operand->Val, S});
    // An integer constant is matched as the index records literals.
    if (const auto *Integer = dyn_cast<IntegerConstant>(Operand->Val))
      if (std::optional<int64_t> V = Integer->getValue().tryExtValue())
        if (std::optional<Atom> Literal = Atom::literal(*V))
          Direct.SiteFacts.push_back({S, *Literal});
    // A constant written once can match different constants (a scalar and a
    // splat), so only variables and instructions make siblings.
    if (UsesOperands && isa<MetaVariable, Instruction>(Operand->Val))
      Direct.Uses.push_back({Operand->Val, Node.getInstructionID()});
    // An operand with ':o' may match an instruction of another kind.
    const auto *Child = dyn_cast<Instruction>(Operand->Val);
    if (Child && !Child->isComposite() && !Child->getOrSelfOperandIndex())
      Direct.Edges.push_back(
          {Node.getInstructionID(), Child->getInstructionID()});
  }
  sortUnique(Direct.Edges);
  sortUnique(Direct.Uses);
  sortUnique(Direct.OperandSites);
  sortUnique(Direct.SiteFacts);
  sortUnique(Direct.Selves);

  // With ':o', the target matches either Node or its or-self operand, so only
  // what both alternatives need is required.
  if (std::optional<unsigned> Index = Node.getOrSelfOperandIndex()) {
    const Value *OrSelf = Node.getOrSelfValue();
    if (!OrSelf && *Index < ValueOperands.size() &&
        !ValueOperands[*Index]->IsArray)
      OrSelf = ValueOperands[*Index]->Val;
    if (OrSelf)
      Direct.intersect(requirementOf(*OrSelf, OnStack));
    else
      Direct = {};
  }

  OnStack.erase(&Node);
  return Direct;
}

static FeatureRequirement
requirementOf(const Value &Node,
              SmallPtrSetImpl<const Instruction *> &OnStack) {
  if (const auto *I = dyn_cast<Instruction>(&Node))
    return requirementOfInstruction(*I, OnStack);
  FeatureRequirement Requirement;
  // A global matches only a global operand of the same name.
  if (const auto *Global = dyn_cast<GlobalValue>(&Node))
    Requirement.Globals.push_back(hashGlobalName(Global->getName()));
  return Requirement;
}

FeatureQuery::FeatureQuery() : TypeContext(std::make_unique<LLVMContext>()) {}
FeatureQuery::FeatureQuery(FeatureQuery &&) = default;
FeatureQuery &FeatureQuery::operator=(FeatureQuery &&) = default;
FeatureQuery::~FeatureQuery() = default;

/// Whether C refers to nothing a match binds, nor to definitions, so that it
/// evaluates the same in every match.
static bool isClosed(const Constraint &C) {
  if (isa<VariableConstraint>(C))
    return false;
  if (const auto *Array = dyn_cast<ArrayConstraint>(&C))
    return all_of(Array->getElements(),
                  [](const Constraint *E) { return isClosed(*E); });
  if (const auto *Access = dyn_cast<ArrayAccessConstraint>(&C))
    return isClosed(*Access->getArray()) && isClosed(*Access->getIndex());
  if (const auto *Operator = dyn_cast<OperatorConstraint>(&C))
    return !Operator->isUserDefined() &&
           all_of(Operator->getArguments(),
                  [](const Constraint *A) { return isClosed(*A); });
  return true;
}

/// Whether some constraint of Lowered rejects every match: a closed
/// constraint evaluates alike in every match, and rejects it when it is false
/// or fails to evaluate (such as 'udiv(1, 0) == 0').
static bool hasFalseConstraint(const Pattern &Lowered) {
  ConstraintInterpreter Interpreter;
  Instantiation Empty;
  for (const Constraint *C : Lowered.getConstraints()) {
    if (!isClosed(*C))
      continue;
    Expected<ConstraintValue> Result = Interpreter.evaluate(*C, Empty);
    Expected<bool> Holds = Result ? detail::requireBoolean(*Result, *C)
                                  : Expected<bool>(Result.takeError());
    if (!Holds) {
      consumeError(Holds.takeError());
      return true;
    }
    if (!*Holds)
      return true;
  }
  return false;
}

FeatureQuery FeatureQuery::compute(const PatternVariants &Variants,
                                   const MIRContext *Definitions) {
  FeatureQuery Query;
  Query.Definitions = Definitions;
  for (const Pattern *Lowered : Variants) {
    Variant V;
    V.Lowered = Lowered;
    V.Impossible = hasFalseConstraint(*Lowered);
    FeatureRequirement &Requirement = V.Requirement;
    SmallPtrSet<const Instruction *, 8> OnStack;
    for (const Instruction *Root : Lowered->getRoots())
      Requirement.unite(requirementOf(*Root, OnStack));

    // Instructions using the same value are siblings.
    for (auto I = Requirement.Uses.begin(); I != Requirement.Uses.end(); ++I)
      for (auto J = std::next(I);
           J != Requirement.Uses.end() && J->first == I->first; ++J)
        Requirement.Siblings.push_back(FunctionFeatures::getEdgeKey(
            std::min(I->second, J->second), std::max(I->second, J->second)));
    sortUnique(Requirement.Siblings);

    // A value's sites: where it is an operand, and, for an instruction
    // matched as itself, its result. A capture is its instruction.
    DenseMap<const Value *, Sites> SitesOf;
    for (const auto &[Value, S] : Requirement.OperandSites)
      SitesOf[Value].push_back(S);
    for (const Instruction *Self : Requirement.Selves) {
      V.Certain.insert(Self);
      SitesOf[Self].push_back(Site{Self, uint8_t(1u << ResultSlot)});
    }
    for (const Instruction *I : Lowered->getInstructions())
      if (V.Certain.count(I))
        V.CertainInOrder.push_back(I);
    for (const Instruction *I : Lowered->getInstructions())
      if (MetaVariable *Capture = I->getCapture())
        if (auto It = SitesOf.find(I); It != SitesOf.end())
          SitesOf[Capture] = It->second;
    for (auto &[Value, S] : SitesOf)
      V.Bindings.bind(*Value, AbstractValue::sites(std::move(S)));

    Requirement.Uses.clear();
    Requirement.OperandSites.clear();
    Requirement.Selves.clear();
    Query.Variants.push_back(std::move(V));
  }
  return Query;
}

/// The limit on the ways to type a variant's instructions.
static constexpr size_t MaxTypings = 256;

/// The matcher operand positions of Node's operands, in order: as written,
/// or with ':c' swapped as InstructionMatcher swaps them.
static SmallVector<unsigned, 4>
operandPositions(const Instruction &Node, unsigned NumOperands, bool Swapped) {
  SmallVector<unsigned, 4> Positions;
  for (unsigned P = 0; P != NumOperands; ++P)
    Positions.push_back(P);
  if (!Swapped)
    return Positions;
  if (Node.getInstructionID() == Instruction::I_call && NumOperands == 3)
    std::swap(Positions[1], Positions[2]);
  else if (NumOperands == 2)
    std::swap(Positions[0], Positions[1]);
  return Positions;
}

/// Binds Node's operand and result types to those of Sig, as InstructionMatcher
/// matches them, into Row; returns whether they match. Types the index does
/// not encode match anything.
static bool bindTypes(const Instruction &Node, const Signature &Sig,
                      bool Swapped, LLVMContext &Context, Instantiation &Row) {
  bool TreatIntAsVec = Node.getSettings().has(PatternSettings::treatIntAsVec);
  unsigned NumOperands =
      count_if(Node.getUnkeyedOperands(), [](const MatcherOperand &Operand) {
        return Operand.IsInstructionOperand;
      });
  SmallVector<unsigned, 4> Positions =
      operandPositions(Node, NumOperands, Swapped);
  Instruction::InstructionID ID = Node.getInstructionID();
  unsigned Index = 0;
  for (const MatcherOperand &Operand : Node.getUnkeyedOperands()) {
    TypeCode Code = NoType;
    if (Operand.IsInstructionOperand) {
      unsigned Position = Positions[Index++];
      if (Operand.IsArray || Position >= NumOperandSlots)
        continue;
      Code = Sig.Operands[Position];
    } else if (ID != Instruction::I_alloca &&
               ID != Instruction::I_getelementptr) {
      // A type-only operand is the result's type (InstructionMatcher's
      // getTypeOnlyOperandTarget).
      Code = Sig.Result;
    }
    const llvm::Type *Target = decodeType(Code, Context);
    if (!Operand.Ty || !Target)
      continue;
    if (!TypeMatcher(*Operand.Ty, *Target, Row, TreatIntAsVec).match())
      return false;
  }
  return true;
}

/// The ways Node can be typed by the signatures of Features.
static SmallVector<Instantiation, 4> typingsOf(const Instruction &Node,
                                               const FunctionFeatures &Features,
                                               LLVMContext &Context) {
  ShapeRequirement Shape = shapeOf(Node);
  bool Commutative = Node.hasMetaFlag(MetaFlag::MF_c);
  SmallVector<Instantiation, 4> Typings;
  Signature First;
  First.ID = Node.getInstructionID();
  for (auto It = llvm::lower_bound(
           Features.Signatures, First,
           [](const Signature &L, const Signature &R) { return L.ID < R.ID; });
       It != Features.Signatures.end() && It->ID == First.ID; ++It) {
    if ((It->Flags & Shape.Present) != Shape.Present ||
        (It->Flags & Shape.Absent) != 0)
      continue;
    for (bool Swapped : {false, true}) {
      if (Swapped && !Commutative)
        break;
      Instantiation Row;
      if (bindTypes(Node, *It, Swapped, Context, Row) &&
          !is_contained(Typings, Row))
        Typings.push_back(std::move(Row));
    }
  }
  return Typings;
}

SmallVector<Instantiation, 4>
FeatureQuery::joinSignatures(const Variant &V,
                             const FunctionFeatures &Features) const {
  SmallVector<Instantiation, 4> Joined(1);
  bool Overflowed = false;
  for (const Instruction *Node : V.CertainInOrder) {
    SmallVector<Instantiation, 4> Typings =
        typingsOf(*Node, Features, *TypeContext);
    if (Typings.empty())
      return {};
    if (Overflowed || Typings.size() > MaxTypings) {
      Overflowed = true;
      continue;
    }
    SmallVector<Instantiation, 4> Next;
    for (const Instantiation &Partial : Joined)
      for (const Instantiation &Typing : Typings) {
        Instantiation Merged = Partial;
        if (Merged.unifyAll(Typing) && !is_contained(Next, Merged))
          Next.push_back(std::move(Merged));
      }
    if (Next.empty())
      return {};
    if (Next.size() > MaxTypings)
      Overflowed = true;
    else
      Joined = std::move(Next);
  }
  // Past the limit, the types are not bound; each instruction can still be
  // typed.
  if (Overflowed)
    return SmallVector<Instantiation, 4>(1);
  return Joined;
}

bool FeatureQuery::constraintsMayHold(const Variant &V,
                                      const FunctionFeatures &Features,
                                      const Instantiation &Types) const {
  // Without the definitions, a call to one would be an error, which the index
  // takes as certain.
  if (!Definitions)
    return true;
  IndexDomain Domain(Features, V.Certain);
  ConstraintEvaluator<IndexDomain> Evaluator(Domain, Definitions);
  AbstractBindings Bindings = V.Bindings;
  Bindings.Types = &Types;
  for (const Constraint *Expression : V.Lowered->getConstraints()) {
    Expected<AbstractValue> Result = Evaluator.evaluate(*Expression, Bindings);
    // An error rejects every match, as on the IR.
    if (!Result) {
      consumeError(Result.takeError());
      return false;
    }
    if (!Result->isConcrete())
      continue;
    Expected<bool> Holds =
        detail::requireBoolean(Result->getConcrete(), *Expression);
    if (!Holds) {
      consumeError(Holds.takeError());
      return false;
    }
    if (!*Holds)
      return false;
  }
  return true;
}

bool FeatureQuery::mayMatchVariant(unsigned Index,
                                   const FunctionFeatures &Features) const {
  const Variant &V = Variants[Index];
  if (V.Impossible || !V.Requirement.isSatisfiedBy(Features))
    return false;
  if (!Features.Fine)
    return true;
  return any_of(joinSignatures(V, Features), [&](const Instantiation &Types) {
    return constraintsMayHold(V, Features, Types);
  });
}

bool FeatureQuery::mayMatch(const FunctionFeatures &Features) const {
  for (unsigned Index = 0; Index != Variants.size(); ++Index)
    if (mayMatchVariant(Index, Features))
      return true;
  return false;
}

template class ConstraintEvaluator<IndexDomain>;

} // namespace metaphir
} // namespace llvm
