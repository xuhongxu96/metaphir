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

#include "metaphir/Exec/ExprEvaluator.h"
#include "metaphir/Exec/TypePattern.h"
#include "metaphir/IR/Sort.h"
#include "metaphir/Matching/Instantiation.h"
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
/// name, and where the pattern writes it.
struct SlotInfo {
  std::string Name;
  bool IsInstruction = false;
  /// For a meta variable, its sort.
  Sort VariableSort = Sort::Unknown;
  /// Where it is written in the pattern: for one inlined from a matcher,
  /// where the use is.
  SMLoc Written;
};

/// A plan compiled to steps (see PlanMatcher.cpp).
class PlanProgram {
public:
  /// Compiles Matcher, which must outlive the program: its constraints are
  /// evaluated from its expressions.
  static std::unique_ptr<PlanProgram> compile(mpir_plan::MatcherOp Matcher);
  ~PlanProgram();

  ArrayRef<SlotInfo> getSlots() const { return Slots; }

  struct Step;

private:
  friend class PlanMatcher;
  PlanProgram();

  std::vector<SlotInfo> Slots;
  std::vector<Step> Steps;
  /// The alternatives of each either: where each begins and ends.
  std::vector<std::pair<unsigned, unsigned>> Regions;
  TypePatterns Types;
  unsigned NumRegisters = 0;
};

/// A match: the bindings of a plan's slots.
class PlanMatch {
public:
  PlanMatch(const PlanProgram &Program,
            std::vector<Instantiation::Binding> Bindings)
      : Program(&Program), Bindings(std::move(Bindings)) {}

  const Instantiation::Binding *lookup(unsigned Slot) const {
    return std::holds_alternative<std::monostate>(Bindings[Slot].Data)
               ? nullptr
               : &Bindings[Slot];
  }

  /// As Instantiation::print: the named meta variables, sorted by name.
  void print(raw_ostream &OS, ModuleSlotTracker *Slots = nullptr) const;
  /// As Instantiation::printInstructions.
  void printInstructions(raw_ostream &OS, const SourceMgr &Source) const;
  /// As Instantiation::printLine.
  void printLine(raw_ostream &OS, StringRef Module, const llvm::Function &F,
                 ModuleSlotTracker *Slots,
                 const SourceMgr *Source = nullptr) const;

  bool operator==(const PlanMatch &Other) const;

private:
  const PlanProgram *Program;
  std::vector<Instantiation::Binding> Bindings;
};

/// A constraint that rejected a structural match.
struct PlanRejection {
  mlir::Value Expression;
  /// Where the constraint is written, which identifies it.
  SMRange Written;
  /// Why it could not be evaluated; empty if it was false.
  std::string Reason;
  /// The first structural match it rejected.
  PlanMatch Rejected;
};

/// A meta variable a relaxed match found bound to two targets.
struct PlanConflict {
  std::string Variable;
  Instantiation::Binding First;
  Instantiation::Binding Second;

  /// As Instantiation::printConflict.
  void print(raw_ostream &OS, ModuleSlotTracker *Slots = nullptr) const;
};

class PlanMatcher {
public:
  explicit PlanMatcher(const PlanProgram &Program);
  ~PlanMatcher();

  /// See ConstraintInterpreter::setUseOracle.
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
  ExprEvaluator Evaluator;
};

} // namespace metaphir
} // namespace llvm

#endif // METAPHIR_EXEC_PLANMATCHER_H
