//===- PatternSettingEmitter.cpp - the pattern settings
//--------------------===//
//
// -gen-pattern-settings: metaphir/IR/PatternSettings.inc, the data of the
// settings; metaphir/IR/PatternSettings.h reads it.
//
//===----------------------------------------------------------------------===//

#include "Emit.h"
#include "Records.h"

using namespace llvm;
using namespace metaphir_tblgen;

namespace {

void emitPatternSettings(const RecordKeeper &Records, raw_ostream &OS) {
  auto Settings = getDefinitionsInOrder(Records, "PatternSetting");
  for (const Record *S : Settings)
    if (S->getValueAsInt("Bit") < 0 || S->getValueAsInt("Bit") > 63)
      PrintFatalError(S, "the settings are bits of a 64-bit mask");

  beginHeader(OS, Records, "The pattern settings",
              "METAPHIR_IR_PATTERN_SETTINGS_INC",
              {"llvm/ADT/StringRef.h", "cstdint"}, {"pattern_setting"});
  OS << "/// A global setting, written `;; <name>(true|false)`. Settings are "
        "bits of a\n/// mask, so more can be added.\n"
        "enum Setting : uint64_t {\n  None = 0,\n";
  for (const Record *S : Settings)
    OS << "  " << S->getName() << " = uint64_t(1) << "
       << S->getValueAsInt("Bit") << ",  ///< "
       << S->getValueAsString("Comment") << "\n";
  OS << "};\n\n/// The settings that are on until a pattern writes them.\n"
        "inline constexpr uint64_t DefaultMask = 0";
  for (const Record *S : Settings)
    if (S->getValueAsBit("Default"))
      OS << " | " << S->getName();
  OS << ";\n\n/// A setting and its keyword.\nstruct SettingKeyword {\n"
        "  Setting Flag;\n  StringRef Keyword;\n};\n\n";
  emitArray<decltype(Settings), const Record *>(
      OS, "SettingKeyword Keywords[]", Settings,
      [](raw_ostream &OS, const Record *const &S) {
        OS << "{" << S->getName() << ", \"" << S->getName() << "\"}";
      });
  endHeader(OS, "METAPHIR_IR_PATTERN_SETTINGS_INC", {"pattern_setting"});
}

TableGen::Emitter::Opt X("gen-pattern-settings", emitPatternSettings,
                         "Generate the pattern settings");

} // namespace
