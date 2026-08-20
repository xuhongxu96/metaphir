#ifndef METAPHIR_IR_INSTRUCTION_H
#define METAPHIR_IR_INSTRUCTION_H

#include "metaphir/IR/MetaFlag.h"
#include "metaphir/IR/Values.h"
#include <cstdint>

namespace llvm {
namespace metaphir {

struct MatcherOperand {
  enum KeyedOperandKind {
    NotKeyed,
    Predicate,
    Alignment,
    AddressSpace,
    InRangeLower,
    InRangeUpper,
    NumKeyedOperandKinds
  };

  Type *Ty = nullptr;
  Value *Val = nullptr;
  bool IsArray = false;
  bool IsInstructionOperand = true;
  MetaVariable *TypeArray = nullptr;
  MetaVariable *ValueArray = nullptr;
  KeyedOperandKind Key = NotKeyed;
  ArrayRef<MetaFlag *> MetaFlags;

  void setMetaFlags(MIRContext &Context, ArrayRef<MetaFlag *> Flags);
};

struct InstructionFlag {
  enum FlagID {
#define MIR_FLAG(Name) F_##Name,
#define MIR_FAST_MATH_FLAG(Name) F_##Name,
#include "metaphir/IR/Flags.def"
    NumFlagIDs,
  };

  FlagID ID;
  MetaVariable *Capture = nullptr;

  static StringRef getName(FlagID ID);
};

class Instruction : public Value {
public:
  enum InstructionID {
#define MIR_INSTRUCTION_MATCHER_ID(Name) I_##Name,
#include "metaphir/IR/InstructionMatchers.def"
  };

  using FlagMask = uint64_t;

  // How the parser spells this instruction's operands. Shared grammars are
  // dispatched by the parser from the .def (see getOperandSyntax); Custom
  // instructions have bespoke per-ID parse code.
  enum class OperandSyntax { Unary, Binary, Ternary, Cast, Custom };

  static constexpr FlagMask NoFlags = 0;

  static constexpr FlagMask FastMathFlags =
      (FlagMask(1) << InstructionFlag::F_fast) |
      (FlagMask(1) << InstructionFlag::F_nnan) |
      (FlagMask(1) << InstructionFlag::F_ninf) |
      (FlagMask(1) << InstructionFlag::F_nsz) |
      (FlagMask(1) << InstructionFlag::F_arcp) |
      (FlagMask(1) << InstructionFlag::F_contract) |
      (FlagMask(1) << InstructionFlag::F_afn) |
      (FlagMask(1) << InstructionFlag::F_reassoc);

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

  InstructionID getInstructionID() const { return ID; }
  StringRef getOpcodeName() const { return getOpcodeName(ID); }
  StringRef getResultName() const { return ResultName; }
  ArrayRef<InstructionFlag> getFlags() const { return Flags; }
  ArrayRef<MetaFlag *> getMetaFlags() const { return MetaFlags; }
  MetaVariable *getParentBlock() const { return ParentBlock; }
  ArrayRef<MatcherOperand> getUnkeyedOperands() const {
    return UnkeyedOperands;
  }
  const MatcherOperand *
  getKeyedOperand(MatcherOperand::KeyedOperandKind Kind) const;
  MetaVariable *getCapture() const { return Capture; }
  static bool classof(const Value *V) {
    return V->getValueID() == InstructionVal;
  }

  static constexpr FlagMask mask(InstructionFlag::FlagID ID) {
    return FlagMask(1) << ID;
  }
  static StringRef getOpcodeName(InstructionID ID);
  static FlagMask getSupportedFlags(InstructionID ID);
  static bool isCommutative(InstructionID ID);
  static OperandSyntax getOperandSyntax(InstructionID ID);
  static Instruction *get(MIRContext &Context, InstructionID ID,
                          StringRef ResultName, ArrayRef<InstructionFlag> Flags,
                          ArrayRef<MetaFlag *> MetaFlags,
                          ArrayRef<MatcherOperand> Operands,
                          MetaVariable *Capture, SourceRange Range,
                          MetaVariable *ParentBlock);

private:
  InstructionID ID;
  StringRef ResultName;
  ArrayRef<InstructionFlag> Flags;
  ArrayRef<MetaFlag *> MetaFlags;
  ArrayRef<MatcherOperand> UnkeyedOperands;
  ArrayRef<MatcherOperand> KeyedOperands;
  uint64_t KeyedOperandMask;
  MetaVariable *Capture = nullptr;
  MetaVariable *ParentBlock;

  Instruction(InstructionID ID, StringRef ResultName,
              ArrayRef<InstructionFlag> Flags, ArrayRef<MetaFlag *> MetaFlags,
              ArrayRef<MatcherOperand> UnkeyedOperands,
              ArrayRef<MatcherOperand> KeyedOperands, uint64_t KeyedOperandMask,
              MetaVariable *Capture, SourceRange Range,
              MetaVariable *ParentBlock)
      : Value(InstructionVal, Range), ID(ID), ResultName(ResultName),
        Flags(Flags), MetaFlags(MetaFlags), UnkeyedOperands(UnkeyedOperands),
        KeyedOperands(KeyedOperands), KeyedOperandMask(KeyedOperandMask),
        Capture(Capture), ParentBlock(ParentBlock) {}
};

raw_ostream &operator<<(raw_ostream &OS, const InstructionFlag &F);
raw_ostream &operator<<(raw_ostream &OS, const MatcherOperand &O);
raw_ostream &operator<<(raw_ostream &OS, const Instruction &I);

} // namespace metaphir
} // namespace llvm
#endif
