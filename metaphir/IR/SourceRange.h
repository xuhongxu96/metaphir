#ifndef METAPHIR_IR_SOURCERANGE_H
#define METAPHIR_IR_SOURCERANGE_H

#include "llvm/Support/SMLoc.h"

namespace llvm {
namespace metaphir {

/// The span of pattern source text an IR object was parsed from. Both ends
/// are null for objects built programmatically.
struct SourceRange {
  SMLoc Begin;
  SMLoc End;
};

} // namespace metaphir
} // namespace llvm

#endif // METAPHIR_IR_SOURCERANGE_H
