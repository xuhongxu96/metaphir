#include "metaphir/Matching/MatchersDetail.h"
#include "metaphir/IR/Values.h"

namespace llvm {
namespace metaphir {
namespace detail {

MatchResults success(Instantiation State) {
  MatchResults Results;
  Results.push_back(std::move(State));
  return Results;
}

bool bind(Instantiation &State, const Value &Matcher,
          Instantiation::Binding Target) {
  if (const Instantiation::Binding *Existing = State.lookup(Matcher))
    return *Existing == Target;
  State.bind(Matcher, std::move(Target));
  return true;
}

} // namespace detail
} // namespace metaphir
} // namespace llvm
