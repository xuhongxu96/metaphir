//===- Binding.h - What a match binds a meta variable to --------*- C++ -*-===//
//
// The target a match binds a pattern's meta variable or instruction matcher
// to: an IR value or type, a predicate, an intrinsic, an integer, a flag, or
// an array of types or values.
//
//===----------------------------------------------------------------------===//

#ifndef METAPHIR_MATCHING_BINDING_H
#define METAPHIR_MATCHING_BINDING_H

#include "llvm/ADT/APSInt.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/IR/InstrTypes.h"
#include "llvm/IR/Intrinsics.h"
#include <variant>

namespace llvm {
class ModuleSlotTracker;
class raw_ostream;
class Type;
class Value;
namespace metaphir {

struct Binding {
  using TypeArray = SmallVector<const llvm::Type *, 4>;
  using ValueArray = SmallVector<const llvm::Value *, 4>;

  /// Integers keep their signedness: a Nat binding (a count, width, index
  /// or alignment) is unsigned; see ConstraintValue for how it is used.
  using Storage =
      std::variant<std::monostate, const llvm::Value *, const llvm::Type *,
                   CmpInst::Predicate, Intrinsic::ID, APSInt, bool, TypeArray,
                   ValueArray>;

  Storage Data;

  Binding() = default;
  Binding(const llvm::Value *Value) : Data(Value) {}
  Binding(const llvm::Type *Type) : Data(Type) {}
  Binding(CmpInst::Predicate Predicate) : Data(Predicate) {}
  Binding(Intrinsic::ID ID) : Data(ID) {}
  Binding(const APSInt &Integer) : Data(Integer) {}
  /// A natural number, i.e. an unsigned integer.
  Binding(const APInt &Natural) : Data(APSInt(Natural, /*isUnsigned=*/true)) {}
  Binding(bool Flag) : Data(Flag) {}
  Binding(TypeArray Types) : Data(std::move(Types)) {}
  Binding(ValueArray Values) : Data(std::move(Values)) {}

  bool operator==(const Binding &Other) const {
    if (const auto *Left = std::get_if<APSInt>(&Data))
      if (const auto *Right = std::get_if<APSInt>(&Other.Data))
        return APSInt::isSameValue(*Left, *Right);
    return Data == Other.Data;
  }
  bool operator!=(const Binding &Other) const { return !(*this == Other); }
};

/// Prints a binding as a match prints it. Slots, when given, numbers the
/// unnamed values; it must have incorporated their function. Without it,
/// each unnamed value numbers its whole function.
void printBinding(raw_ostream &OS, const Binding &B, ModuleSlotTracker *Slots);
raw_ostream &operator<<(raw_ostream &OS, const Binding &B);

} // namespace metaphir
} // namespace llvm

#endif // METAPHIR_MATCHING_BINDING_H
