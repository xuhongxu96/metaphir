#ifndef METAPHIR_PARSER_MIR_TOKEN_H
#define METAPHIR_PARSER_MIR_TOKEN_H

#include "llvm/ADT/StringRef.h"

namespace llvm {
namespace metaphir {
namespace tok {

enum Kind {
  StartOfKind,

#define MIR_TOKEN_KIND(Kind) Kind,
#include "metaphir/Parser/MIRTokenKinds.def"

  EndOfKind,
};

StringRef getTokenKindName(Kind Kind);

} // namespace tok
} // namespace metaphir
} // namespace llvm

#endif
