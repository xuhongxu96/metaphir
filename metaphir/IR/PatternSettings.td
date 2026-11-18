//===- PatternSettings.td - The `;; name(true|false)` settings --*- tablegen -*-===//
//
// Generated into PatternSettings.inc by metaphir-tblgen -gen-pattern-settings.
//
//===----------------------------------------------------------------------===//

/// A global pattern setting, written `;; <name>(true|false)`. The record's
/// name is its keyword.
class PatternSetting {
  /// The setting is the mask 1 << Bit.
  int Bit;
  string Comment;
  /// Whether the setting is on until a pattern writes it.
  bit Default = 0;
}

def treatIntAsVec : PatternSetting {
  let Bit = 0;
  let Comment = "a scalar integer type/constant also matches vectors";
}
