#include "metaphir/IR/Instruction.h"
#include "llvm/Support/ErrorHandling.h"
#include <cassert>
#include <iterator>

namespace llvm {
namespace metaphir {

StringRef instruction_flag::getName(FlagID ID) {
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
  instruction::FlagMask SupportedFlags;
  bool Commutative;
  instruction::OperandSyntax Syntax;
  unsigned Arity;
};
} // namespace

static const Info &getInfo(instruction::InstructionID ID) {
  using namespace instruction;
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

StringRef instruction::getOpcodeName(InstructionID ID) {
  return getInfo(ID).Name;
}
instruction::FlagMask instruction::getSupportedFlags(InstructionID ID) {
  return getInfo(ID).SupportedFlags;
}
bool instruction::isCommutative(InstructionID ID) {
  return getInfo(ID).Commutative;
}
instruction::OperandSyntax instruction::getOperandSyntax(InstructionID ID) {
  return getInfo(ID).Syntax;
}
unsigned instruction::getOperandArity(InstructionID ID) {
  return getInfo(ID).Arity;
}

} // namespace metaphir
} // namespace llvm
