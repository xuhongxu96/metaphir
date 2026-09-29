#ifndef METAPHIR_IR_PATTERN_LOWERING_H
#define METAPHIR_IR_PATTERN_LOWERING_H

#include "metaphir/IR/PatternVariants.h"
#include "llvm/Support/Error.h"

namespace llvm {
namespace metaphir {

class MIRContext;
class Pattern;

/// Lowers a parsed pattern into the patterns the matcher runs:
///
///  1. Every use of a composite ('match') matcher is expanded into one pattern
///     per branch, and per operand order for a ':c' use. A branch whose
///     parameter types or fixed flags cannot fit the use is dropped. Each use
///     gets its own copies of the branch's local meta variables, so two uses
///     of one matcher bind them independently.
///  2. Metaflags are desugared into constraints on each resulting pattern.
class PatternLowering {
public:
  explicit PatternLowering(MIRContext &Context) : Context(Context) {}

  /// Lowers P. P itself is not modified; the returned patterns are owned by
  /// the context. A null P lowers to no patterns.
  Expected<PatternVariants> lower(const Pattern *P);

private:
  MIRContext &Context;
};

} // namespace metaphir
} // namespace llvm

#endif // METAPHIR_IR_PATTERN_LOWERING_H
