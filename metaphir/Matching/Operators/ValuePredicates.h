#ifndef METAPHIR_MATCHING_OPERATORS_VALUEPREDICATES_H
#define METAPHIR_MATCHING_OPERATORS_VALUEPREDICATES_H

#include "metaphir/Matching/Operators/AbstractCall.h"
#include "metaphir/Matching/Operators/Facts.h"
#include "metaphir/Matching/Operators/OperatorCall.h"
#include "llvm/Support/Error.h"

namespace llvm {
namespace metaphir {

// Operators that inspect an LLVM value by itself, without value tracking:
// its class, opcode, constant value and uses.

#define MIR_DECLARE_OPERATOR(ID)                                               \
  struct Op##ID {                                                              \
    static constexpr bool ShortCircuits = false;                               \
    static Expected<ConstraintValue> concrete(const ConcreteCall &Call);       \
  };

/// A predicate the index records as Fact: holds() decides it on the IR for
/// both the matcher (concrete) and the index (record); abstract() is false
/// where the index lacks the fact.
#define MIR_DECLARE_RECORDED_PREDICATE(ID)                                     \
  struct Op##ID {                                                              \
    static constexpr bool ShortCircuits = false;                               \
    static constexpr Atom::Predicate Fact = Atom::ID;                          \
    static bool holds(const llvm::Value &V);                                   \
    static Expected<ConstraintValue> concrete(const ConcreteCall &Call);       \
    static void record(const RecordCall &Call);                                \
    static AbstractValue abstract(const AbstractCall &Call);                   \
  };

struct OpIsa {
  static constexpr bool ShortCircuits = false;
  /// Whether V is of the ClassIndex-th class of LLVMValueClasses.def.
  static bool holds(const llvm::Value &V, unsigned ClassIndex);
  /// Whether the index records the class: not those nearly every value at a
  /// site is of.
  static bool isRecorded(unsigned ClassIndex);
  static Expected<ConstraintValue> concrete(const ConcreteCall &Call);
  static void record(const RecordCall &Call);
  static AbstractValue abstract(const AbstractCall &Call);
};

MIR_DECLARE_OPERATOR(Opcode)

/// A constant class the index does not record.
#define MIR_DECLARE_PREDICATE(ID)                                              \
  struct Op##ID {                                                              \
    static constexpr bool ShortCircuits = false;                               \
    static bool holds(const llvm::Value &V);                                   \
    static Expected<ConstraintValue> concrete(const ConcreteCall &Call);       \
  };
#define MIR_CONSTANT_CLASS(ID, Name, Matcher, IntegerTest)                     \
  MIR_DECLARE_RECORDED_PREDICATE(ID)
#define MIR_UNRECORDED_CONSTANT_CLASS(ID, Name, Matcher, IntegerTest)          \
  MIR_DECLARE_PREDICATE(ID)
#include "metaphir/IR/ConstantClasses.def"
#undef MIR_DECLARE_PREDICATE

MIR_DECLARE_RECORDED_PREDICATE(IsAnyIntegralConstant)
MIR_DECLARE_RECORDED_PREDICATE(IsImmConstant)
MIR_DECLARE_RECORDED_PREDICATE(IsForbidPoison)
MIR_DECLARE_RECORDED_PREDICATE(IsConstantSplat)
/// Not recorded: nearly every value is scalar.
struct OpIsScalar {
  static constexpr bool ShortCircuits = false;
  static bool holds(const llvm::Value &V);
  static Expected<ConstraintValue> concrete(const ConcreteCall &Call);
};
MIR_DECLARE_RECORDED_PREDICATE(HasOneUse)
MIR_DECLARE_RECORDED_PREDICATE(HasOneUser)

/// The intrinsic a call calls, and the predicate of a compare.
MIR_DECLARE_OPERATOR(Intrinsic)
MIR_DECLARE_OPERATOR(Predicate)
/// The width of a value's, or a type's, scalar type.
MIR_DECLARE_OPERATOR(BitWidth)

/// Records the facts of the predicates above for a value at a site.
void recordValuePredicates(const RecordCall &Call);

#undef MIR_DECLARE_RECORDED_PREDICATE
#undef MIR_DECLARE_OPERATOR

} // namespace metaphir
} // namespace llvm

#endif
