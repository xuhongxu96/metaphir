#ifndef METAPHIR_MATCHING_CONSTRAINTVALUE_H
#define METAPHIR_MATCHING_CONSTRAINTVALUE_H

#include "metaphir/Matching/Instantiation.h"
#include "llvm/ADT/APSInt.h"
#include "llvm/Support/KnownBits.h"
#include <string>
#include <variant>

namespace llvm {
namespace metaphir {

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
  bool getBoolean() const;
  StringRef getString() const;
  const llvm::Type *getType() const;
  const llvm::Value *getValue() const;
  const Instantiation::TypeArray &getTypeArray() const;
  const Instantiation::ValueArray &getValueArray() const;
  const StringArrayStorage &getStringArray() const;
  const llvm::KnownBits &getKnownBits() const;

  static ConstraintValue getInteger(APSInt Value);
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

  explicit ConstraintValue(Storage Value) : Data(std::move(Value)) {}
};

} // namespace metaphir
} // namespace llvm

#endif // METAPHIR_MATCHING_CONSTRAINTVALUE_H
