//===- PatternSettings.td - The `;; name(true|false)` settings --*- tablegen -*-===//
//
// Generated into PatternSettings.inc by metaphir-tblgen -gen-pattern-settings.
//
//===----------------------------------------------------------------------===//

include "metaphir/IR/LanguageBase.td"

def treatIntAsVec
    : PatternSetting<0, "a scalar integer type/constant also matches vectors">;
