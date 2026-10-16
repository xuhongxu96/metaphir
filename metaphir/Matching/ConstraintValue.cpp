#include "metaphir/Matching/ConstraintValue.h"
#include "metaphir/Matching/Instantiation.h"
#include <type_traits>

namespace llvm {
namespace metaphir {

ConstraintValue::ValueKind ConstraintValue::getKind() const {
  return std::visit(
      [](const auto &Alt) -> ValueKind {
        using T = std::decay_t<decltype(Alt)>;
        if constexpr (std::is_same_v<T, APSInt>)
          return Integer;
        else if constexpr (std::is_same_v<T, bool>)
          return Boolean;
        else if constexpr (std::is_same_v<T, std::string>)
          return String;
        else if constexpr (std::is_same_v<T, const llvm::Type *>)
          return Type;
        else if constexpr (std::is_same_v<T, const llvm::Value *>)
          return Value;
        else if constexpr (std::is_same_v<T, Instantiation::TypeArray>)
          return TypeArray;
        else if constexpr (std::is_same_v<T, Instantiation::ValueArray>)
          return ValueArray;
        else if constexpr (std::is_same_v<T, llvm::KnownBits>)
          return BitVector;
        else {
          static_assert(std::is_same_v<T, StringArrayStorage>);
          return StringArray;
        }
      },
      Data);
}

const APSInt &ConstraintValue::getInteger() const {
  return std::get<APSInt>(Data);
}

bool ConstraintValue::getBoolean() const { return std::get<bool>(Data); }

StringRef ConstraintValue::getString() const {
  return std::get<std::string>(Data);
}

const llvm::Type *ConstraintValue::getType() const {
  return std::get<const llvm::Type *>(Data);
}

const llvm::Value *ConstraintValue::getValue() const {
  return std::get<const llvm::Value *>(Data);
}

const Instantiation::TypeArray &ConstraintValue::getTypeArray() const {
  return std::get<Instantiation::TypeArray>(Data);
}

const Instantiation::ValueArray &ConstraintValue::getValueArray() const {
  return std::get<Instantiation::ValueArray>(Data);
}

const ConstraintValue::StringArrayStorage &
ConstraintValue::getStringArray() const {
  return std::get<StringArrayStorage>(Data);
}

const llvm::KnownBits &ConstraintValue::getKnownBits() const {
  return std::get<llvm::KnownBits>(Data);
}

ConstraintValue ConstraintValue::getInteger(APSInt Value) {
  return ConstraintValue(std::move(Value));
}

ConstraintValue ConstraintValue::getModularInteger(APInt Bits) {
  ConstraintValue Result(APSInt(std::move(Bits), /*isUnsigned=*/false));
  Result.Modular = true;
  return Result;
}

ConstraintValue ConstraintValue::getBoolean(bool Value) {
  return ConstraintValue(Value);
}

ConstraintValue ConstraintValue::getString(StringRef Value) {
  return ConstraintValue(Value.str());
}

ConstraintValue ConstraintValue::getType(const llvm::Type *Value) {
  return ConstraintValue(Value);
}

ConstraintValue ConstraintValue::getValue(const llvm::Value *Value) {
  return ConstraintValue(Value);
}

ConstraintValue ConstraintValue::getTypeArray(Instantiation::TypeArray Value) {
  return ConstraintValue(std::move(Value));
}

ConstraintValue
ConstraintValue::getValueArray(Instantiation::ValueArray Value) {
  return ConstraintValue(std::move(Value));
}

ConstraintValue ConstraintValue::getStringArray(StringArrayStorage Value) {
  return ConstraintValue(std::move(Value));
}

ConstraintValue ConstraintValue::getKnownBits(llvm::KnownBits Value) {
  return ConstraintValue(std::move(Value));
}

} // namespace metaphir
} // namespace llvm
