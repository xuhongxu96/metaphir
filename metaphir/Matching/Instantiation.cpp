#include "metaphir/Matching/Instantiation.h"
#include "metaphir/IR/MetaVariable.h"
#include "metaphir/IR/Pattern.h"
#include "llvm/ADT/STLExtras.h"
#include "llvm/ADT/StringSet.h"
#include "llvm/IR/IntrinsicInst.h"
#include "llvm/IR/ModuleSlotTracker.h"
#include "llvm/Support/ErrorHandling.h"
#include "llvm/Support/raw_ostream.h"
#include <type_traits>

namespace llvm {
namespace metaphir {

void Instantiation::requireComplete(const Pattern &Pattern) const {
  for (const MetaVariable *Variable : Pattern.getMetaVariables()) {
    if (Variable->getName().empty() || Variable->getName().starts_with("_"))
      continue;
    if (!lookup(*Variable))
      report_fatal_error(Twine("successful match did not instantiate meta ") +
                         "variable '?" + Variable->getName() + "'");
  }
}

bool Instantiation::operator==(const Instantiation &Other) const {
  if (Bindings.size() != Other.Bindings.size())
    return false;
  for (const auto &[Matcher, Binding] : Bindings) {
    auto It = Other.Bindings.find(Matcher);
    if (It == Other.Bindings.end() || It->second != Binding)
      return false;
  }
  return true;
}

void appendUnique(MatchResults &Into, MatchResults &&From) {
  size_t Existing = Into.size();
  for (Instantiation &Candidate : From)
    if (llvm::none_of(ArrayRef(Into).take_front(Existing),
                      [&](const Instantiation &I) { return I == Candidate; }))
      Into.push_back(std::move(Candidate));
}

static void printBinding(raw_ostream &OS, const Instantiation::Binding &Binding,
                         ModuleSlotTracker *Slots) {
  auto PrintValue = [&](const llvm::Value &Value) {
    if (Slots)
      Value.printAsOperand(OS, false, *Slots);
    else
      Value.printAsOperand(OS, false);
  };
  std::visit(
      [&](const auto &Value) {
        using T = std::decay_t<decltype(Value)>;
        if constexpr (std::is_same_v<T, std::monostate>) {
          llvm_unreachable("cannot print an empty instantiation binding");
        } else if constexpr (std::is_same_v<T, const llvm::Value *>) {
          PrintValue(*Value);
        } else if constexpr (std::is_same_v<T, const llvm::Type *>) {
          Value->print(OS, false, true);
        } else if constexpr (std::is_same_v<T, CmpInst::Predicate>) {
          OS << CmpInst::getPredicateName(Value);
        } else if constexpr (std::is_same_v<T, Intrinsic::ID>) {
          OS << Intrinsic::getBaseName(Value);
        } else if constexpr (std::is_same_v<T, APSInt>) {
          Value.print(OS, Value.isSigned());
        } else if constexpr (std::is_same_v<T, bool>) {
          OS << (Value ? "true" : "false");
        } else {
          OS << '[';
          for (unsigned Index = 0; Index != Value.size(); ++Index) {
            if (Index)
              OS << ", ";
            if constexpr (std::is_same_v<T, Instantiation::TypeArray>)
              Value[Index]->print(OS, false, true);
            else if (Value[Index]->hasName())
              OS << '%' << Value[Index]->getName();
            else
              PrintValue(*Value[Index]);
          }
          OS << ']';
        }
      },
      Binding.Data);
}

raw_ostream &operator<<(raw_ostream &OS,
                        const Instantiation::Binding &Binding) {
  printBinding(OS, Binding, nullptr);
  return OS;
}

void Instantiation::print(raw_ostream &OS, ModuleSlotTracker *Slots) const {
  SmallVector<std::pair<StringRef, const Binding *>, 8> Named;
  StringSet<> SeenNames;
  for (const auto &[Matcher, Binding] : Bindings)
    if (const auto *Variable = dyn_cast<MetaVariable>(Matcher))
      if (!Variable->getName().empty() && !Variable->getName().starts_with("_"))
        if (SeenNames.insert(Variable->getName()).second)
          Named.emplace_back(Variable->getName(), &Binding);
  llvm::sort(Named, [](const auto &Left, const auto &Right) {
    return Left.first < Right.first;
  });

  OS << '{';
  for (unsigned Index = 0; Index != Named.size(); ++Index) {
    if (Index)
      OS << ", ";
    OS << '?' << Named[Index].first << " = ";
    printBinding(OS, *Named[Index].second, Slots);
  }
  OS << '}';
}

raw_ostream &operator<<(raw_ostream &OS, const Instantiation &Instantiation) {
  Instantiation.print(OS);
  return OS;
}

} // namespace metaphir
} // namespace llvm
