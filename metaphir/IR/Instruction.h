#ifndef METAPHIR_IR_INSTRUCTION_H
#define METAPHIR_IR_INSTRUCTION_H

#include "metaphir/IR/Instruction.inc"
#include <cassert>

namespace llvm {
namespace metaphir {

/// The semantic flags an instruction matcher can name. Their data is
/// generated from Flags.td (Instruction.inc); this reads it.
namespace instruction_flag {

inline StringRef getName(FlagID ID) {
  assert(ID < NumFlagIDs && "invalid semantic flag ID");
  return FlagNames[ID];
}

} // namespace instruction_flag

/// The built-in instruction matchers and their properties, generated from
/// InstructionMatchers.td (Instruction.inc).
namespace instruction {

inline const InstructionInfo &getInfo(InstructionID ID) {
  assert(ID < NumInstructionIDs && "invalid instruction kind");
  return Infos[ID];
}

inline StringRef getOpcodeName(InstructionID ID) { return getInfo(ID).Name; }

inline FlagMask getSupportedFlags(InstructionID ID) {
  return getInfo(ID).SupportedFlags;
}

inline bool isCommutative(InstructionID ID) { return getInfo(ID).Commutative; }

inline OperandSyntax getOperandSyntax(InstructionID ID) {
  return getInfo(ID).Syntax;
}

/// For the Nary syntax, the number of operands.
inline unsigned getOperandArity(InstructionID ID) { return getInfo(ID).Arity; }

} // namespace instruction

} // namespace metaphir
} // namespace llvm

#endif
