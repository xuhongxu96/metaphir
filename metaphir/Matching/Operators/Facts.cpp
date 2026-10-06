#include "metaphir/Matching/Operators/Facts.h"
#include "llvm/Analysis/ValueTracking.h"

namespace llvm {
namespace metaphir {

static constexpr unsigned NumValueClasses = 0
#define MIR_LLVM_VALUE_CLASS(Class) +1
#include "metaphir/Matching/LLVMValueClasses.def"
    ;

StringRef Atom::getName(Predicate P) {
  static constexpr StringLiteral Names[] = {
#define MIR_FACT(ID, Name) Name,
#include "metaphir/Matching/Operators/Facts.def"
  };
  return Names[P];
}

StringRef getMeasureName(Measure M) {
  static constexpr StringLiteral Names[] = {
#define MIR_MEASURE(ID, Name) Name,
#include "metaphir/Matching/Operators/Facts.def"
  };
  return Names[size_t(M)];
}

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
