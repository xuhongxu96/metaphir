#include "metaphir/Parser/MIRToken.h"

namespace llvm {
namespace metaphir {
namespace tok {

StringRef getTokenKindName(Kind Kind) {
  switch (Kind) {
  case StartOfKind:
    return "StartOfKind";

#define MIR_TOKEN_KIND(KIND)                                                   \
  case KIND:                                                                   \
    return #KIND;
#include "MIRTokenKinds.def"

  case EndOfKind:
    return "EndOfKind";
  }
  return "<unknown>";
}

} // namespace tok
} // namespace metaphir
} // namespace llvm