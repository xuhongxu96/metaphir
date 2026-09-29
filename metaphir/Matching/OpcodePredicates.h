#ifndef METAPHIR_MATCHING_OPCODE_PREDICATES_H
#define METAPHIR_MATCHING_OPCODE_PREDICATES_H

#include "metaphir/IR/Instruction.h"

namespace llvm {
class Instruction;
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

} // namespace metaphir
} // namespace llvm

#endif
