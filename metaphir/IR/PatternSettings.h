#ifndef METAPHIR_IR_PATTERNSETTINGS_H
#define METAPHIR_IR_PATTERNSETTINGS_H

#include "llvm/ADT/StringRef.h"
#include <cstdint>

namespace llvm {
namespace metaphir {

// Encapsulates global pattern settings, applied at a `;; <name>(true|false)`
// directive and active for the instructions that follow it. Stored as an ORed
// bitmask so more settings can be added later; the Setting enum is generated
// from PatternSettings.def. Callers query/update through methods rather than
// manipulating raw bits.
class PatternSettings {
public:
  enum Setting : uint64_t {
    None = 0,
#define MIR_PATTERN_SETTING_ID(Name, Bit, Comment) Name = uint64_t(1) << Bit,
#include "metaphir/IR/PatternSettings.def"
  };

  PatternSettings() = default;
  explicit PatternSettings(uint64_t Mask) : Mask(Mask), Specified(Mask) {}

  bool has(Setting Flag) const { return Mask & uint64_t(Flag); }
  void set(Setting Flag) {
    Mask |= uint64_t(Flag);
    Specified |= uint64_t(Flag);
  }
  void clear(Setting Flag) {
    Mask &= ~uint64_t(Flag);
    Specified |= uint64_t(Flag);
  }

  /// Whether this setting was written here, as opposed to being left at its
  /// default or taken from an enclosing position.
  bool isSpecified(Setting Flag) const { return Specified & uint64_t(Flag); }

  /// Settings for an instruction placed at Outer's position: Outer's values
  /// apply, except for settings written here, which take precedence. Used when
  /// a 'match' body is inlined into a use site.
  PatternSettings inheritedFrom(PatternSettings Outer) const {
    PatternSettings Result;
    Result.Mask = (Outer.Mask & ~Specified) | (Mask & Specified);
    Result.Specified = Outer.Specified | Specified;
    return Result;
  }

  // Map a Setting back to its directive keyword (used in error messages).
  static StringRef getName(Setting Flag);

private:
  uint64_t Mask = None;
  /// Bits for the settings written explicitly, so an inlined body can override
  /// its use site rather than silently resetting it.
  uint64_t Specified = None;
};

} // namespace metaphir
} // namespace llvm

#endif // METAPHIR_IR_PATTERNSETTINGS_H
