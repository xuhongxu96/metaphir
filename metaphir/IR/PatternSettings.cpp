#include "metaphir/IR/PatternSettings.h"
#include "llvm/Support/ErrorHandling.h"
#include <algorithm>

namespace llvm {
namespace metaphir {

// The setting mask is a uint64_t; verify the .def never assigns a bit index
// beyond 63 so the mask cannot overflow. Adding a setting past bit 63 fails to
// compile here rather than silently truncating the mask.
static constexpr unsigned getMaxSettingBit() {
  unsigned Max = 0;
#define MIR_PATTERN_SETTING_ID(Name, Bit, Comment)                             \
  Max = std::max(Max, static_cast<unsigned>(Bit));
#include "metaphir/IR/PatternSettings.def"
  return Max;
}
static_assert(getMaxSettingBit() < 64,
              "pattern settings exceed the 64-bit mask");

StringRef PatternSettings::getName(PatternSettings::Setting Flag) {
  switch (Flag) {
#define MIR_PATTERN_SETTING_ID(Name, Bit, Comment)                             \
  case Name:                                                                   \
    return #Name;
#include "metaphir/IR/PatternSettings.def"
  default:
    llvm_unreachable("invalid pattern setting");
  }
}

} // namespace metaphir
} // namespace llvm
