#include "metaphir/Dialect/Pattern/SourceLocation.h"
#include "mlir/IR/BuiltinAttributes.h"
#include "mlir/IR/Location.h"
#include "mlir/Support/TypeID.h"
#include "llvm/Support/SourceMgr.h"

using namespace mlir;

namespace llvm {
namespace metaphir {

namespace {
/// Tags the OpaqueLocs holding pointers into pattern source text.
struct SourcePointerTag {};
} // namespace

} // namespace metaphir
} // namespace llvm

MLIR_DECLARE_EXPLICIT_TYPE_ID(llvm::metaphir::SourcePointerTag)
MLIR_DEFINE_EXPLICIT_TYPE_ID(llvm::metaphir::SourcePointerTag)

namespace llvm {
namespace metaphir {

static Location pointerLoc(MLIRContext *Context, SMLoc Loc, Location Fallback) {
  return OpaqueLoc::get(reinterpret_cast<uintptr_t>(Loc.getPointer()),
                        TypeID::get<SourcePointerTag>(), Fallback);
}

Location getLocation(MLIRContext *Context, const SourceMgr &SM, SMRange Range) {
  if (!Range.Start.isValid())
    return UnknownLoc::get(Context);
  Location Fallback = UnknownLoc::get(Context);
  if (unsigned Buffer = SM.FindBufferContainingLoc(Range.Start)) {
    auto [Line, Column] = SM.getLineAndColumn(Range.Start, Buffer);
    StringRef Name = SM.getMemoryBuffer(Buffer)->getBufferIdentifier();
    Fallback = FileLineColLoc::get(Context, Name, Line, Column);
  }
  SMLoc End = Range.End.isValid() ? Range.End : Range.Start;
  return FusedLoc::get(Context,
                       {pointerLoc(Context, Range.Start, Fallback),
                        pointerLoc(Context, End, Fallback)},
                       StringAttr::get(Context, "mpir.range"));
}

/// The range of a location getLocation made, if Loc is one.
static std::optional<SMRange> ownRange(Location Loc) {
  auto Fused = dyn_cast<FusedLoc>(Loc);
  if (!Fused || Fused.getLocations().size() != 2)
    return std::nullopt;
  auto Begin = dyn_cast<OpaqueLoc>(Fused.getLocations()[0]);
  auto End = dyn_cast<OpaqueLoc>(Fused.getLocations()[1]);
  if (!Begin || !End ||
      Begin.getUnderlyingTypeID() != TypeID::get<SourcePointerTag>())
    return std::nullopt;
  return SMRange(SMLoc::getFromPointer(reinterpret_cast<const char *>(
                     Begin.getUnderlyingLocation())),
                 SMLoc::getFromPointer(reinterpret_cast<const char *>(
                     End.getUnderlyingLocation())));
}

SMRange getSourceRange(Location Loc) {
  if (std::optional<SMRange> Range = ownRange(Loc))
    return *Range;
  if (auto Call = dyn_cast<CallSiteLoc>(Loc))
    return getSourceRange(Call.getCallee());
  return SMRange();
}

SMRange getOutermostSourceRange(Location Loc) {
  if (auto Call = dyn_cast<CallSiteLoc>(Loc))
    return getOutermostSourceRange(Call.getCaller());
  return getSourceRange(Loc);
}

} // namespace metaphir
} // namespace llvm
