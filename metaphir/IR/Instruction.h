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

struct MatcherFlag {
  StringRef Name;
  MetaVariable *Capture = nullptr;
};

class Instruction : public Value {
public:
  enum InstructionID {
#define MIR_INSTRUCTION_MATCHER_ID(Name) I_##Name,
#include "metaphir/IR/InstructionMatchers.def"
  };

  enum SemanticFlagID {
#define MIR_FLAG(Name) F_##Name,
#define MIR_FAST_MATH_FLAG(Name) F_##Name,
#include "metaphir/IR/Flags.def"
    NumSemanticFlags,
  };

  using FlagMask = uint64_t;

  static constexpr FlagMask NoFlags = 0;

  static constexpr FlagMask FastMathFlags =
      (FlagMask(1) << F_fast) | (FlagMask(1) << F_nnan) |
      (FlagMask(1) << F_ninf) | (FlagMask(1) << F_nsz) |
      (FlagMask(1) << F_arcp) | (FlagMask(1) << F_contract) |
      (FlagMask(1) << F_afn) | (FlagMask(1) << F_reassoc);

  static constexpr FlagMask NSWNUWFlags =
      (FlagMask(1) << F_nsw) | (FlagMask(1) << F_nuw);

  static constexpr FlagMask ExactFlag = FlagMask(1) << F_exact;
  static constexpr FlagMask DisjointFlag = FlagMask(1) << F_disjoint;
  static constexpr FlagMask InAllocaFlag = FlagMask(1) << F_inalloca;
  static constexpr FlagMask VolatileFlag = FlagMask(1) << F_volatile;

  static constexpr FlagMask GEPFlags = (FlagMask(1) << F_inbounds) |
                                       (FlagMask(1) << F_nusw) |
                                       (FlagMask(1) << F_nuw);

  static constexpr FlagMask NNegFlag = FlagMask(1) << F_nneg;
  static constexpr FlagMask SameSignFlag = FlagMask(1) << F_samesign;

  static constexpr FlagMask FastMathNNegFlags = FastMathFlags | NNegFlag;

  InstructionID getInstructionID() const { return ID; }
  StringRef getOpcodeName() const { return getOpcodeName(ID); }
  StringRef getResultName() const { return ResultName; }
  ArrayRef<MatcherFlag> getFlags() const { return Flags; }
  ArrayRef<MetaFlag *> getMetaFlags() const { return MetaFlags; }
  ArrayRef<MatcherOperand> getUnkeyedOperands() const {
    return UnkeyedOperands;
  }
  const MatcherOperand *
  getKeyedOperand(MatcherOperand::KeyedOperandKind Kind) const;
  MetaVariable *getCapture() const { return Capture; }
  static bool classof(const Value *V) {
    return V->getValueID() == InstructionVal;
  }

  static constexpr FlagMask mask(SemanticFlagID ID) {
    return FlagMask(1) << ID;
  }
  static StringRef getOpcodeName(InstructionID ID);
  static FlagMask getSupportedFlags(InstructionID ID);
  static bool isCommutative(InstructionID ID);
  static Instruction *get(MIRContext &Context, InstructionID ID,
                          StringRef ResultName, ArrayRef<MatcherFlag> Flags,
                          ArrayRef<MetaFlag *> MetaFlags,
                          ArrayRef<MatcherOperand> Operands,
                          MetaVariable *Capture, SourceRange Range);

private:
  InstructionID ID;
  StringRef ResultName;
  ArrayRef<MatcherFlag> Flags;
  ArrayRef<MetaFlag *> MetaFlags;
  ArrayRef<MatcherOperand> UnkeyedOperands;
  ArrayRef<MatcherOperand> KeyedOperands;
  uint64_t KeyedOperandMask;
  MetaVariable *Capture = nullptr;

  Instruction(InstructionID ID, StringRef ResultName,
              ArrayRef<MatcherFlag> Flags, ArrayRef<MetaFlag *> MetaFlags,
              ArrayRef<MatcherOperand> UnkeyedOperands,
              ArrayRef<MatcherOperand> KeyedOperands, uint64_t KeyedOperandMask,
              MetaVariable *Capture, SourceRange Range)
      : Value(InstructionVal, Range), ID(ID), ResultName(ResultName),
        Flags(Flags), MetaFlags(MetaFlags), UnkeyedOperands(UnkeyedOperands),
        KeyedOperands(KeyedOperands), KeyedOperandMask(KeyedOperandMask),
        Capture(Capture) {}
};

raw_ostream &operator<<(raw_ostream &OS, const MatcherFlag &F);
raw_ostream &operator<<(raw_ostream &OS, const MatcherOperand &O);
raw_ostream &operator<<(raw_ostream &OS, const Instruction &I);

} // namespace metaphir
} // namespace llvm
#endif
