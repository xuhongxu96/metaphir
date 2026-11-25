//===- PlanProgram.h - Match plans compiled to steps ------------*- C++ -*-===//
//
// A match plan (an mpir_plan.matcher) compiled to a flat program of steps,
// for PlanMatcher to run.
//
//===----------------------------------------------------------------------===//

#ifndef METAPHIR_EXEC_PLANPROGRAM_H
#define METAPHIR_EXEC_PLANPROGRAM_H

#include "metaphir/Exec/PlanStep.h"
#include "metaphir/IR/Sort.h"
#include "llvm/ADT/ArrayRef.h"
#include "llvm/Support/SMLoc.h"
#include <memory>
#include <string>
#include <vector>

namespace llvm {
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

/// A plan compiled to steps (see PlanProgram.cpp).
class PlanProgram {
public:
  /// Compiles Matcher, which must outlive the program: its constraints are
  /// evaluated from its expressions.
  static std::unique_ptr<PlanProgram> compile(mpir_plan::MatcherOp Matcher);

  using Step = plan_step::Step;

  ArrayRef<SlotInfo> getSlots() const { return Slots; }
  ArrayRef<Step> getSteps() const { return Steps; }
  /// How many registers the steps read and write.
  unsigned getNumRegisters() const { return NumRegisters; }

private:
  /// Fills a program in from a plan (see PlanProgram.cpp).
  class Builder;
  PlanProgram() = default;

  std::vector<SlotInfo> Slots;
  std::vector<Step> Steps;
  unsigned NumRegisters = 0;
};

} // namespace metaphir
} // namespace llvm

#endif // METAPHIR_EXEC_PLANPROGRAM_H
