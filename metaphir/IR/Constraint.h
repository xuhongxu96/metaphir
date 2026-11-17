#ifndef METAPHIR_IR_CONSTRAINT_H
#define METAPHIR_IR_CONSTRAINT_H

#include "metaphir/IR/Constraint.inc"
#include "metaphir/IR/Sort.h"
#include "llvm/ADT/StringMap.h"
#include "llvm/ADT/StringRef.h"
#include <array>
#include <optional>

namespace llvm {
namespace metaphir {

/// The built-in operators of constraint expressions ('==', '&&', 'isZero',
/// ...), and the sorts they take and give. Their data is generated from
/// ConstraintOperators.td (Constraint.inc); this reads it.
namespace constraint {

/// Whether ID is one of the operators; an ID read from a file may not be.
inline bool isOperator(OperatorID ID) {
  return ID > UnknownOperator && unsigned(ID) <= NumOperators;
}

inline std::optional<OperatorSchema> getOperatorSchema(OperatorID ID) {
  if (!isOperator(ID))
    return std::nullopt;
  return Schemas[ID - 1];
}

inline StringRef getOperatorName(OperatorID ID) {
  return isOperator(ID) ? OperatorNames[ID - 1] : StringRef();
}

/// The operator written as Name in the way Kind says, or UnknownOperator.
inline OperatorID getOperatorID(StringRef Name, OperatorKind Kind) {
  static const std::array<StringMap<OperatorID>, 3> Maps = [] {
    std::array<StringMap<OperatorID>, 3> M;
    for (const OperatorSpelling &S : Spellings)
      M[S.Kind][S.Name] = S.ID;
    return M;
  }();
  const StringMap<OperatorID> &Map = Maps[Kind];
  auto It = Map.find(Name);
  return It != Map.end() ? It->second : UnknownOperator;
}

/// The sort argument Index of a built-in operator must coerce to; Unknown
/// when any value is accepted.
inline Sort getArgumentType(OperatorID ID, unsigned Index) {
  if (!isOperator(ID))
    return Sort::Unknown;
  const ArgumentSorts &Signature = Signatures[ID - 1];
  return Index < Signature.NumExplicit ? Signature.Explicit[Index]
                                       : Signature.Rest;
}

/// Whether a value of sort From may be used where To is expected: From is
/// a subsort of To, one of them is unknown until evaluation, or From's
/// representation converts to To.
inline bool canCoerce(Sort From, Sort To) {
  if (From == Sort::Unknown || To == Sort::Unknown || isSubsort(From, To))
    return true;
  Sort Represented = getRepresentation(From);
  if (Represented == To)
    return true;
  for (const SortPair &Coercion : Coercions)
    if (Represented == Coercion.From && To == Coercion.To)
      return true;
  return false;
}

/// A phrase naming a sort for diagnostics, e.g. "an integer".
inline StringRef describe(Sort S) { return SortDescriptions[unsigned(S)]; }

} // namespace constraint

} // namespace metaphir
} // namespace llvm

#endif
