#ifndef METAPHIR_IR_INSTRUCTION_H
#define METAPHIR_IR_INSTRUCTION_H

#include "metaphir/IR/MetaFlag.h"
#include "metaphir/IR/Values.h"
#include <cstdint>

namespace llvm {
namespace metaphir {

class CompositeMatcher;
class MetaVariable;

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

  MatcherOperand(Type *Ty = nullptr, Value *Val = nullptr, bool IsArray = false,
                 bool IsInstructionOperand = true,
                 MetaVariable *TypeArray = nullptr,
                 MetaVariable *ValueArray = nullptr,
                 KeyedOperandKind Key = NotKeyed,
                 ArrayRef<MetaFlag *> MetaFlags = {})
      : Ty(Ty), Val(Val), IsArray(IsArray),
        IsInstructionOperand(IsInstructionOperand), TypeArray(TypeArray),
        ValueArray(ValueArray), Key(Key), MetaFlags(MetaFlags) {}

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

// Encapsulates global pattern settings, applied at a `;; <name>(true|false)`
// directive and active for the instructions that follow it. Stored as an ORed
// bitmask so more settings can be added later; the Setting enum is generated
// from PatternSettings.def. Callers query/update through methods rather than
// manipulating raw bits.
class PatternSettings {
public:
  enum Setting : uint64_t {
    None = 0,
#define MIR_PATTERN_SETTING_ID(Name, Bit, Comment) Name = uint64_t(1) << Bit,
#include "metaphir/IR/PatternSettings.def"
  };

  PatternSettings() = default;
  explicit PatternSettings(uint64_t Mask) : Mask(Mask), Specified(Mask) {}

  bool has(Setting Flag) const { return Mask & uint64_t(Flag); }
  void set(Setting Flag) {
    Mask |= uint64_t(Flag);
    Specified |= uint64_t(Flag);
  }
  void clear(Setting Flag) {
    Mask &= ~uint64_t(Flag);
    Specified |= uint64_t(Flag);
  }

  /// Whether this setting was written here, as opposed to being left at its
  /// default or taken from an enclosing position.
  bool isSpecified(Setting Flag) const { return Specified & uint64_t(Flag); }

  /// Settings for an instruction placed at Outer's position: Outer's values
  /// apply, except for settings written here, which take precedence. Used when
  /// a 'match' body is inlined into a use site.
  PatternSettings inheritedFrom(PatternSettings Outer) const {
    PatternSettings Result;
    Result.Mask = (Outer.Mask & ~Specified) | (Mask & Specified);
    Result.Specified = Outer.Specified | Specified;
    return Result;
  }

  // Map a Setting back to its directive keyword (used in error messages).
  static StringRef getName(Setting Flag);

private:
  uint64_t Mask = None;
  /// Bits for the settings written explicitly, so an inlined body can override
  /// its use site rather than silently resetting it.
  uint64_t Specified = None;
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
  StringRef getOpcodeName() const {
    return isComposite() ? CustomOpcodeName : getOpcodeName(ID);
  }
  StringRef getResultName() const { return ResultName; }
  ArrayRef<InstructionFlag> getFlags() const { return Flags; }

  ArrayRef<MetaFlag *> getMetaFlags() const { return MetaFlags; }
  void setMetaFlags(MIRContext &Context, ArrayRef<MetaFlag *> Flags);
  void setOperandMetaFlags(unsigned OpIdx, MIRContext &Context,
                           ArrayRef<MetaFlag *> Flags);
  bool hasMetaFlag(MetaFlag::MetaFlagID FlagID) const {
    return llvm::any_of(MetaFlags, [FlagID](const MetaFlag *Flag) {
      return Flag->getMetaFlagID() == FlagID;
    });
  }

  MetaVariable *getParentBlock() const { return ParentBlock; }
  PatternSettings getSettings() const { return Settings; }
  ArrayRef<MatcherOperand> getUnkeyedOperands() const {
    return UnkeyedOperands;
  }
  SmallVector<MatcherOperand, 4> getKeyedOperands() const;
  const MatcherOperand *
  getKeyedOperand(MatcherOperand::KeyedOperandKind Kind) const;

  MetaVariable *getCapture() const { return Capture; }
  void setCapture(MetaVariable *V) { Capture = V; }

  Value *getOrSelfValue() const { return OrSelfValue; }
  void setOrSelfValue(Value *V) { OrSelfValue = V; }

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
  bool isComposite() const { return Composite != nullptr; }
  CompositeMatcher *getCompositeMatcher() const { return Composite; }
  StringRef getCustomOpcodeName() const { return CustomOpcodeName; }

  static Instruction *get(MIRContext &Context, InstructionID ID,
                          StringRef ResultName, ArrayRef<InstructionFlag> Flags,
                          ArrayRef<MetaFlag *> MetaFlags,
                          ArrayRef<MatcherOperand> Operands,
                          MetaVariable *Capture, SourceRange Range,
                          MetaVariable *ParentBlock,
                          PatternSettings Settings = {});
  static Instruction *
  getComposite(MIRContext &Context, StringRef ResultName,
               CompositeMatcher *Composite, StringRef OpcodeName,
               ArrayRef<InstructionFlag> Flags, ArrayRef<MetaFlag *> MetaFlags,
               ArrayRef<MatcherOperand> Operands, MetaVariable *Capture,
               SourceRange Range, MetaVariable *ParentBlock,
               PatternSettings Settings = {});

private:
  InstructionID ID;
  StringRef ResultName;
  ArrayRef<InstructionFlag> Flags;
  ArrayRef<MetaFlag *> MetaFlags;
  ArrayRef<MatcherOperand> UnkeyedOperands;
  ArrayRef<MatcherOperand> KeyedOperands;
  uint64_t KeyedOperandMask;
  MetaVariable *Capture = nullptr;
  // For an expanded composite's ':o', this is the caller operand used by the
  // or-self alternative. It is separate from the branch root's operands.
  Value *OrSelfValue = nullptr;
  MetaVariable *ParentBlock;
  PatternSettings Settings;
  CompositeMatcher *Composite = nullptr;
  StringRef CustomOpcodeName;

  Instruction(InstructionID ID, StringRef ResultName,
              ArrayRef<InstructionFlag> Flags, ArrayRef<MetaFlag *> MetaFlags,
              ArrayRef<MatcherOperand> UnkeyedOperands,
              ArrayRef<MatcherOperand> KeyedOperands, uint64_t KeyedOperandMask,
              MetaVariable *Capture, SourceRange Range,
              MetaVariable *ParentBlock, PatternSettings Settings,
              CompositeMatcher *Composite = nullptr,
              StringRef CustomOpcodeName = "")
      : Value(InstructionVal, Range), ID(ID), ResultName(ResultName),
        Flags(Flags), MetaFlags(MetaFlags), UnkeyedOperands(UnkeyedOperands),
        KeyedOperands(KeyedOperands), KeyedOperandMask(KeyedOperandMask),
        Capture(Capture), ParentBlock(ParentBlock), Settings(Settings),
        Composite(Composite), CustomOpcodeName(CustomOpcodeName) {}
};

raw_ostream &operator<<(raw_ostream &OS, const InstructionFlag &F);
raw_ostream &operator<<(raw_ostream &OS, const MatcherOperand &O);
raw_ostream &operator<<(raw_ostream &OS, const Instruction &I);

} // namespace metaphir
} // namespace llvm
#endif
