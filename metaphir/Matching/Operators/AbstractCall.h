#ifndef METAPHIR_MATCHING_OPERATORS_ABSTRACTCALL_H
#define METAPHIR_MATCHING_OPERATORS_ABSTRACTCALL_H

#include "metaphir/IR/Instruction.h"
#include "metaphir/IR/Site.h"
#include "metaphir/Matching/ConstraintError.h"
#include "metaphir/Matching/ConstraintValue.h"
#include "metaphir/Matching/Operators/Facts.h"
#include "llvm/ADT/ArrayRef.h"
#include "llvm/ADT/SmallVector.h"
#include <tuple>
#include <type_traits>
#include <variant>

namespace llvm {
namespace metaphir {

class FunctionFeatures;

/// What a constraint expression is on a function's features: a value it
/// certainly has (a literal, or a type bound during index matching), the
/// sites of an IR value, or unknown.
///
/// A concrete boolean B stands for "B, or an evaluation error": either way a
/// match is rejected when B is false, so the index may prune on it.
class AbstractValue {
public:
  static AbstractValue unknown() { return AbstractValue(std::monostate()); }
  static AbstractValue concrete(ConstraintValue V) {
    return AbstractValue(std::move(V));
  }
  static AbstractValue sites(Sites S) { return AbstractValue(std::move(S)); }

  bool isConcrete() const {
    return std::holds_alternative<ConstraintValue>(Data);
  }
  bool isSites() const { return std::holds_alternative<Sites>(Data); }
  const ConstraintValue &getConcrete() const {
    return std::get<ConstraintValue>(Data);
  }
  const Sites &getSites() const { return std::get<Sites>(Data); }

  /// Whether this is the boolean false.
  bool isFalse() const {
    return isConcrete() &&
           getConcrete().getKind() == ConstraintValue::Boolean &&
           !getConcrete().getBoolean();
  }

private:
  using Storage = std::variant<std::monostate, ConstraintValue, Sites>;
  explicit AbstractValue(Storage Data) : Data(std::move(Data)) {}

  Storage Data;
};

/// A built-in constraint operator applied to abstract operands, on a
/// function's features. An operator's abstract(const AbstractCall &) is
/// called when some operand is not concrete; IndexQuery applies its
/// concrete() when all are.
struct AbstractCall {
  ArrayRef<AbstractValue> Operands;
  mlir::Value Expression;
  const FunctionFeatures &Features;
  /// For a value-tracking operator, the node of the pattern instruction its
  /// context resolves to, if that instruction is certainly matched; -1 if
  /// not.
  int64_t Context = -1;
};

/// False if some site of V lacks fact A in all its positions, where the index
/// records it; otherwise unknown. V is Operands[OperandIndex], and a value
/// that is not a site list is unknown.
AbstractValue lacksFact(const AbstractCall &Call, unsigned OperandIndex,
                        Atom A);

/// Like lacksFact for a value-tracking fact: only the sites of the context
/// instruction count, as value tracking is anchored there.
AbstractValue lacksValueFact(const AbstractCall &Call, unsigned OperandIndex,
                             Atom A);

/// False if some site of Operands[OperandIndex], of the context instruction,
/// has measure M outside Bound in all its positions: above it for a least
/// measure, below it for a most one. Otherwise unknown.
AbstractValue exceedsMeasure(const AbstractCall &Call, unsigned OperandIndex,
                             Measure M, unsigned Bound);

namespace detail {
/// Whether the operator descriptor Op has an abstract() face.
template <class Op, class = void> struct HasAbstract : std::false_type {};
template <class Op>
struct HasAbstract<Op, std::void_t<decltype(&Op::abstract)>> : std::true_type {
};
} // namespace detail

} // namespace metaphir
} // namespace llvm

#endif
