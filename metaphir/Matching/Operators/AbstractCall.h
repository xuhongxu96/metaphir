#ifndef METAPHIR_MATCHING_OPERATORS_ABSTRACTCALL_H
#define METAPHIR_MATCHING_OPERATORS_ABSTRACTCALL_H

#include "metaphir/IR/Instruction.h"
#include "metaphir/Matching/ConstraintValue.h"
#include "metaphir/Matching/Operators/Facts.h"
#include "llvm/ADT/ArrayRef.h"
#include "llvm/ADT/SmallVector.h"
#include <tuple>
#include <variant>

namespace llvm {
namespace metaphir {

class Constraint;
class FunctionFeatures;

/// A place a pattern value certainly occupies in every match: an operand, in
/// one of Slots, of the instruction Parent matches, or (Slots holding
/// ResultSlot) that instruction itself.
struct Site {
  const Instruction *Parent = nullptr;
  /// Bit S is set for slot S; with ':c', operands can be in either of two.
  uint8_t Slots = 0;

  auto tie() const { return std::make_tuple(Parent, Slots); }
  bool operator<(const Site &Other) const { return tie() < Other.tie(); }
  bool operator==(const Site &Other) const { return tie() == Other.tie(); }
};

using Sites = SmallVector<Site, 2>;

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
/// called when some operand is not concrete; ConstraintEvaluator applies its
/// concrete() when all are.
struct AbstractCall {
  ArrayRef<AbstractValue> Operands;
  const Constraint &Expression;
  const FunctionFeatures &Features;
  /// For a value-tracking operator, the pattern instruction its context
  /// resolves to, if that instruction is certainly matched.
  const Instruction *Context = nullptr;
};

/// False if some site of V lacks fact A in all its slots, where the index
/// records it; otherwise unknown. V is Operands[OperandIndex], and a value
/// that is not a site list is unknown.
AbstractValue lacksFact(const AbstractCall &Call, unsigned OperandIndex,
                        Atom A);

/// Like lacksFact for a value-tracking fact: only the sites of the context
/// instruction count, as value tracking is anchored there.
AbstractValue lacksValueFact(const AbstractCall &Call, unsigned OperandIndex,
                             Atom A);

/// False if some site of Operands[OperandIndex], of the context instruction,
/// has measure M outside Bound in all its slots: above it for a least
/// measure, below it for a most one. Otherwise unknown.
AbstractValue exceedsMeasure(const AbstractCall &Call, unsigned OperandIndex,
                             Measure M, unsigned Bound);

} // namespace metaphir
} // namespace llvm

#endif
