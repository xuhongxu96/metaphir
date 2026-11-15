#ifndef METAPHIR_IR_INSTRUCTION_H
#define METAPHIR_IR_INSTRUCTION_H

#include "llvm/ADT/StringRef.h"
#include <cstdint>

namespace llvm {
namespace metaphir {

/// The semantic flags an instruction matcher can name ('nsw', 'nnan', ...),
/// from Flags.def.
namespace instruction_flag {
enum FlagID {
#define MIR_FLAG_TOKEN_KIND(Name) F_##Name,
#include "metaphir/IR/Flags.def"
  NumFlagIDs,
};

StringRef getName(FlagID ID);
} // namespace instruction_flag

/// The built-in instruction matchers, from InstructionMatchers.def, and
/// their properties.
namespace instruction {
enum InstructionID {
#define MIR_INSTRUCTION_MATCHER_ID(Name) I_##Name,
#include "metaphir/IR/InstructionMatchers.def"
  NumInstructionIDs,
};

using FlagMask = uint64_t;

// How the parser spells this instruction's operands. Shared grammars are
// dispatched by the parser from the .def (see getOperandSyntax); Custom
// instructions have bespoke per-ID parse code. Nary spells a fixed number of
// individually typed operands; the number comes from getOperandArity (or the
// composite matcher's parameter list).
enum class OperandSyntax { Nary, Binary, Cast, Custom };

constexpr FlagMask NoFlags = 0;

constexpr FlagMask FastMathFlags = 0
#define MIR_FLAG(Name)
#define MIR_FAST_MATH_FLAG(Name) | (FlagMask(1) << instruction_flag::F_##Name)
#include "metaphir/IR/Flags.def"
    ;

constexpr FlagMask NSWNUWFlags = (FlagMask(1) << instruction_flag::F_nsw) |
                                 (FlagMask(1) << instruction_flag::F_nuw);

constexpr FlagMask ExactFlag = FlagMask(1) << instruction_flag::F_exact;
constexpr FlagMask DisjointFlag = FlagMask(1) << instruction_flag::F_disjoint;
constexpr FlagMask InAllocaFlag = FlagMask(1) << instruction_flag::F_inalloca;
constexpr FlagMask VolatileFlag = FlagMask(1) << instruction_flag::F_volatile;

constexpr FlagMask GEPFlags = (FlagMask(1) << instruction_flag::F_inbounds) |
                              (FlagMask(1) << instruction_flag::F_nusw) |
                              (FlagMask(1) << instruction_flag::F_nuw);

constexpr FlagMask NNegFlag = FlagMask(1) << instruction_flag::F_nneg;
constexpr FlagMask SameSignFlag = FlagMask(1) << instruction_flag::F_samesign;

constexpr FlagMask FastMathNNegFlags = FastMathFlags | NNegFlag;

constexpr FlagMask mask(instruction_flag::FlagID ID) {
  return FlagMask(1) << ID;
}

StringRef getOpcodeName(InstructionID ID);
FlagMask getSupportedFlags(InstructionID ID);
bool isCommutative(InstructionID ID);
OperandSyntax getOperandSyntax(InstructionID ID);
/// For the Nary syntax, the number of operands.
unsigned getOperandArity(InstructionID ID);
} // namespace instruction

} // namespace metaphir
} // namespace llvm
#endif
