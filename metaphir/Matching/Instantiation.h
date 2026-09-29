#ifndef METAPHIR_MATCHING_INSTANTIATION_H
#define METAPHIR_MATCHING_INSTANTIATION_H

#include "llvm/ADT/APSInt.h"
#include "llvm/ADT/DenseMap.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/IR/InstrTypes.h"
#include "llvm/IR/Intrinsics.h"
#include <utility>
#include <variant>

namespace llvm {
class ModuleSlotTracker;
class raw_ostream;
class Type;
class Value;
namespace metaphir {

class Pattern;
class Value;

class Instantiation {
public:
  using TypeArray = SmallVector<const llvm::Type *, 4>;
  using ValueArray = SmallVector<const llvm::Value *, 4>;

  struct Binding {
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
    Binding(const APInt &Natural)
        : Data(APSInt(Natural, /*isUnsigned=*/true)) {}
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

  const Binding *lookup(const metaphir::Value &Matcher) const {
    auto It = Bindings.find(&Matcher);
    return It == Bindings.end() ? nullptr : &It->second;
  }

  /// Binds Matcher to Target, replacing any binding it has.
  void bind(const metaphir::Value &Matcher, Binding Target) {
    Bindings[&Matcher] = std::move(Target);
  }

  /// Binds Matcher to Target if it is unbound; otherwise returns whether its
  /// binding equals Target.
  bool unify(const metaphir::Value &Matcher, Binding Target) {
    auto [It, Inserted] = Bindings.try_emplace(&Matcher, std::move(Target));
    return Inserted || It->second == Target;
  }

  void requireComplete(const Pattern &Pattern) const;

  /// Prints the named meta variables' bindings, sorted by name. Slots, when
  /// given, numbers the unnamed values; it must have incorporated their
  /// function. Without it, each unnamed value numbers its whole function.
  void print(raw_ostream &OS, ModuleSlotTracker *Slots = nullptr) const;

  /// Whether both bind the same matchers to the same targets.
  bool operator==(const Instantiation &Other) const;
  bool operator!=(const Instantiation &Other) const {
    return !(*this == Other);
  }

private:
  DenseMap<const metaphir::Value *, Binding> Bindings;
};

using MatchResults = SmallVector<Instantiation, 4>;

/// The result list holding just State.
inline MatchResults singleResult(Instantiation State) {
  MatchResults Results;
  Results.push_back(std::move(State));
  return Results;
}

/// Appends the results in From that Into does not already contain.
void appendUnique(MatchResults &Into, MatchResults &&From);

raw_ostream &operator<<(raw_ostream &OS, const Instantiation::Binding &Binding);
raw_ostream &operator<<(raw_ostream &OS, const Instantiation &Instantiation);

} // namespace metaphir
} // namespace llvm

#endif
