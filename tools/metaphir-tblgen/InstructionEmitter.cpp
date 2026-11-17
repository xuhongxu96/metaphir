//===- InstructionEmitter.cpp - flags and instruction matchers
//--------------===//
//
// -gen-instructions: metaphir/IR/Instruction.inc, the data of the semantic
// flags and the built-in instruction matchers; metaphir/IR/Instruction.h
// reads it.
// -gen-opcode-matchers: metaphir/Matching/OpcodeMatchers.inc, which
// llvm::Instructions each matcher accepts; OpcodePredicates.cpp reads it.
//
//===----------------------------------------------------------------------===//

#include "Emit.h"
#include "Records.h"

using namespace llvm;
using namespace metaphir_tblgen;

namespace {

void emitInstructions(const RecordKeeper &Records, raw_ostream &OS) {
  auto Flags = getDefinitionsInOrder(Records, "Flag");
  auto Sets = getDefinitionsInOrder(Records, "FlagSet");
  auto Matchers = getDefinitionsInOrder(Records, "InstructionMatcher");
  for (const Record *M : Matchers) {
    StringRef Syntax = M->getValueAsString("OperandSyntax");
    if (Syntax != "Nary" && Syntax != "Binary" && Syntax != "Cast" &&
        Syntax != "Custom")
      PrintFatalError(M, "unknown operand syntax '" + Syntax + "'");
  }

  beginHeader(OS, Records, "The instruction matchers and their flags",
              "METAPHIR_IR_INSTRUCTION_INC",
              {"llvm/ADT/StringRef.h", "cstdint"});
  OS << "/// The semantic flags an instruction matcher can name ('nsw', "
        "'nnan', ...).\nnamespace instruction_flag {\nenum FlagID {\n";
  for (const Record *F : Flags)
    OS << "  F_" << F->getName() << ",\n";
  OS << "  NumFlagIDs,\n};\n\n";
  emitArray<decltype(Flags), const Record *>(
      OS, "StringRef FlagNames[]", Flags,
      [](raw_ostream &OS, const Record *const &F) {
        OS << '"' << F->getName() << '"';
      });
  OS << "} // namespace instruction_flag\n\n"
        "/// The built-in instruction matchers, and their properties.\n"
        "namespace instruction {\nenum InstructionID {\n";
  for (const Record *M : Matchers)
    OS << "  I_" << M->getName() << ",\n";
  OS << "  NumInstructionIDs,\n};\n\n"
        "using FlagMask = uint64_t;\n\n"
        "/// How the parser spells an instruction's operands. Shared grammars "
        "are\n/// dispatched by the parser; Custom instructions have bespoke "
        "per-ID parse\n/// code. Nary spells a fixed number of individually "
        "typed operands; the\n/// number comes from getOperandArity (or the "
        "composite matcher's parameter\n/// list).\n"
        "enum class OperandSyntax { Nary, Binary, Cast, Custom };\n\n"
        "constexpr FlagMask mask(instruction_flag::FlagID ID) {\n"
        "  return FlagMask(1) << ID;\n}\n\n";
  for (const Record *S : Sets) {
    OS << "constexpr FlagMask " << S->getName() << " = 0";
    for (const Record *F : S->getValueAsListOfDefs("Flags"))
      OS << " | mask(instruction_flag::F_" << F->getName() << ")";
    OS << ";\n";
  }
  OS << "\n/// What a matcher is, besides its spelling.\n"
        "struct InstructionInfo {\n  StringRef Name;\n"
        "  FlagMask SupportedFlags;\n  bool Commutative;\n"
        "  OperandSyntax Syntax;\n  unsigned Arity;\n};\n\n";
  emitArray<decltype(Matchers), const Record *>(
      OS, "InstructionInfo Infos[]", Matchers,
      [](raw_ostream &OS, const Record *const &M) {
        OS << "{\"" << M->getName() << "\", "
           << M->getValueAsDef("SupportedFlags")->getName() << ", "
           << (M->getValueAsBit("Commutative") ? "true" : "false")
           << ", OperandSyntax::" << M->getValueAsString("OperandSyntax")
           << ", " << M->getValueAsInt("Arity") << "}";
      });
  OS << "} // namespace instruction\n\n";
  endHeader(OS, "METAPHIR_IR_INSTRUCTION_INC");
}

void emitOpcodeMatchers(const RecordKeeper &Records, raw_ostream &OS) {
  auto Matchers = getDefinitionsInOrder(Records, "InstructionMatcher");
  for (const Record *M : Matchers) {
    bool HasOpcode = !M->getValueAsString("Opcode").empty();
    bool HasCheck = !M->getValueAsString("TargetCheck").empty();
    if (HasOpcode == HasCheck)
      PrintFatalError(M, "give an opcode or a target check, and not both");
  }
  beginHeader(OS, Records, "Matching llvm::Instructions with the matchers",
              "METAPHIR_MATCHING_OPCODE_MATCHERS_INC",
              {"llvm/IR/Instruction.h", "llvm/IR/Instructions.h"},
              {"instruction"});
  OS << "/// Which llvm::Instructions a matcher accepts: those of an opcode, "
        "or those\n/// a check accepts when it has one.\n"
        "struct InstructionTarget {\n  unsigned Opcode;\n"
        "  bool (*Check)(const llvm::Instruction &Target);\n};\n\n";
  emitArray<decltype(Matchers), const Record *>(
      OS, "InstructionTarget Targets[]", Matchers,
      [](raw_ostream &OS, const Record *const &M) {
        StringRef Opcode = M->getValueAsString("Opcode");
        StringRef Check = M->getValueAsString("TargetCheck");
        if (!Opcode.empty())
          OS << "{llvm::Instruction::" << Opcode << ", nullptr}";
        else
          OS << "{0, [](const llvm::Instruction &Target) { return " << Check
             << "; }}";
      });
  endHeader(OS, "METAPHIR_MATCHING_OPCODE_MATCHERS_INC", {"instruction"});
}

TableGen::Emitter::Opt X("gen-instructions", emitInstructions,
                         "Generate the instruction matchers and flags");
TableGen::Emitter::Opt Y("gen-opcode-matchers", emitOpcodeMatchers,
                         "Generate the matchers of instruction opcodes");

} // namespace
