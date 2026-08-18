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
    using Storage =
        std::variant<std::monostate, const llvm::Value *, const llvm::Type *,
                     CmpInst::Predicate, Intrinsic::ID, APInt, bool, TypeArray,
                     ValueArray>;

    Storage Data;

    Binding() = default;
    Binding(const llvm::Value *Value) : Data(Value) {}
    Binding(const llvm::Type *Type) : Data(Type) {}
    Binding(CmpInst::Predicate Predicate) : Data(Predicate) {}
    Binding(Intrinsic::ID ID) : Data(ID) {}
    Binding(const APInt &Integer) : Data(Integer) {}
    Binding(bool Flag) : Data(Flag) {}
    Binding(TypeArray Types) : Data(std::move(Types)) {}
    Binding(ValueArray Values) : Data(std::move(Values)) {}

    bool operator==(const Binding &Other) const {
      if (const auto *Left = std::get_if<APInt>(&Data))
        if (const auto *Right = std::get_if<APInt>(&Other.Data))
          return APSInt::isSameValue(APSInt(*Left, true), APSInt(*Right, true));
      return Data == Other.Data;
    }
    bool operator!=(const Binding &Other) const { return !(*this == Other); }
  };

  const Binding *lookup(const metaphir::Value &Matcher) const {
    auto It = Bindings.find(&Matcher);
    return It == Bindings.end() ? nullptr : &It->second;
  }

  void bind(const metaphir::Value &Matcher, Binding Target) {
    Bindings[&Matcher] = std::move(Target);
  }

  void requireComplete(const Pattern &Pattern) const;

private:
  DenseMap<const metaphir::Value *, Binding> Bindings;

  friend raw_ostream &operator<<(raw_ostream &OS,
                                 const Instantiation &Instantiation);
};

raw_ostream &operator<<(raw_ostream &OS, const Instantiation::Binding &Binding);
raw_ostream &operator<<(raw_ostream &OS, const Instantiation &Instantiation);

} // namespace metaphir
} // namespace llvm

#endif
