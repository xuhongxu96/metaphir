//===- PlanMatcher.h - Run match plans on LLVM IR ---------------*- C++ -*-===//
//
// A match plan (an mpir_plan.matcher) compiled to a flat program, and the
// interpreter that runs it on a function: it follows each path of the plan,
// backtracking at its choices, and keeps the paths that reach emit and
// satisfy the plan's constraints.
//
//===----------------------------------------------------------------------===//

#ifndef METAPHIR_EXEC_PLANMATCHER_H
#define METAPHIR_EXEC_PLANMATCHER_H

#include "metaphir/Exec/ConcreteEvaluator.h"
#include "metaphir/Exec/PlanStep.h"
#include "metaphir/IR/Sort.h"
#include "metaphir/Matching/Binding.h"
#include "mlir/IR/Location.h"
#include "mlir/IR/Value.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/ADT/StringRef.h"
#include "llvm/Support/SMLoc.h"
#include <memory>
#include <string>
#include <vector>

namespace mlir {
class Operation;
} // namespace mlir

namespace llvm {
class Function;
class ModuleSlotTracker;
class SourceMgr;
namespace metaphir {

namespace mpir_plan {
class MatcherOp;
} // namespace mpir_plan

/// What a slot of a plan is: a meta variable or an instruction matcher, its
/// name, and its location.
struct SlotInfo {
  std::string Name;
  bool IsInstruction = false;
  /// For a meta variable, its sort.
  Sort VariableSort = Sort::Unknown;
  /// The start of the slot in the pattern. A slot from an inlined matcher
  /// body is located at the outermost use of the matcher, so the slots of
  /// different uses get different locations.
  SMLoc Loc;
};

/// A plan compiled to steps (see PlanMatcher.Program.cpp).
class PlanProgram {
public:
  /// Compiles Matcher, which must outlive the program: its constraints are
  /// evaluated from its expressions.
  static std::unique_ptr<PlanProgram> compile(mpir_plan::MatcherOp Matcher);

  ArrayRef<SlotInfo> getSlots() const { return Slots; }

  using Step = plan_step::Step;

private:
  friend class PlanMatcher;
  /// Fills a program in from a plan (see PlanMatcher.Program.cpp).
  class Builder;
  PlanProgram() = default;

  std::vector<SlotInfo> Slots;
  std::vector<Step> Steps;
  unsigned NumRegisters = 0;
};

/// A match: the bindings of a plan's slots.
class PlanMatch {
public:
  PlanMatch(const PlanProgram &Program, std::vector<Binding> Bindings)
      : Program(&Program), Bindings(std::move(Bindings)) {}

  const Binding *lookup(unsigned Slot) const {
    return std::holds_alternative<std::monostate>(Bindings[Slot].Data)
               ? nullptr
               : &Bindings[Slot];
  }

  /// Prints the named meta variables' bindings, sorted by name; Slots as
  /// for printBinding.
  void print(raw_ostream &OS, ModuleSlotTracker *Slots = nullptr) const;
  /// Prints the IR instructions the pattern's instructions matched, as
  /// "{%name@line = #position, ...}": each pattern instruction by its result
  /// name (or opcode) and, if it is in the main file of Source (the
  /// pattern's), its line there -- for one inlined from a matcher, that of
  /// the use of the matcher; the IR instruction by its position among its
  /// function's instructions. An or-self matcher stands for the instruction
  /// it matched in its place; one that matched another kind of value is
  /// left out.
  void printInstructions(raw_ostream &OS, const SourceMgr &Source) const;
  /// Prints the match as metaphir-match --matches-only does: Module,
  /// @function and bindings, and with Source the instructions it matched,
  /// separated by tabs, on a line.
  void printLine(raw_ostream &OS, StringRef Module, const llvm::Function &F,
                 ModuleSlotTracker *Slots,
                 const SourceMgr *Source = nullptr) const;

  bool operator==(const PlanMatch &Other) const;

private:
  const PlanProgram *Program;
  std::vector<Binding> Bindings;
};

/// A constraint that rejected a structural match.
struct PlanRejection {
  mlir::Value Expression;
  /// The constraint's source range, which identifies it.
  SMRange Range;
  /// Why it could not be evaluated; empty if it was false.
  std::string Reason;
  /// The first structural match it rejected.
  PlanMatch Rejected;
};

/// A meta variable a relaxed match found bound to two targets.
struct PlanConflict {
  std::string Variable;
  Binding First;
  Binding Second;

  /// Prints the conflict as "?x would be both %a and %b"; Slots as for
  /// printBinding.
  void print(raw_ostream &OS, ModuleSlotTracker *Slots = nullptr) const;
};

class PlanMatcher {
public:
  explicit PlanMatcher(const PlanProgram &Program);
  ~PlanMatcher();

  /// See ConcreteEvaluator::setUseOracle.
  void setUseOracle(UseOracle *Oracle) { Evaluator.setUseOracle(Oracle); }

  /// The matches of the plan in F, each once. If there are none, the
  /// constraints that rejected structural matches are added to Unsatisfied;
  /// HadStructuralMatch tells whether there were any.
  std::vector<PlanMatch>
  match(const llvm::Function &F,
        SmallVectorImpl<PlanRejection> *Unsatisfied = nullptr,
        bool *HadStructuralMatch = nullptr);

  /// For a function without a structural match: the meta variables a match
  /// would bind to two different targets each, as one found by letting them;
  /// none if even that finds none.
  SmallVector<PlanConflict, 1> findConflicts(const llvm::Function &F);

private:
  class Run;
  const PlanProgram &Program;
  ConcreteEvaluator Evaluator;
};

} // namespace metaphir
} // namespace llvm

#endif // METAPHIR_EXEC_PLANMATCHER_H
