#include "metaphir/IR/Instruction.h"
#include "metaphir/IR/CompositeMatcher.h"
#include "metaphir/IR/MIRContext.h"
#include "metaphir/IR/MIRContextImpl.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/Support/raw_ostream.h"
#include <algorithm>

namespace llvm {
namespace metaphir {

namespace {

// The setting mask is a uint64_t; verify the .def never assigns a bit index
// beyond 63 so the mask cannot overflow. Adding a setting past bit 63 fails to
// compile here rather than silently truncating the mask.
constexpr unsigned getMaxSettingBit() {
  unsigned Max = 0;
#define MIR_PATTERN_SETTING_ID(Name, Bit, Comment)                             \
  Max = std::max(Max, static_cast<unsigned>(Bit));
#include "metaphir/IR/PatternSettings.def"
  return Max;
}
static_assert(getMaxSettingBit() < 64,
              "pattern settings exceed the 64-bit mask");

void printWithoutType(raw_ostream &OS, const MatcherOperand &O) {
  if (O.IsArray) {
    OS << O;
    return;
  }
  if (O.Val)
    OS << *O.Val;
  for (const MetaFlag *F : O.MetaFlags)
    OS << *F;
}

void printSeparated(raw_ostream &OS, ArrayRef<MatcherOperand> Ops,
                    unsigned Begin = 0) {
  for (unsigned Index = Begin; Index != Ops.size(); ++Index) {
    if (Index != Begin)
      OS << ", ";
    OS << Ops[Index];
  }
}

} // namespace

void MatcherOperand::setMetaFlags(MIRContext &Context,
                                  ArrayRef<MetaFlag *> Flags) {
  MetaFlags = Context.pImpl->copyArray<MetaFlag *>(Flags);
}

void Instruction::setMetaFlags(MIRContext &Context,
                               ArrayRef<MetaFlag *> Flags) {
  MetaFlags = Context.pImpl->copyArray<MetaFlag *>(Flags);
}

void Instruction::setOperandMetaFlags(unsigned OpIdx, MIRContext &Context,
                                      ArrayRef<MetaFlag *> Flags) {
  assert(OpIdx < UnkeyedOperands.size() && "operand index out of range");
  const_cast<MatcherOperand &>(UnkeyedOperands[OpIdx])
      .setMetaFlags(Context, Flags);
}

Instruction *Instruction::get(
    MIRContext &Context, InstructionID ID, StringRef ResultName,
    ArrayRef<InstructionFlag> Flags, ArrayRef<MetaFlag *> MetaFlags,
    ArrayRef<MatcherOperand> Operands, MetaVariable *Capture, SourceRange Range,
    MetaVariable *ParentBlock, PatternSettings Settings) {
  assert((ParentBlock == nullptr ||
          ParentBlock->getType() == MetaType::BasicBlock) &&
         "instruction must have a basic block");
  SmallVector<MatcherOperand, 8> UnkeyedOperands;
  MatcherOperand KeyedOperands[MatcherOperand::NumKeyedOperandKinds];
  uint64_t KeyedOperandMask = 0;
  static_assert(MatcherOperand::NumKeyedOperandKinds <= 64,
                "keyed operand mask is too small");
  for (const MatcherOperand &Operand : Operands) {
    if (Operand.Key == MatcherOperand::NotKeyed) {
      UnkeyedOperands.push_back(Operand);
      continue;
    }
    uint64_t Bit = uint64_t(1) << Operand.Key;
    assert(!(KeyedOperandMask & Bit) && "duplicate keyed operand");
    KeyedOperandMask |= Bit;
    KeyedOperands[Operand.Key] = Operand;
  }
  return new (Context.pImpl->Alloc) Instruction(
      ID, Context.pImpl->Saver.save(ResultName),
      Context.pImpl->copyArray<InstructionFlag>(Flags),
      Context.pImpl->copyArray<MetaFlag *>(MetaFlags),
      Context.pImpl->copyArray<MatcherOperand>(UnkeyedOperands),
      KeyedOperandMask ? Context.pImpl->copyArray<MatcherOperand>(KeyedOperands)
                       : ArrayRef<MatcherOperand>{},
      KeyedOperandMask, Capture, Range, ParentBlock, Settings);
}

Instruction *Instruction::getComposite(
    MIRContext &Context, StringRef ResultName, CompositeMatcher *Composite,
    ArrayRef<InstructionFlag> Flags, ArrayRef<MetaFlag *> MetaFlags,
    ArrayRef<MatcherOperand> Operands, MetaVariable *Capture, SourceRange Range,
    MetaVariable *ParentBlock, PatternSettings Settings) {
  return new (Context.pImpl->Alloc)
      Instruction(InstructionID(0), Context.pImpl->Saver.save(ResultName),
                  Context.pImpl->copyArray<InstructionFlag>(Flags),
                  Context.pImpl->copyArray<MetaFlag *>(MetaFlags),
                  Context.pImpl->copyArray<MatcherOperand>(Operands), {}, 0,
                  Capture, Range, ParentBlock, Settings, Composite);
}

Instruction *
Instruction::withOperands(MIRContext &Context, const Instruction *Orig,
                          ArrayRef<MatcherOperand> NewUnkeyedOperands) {
  auto *NewI = new (Context.pImpl->Alloc)
      Instruction(Orig->ID, Orig->ResultName, Orig->Flags, Orig->MetaFlags,
                  Context.pImpl->copyArray<MatcherOperand>(NewUnkeyedOperands),
                  Orig->KeyedOperands, Orig->KeyedOperandMask, Orig->Capture,
                  Orig->getSourceRange(), Orig->ParentBlock, Orig->Settings,
                  Orig->Composite);
  NewI->setOrSelfValue(Orig->OrSelfValue);
  return NewI;
}

StringRef Instruction::getOpcodeName() const {
  return isComposite() ? Composite->getName() : getOpcodeName(ID);
}

StringRef Instruction::getCustomOpcodeName() const {
  return isComposite() ? Composite->getName() : "";
}

StringRef InstructionFlag::getName(FlagID ID) {
  switch (ID) {
#define MIR_FLAG(Name)                                                         \
  case F_##Name:                                                               \
    return #Name;
#define MIR_FAST_MATH_FLAG(Name)                                               \
  case F_##Name:                                                               \
    return #Name;
#include "metaphir/IR/Flags.def"
  case NumFlagIDs:
    break;
  }
  llvm_unreachable("invalid semantic flag ID");
}

SmallVector<MatcherOperand, 4> Instruction::getKeyedOperands() const {
  SmallVector<MatcherOperand, 4> Result;
  for (unsigned I = MatcherOperand::NotKeyed + 1;
       I < MatcherOperand::NumKeyedOperandKinds; ++I) {
    if (KeyedOperandMask & (uint64_t(1) << I))
      Result.push_back(KeyedOperands[I]);
  }
  return Result;
}

const MatcherOperand *
Instruction::getKeyedOperand(MatcherOperand::KeyedOperandKind Kind) const {
  assert(Kind > MatcherOperand::NotKeyed &&
         Kind < MatcherOperand::NumKeyedOperandKinds &&
         "not a keyed operand kind");
  if (!(KeyedOperandMask & (uint64_t(1) << Kind)))
    return nullptr;
  return &KeyedOperands[Kind];
}

StringRef Instruction::getOpcodeName(InstructionID ID) {
  switch (ID) {
#define MIR_INSTRUCTION_MATCHER_NAME(Name)                                     \
  case I_##Name:                                                               \
    return #Name;
#include "metaphir/IR/InstructionMatchers.def"
  }
  llvm_unreachable("invalid instruction kind");
}

Instruction::FlagMask Instruction::getSupportedFlags(InstructionID ID) {
  switch (ID) {
#define MIR_INSTRUCTION_MATCHER_SUPPORTED_FLAGS(Name, Flags)                   \
  case I_##Name:                                                               \
    return Flags;
#include "metaphir/IR/InstructionMatchers.def"
  }
  llvm_unreachable("invalid instruction kind");
}

bool Instruction::isCommutative(InstructionID ID) {
  switch (ID) {
#define MIR_INSTRUCTION_MATCHER_COMMUTATIVE(Name, Commutative)                 \
  case I_##Name:                                                               \
    return Commutative;
#include "metaphir/IR/InstructionMatchers.def"
  }
  llvm_unreachable("invalid instruction kind");
}

Instruction::OperandSyntax Instruction::getOperandSyntax(InstructionID ID) {
  switch (ID) {
#define MIR_INSTRUCTION_MATCHER_OPERAND_SYNTAX(Name, Syntax, Arity)            \
  case I_##Name:                                                               \
    return Instruction::OperandSyntax::Syntax;
#include "metaphir/IR/InstructionMatchers.def"
  }
  llvm_unreachable("invalid instruction kind");
}

unsigned Instruction::getOperandArity(InstructionID ID) {
  switch (ID) {
#define MIR_INSTRUCTION_MATCHER_OPERAND_SYNTAX(Name, Syntax, Arity)            \
  case I_##Name:                                                               \
    return Arity;
#include "metaphir/IR/InstructionMatchers.def"
  }
  llvm_unreachable("invalid instruction kind");
}

StringRef PatternSettings::getName(PatternSettings::Setting Flag) {
  switch (Flag) {
#define MIR_PATTERN_SETTING_ID(Name, Bit, Comment)                             \
  case Name:                                                                   \
    return #Name;
#include "metaphir/IR/PatternSettings.def"
  default:
    llvm_unreachable("invalid pattern setting");
  }
}

raw_ostream &operator<<(raw_ostream &OS, const InstructionFlag &F) {
  OS << InstructionFlag::getName(F.ID);
  if (F.Capture)
    OS << ":" << *F.Capture;
  return OS;
}

raw_ostream &operator<<(raw_ostream &OS, const MatcherOperand &O) {
  if (O.IsArray) {
    OS << "...";
    if (O.TypeArray)
      OS << *O.TypeArray << ' ';
    return OS << *O.ValueArray;
  }
  if (O.Ty)
    OS << *O.Ty << (O.Val ? " " : "");
  if (O.Val)
    OS << *O.Val;
  for (const MetaFlag *F : O.MetaFlags)
    OS << *F;
  return OS;
}

raw_ostream &operator<<(raw_ostream &OS, const Instruction &I) {
  ArrayRef<MatcherOperand> Ops = I.getUnkeyedOperands();
  if (!I.getResultName().empty())
    OS << '%' << I.getResultName() << " = ";
  OS << I.getOpcodeName();
  if (I.getCapture())
    OS << ":" << *I.getCapture();
  for (const MetaFlag *F : I.getMetaFlags())
    OS << *F;
  for (const InstructionFlag &F : I.getFlags())
    OS << ' ' << F;

  if (I.isComposite()) {
    if (Ops.empty())
      return OS;
    OS << ' ' << Ops[0];
    for (unsigned Index = 1; Index != Ops.size(); ++Index) {
      OS << ", ";
      printWithoutType(OS, Ops[Index]);
    }
    return OS;
  }

  using ID = Instruction::InstructionID;
  switch (I.getInstructionID()) {
  case ID::I_add:
  case ID::I_fadd:
  case ID::I_sub:
  case ID::I_fsub:
  case ID::I_mul:
  case ID::I_fmul:
  case ID::I_udiv:
  case ID::I_sdiv:
  case ID::I_fdiv:
  case ID::I_urem:
  case ID::I_srem:
  case ID::I_frem:
  case ID::I_shl:
  case ID::I_lshr:
  case ID::I_ashr:
  case ID::I_and:
  case ID::I_or:
  case ID::I_xor:
    OS << ' ' << Ops[0] << ", ";
    printWithoutType(OS, Ops[1]);
    return OS;
  case ID::I_trunc:
  case ID::I_zext:
  case ID::I_sext:
  case ID::I_fptrunc:
  case ID::I_fpext:
  case ID::I_fptoui:
  case ID::I_fptosi:
  case ID::I_uitofp:
  case ID::I_sitofp:
  case ID::I_ptrtoint:
  case ID::I_ptrtoaddr:
  case ID::I_inttoptr:
  case ID::I_bitcast:
    return OS << ' ' << Ops[0] << " to " << *Ops[1].Ty;
  case ID::I_icmp:
  case ID::I_fcmp:
    OS << ' ';
    printWithoutType(OS, *I.getKeyedOperand(MatcherOperand::Predicate));
    OS << ' ' << Ops[0] << ", ";
    printWithoutType(OS, Ops[1]);
    return OS;
  case ID::I_phi:
    OS << ' ' << *Ops[0].Ty << ' ';
    for (unsigned Index = 0; Index != Ops.size(); Index += 2) {
      if (Index)
        OS << ", ";
      OS << '[';
      printWithoutType(OS, Ops[Index]);
      OS << ", ";
      printWithoutType(OS, Ops[Index + 1]);
      OS << ']';
    }
    return OS;
  case ID::I_call:
    OS << ' ' << *Ops[0].Ty << ' ';
    printWithoutType(OS, Ops[1]);
    OS << '(';
    printSeparated(OS, Ops, 2);
    return OS << ')';
  case ID::I_getelementptr: {
    if (const MatcherOperand *Lower =
            I.getKeyedOperand(MatcherOperand::InRangeLower)) {
      OS << " inrange(";
      printWithoutType(OS, *Lower);
      OS << ", ";
      printWithoutType(OS, *I.getKeyedOperand(MatcherOperand::InRangeUpper));
      OS << ')';
    }
    OS << ' ';
    printSeparated(OS, Ops);
    return OS;
  }
  case ID::I_alloca:
  case ID::I_load:
  case ID::I_store:
    OS << ' ';
    printSeparated(OS, Ops);
    if (const MatcherOperand *Alignment =
            I.getKeyedOperand(MatcherOperand::Alignment))
      OS << ", align " << *Alignment;
    if (const MatcherOperand *AddressSpace =
            I.getKeyedOperand(MatcherOperand::AddressSpace))
      OS << ", addrspace(" << *AddressSpace << ')';
    return OS;
  case ID::I_ret:
    OS << ' ' << *Ops[0].Ty;
    if (Ops[0].Val)
      OS << ' ' << *Ops[0].Val;
    return OS;
  default:
    OS << ' ';
    printSeparated(OS, Ops);
    return OS;
  }
}

} // namespace metaphir
} // namespace llvm
