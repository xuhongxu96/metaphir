#include "metaphir/Matching/MatchersDetail.h"
#include "metaphir/IR/Values.h"
#include "llvm/IR/Constants.h"

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

std::optional<APInt> getConstantInteger(const llvm::Value &V) {
  if (const auto *Integer = dyn_cast<ConstantInt>(&V))
    return Integer->getValue();
  if (const auto *Constant = dyn_cast<llvm::Constant>(&V))
    if (Constant->getType()->isVectorTy())
      if (const auto *Splat = dyn_cast_or_null<ConstantInt>(
              Constant->getSplatValue(/*AllowPoison=*/true)))
        return Splat->getValue();
  return std::nullopt;
}

} // namespace detail
} // namespace metaphir
} // namespace llvm
