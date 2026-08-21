#ifndef METAPHIR_MATCHING_MATCHERS_DETAIL_H
#define METAPHIR_MATCHING_MATCHERS_DETAIL_H

#include "metaphir/Matching/Instantiation.h"

namespace llvm {
namespace metaphir {

class Value;

namespace detail {

MatchResults success(Instantiation State);

bool bind(Instantiation &State, const Value &Matcher,
          Instantiation::Binding Target);

} // namespace detail
} // namespace metaphir
} // namespace llvm

#endif
