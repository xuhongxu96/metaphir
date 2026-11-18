//===- Language.td - The pattern language's vocabulary ----------*- tablegen -*-===//
//
// Every table the backends of metaphir-tblgen read. A backend reads the
// records of the classes it needs, whichever table defines them, so each
// run is given this whole file.
//
//===----------------------------------------------------------------------===//

include "metaphir/IR/Sorts.td"
include "metaphir/IR/MetaFlags.td"
include "metaphir/IR/Constraint/ConstraintOperators.td"
include "metaphir/IR/Constraint/ConstraintCoercions.td"
include "metaphir/Matching/LLVMValueClasses.td"
include "metaphir/Matching/Operators/Facts.td"
include "metaphir/IR/Types.td"
include "metaphir/IR/Instruction/InstructionMatchers.td"
include "metaphir/IR/KeywordConstants.td"
include "metaphir/IR/PatternSettings.td"
include "metaphir/Parser/MIRKeywords.td"
include "metaphir/Parser/MIRTokenKinds.td"
