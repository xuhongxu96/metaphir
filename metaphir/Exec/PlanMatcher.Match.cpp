//===- PlanMatcher.Match.cpp - Print the matches of match plans -----------===//
//===----------------------------------------------------------------------===//

#include "metaphir/Exec/PlanMatcher.h"

#include "metaphir/Dialect/Pattern/SourceLocation.h"
#include "llvm/ADT/StringSet.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/InstIterator.h"
#include "llvm/Support/raw_ostream.h"

namespace llvm {
namespace metaphir {

/// Whether a slot is a named meta variable, which a match reports.
static bool isReported(const SlotInfo &Slot) {
  return !Slot.IsInstruction && !Slot.Name.empty() &&
         !StringRef(Slot.Name).starts_with("_");
}

void PlanMatch::print(raw_ostream &OS, ModuleSlotTracker *Slots) const {
  SmallVector<std::pair<StringRef, const Binding *>, 8> Named;
  StringSet<> SeenNames;
  for (auto [Index, Slot] : enumerate(Program->getSlots()))
    if (isReported(Slot) && lookup(Index) && SeenNames.insert(Slot.Name).second)
      Named.emplace_back(Slot.Name, lookup(Index));
  llvm::sort(Named,
             [](const auto &L, const auto &R) { return L.first < R.first; });
  OS << '{';
  for (auto [Index, Each] : enumerate(Named)) {
    if (Index)
      OS << ", ";
    OS << '?' << Each.first << " = ";
    printBinding(OS, *Each.second, Slots);
  }
  OS << '}';
}

void PlanMatch::printInstructions(raw_ostream &OS,
                                  const SourceMgr &Source) const {
  struct Matched {
    std::optional<unsigned> Line;
    std::string Name;
    const llvm::Instruction *Target;
  };
  SmallVector<Matched, 8> All;
  for (auto [Index, Slot] : enumerate(Program->getSlots())) {
    if (!Slot.IsInstruction)
      continue;
    const Binding *B = lookup(Index);
    const auto *const *Value =
        B ? std::get_if<const llvm::Value *>(&B->Data) : nullptr;
    const auto *Target = Value ? dyn_cast<llvm::Instruction>(*Value) : nullptr;
    if (!Target)
      continue;
    // An unnamed matcher is named by its opcode: that of the instruction it
    // matched.
    std::string Name = Slot.Name.empty() ? Target->getOpcodeName() : Slot.Name;
    All.push_back({getMainFileLine(Source, Slot.Loc), Name, Target});
  }
  if (All.empty()) {
    OS << "{}";
    return;
  }
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

void PlanMatch::printLine(raw_ostream &OS, StringRef Module,
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

bool PlanMatch::operator==(const PlanMatch &Other) const {
  return Bindings == Other.Bindings;
}

void PlanConflict::print(raw_ostream &OS, ModuleSlotTracker *Slots) const {
  OS << '?' << Variable << " would be both ";
  printBinding(OS, First, Slots);
  OS << " and ";
  printBinding(OS, Second, Slots);
}

} // namespace metaphir
} // namespace llvm
