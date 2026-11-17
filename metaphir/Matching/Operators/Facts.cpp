#include "metaphir/Matching/Operators/Facts.h"
#include "metaphir/Matching/LLVMValueClasses.h"
#include "llvm/Analysis/ValueTracking.h"

namespace llvm {
namespace metaphir {

std::optional<Atom> Atom::literal(int64_t V) {
  if (V < MinLiteral || V > MaxLiteral)
    return std::nullopt;
  return Atom(uint16_t(LiteralBase + (V - MinLiteral)));
}

Atom Atom::valueClass(unsigned ClassIndex) {
  assert(ClassIndex < NumValueClasses && "invalid LLVM value class index");
  static_assert(ClassBase + NumValueClasses <= End,
                "LLVM value classes must fit in an atom");
  return Atom(uint16_t(ClassBase + ClassIndex));
}

FactSink::~FactSink() = default;

const KnownBits &RecordCall::knownBits() const {
  assert(Query && "known bits without value tracking");
  if (!Known)
    Known = computeKnownBits(&Value, *Query);
  return *Known;
}

} // namespace metaphir
} // namespace llvm
