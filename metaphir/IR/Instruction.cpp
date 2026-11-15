#include "metaphir/IR/Instruction.h"
#include "llvm/Support/ErrorHandling.h"
#include <cassert>
#include <iterator>

namespace llvm {
namespace metaphir {

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

namespace {
/// Properties of a built-in instruction matcher, from
/// InstructionMatchers.def.
struct Info {
  StringRef Name;
  Instruction::FlagMask SupportedFlags;
  bool Commutative;
  Instruction::OperandSyntax Syntax;
  unsigned Arity;
};
} // namespace

static const Info &getInfo(Instruction::InstructionID ID) {
  using namespace Instruction;
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

StringRef Instruction::getOpcodeName(InstructionID ID) {
  return getInfo(ID).Name;
}
Instruction::FlagMask Instruction::getSupportedFlags(InstructionID ID) {
  return getInfo(ID).SupportedFlags;
}
bool Instruction::isCommutative(InstructionID ID) {
  return getInfo(ID).Commutative;
}
Instruction::OperandSyntax Instruction::getOperandSyntax(InstructionID ID) {
  return getInfo(ID).Syntax;
}
unsigned Instruction::getOperandArity(InstructionID ID) {
  return getInfo(ID).Arity;
}

} // namespace metaphir
} // namespace llvm
