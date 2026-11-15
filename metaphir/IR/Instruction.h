#ifndef METAPHIR_IR_INSTRUCTION_H
#define METAPHIR_IR_INSTRUCTION_H

#include "llvm/ADT/StringRef.h"
#include <cstdint>

namespace llvm {
namespace metaphir {

/// The semantic flags an instruction matcher can name ('nsw', 'nnan', ...),
/// from Flags.def.
struct InstructionFlag {
  enum FlagID {
#define MIR_FLAG_TOKEN_KIND(Name) F_##Name,
#include "metaphir/IR/Flags.def"
    NumFlagIDs,
  };

  static StringRef getName(FlagID ID);

  InstructionFlag() = delete;
};

/// The built-in instruction matchers, from InstructionMatchers.def, and
/// their properties.
struct Instruction {
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

  static constexpr FlagMask NoFlags = 0;

  static constexpr FlagMask FastMathFlags = 0
#define MIR_FLAG(Name)
#define MIR_FAST_MATH_FLAG(Name) | (FlagMask(1) << InstructionFlag::F_##Name)
#include "metaphir/IR/Flags.def"
      ;

  static constexpr FlagMask NSWNUWFlags =
      (FlagMask(1) << InstructionFlag::F_nsw) |
      (FlagMask(1) << InstructionFlag::F_nuw);

  static constexpr FlagMask ExactFlag = FlagMask(1) << InstructionFlag::F_exact;
  static constexpr FlagMask DisjointFlag = FlagMask(1)
                                           << InstructionFlag::F_disjoint;
  static constexpr FlagMask InAllocaFlag = FlagMask(1)
                                           << InstructionFlag::F_inalloca;
  static constexpr FlagMask VolatileFlag = FlagMask(1)
                                           << InstructionFlag::F_volatile;

  static constexpr FlagMask GEPFlags =
      (FlagMask(1) << InstructionFlag::F_inbounds) |
      (FlagMask(1) << InstructionFlag::F_nusw) |
      (FlagMask(1) << InstructionFlag::F_nuw);

  static constexpr FlagMask NNegFlag = FlagMask(1) << InstructionFlag::F_nneg;
  static constexpr FlagMask SameSignFlag = FlagMask(1)
                                           << InstructionFlag::F_samesign;

  static constexpr FlagMask FastMathNNegFlags = FastMathFlags | NNegFlag;

  static constexpr FlagMask mask(InstructionFlag::FlagID ID) {
    return FlagMask(1) << ID;
  }
  static StringRef getOpcodeName(InstructionID ID) { return getInfo(ID).Name; }
  static FlagMask getSupportedFlags(InstructionID ID) {
    return getInfo(ID).SupportedFlags;
  }
  static bool isCommutative(InstructionID ID) {
    return getInfo(ID).Commutative;
  }
  static OperandSyntax getOperandSyntax(InstructionID ID) {
    return getInfo(ID).Syntax;
  }
  static unsigned getOperandArity(InstructionID ID) {
    return getInfo(ID).Arity;
  }

  Instruction() = delete;

private:
  /// Properties of a built-in instruction matcher, from
  /// InstructionMatchers.def.
  struct Info {
    StringRef Name;
    FlagMask SupportedFlags;
    bool Commutative;
    OperandSyntax Syntax;
    unsigned Arity;
  };
  static const Info &getInfo(InstructionID ID);
};

} // namespace metaphir
} // namespace llvm
#endif
