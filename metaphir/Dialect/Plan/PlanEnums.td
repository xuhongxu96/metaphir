//===- PlanEnums.td - The enumerations of the mpir_plan dialect -*- tablegen -*-===//
//
// Kept apart from PlanOps.td, which includes the mpir dialect's definitions:
// the enumeration backends emit every enumeration a file includes.
//
//===----------------------------------------------------------------------===//

#ifndef METAPHIR_DIALECT_PLAN_PLANENUMS_TD
#define METAPHIR_DIALECT_PLAN_PLANENUMS_TD

include "mlir/IR/EnumAttr.td"

// What a slot of a plan stands for.
def Plan_SlotKind : I32Enum<"SlotKind", "what a plan slot stands for", [
  I32EnumAttrCase<"Variable", 0, "variable">,
  I32EnumAttrCase<"Instruction", 1, "instruction">,
]> {
  let cppNamespace = "::llvm::metaphir::mpir_plan";
}

#endif // METAPHIR_DIALECT_PLAN_PLANENUMS_TD
