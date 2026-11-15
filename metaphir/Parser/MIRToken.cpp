#include "metaphir/Parser/MIRToken.h"
#include "llvm/Support/ErrorHandling.h"

namespace llvm {
namespace metaphir {
namespace tok {

StringRef getTokenKindName(Kind Kind) {
  switch (Kind) {
#define MIR_TOKEN_KIND(KIND)                                                   \
  case KIND:                                                                   \
    return #KIND;
#include "MIRTokenKinds.def"
  }
  llvm_unreachable("invalid token kind");
}

} // namespace tok
} // namespace metaphir
} // namespace llvm