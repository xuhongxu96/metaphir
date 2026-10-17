#ifndef METAPHIR_MATCHING_VALUETRACKCONTEXT_H
#define METAPHIR_MATCHING_VALUETRACKCONTEXT_H

#include "llvm/Analysis/AssumptionCache.h"
#include "llvm/Analysis/DomConditionCache.h"
#include "llvm/Analysis/SimplifyQuery.h"
#include "llvm/Analysis/TargetLibraryInfo.h"
#include "llvm/IR/Dominators.h"
#include <optional>

namespace llvm {
class Instruction;
namespace metaphir {
namespace detail {

// Lazily-constructed, per-function analysis context for ValueTracking-backed
// constraint operators, and for the value facts the index records. Nothing is
// built until the first query for a function; that query builds all of its
// analyses (DominatorTree, AssumptionCache, DomConditionCache,
// TargetLibraryInfo) at once, and they are kept until the function changes or
// reset() is called.
class ValueTrackContext {
public:
  // Returns a query anchored at CtxI, materializing the enclosing function's
  // analyses on first use.
  SimplifyQuery getQuery(const llvm::Instruction *CtxI);

  // Drops every analysis. The cache is keyed on the function's address, so it
  // must be reset before that function is freed and the address reused.
  void reset();

  // Test-only introspection for the lazy-initialization property.
  bool hasMaterializedDominatorTree() const { return DT.has_value(); }
  bool hasMaterializedAssumptionCache() const { return AC.has_value(); }
  bool hasMaterializedTargetLibraryInfo() const { return TLI.has_value(); }

private:
  // Resets per-function components when the context instruction's function
  // changes, then ensures they are materialized. Returns the module's
  // DataLayout.
  const DataLayout &ensure(const llvm::Instruction *CtxI);

  const llvm::Function *F = nullptr;
  std::optional<llvm::DominatorTree> DT;
  std::optional<llvm::AssumptionCache> AC;
  std::optional<llvm::DomConditionCache> DC;
  std::optional<llvm::TargetLibraryInfoImpl> TLII;
  std::optional<llvm::TargetLibraryInfo> TLI;
};

} // namespace detail
} // namespace metaphir
} // namespace llvm

#endif // METAPHIR_MATCHING_VALUETRACKCONTEXT_H