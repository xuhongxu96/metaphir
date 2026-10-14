#include "metaphir/IR/Constraint.h"
#include "metaphir/IR/MIRContext.h"
#include "metaphir/IR/MIRContextImpl.h"
#include "llvm/Support/raw_ostream.h"

namespace llvm {
namespace metaphir {

IntegerConstraint *IntegerConstraint::create(MIRContext &Context,
                                             int64_t Number,
                                             SourceRange Range) {
  return new (Context.pImpl->Alloc) IntegerConstraint(Number, Range);
}

BooleanConstraint *BooleanConstraint::create(MIRContext &Context, bool State,
                                             SourceRange Range) {
  return new (Context.pImpl->Alloc) BooleanConstraint(State, Range);
}

StringConstraint *StringConstraint::create(MIRContext &Context, StringRef Value,
                                           SourceRange Range) {
  return new (Context.pImpl->Alloc)
      StringConstraint(Context.pImpl->Saver.save(Value), Range);
}

ArrayConstraint *ArrayConstraint::create(MIRContext &Context, Sort Type,
                                         ArrayRef<Constraint *> Elements,
                                         SourceRange Range) {
  return new (Context.pImpl->Alloc)
      ArrayConstraint(Type, Context.pImpl->copyArray(Elements), Range);
}

VariableConstraint *VariableConstraint::create(MIRContext &Context,
                                               Value *Variable, Sort Type,
                                               SourceRange Range) {
  return new (Context.pImpl->Alloc) VariableConstraint(Variable, Type, Range);
}

ArrayAccessConstraint *
ArrayAccessConstraint::create(MIRContext &Context, Sort Type, Constraint *Array,
                              Constraint *Index, SourceRange Range) {
  return new (Context.pImpl->Alloc)
      ArrayAccessConstraint(Type, Array, Index, Range);
}

OperatorConstraint *OperatorConstraint::createBuiltin(
    MIRContext &Context, ConstraintID ID, Sort Type, OperatorID OpID,
    ArrayRef<Constraint *> Arguments, SourceRange Range) {
  assert(OpID != UnknownOperator &&
         "built-in OperatorConstraint::getBuiltin requires a known OperatorID");
  return new (Context.pImpl->Alloc) OperatorConstraint(
      ID, Type, OpID, Context.pImpl->copyArray<Constraint *>(Arguments), Range);
}

OperatorConstraint *OperatorConstraint::createUserDefined(
    MIRContext &Context, ConstraintID ID, Sort Type, StringRef Operator,
    ArrayRef<Constraint *> Arguments, SourceRange Range) {
  assert(Constraint::getOperatorID(Operator, ID) == UnknownOperator &&
         "custom OperatorConstraint::getUserDefined cannot be called with a "
         "built-in operator name");
  StringRef SavedOperator = Context.pImpl->Saver.save(Operator);
  return new (Context.pImpl->Alloc) OperatorConstraint(
      ID, Type, SavedOperator,
      Context.pImpl->copyArray<Constraint *>(Arguments), Range);
}

Constraint::OperatorID OperatorConstraint::getOperatorID() const {
  if (const auto *ID = std::get_if<OperatorID>(&Op))
    return *ID;
  return UnknownOperator;
}

StringRef OperatorConstraint::getOperator() const {
  if (const auto *ID = std::get_if<OperatorID>(&Op))
    return Constraint::getOperatorName(*ID);
  return std::get<StringRef>(Op);
}

std::optional<Constraint::OperatorSchema>
Constraint::getOperatorSchema(OperatorID ID) {
  switch (ID) {
#define MIR_CONSTRAINT_OPERATOR_SCHEMA(OperatorID, Name, Kind, Result,         \
                                       MinArity, MaxArity)                     \
  case O_##OperatorID:                                                         \
    return OperatorSchema{Result, MinArity, MaxArity};
#include "metaphir/IR/ConstraintOperators.def"
  case UnknownOperator:
    break;
  }
  return std::nullopt;
}

Constraint::OperatorID Constraint::getOperatorID(StringRef Name,
                                                 ConstraintID Kind) {
  static const auto OperatorMaps = [] {
    struct Maps {
      StringMap<OperatorID> Unary;
      StringMap<OperatorID> Binary;
      StringMap<OperatorID> Call;
    } M;
#define MIR_CONSTRAINT_OPERATOR_ID(OperatorID, OperatorName, OperatorKind)     \
  if (OperatorKind == Constraint::Unary)                                       \
    M.Unary[OperatorName] = Constraint::O_##OperatorID;                        \
  else if (OperatorKind == Constraint::Binary)                                 \
    M.Binary[OperatorName] = Constraint::O_##OperatorID;                       \
  else if (OperatorKind == Constraint::Call)                                   \
    M.Call[OperatorName] = Constraint::O_##OperatorID;
#define MIR_CONSTRAINT_OPERATOR_ALIAS(OperatorID, OperatorName, OperatorKind)  \
  if (OperatorKind == Constraint::Unary)                                       \
    M.Unary[OperatorName] = Constraint::O_##OperatorID;                        \
  else if (OperatorKind == Constraint::Binary)                                 \
    M.Binary[OperatorName] = Constraint::O_##OperatorID;                       \
  else if (OperatorKind == Constraint::Call)                                   \
    M.Call[OperatorName] = Constraint::O_##OperatorID;
#include "metaphir/IR/ConstraintOperators.def"
    return M;
  }();

  const StringMap<OperatorID> *Map = nullptr;
  switch (Kind) {
  case Unary:
    Map = &OperatorMaps.Unary;
    break;
  case Binary:
    Map = &OperatorMaps.Binary;
    break;
  case Call:
    Map = &OperatorMaps.Call;
    break;
  default:
    return UnknownOperator;
  }

  auto It = Map->find(Name);
  return It != Map->end() ? It->second : UnknownOperator;
}

StringRef Constraint::getOperatorName(OperatorID ID) {
  switch (ID) {
#define MIR_CONSTRAINT_OPERATOR_ID(OperatorID, Name, Kind)                     \
  case O_##OperatorID:                                                         \
    return Name;
#include "metaphir/IR/ConstraintOperators.def"
  case UnknownOperator:
    return {};
  }
  llvm_unreachable("invalid constraint function ID");
}

bool Constraint::canCoerce(Sort From, Sort To) {
  if (From == Sort::Unknown || To == Sort::Unknown || isSubsort(From, To))
    return true;
  Sort Represented = getRepresentation(From);
  if (Represented == To)
    return true;
#define MIR_COERCION(Src, Dst, Op)                                             \
  if (Represented == Sort::Src && To == Sort::Dst)                             \
    return true;
#include "metaphir/IR/ConstraintCoercions.def"
  return false;
}

Sort Constraint::getArgumentType(OperatorID ID, unsigned Index) {
  switch (ID) {
  case O_LogicalOr:
  case O_LogicalAnd:
  case O_Not:
    return Sort::Boolean;
  case O_Add:
  case O_Subtract:
  case O_Multiply:
  case O_Negate:
  case O_SLT:
  case O_ULT:
  case O_SLE:
  case O_ULE:
  case O_SGT:
  case O_UGT:
  case O_SGE:
  case O_UGE:
  case O_SDiv:
  case O_UDiv:
  case O_SRem:
  case O_URem:
  case O_Lshr:
  case O_Ashr:
  case O_Shl:
  case O_And:
  case O_Or:
  case O_Xor:
  case O_Log2:
  case O_Popcount:
  case O_CountlZero:
  case O_CountrZero:
  case O_CountlOne:
  case O_CountrOne:
    return Sort::Integer;
  case O_Isa:
    return Index == 0 ? Sort::Value : Sort::String;
  case O_Opcode:
  case O_Intrinsic:
  case O_Predicate:
    return Sort::Value;
#define MIR_CMP_PREDICATE_TEST(ID, Name, Test) case O_##ID:
#define MIR_CMP_PREDICATE_MAP(ID, Name, Map) case O_##ID:
#include "metaphir/IR/CmpPredicateOperators.def"
  case O_FlippedSignednessPredicate:
    return Sort::String;
  case O_KnownZeros:
  case O_KnownOnes:
    return Sort::BitVector;
  // Value-tracking operators take values, then an optional context
  // instruction.
  case O_NoOverflow:
    return Index == 0 ? Sort::String : Sort::Value;
  case O_KnownBits:
  case O_IsKnownNonZero:
  case O_IsKnownNegative:
  case O_IsGuaranteedNotToBeUndef:
  case O_IsKnownNonNegative:
  case O_IsKnownPositive:
  case O_IsKnownPowerOfTwo:
  case O_IsKnownPowerOfTwoOrZero:
  case O_IsGuaranteedNotToBePoison:
  case O_IsGuaranteedNotToBeUndefOrPoison:
  case O_NumSignBits:
  case O_MaxSignificantBits:
  case O_IsKnownNeverNaN:
  case O_IsKnownNeverInfinity:
  case O_IsKnownNeverInfOrNaN:
  case O_CannotBeNegativeZero:
  case O_CannotBeOrderedLessThanZero:
    return Sort::Value;
  case O_MaskedValueIsZero:
    return Index == 1 ? Sort::Integer : Sort::Value;
  case O_HasNUses:
  case O_HasNUsesOrMore:
    return Index == 1 ? Sort::Integer : Sort::Value;
  case O_InSignedRange:
  case O_InUnsignedRange:
    return Index == 1 || Index == 2 ? Sort::Integer : Sort::Value;
  // These accept a value or a plain integer, or answer false for anything
  // else.
  case O_Equal:
  case O_NotEqual:
  case O_IsAnyIntegralConstant:
  case O_IsForbidPoison:
  case O_IsConstantSplat:
  case O_IsScalar:
  case O_HasOneUse:
  case O_HasOneUser:
  case O_IsImmConstant:
#define MIR_CONSTANT_CLASS(ID, Name, Matcher, IntegerTest) case O_##ID:
#include "metaphir/IR/ConstantClasses.def"
  // bitWidth takes a value or a type.
  case O_BitWidth:
  case UnknownOperator:
    return Sort::Unknown;
  }
  llvm_unreachable("invalid constraint operator");
}

StringRef Constraint::describe(Sort Type) {
  switch (getRepresentation(Type)) {
  case Sort::Unknown:
    return "any value";
  case Sort::Integer:
    return "an integer";
  case Sort::Boolean:
    return "a boolean";
  case Sort::String:
    return "a string";
  case Sort::Type:
    return "a type";
  case Sort::Value:
    return "a value";
  case Sort::TypeArray:
    return "a type array";
  case Sort::ValueArray:
    return "a value array";
  case Sort::StringArray:
    return "a string array";
  case Sort::BitVector:
    return "a bit vector";
  default:
    break;
  }
  llvm_unreachable("a representation sort has no description");
}

void Constraint::setDefaultContextInstruction(const Instruction *CxtI) {
  if (!Context)
    Context = CxtI;
  switch (ID) {
  case Array:
    for (Constraint *Element : cast<ArrayConstraint>(this)->getElements())
      Element->setDefaultContextInstruction(CxtI);
    break;
  case ArrayAccess: {
    auto *Access = cast<ArrayAccessConstraint>(this);
    Access->getArray()->setDefaultContextInstruction(CxtI);
    Access->getIndex()->setDefaultContextInstruction(CxtI);
    break;
  }
  case Unary:
  case Binary:
  case Call:
    for (Constraint *Argument : cast<OperatorConstraint>(this)->getArguments())
      Argument->setDefaultContextInstruction(CxtI);
    break;
  case Integer:
  case Boolean:
  case String:
  case Variable:
    break;
  }
}

raw_ostream &operator<<(raw_ostream &OS, const Constraint &C) {
  switch (C.getConstraintID()) {
  case Constraint::Integer:
    return OS << cast<IntegerConstraint>(C).getValue();
  case Constraint::Boolean:
    return OS << (cast<BooleanConstraint>(C).getValue() ? "true" : "false");
  case Constraint::String:
    return OS << '"' << cast<StringConstraint>(C).getValue() << '"';
  case Constraint::Array: {
    const auto &Array = cast<ArrayConstraint>(C);
    OS << '[';
    for (unsigned Index = 0; Index != Array.getElements().size(); ++Index) {
      if (Index)
        OS << ',';
      OS << *Array.getElements()[Index];
    }
    return OS << ']';
  }
  case Constraint::Variable: {
    const Value *V = cast<VariableConstraint>(C).getVariable();
    if (const auto *MV = dyn_cast<MetaVariable>(V))
      return OS << *MV;
    return OS << *V;
  }
  case Constraint::ArrayAccess: {
    const auto &Access = cast<ArrayAccessConstraint>(C);
    return OS << *Access.getArray() << '[' << *Access.getIndex() << ']';
  }
  case Constraint::Unary:
  case Constraint::Binary:
  case Constraint::Call: {
    const auto &Operator = cast<OperatorConstraint>(C);
    OS << '(' << Operator.getOperator();
    for (const Constraint *Argument : Operator.getArguments())
      OS << ' ' << *Argument;
    return OS << ')';
  }
  }
  llvm_unreachable("invalid constraint kind");
}

} // namespace metaphir
} // namespace llvm
