#ifndef METAPHIR_MATCHING_OPCODE_PREDICATES_H
#define METAPHIR_MATCHING_OPCODE_PREDICATES_H

#include "metaphir/IR/Instruction.h"

namespace llvm {
class Instruction;
namespace metaphir {

/// Whether the built-in instruction matcher ID accepts Target's kind of
/// instruction. This is the only opcode check the matcher makes, so summaries
/// of functions by instruction matcher must use it too.
bool matchesInstructionID(Instruction::InstructionID ID,
                          const llvm::Instruction &Target);

} // namespace metaphir
} // namespace llvm

#endif
