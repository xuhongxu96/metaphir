//===- MetaFlagEmitter.cpp - the built-in metaflags
//------------------------===//
//
// -gen-metaflags: metaphir/IR/MetaFlag.inc, the built-in metaflags and what
// each accepts.
//
//===----------------------------------------------------------------------===//

#include "Emit.h"
#include "Records.h"

using namespace llvm;
using namespace metaphir_tblgen;

namespace {

void emitMetaFlags(const RecordKeeper &Records, raw_ostream &OS) {
  auto Flags = getDefinitionsInOrder(Records, "MetaFlag");
  for (const Record *F : Flags) {
    StringRef Placement = F->getValueAsString("Placement");
    if (Placement != "InstructionPlacement" &&
        Placement != "OperandPlacement" && Placement != "AnyPlacement")
      PrintFatalError(F, "unknown placement '" + Placement + "'");
    StringRef Kind = F->getValueAsString("Arguments");
    if (Kind != "AnyArgument" && Kind != "IntegerArgument" &&
        Kind != "FlagArgument")
      PrintFatalError(F, "unknown argument kind '" + Kind + "'");
    int64_t Max = F->getValueAsInt("MaxArguments");
    if (Max != -1 && Max < F->getValueAsInt("MinArguments"))
      PrintFatalError(F, "the flag takes fewer arguments than its minimum");
  }

  beginHeader(OS, Records, "The built-in metaflags",
              "METAPHIR_IR_META_FLAG_INC", {"llvm/ADT/StringRef.h"},
              {"metaflag"});
  OS << "// The data of the metaflags; metaphir/IR/MetaFlag.h reads it.\n\n"
        "enum MetaFlagID {\n  UnknownMetaFlag,\n";
  for (const Record *F : Flags)
    OS << "  MF_" << F->getValueAsString("Name") << ",\n";
  OS << "};\n\n"
        "enum Placement {\n  InstructionPlacement = 1,\n"
        "  OperandPlacement = 2,\n"
        "  AnyPlacement = InstructionPlacement | OperandPlacement\n};\n\n"
        "enum ArgumentKind { AnyArgument, IntegerArgument, FlagArgument };\n\n"
        "constexpr unsigned UnlimitedArgs = ~0u;\n\n"
        "/// What a built-in metaflag accepts.\nstruct Schema {\n"
        "  Placement AllowedPlacement;\n  unsigned MinArguments;\n"
        "  unsigned MaxArguments;\n  ArgumentKind Arguments;\n"
        "  /// Whether the flag changes how the instruction itself is matched. It is\n"
        "  /// not lowered to a constraint.\n"
        "  bool Structural;\n"
        "  /// Whether the flag may be an argument of another metaflag.\n"
        "  bool Nestable;\n};\n\n"
        "/// A built-in metaflag: its name, and what it accepts.\n"
        "struct BuiltIn {\n  StringRef Name;\n  Schema Accepts;\n};\n\n"
        "/// In the order of MetaFlagID, after UnknownMetaFlag.\n";
  emitArray<decltype(Flags), const Record *>(
      OS, "BuiltIn BuiltIns[]", Flags,
      [](raw_ostream &OS, const Record *const &F) {
        int64_t Max = F->getValueAsInt("MaxArguments");
        OS << "{\"" << F->getValueAsString("Name") << "\", {"
           << F->getValueAsString("Placement") << ", "
           << F->getValueAsInt("MinArguments") << ", "
           << (Max == -1 ? "UnlimitedArgs" : std::to_string(Max)) << ", "
           << F->getValueAsString("Arguments") << ", "
           << (F->getValueAsBit("Structural") ? "true" : "false") << ", "
           << (F->getValueAsBit("Nestable") ? "true" : "false") << "}}";
      });
  endHeader(OS, "METAPHIR_IR_META_FLAG_INC", {"metaflag"});
}

TableGen::Emitter::Opt X("gen-metaflags", emitMetaFlags,
                         "Generate the built-in metaflags");

} // namespace
