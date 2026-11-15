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

} // namespace metaphir
} // namespace llvm
