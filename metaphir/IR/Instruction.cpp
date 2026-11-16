#include "metaphir/IR/Instruction.h"
#include "llvm/Support/ErrorHandling.h"
#include <cassert>
#include <iterator>

namespace llvm {
namespace metaphir {

namespace instruction_flag {
StringRef getName(FlagID ID) {
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
} // namespace instruction_flag

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

namespace instruction {
StringRef getOpcodeName(InstructionID ID) { return getInfo(ID).Name; }
FlagMask getSupportedFlags(InstructionID ID) {
  return getInfo(ID).SupportedFlags;
}
bool isCommutative(InstructionID ID) { return getInfo(ID).Commutative; }
OperandSyntax getOperandSyntax(InstructionID ID) { return getInfo(ID).Syntax; }
unsigned getOperandArity(InstructionID ID) { return getInfo(ID).Arity; }
} // namespace instruction

} // namespace metaphir
} // namespace llvm
