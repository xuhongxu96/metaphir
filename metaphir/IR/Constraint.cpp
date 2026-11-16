#include "metaphir/IR/Constraint.h"
#include "llvm/ADT/StringMap.h"
#include "llvm/Support/ErrorHandling.h"

namespace llvm {
namespace metaphir {
namespace constraint {

std::optional<OperatorSchema> getOperatorSchema(OperatorID ID) {
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

OperatorID getOperatorID(StringRef Name, OperatorKind Kind) {
  static const auto OperatorMaps = [] {
    struct Maps {
      StringMap<OperatorID> Unary;
      StringMap<OperatorID> Binary;
      StringMap<OperatorID> Call;
    } M;
#define MIR_CONSTRAINT_OPERATOR_ID(OperatorID, OperatorName, OperatorKind)     \
  if (OperatorKind == constraint::Unary)                                       \
    M.Unary[OperatorName] = constraint::O_##OperatorID;                        \
  else if (OperatorKind == constraint::Binary)                                 \
    M.Binary[OperatorName] = constraint::O_##OperatorID;                       \
  else if (OperatorKind == constraint::Call)                                   \
    M.Call[OperatorName] = constraint::O_##OperatorID;
#define MIR_CONSTRAINT_OPERATOR_ALIAS(OperatorID, OperatorName, OperatorKind)  \
  if (OperatorKind == constraint::Unary)                                       \
    M.Unary[OperatorName] = constraint::O_##OperatorID;                        \
  else if (OperatorKind == constraint::Binary)                                 \
    M.Binary[OperatorName] = constraint::O_##OperatorID;                       \
  else if (OperatorKind == constraint::Call)                                   \
    M.Call[OperatorName] = constraint::O_##OperatorID;
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
  }

  auto It = Map->find(Name);
  return It != Map->end() ? It->second : UnknownOperator;
}

StringRef getOperatorName(OperatorID ID) {
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

bool canCoerce(Sort From, Sort To) {
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

Sort getArgumentType(OperatorID ID, unsigned Index) {
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
  // With a bit width, the operands of equality are integers.
  case O_Equal:
  case O_NotEqual:
    return Index == 2 ? Sort::Integer : Sort::Unknown;
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

StringRef describe(Sort Type) {
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

} // namespace constraint
} // namespace metaphir
} // namespace llvm
