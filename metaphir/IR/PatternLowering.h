#ifndef METAPHIR_IR_PATTERN_LOWERING_H
#define METAPHIR_IR_PATTERN_LOWERING_H

#include "metaphir/IR/PatternVariants.h"
#include "metaphir/IR/SourceRange.h"
#include "llvm/Support/Error.h"

namespace llvm {
namespace metaphir {

class MIRContext;
class Pattern;

/// An error in lowering a pattern, at the source text it is about.
class LoweringError : public ErrorInfo<LoweringError> {
public:
  static char ID;
  SourceRange Range;
  std::string Message;

  LoweringError(SourceRange Range, const Twine &Message)
      : Range(Range), Message(Message.str()) {}

  void log(raw_ostream &OS) const override { OS << Message; }
  std::error_code convertToErrorCode() const override {
    return inconvertibleErrorCode();
  }
};

/// Prints the errors of lowering a pattern parsed with SM, each with its
/// source line when SM or Context's libraries hold it.
void printLoweringErrors(Error E, const SourceMgr &SM,
                         const MIRContext &Context, raw_ostream &OS,
                         const char *ProgName = nullptr,
                         bool ShowColors = false);

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
