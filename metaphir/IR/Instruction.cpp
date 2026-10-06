#include "metaphir/IR/Instruction.h"
#include "metaphir/IR/CompositeMatcher.h"
#include "metaphir/IR/MIRContext.h"
#include "metaphir/IR/MIRContextImpl.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/Support/raw_ostream.h"
#include <algorithm>

namespace llvm {
namespace metaphir {

static void printWithoutType(raw_ostream &OS, const MatcherOperand &O) {
  if (O.IsArray) {
    OS << O;
    return;
  }
  if (O.Val)
    OS << *O.Val;
  for (const MetaFlag *F : O.MetaFlags)
    OS << *F;
}

static void printSeparated(raw_ostream &OS, ArrayRef<MatcherOperand> Ops,
                           unsigned Begin = 0) {
  interleaveComma(Ops.drop_front(Begin), OS);
}

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

Instruction *Instruction::create(
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

Instruction *Instruction::createComposite(
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

Instruction *Instruction::createLike(
    MIRContext &Context, const Instruction &Proto, StringRef ResultName,
    ArrayRef<InstructionFlag> Flags, ArrayRef<MetaFlag *> MetaFlags,
    ArrayRef<MatcherOperand> Operands, MetaVariable *Capture, SourceRange Range,
    MetaVariable *ParentBlock, PatternSettings Settings) {
  Instruction *Like =
      Proto.isComposite()
          ? createComposite(Context, ResultName, Proto.getCompositeMatcher(),
                            Flags, MetaFlags, Operands, Capture, Range,
                            ParentBlock, Settings)
          : create(Context, Proto.getInstructionID(), ResultName, Flags,
                   MetaFlags, Operands, Capture, Range, ParentBlock, Settings);
  Like->setExpandedFrom(Proto.getExpandedFrom());
  return Like;
}

std::optional<unsigned> Instruction::getOrSelfOperandIndex() const {
  for (const MetaFlag *Flag : MetaFlags) {
    assert(Flag && "null instruction meta flag");
    if (Flag->getMetaFlagID() != MetaFlag::MF_o)
      continue;
    if (Flag->getArguments().empty())
      return 0;
    assert(Flag->getArguments().size() == 1 &&
           Flag->getArguments().front().K == MetaFlag::Argument::Integer &&
           Flag->getArguments().front().IntegerValue >= 0 &&
           "':o' requires one non-negative integer argument");
    return static_cast<unsigned>(Flag->getArguments().front().IntegerValue);
  }
  return std::nullopt;
}

StringRef Instruction::getOpcodeName() const {
  return isComposite() ? Composite->getName() : getOpcodeName(ID);
}

StringRef Instruction::getCustomOpcodeName() const {
  return isComposite() ? Composite->getName() : "";
}

StringRef InstructionFlag::getName(FlagID ID) {
  switch (ID) {
#define MIR_FLAG_TOKEN_KIND(Name)                                              \
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

const Instruction::Info &Instruction::getInfo(InstructionID ID) {
  static const Info Table[] = {
#define MIR_INSTRUCTION_MATCHER(Name, TargetMatcher, Flags, Commutative,       \
                                Syntax, Arity)                                 \
  {#Name, Flags, Commutative, OperandSyntax::Syntax, Arity},
#include "metaphir/IR/InstructionMatchers.def"
  };
  assert(static_cast<size_t>(ID) < std::size(Table) &&
         "invalid instruction kind");
  return Table[ID];
}

raw_ostream &operator<<(raw_ostream &OS, const InstructionFlag &F) {
  if (F.Negated)
    OS << '!';
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
    if (O.ValueArray)
      OS << *O.ValueArray;
    return OS;
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
    for (const MatcherOperand &Op : Ops.drop_front()) {
      OS << ", ";
      printWithoutType(OS, Op);
    }
    return OS;
  }

  using ID = Instruction::InstructionID;
  switch (Instruction::getOperandSyntax(I.getInstructionID())) {
  case Instruction::OperandSyntax::Binary:
    // The second operand shares the first's type, which is written once.
    OS << ' ' << Ops[0] << ", ";
    printWithoutType(OS, Ops[1]);
    return OS;
  case Instruction::OperandSyntax::Cast:
    OS << ' ' << Ops[0];
    if (Ops.size() > 1 && Ops[1].Ty)
      OS << " to " << *Ops[1].Ty;
    return OS;
  case Instruction::OperandSyntax::Nary:
    OS << ' ';
    printSeparated(OS, Ops);
    return OS;
  case Instruction::OperandSyntax::Custom:
    break;
  }

  switch (I.getInstructionID()) {
  case ID::I_icmp:
  case ID::I_fcmp:
    if (const MatcherOperand *Predicate =
            I.getKeyedOperand(MatcherOperand::Predicate)) {
      OS << ' ';
      printWithoutType(OS, *Predicate);
    }
    OS << ' ' << Ops[0] << ", ";
    printWithoutType(OS, Ops[1]);
    return OS;
  case ID::I_phi:
    if (Ops.empty())
      return OS;
    if (Ops[0].Ty)
      OS << ' ' << *Ops[0].Ty;
    OS << ' ';
    for (unsigned Index = 0; Index < Ops.size(); Index += 2) {
      if (Index)
        OS << ", ";
      OS << '[';
      printWithoutType(OS, Ops[Index]);
      if (Index + 1 < Ops.size()) {
        OS << ", ";
        printWithoutType(OS, Ops[Index + 1]);
      }
      OS << ']';
    }
    return OS;
  case ID::I_call:
    if (Ops.size() < 2 || !Ops[0].Ty) {
      OS << ' ';
      printSeparated(OS, Ops);
      return OS;
    }
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
      if (const MatcherOperand *Upper =
              I.getKeyedOperand(MatcherOperand::InRangeUpper)) {
        OS << ", ";
        printWithoutType(OS, *Upper);
      }
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
    if (Ops.empty() || !Ops[0].Ty)
      return OS;
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
