#ifndef METAPHIR_IR_PATTERNSETTINGS_H
#define METAPHIR_IR_PATTERNSETTINGS_H

#include "metaphir/IR/PatternSettings.inc"
#include "llvm/Support/ErrorHandling.h"
#include <cstdint>

namespace llvm {
namespace metaphir {

namespace pattern_setting {

/// Whether a setting is on until a pattern writes it.
constexpr bool getDefault(Setting Flag) { return DefaultMask & uint64_t(Flag); }

/// The keyword of a setting, for error messages.
inline StringRef getName(Setting Flag) {
  for (const SettingKeyword &S : Keywords)
    if (S.Flag == Flag)
      return S.Keyword;
  llvm_unreachable("invalid pattern setting");
}

} // namespace pattern_setting

// Encapsulates global pattern settings, applied at a `;; <name>(true|false)`
// directive and active for the instructions that follow it. Stored as an ORed
// bitmask so more settings can be added later; the Setting enum is generated
// from PatternSettings.td. Callers query/update through methods rather than
// manipulating raw bits.
class PatternSettings {
public:
  using Setting = pattern_setting::Setting;
  static constexpr Setting None = pattern_setting::None;

  PatternSettings() = default;
  explicit PatternSettings(uint64_t Mask) : Mask(Mask), Specified(Mask) {}

  bool has(Setting Flag) const { return Mask & uint64_t(Flag); }
  /// Whether Flag was written, to either value.
  bool isSpecified(Setting Flag) const { return Specified & uint64_t(Flag); }
  void set(Setting Flag) {
    Mask |= uint64_t(Flag);
    Specified |= uint64_t(Flag);
  }
  void clear(Setting Flag) {
    Mask &= ~uint64_t(Flag);
    Specified |= uint64_t(Flag);
  }

  /// Settings for an instruction placed at Outer's position: Outer's values
  /// apply, except for settings written here, which take precedence. Used when
  /// a 'match' body is inlined into a use site.
  PatternSettings inheritedFrom(PatternSettings Outer) const {
    PatternSettings Result;
    Result.Mask = (Outer.Mask & ~Specified) | (Mask & Specified);
    Result.Specified = Outer.Specified | Specified;
    return Result;
  }

private:
  uint64_t Mask = pattern_setting::DefaultMask;
  /// Bits for the settings written explicitly, so an inlined body can override
  /// its use site rather than silently resetting it.
  uint64_t Specified = None;
};

} // namespace metaphir
} // namespace llvm

#endif // METAPHIR_IR_PATTERNSETTINGS_H
