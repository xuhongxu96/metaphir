#ifndef METAPHIR_MATCHING_CONSTRAINTINTERPRETER_H
#define METAPHIR_MATCHING_CONSTRAINTINTERPRETER_H

#include "metaphir/Matching/ConstraintValue.h"
#include "llvm/Support/Error.h"
#include <memory>
#include <optional>

namespace llvm {
struct SimplifyQuery;
namespace metaphir {
namespace detail {
class ValueTrackContext;
} // namespace detail

class Constraint;
class Instantiation;
class ArrayConstraint;
class ArrayAccessConstraint;
class OperatorConstraint;
class VariableConstraint;
class MIRContext;

class ConstraintInterpreter {
public:
  /// Context holds the 'constraint' definitions that calls refer to; without
  /// one, only built-in operations can be evaluated.
  explicit ConstraintInterpreter(MIRContext *Context = nullptr);
  ~ConstraintInterpreter();

  Expected<ConstraintValue> evaluate(const Constraint &Expression,
                                     const Instantiation &State);

private:
  // Signature of a value-tracking operator's pure evaluator: given the
  // evaluated operand values, the query context, and the operator node,
  // produce the result.
  using ValueTrackOp = Expected<ConstraintValue> (*)(
      ArrayRef<ConstraintValue> Values, const SimplifyQuery &Query,
      const Constraint &Expression);

  // Evaluates the operator's fixed operands, resolves the context instruction
  // (explicit ?ctx or the constraint's context instruction), builds the lazy
  // query, and dispatches to the operator's pure evaluator.
  Expected<ConstraintValue> evaluateValueTrack(ArrayRef<Constraint *> Arguments,
                                               unsigned BaseArity,
                                               const Instantiation &State,
                                               const Constraint &Expression,
                                               ValueTrackOp Op);

  // Value-tracking operators build their query through this context. The
  // per-function analyses are materialized lazily on first use.
  SimplifyQuery getValueTrackQuery(const llvm::Instruction *CtxI);

  // Resolves the use-point instruction for a value-tracking operator: the
  // explicit trailing ?ctx argument when present, otherwise the constraint's
  // context instruction resolved through the match bindings.
  Expected<const llvm::Instruction *>
  resolveValueTrackContext(ArrayRef<Constraint *> Arguments, unsigned BaseArity,
                           const Instantiation &State,
                           const Constraint &Expression);
  // Evaluates integer/boolean/string literal nodes.
  Expected<ConstraintValue> evalLiteral(const Constraint &Expression,
                                        const Instantiation &State);
  // Dispatches a variable reference by resolving it against the instantiation
  // state, checking that the bound value matches the expected result type.
  Expected<ConstraintValue> evalVariable(const VariableConstraint &Expression,
                                         const Instantiation &State);
  Expected<ConstraintValue> evalArray(const ArrayConstraint &Expression,
                                      const Instantiation &State);
  Expected<ConstraintValue> evalArrayAccess(const ArrayAccessConstraint &Access,
                                            const Instantiation &State);
  Expected<ConstraintValue> evalOperator(const OperatorConstraint &Operator,
                                         const Instantiation &State);
  /// Evaluates a call to a 'constraint' definition: its body, with the
  /// parameters bound to the evaluated arguments.
  Expected<ConstraintValue> evalUserDefinedCall(const OperatorConstraint &Call,
                                                const Instantiation &State);
  Expected<ConstraintValue> evalLogical(const OperatorConstraint &Operator,
                                        const Instantiation &State);
  Expected<ConstraintValue> evalUnary(const OperatorConstraint &Operator,
                                      const Instantiation &State);
  Expected<ConstraintValue> evalShift(const OperatorConstraint &Operator,
                                      const Instantiation &State);
  Expected<ConstraintValue> evalArithmetic(const OperatorConstraint &Operator,
                                           const Instantiation &State);
  // Evaluates an optional trailing bitwidth argument. Returns std::nullopt when
  // the argument is absent (i.e. the operator was used without a bitwidth).
  Expected<std::optional<unsigned>>
  evalOptionalBitWidth(const OperatorConstraint &Operator,
                       unsigned ArgumentIndex, const Instantiation &State);

  // Lazily-constructed per-function analyses for value-tracking operators.
  std::unique_ptr<detail::ValueTrackContext> Analysis;
  MIRContext *Context = nullptr;
  /// Nesting of user-defined constraint calls being evaluated.
  unsigned CallDepth = 0;
  static constexpr unsigned MaxCallDepth = 256;
};

} // namespace metaphir
} // namespace llvm

#endif