#ifndef METAPHIR_MATCHING_OPCODE_PREDICATES_H
#define METAPHIR_MATCHING_OPCODE_PREDICATES_H

#include "metaphir/IR/Instruction.h"
#include "llvm/ADT/SmallVector.h"

namespace llvm {
class Instruction;
class Value;
namespace metaphir {

/// Whether the built-in instruction matcher ID accepts Target's kind of
/// instruction. This is the only opcode check the matcher makes, so summaries
/// of functions by instruction matcher must use it (and hasSemanticFlag) too.
bool matchesInstructionID(Instruction::InstructionID ID,
                          const llvm::Instruction &Target);

/// Whether Target carries the flag; a flag it cannot carry is absent. The
/// matcher requires the flags a pattern names without a capture and, for the
/// flags its instruction matcher supports, the absence of the others.
bool hasSemanticFlag(InstructionFlag::FlagID ID,
                     const llvm::Instruction &Target);

/// Sets Operands to the values a pattern instruction's operands are matched
/// against, in order: those of operands() mostly, but a call's callee comes
/// first, a phi's incoming values alternate with their blocks, and
/// extractvalue and insertvalue add their indices as i64 constants.
void collectMatcherOperands(const llvm::Instruction &Target,
                            SmallVectorImpl<const llvm::Value *> &Operands);

} // namespace metaphir
} // namespace llvm

#endif
