#ifndef METAPHIR_MATCHING_CONSTRAINTINTERPRETER_H
#define METAPHIR_MATCHING_CONSTRAINTINTERPRETER_H

#include "metaphir/Matching/Instantiation.h"
#include "llvm/ADT/APSInt.h"
#include "llvm/Support/Error.h"
#include <string>
#include <variant>

namespace llvm {
namespace metaphir {

class Constraint;
class Instantiation;

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
    StringArray
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

  static ConstraintValue getInteger(APSInt Value);
  static ConstraintValue getBoolean(bool Value);
  static ConstraintValue getString(StringRef Value);
  static ConstraintValue getType(const llvm::Type *Value);
  static ConstraintValue getValue(const llvm::Value *Value);
  static ConstraintValue getTypeArray(Instantiation::TypeArray Value);
  static ConstraintValue getValueArray(Instantiation::ValueArray Value);
  static ConstraintValue getStringArray(StringArrayStorage Value);

private:
  using Storage = std::variant<APSInt, bool, std::string, const llvm::Type *,
                               const llvm::Value *, Instantiation::TypeArray,
                               Instantiation::ValueArray, StringArrayStorage>;

  Storage Data;

  explicit ConstraintValue(Storage Value) : Data(std::move(Value)) {}
};

class ConstraintInterpreter {
public:
  Expected<ConstraintValue> evaluate(const Constraint &Expression,
                                     const Instantiation &State) const;
};

} // namespace metaphir
} // namespace llvm

#endif
