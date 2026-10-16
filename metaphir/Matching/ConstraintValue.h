#ifndef METAPHIR_MATCHING_CONSTRAINTVALUE_H
#define METAPHIR_MATCHING_CONSTRAINTVALUE_H

#include "metaphir/Matching/Instantiation.h"
#include "llvm/ADT/APSInt.h"
#include "llvm/Support/KnownBits.h"
#include <string>
#include <variant>

namespace llvm {
namespace metaphir {

/// The value of a constraint expression.
///
/// Integers are APSInts: they carry a width and a signedness and denote a
/// mathematical number.
///  - A literal is signed if negative, unsigned otherwise.
///  - An LLVM constant is read as signed at its type's width.
///  - A Nat binding (a count, width, index or alignment) is unsigned.
/// Arithmetic and comparisons widen their operands until both values fit
/// (see detail::widen), so no operation wraps unless an explicit bitwidth
/// argument asks for modular arithmetic at that width.
///  - The result of such an operator is a W-bit pattern, as an LLVM iW
///    value is (isModular). It is read as signed, but by the unsigned
///    comparisons, which read it as unsigned as 'icmp ult' does. 'eq'
///    compares the low bits of any two integers.
class ConstraintValue {
public:
  enum ValueKind {
    Integer,
    Boolean,
    String,
    Type,
    Value,
    TypeArray,
    ValueArray,
    StringArray,
    BitVector,
    NumValueKinds
  };

  using StringArrayStorage = SmallVector<std::string, 4>;

  ValueKind getKind() const;
  const APSInt &getInteger() const;
  /// Whether this integer is a bit pattern of its width (see above).
  bool isModular() const { return Modular; }
  bool getBoolean() const;
  StringRef getString() const;
  const llvm::Type *getType() const;
  const llvm::Value *getValue() const;
  const Instantiation::TypeArray &getTypeArray() const;
  const Instantiation::ValueArray &getValueArray() const;
  const StringArrayStorage &getStringArray() const;
  const llvm::KnownBits &getKnownBits() const;

  static ConstraintValue getInteger(APSInt Value);
  static ConstraintValue getModularInteger(APInt Bits);
  static ConstraintValue getBoolean(bool Value);
  static ConstraintValue getString(StringRef Value);
  static ConstraintValue getType(const llvm::Type *Value);
  static ConstraintValue getValue(const llvm::Value *Value);
  static ConstraintValue getTypeArray(Instantiation::TypeArray Value);
  static ConstraintValue getValueArray(Instantiation::ValueArray Value);
  static ConstraintValue getStringArray(StringArrayStorage Value);
  static ConstraintValue getKnownBits(llvm::KnownBits Value);

private:
  using Storage = std::variant<APSInt, bool, std::string, const llvm::Type *,
                               const llvm::Value *, Instantiation::TypeArray,
                               Instantiation::ValueArray, StringArrayStorage,
                               llvm::KnownBits>;

  Storage Data;
  bool Modular = false;

  explicit ConstraintValue(Storage Value) : Data(std::move(Value)) {}
};

} // namespace metaphir
} // namespace llvm

#endif // METAPHIR_MATCHING_CONSTRAINTVALUE_H
