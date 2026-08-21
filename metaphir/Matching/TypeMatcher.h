#ifndef METAPHIR_MATCHING_TYPE_MATCHER_H
#define METAPHIR_MATCHING_TYPE_MATCHER_H

#include "metaphir/IR/Instruction.h"
#include "metaphir/Matching/Instantiation.h"

namespace llvm {
class Type;
namespace metaphir {

class Type;
class SequenceType;

// Matches a MetaphIR type matcher against a concrete LLVM type, optionally
// treating scalar integer types as matching vector element types. Instances are
// cheap to construct on demand; the only state is the treatIntAsVec flag.
class TypeMatcher {
public:
  explicit TypeMatcher(const Type &Matcher, const llvm::Type &Target,
                       Instantiation &State, bool TreatIntAsVec = false)
      : Matcher(Matcher), Target(Target), State(State),
        TreatIntAsVec(TreatIntAsVec) {}

  TypeMatcher(const TypeMatcher &) = delete;
  TypeMatcher(TypeMatcher &&) = delete;

  bool match() const;

private:
  bool matchSequenceType(const SequenceType &Matcher,
                         const llvm::Type &TargetElement,
                         uint64_t TargetCount) const;

  const Type &Matcher;
  const llvm::Type &Target;
  Instantiation &State;

  bool TreatIntAsVec;
};

} // namespace metaphir
} // namespace llvm

#endif
