#ifndef METAPHIR_IR_CONSTRAINT_H
#define METAPHIR_IR_CONSTRAINT_H

#include "metaphir/IR/Sort.h"
#include "llvm/ADT/StringRef.h"
#include <optional>

namespace llvm {
namespace metaphir {

/// The built-in operators of constraint expressions ('==', '&&', 'isZero',
/// ...), from ConstraintOperators.def, and the sorts they take and give.
struct Constraint {
  /// How an operator is written.
  enum OperatorKind { Unary, Binary, Call };
  enum OperatorID {
    UnknownOperator,
#define MIR_CONSTRAINT_OPERATOR_ID(ID, Name, Kind) O_##ID,
#include "metaphir/IR/ConstraintOperators.def"
  };

  struct OperatorSchema {
    Sort Result;
    unsigned MinArity;
    unsigned MaxArity;
  };

  static std::optional<OperatorSchema> getOperatorSchema(OperatorID ID);
  static StringRef getOperatorName(OperatorID ID);
  static OperatorID getOperatorID(StringRef Name, OperatorKind Kind);

  /// Whether a value of sort From may be used where To is expected: From is
  /// a subsort of To, one of them is unknown until evaluation, or From's
  /// representation converts to To (see ConstraintCoercions.def).
  static bool canCoerce(Sort From, Sort To);
  /// The sort argument Index of a built-in operator must coerce to; Unknown
  /// when any value is accepted.
  static Sort getArgumentType(OperatorID ID, unsigned Index);
  /// A phrase naming a sort for diagnostics, e.g. "an integer".
  static StringRef describe(Sort Type);

  Constraint() = delete;
};

} // namespace metaphir
} // namespace llvm
#endif
