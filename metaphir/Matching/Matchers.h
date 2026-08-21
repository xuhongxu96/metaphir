#ifndef METAPHIR_MATCHING_MATCHERS_H
#define METAPHIR_MATCHING_MATCHERS_H

#include "metaphir/Matching/Instantiation.h"
#include "llvm/ADT/STLFunctionalExtras.h"
#include "llvm/ADT/SmallVector.h"

namespace llvm {
class Type;
class Value;
namespace metaphir {

class Instruction;
class Type;
class Value;

using MatchResults = SmallVector<Instantiation, 4>;

class MatchDriver {
public:
  using MatchFunction =
      function_ref<MatchResults(const metaphir::Value &, const llvm::Value &,
                                Instantiation, const MatchDriver &)>;

  explicit MatchDriver(MatchFunction Match) : MatchFn(Match) {}

  MatchResults match(const metaphir::Value &Pattern, const llvm::Value &Target,
                     Instantiation State) const {
    return MatchFn(Pattern, Target, std::move(State), *this);
  }

private:
  MatchFunction MatchFn;
};

MatchResults matchValue(const metaphir::Value &Matcher,
                        const llvm::Value &Target, Instantiation State,
                        const MatchDriver &Driver);

bool matchType(const metaphir::Type &Matcher, const llvm::Type &Target,
               Instantiation &State, bool TreatIntAsVec = false);
bool matchValue(const metaphir::Value &Matcher, const llvm::Value &Target,
                Instantiation &State);

namespace detail {

MatchResults success(Instantiation State);
bool bind(Instantiation &State, const Value &Matcher,
          Instantiation::Binding Target);
MatchResults matchInstruction(const Instruction &Matcher,
                              const llvm::Value &Target, Instantiation State,
                              const MatchDriver &Driver);

} // namespace detail

} // namespace metaphir
} // namespace llvm

#endif
