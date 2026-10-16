#include "metaphir/Matching/Instantiation.h"
#include "metaphir/IR/Instruction.h"
#include "metaphir/IR/MetaVariable.h"
#include "metaphir/IR/Pattern.h"
#include "metaphir/IR/SourceRange.h"
#include "llvm/ADT/STLExtras.h"
#include "llvm/ADT/StringSet.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/InstIterator.h"
#include "llvm/IR/Instruction.h"
#include "llvm/IR/IntrinsicInst.h"
#include "llvm/IR/ModuleSlotTracker.h"
#include "llvm/Support/ErrorHandling.h"
#include "llvm/Support/raw_ostream.h"
#include <tuple>
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

void Instantiation::printInstructions(raw_ostream &OS,
                                      const SourceMgr &Source) const {
  struct Matched {
    std::optional<unsigned> Line;
    std::string Name;
    const llvm::Instruction *Target;
  };
  SmallVector<Matched, 8> All;
  for (const auto &[Matcher, Binding] : Bindings) {
    const auto *PatternInstruction = dyn_cast<metaphir::Instruction>(Matcher);
    if (!PatternInstruction)
      continue;
    const auto *const *Value = std::get_if<const llvm::Value *>(&Binding.Data);
    const auto *Target = Value ? dyn_cast<llvm::Instruction>(*Value) : nullptr;
    if (!Target)
      continue;
    // An instruction expanded from a composite has the line of the
    // instruction, written in the pattern, that used it.
    const metaphir::Instruction *Written = PatternInstruction;
    while (Written->getExpandedFrom())
      Written = Written->getExpandedFrom();
    std::optional<unsigned> Line =
        getMainFileLine(Source, Written->getSourceRange().Begin);
    StringRef Result = PatternInstruction->getResultName();
    All.push_back({Line,
                   Result.empty() ? PatternInstruction->getOpcodeName().str()
                                  : ("%" + Result).str(),
                   Target});
  }
  if (All.empty()) {
    OS << "{}";
    return;
  }
  // Positions among the function's instructions, in order.
  DenseMap<const llvm::Instruction *, unsigned> Positions;
  for (const llvm::Instruction &I :
       instructions(*All.front().Target->getFunction()))
    Positions[&I] = Positions.size();
  llvm::sort(All, [&](const Matched &L, const Matched &R) {
    return std::make_tuple(L.Line.value_or(~0u), L.Name, Positions[L.Target]) <
           std::make_tuple(R.Line.value_or(~0u), R.Name, Positions[R.Target]);
  });
  OS << '{';
  for (auto [Index, Each] : enumerate(All)) {
    if (Index)
      OS << ", ";
    OS << Each.Name;
    if (Each.Line)
      OS << '@' << *Each.Line;
    OS << " = #" << Positions[Each.Target];
  }
  OS << '}';
}

bool Instantiation::recordConflict(const metaphir::Value &Matcher,
                                   const Binding &First,
                                   const Binding &Second) {
  // Only meta variables: an instruction matched twice is no conflict.
  const auto *Variable = dyn_cast<MetaVariable>(&Matcher);
  if (!Variable)
    return false;
  if (none_of(Conflicts, [&](const Conflict &C) {
        return C.Variable == Variable && C.First == First && C.Second == Second;
      }))
    Conflicts.push_back({Variable, First, Second});
  return true;
}

void Instantiation::printConflict(raw_ostream &OS, const Conflict &C,
                                  ModuleSlotTracker *Slots) {
  OS << '?' << C.Variable->getName() << " would be both ";
  printBinding(OS, C.First, Slots);
  OS << " and ";
  printBinding(OS, C.Second, Slots);
}

void Instantiation::printLine(raw_ostream &OS, StringRef Module,
                              const llvm::Function &F, ModuleSlotTracker *Slots,
                              const SourceMgr *Source) const {
  OS << Module << "\t@" << F.getName() << '\t';
  print(OS, Slots);
  if (Source) {
    OS << '\t';
    printInstructions(OS, *Source);
  }
  OS << '\n';
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
