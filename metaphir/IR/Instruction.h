#ifndef METAPHIR_IR_INSTRUCTION_H
#define METAPHIR_IR_INSTRUCTION_H

#include "metaphir/IR/Constants.h"
#include "metaphir/IR/MetaFlag.h"
#include "metaphir/IR/PatternSettings.h"
#include <cstdint>
#include <optional>

namespace llvm {
namespace metaphir {

class CompositeMatcher;
class MetaVariable;

/// An operand of an instruction matcher. Most are typed values ('i32 ?x');
/// others are bare types (a cast's destination, IsInstructionOperand false),
/// array captures of the remaining operands ('...?types ?values', IsArray),
/// or keyed operands such as a predicate or alignment (Key).
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

/// A semantic flag written on an instruction matcher ('nsw'). Without a
/// Capture the flag must be present; with one it is optional and Capture is
/// bound to whether it is.
struct InstructionFlag {
  enum FlagID {
#define MIR_FLAG_TOKEN_KIND(Name) F_##Name,
#include "metaphir/IR/Flags.def"
    NumFlagIDs,
  };

  FlagID ID = NumFlagIDs;
  MetaVariable *Capture = nullptr;

  static StringRef getName(FlagID ID);
};

/// An instruction matcher: a built-in one (an InstructionID from
/// InstructionMatchers.def) or a use of a composite ('match') matcher.
/// Created by the factories, owned by the MIRContext, not uniqued.
class Instruction : public Value {
public:
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

  InstructionID getInstructionID() const {
    assert(!isComposite() &&
           "a composite matcher use has no built-in instruction ID");
    return ID;
  }
  StringRef getOpcodeName() const;
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

  /// The index, among the value operands, of the operand that ':o' lets match
  /// in place of this instruction; none without ':o'.
  std::optional<unsigned> getOrSelfOperandIndex() const;
  void setOrSelfValue(Value *V) { OrSelfValue = V; }

  static bool classof(const Value *V) {
    return V->getValueID() == InstructionVal;
  }

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
  bool isComposite() const { return Composite != nullptr; }
  CompositeMatcher *getCompositeMatcher() const { return Composite; }
  StringRef getCustomOpcodeName() const;

  static Instruction *
  create(MIRContext &Context, InstructionID ID, StringRef ResultName,
         ArrayRef<InstructionFlag> Flags, ArrayRef<MetaFlag *> MetaFlags,
         ArrayRef<MatcherOperand> Operands, MetaVariable *Capture,
         SourceRange Range, MetaVariable *ParentBlock,
         PatternSettings Settings = {});
  static Instruction *createComposite(MIRContext &Context, StringRef ResultName,
                                      CompositeMatcher *Composite,
                                      ArrayRef<InstructionFlag> Flags,
                                      ArrayRef<MetaFlag *> MetaFlags,
                                      ArrayRef<MatcherOperand> Operands,
                                      MetaVariable *Capture, SourceRange Range,
                                      MetaVariable *ParentBlock,
                                      PatternSettings Settings = {});

  /// Creates an instruction of the same kind as Proto -- the same built-in
  /// matcher, or the same composite -- with everything else given anew.
  /// Operands holds keyed and unkeyed operands, as for create().
  static Instruction *
  createLike(MIRContext &Context, const Instruction &Proto,
             StringRef ResultName, ArrayRef<InstructionFlag> Flags,
             ArrayRef<MetaFlag *> MetaFlags, ArrayRef<MatcherOperand> Operands,
             MetaVariable *Capture, SourceRange Range,
             MetaVariable *ParentBlock, PatternSettings Settings);

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

  Instruction(InstructionID ID, StringRef ResultName,
              ArrayRef<InstructionFlag> Flags, ArrayRef<MetaFlag *> MetaFlags,
              ArrayRef<MatcherOperand> UnkeyedOperands,
              ArrayRef<MatcherOperand> KeyedOperands, uint64_t KeyedOperandMask,
              MetaVariable *Capture, SourceRange Range,
              MetaVariable *ParentBlock, PatternSettings Settings,
              CompositeMatcher *Composite = nullptr)
      : Value(InstructionVal, Range), ID(ID), ResultName(ResultName),
        Flags(Flags), MetaFlags(MetaFlags), UnkeyedOperands(UnkeyedOperands),
        KeyedOperands(KeyedOperands), KeyedOperandMask(KeyedOperandMask),
        Capture(Capture), ParentBlock(ParentBlock), Settings(Settings),
        Composite(Composite) {}
};

raw_ostream &operator<<(raw_ostream &OS, const InstructionFlag &F);
raw_ostream &operator<<(raw_ostream &OS, const MatcherOperand &O);
raw_ostream &operator<<(raw_ostream &OS, const Instruction &I);

} // namespace metaphir
} // namespace llvm
#endif
