#ifndef METAPHIR_IR_SOURCERANGE_H
#define METAPHIR_IR_SOURCERANGE_H

#include "llvm/Support/SMLoc.h"
#include "llvm/Support/SourceMgr.h"
#include <optional>

namespace llvm {
namespace metaphir {

/// The span of pattern source text an IR object was parsed from. Both ends
/// are null for objects built programmatically.
struct SourceRange {
  SMLoc Begin;
  SMLoc End;
};

/// The line of Loc in the main file of SM (the pattern parsed first), if it
/// is there rather than in a library.
inline std::optional<unsigned> getMainFileLine(const SourceMgr &SM, SMLoc Loc) {
  if (!Loc.isValid() || SM.getNumBuffers() == 0 ||
      SM.FindBufferContainingLoc(Loc) != SM.getMainFileID())
    return std::nullopt;
  return SM.getLineAndColumn(Loc, SM.getMainFileID()).first;
}

} // namespace metaphir
} // namespace llvm

#endif // METAPHIR_IR_SOURCERANGE_H
