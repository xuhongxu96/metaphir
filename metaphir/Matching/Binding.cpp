#include "metaphir/Matching/Binding.h"
#include "llvm/IR/ModuleSlotTracker.h"
#include "llvm/IR/Type.h"
#include "llvm/IR/Value.h"
#include "llvm/Support/ErrorHandling.h"
#include "llvm/Support/raw_ostream.h"
#include <type_traits>

namespace llvm {
namespace metaphir {

void printBinding(raw_ostream &OS, const Binding &B, ModuleSlotTracker *Slots) {
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
          llvm_unreachable("cannot print an empty binding");
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
            if constexpr (std::is_same_v<T, Binding::TypeArray>)
              Value[Index]->print(OS, false, true);
            else if (Value[Index]->hasName())
              OS << '%' << Value[Index]->getName();
            else
              PrintValue(*Value[Index]);
          }
          OS << ']';
        }
      },
      B.Data);
}

raw_ostream &operator<<(raw_ostream &OS, const Binding &B) {
  printBinding(OS, B, nullptr);
  return OS;
}

} // namespace metaphir
} // namespace llvm
