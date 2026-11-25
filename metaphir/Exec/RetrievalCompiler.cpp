#include "metaphir/Exec/RetrievalCompiler.h"
#include "metaphir/Dialect/Index/IndexDialect.h"
#include "metaphir/Matching/Features.h"

namespace llvm {
namespace metaphir {

RetrievalPlan compileRetrieval(mpir_index::RetrieveOp Retrieve) {
  RetrievalPlan Plan;
  DenseMap<mlir::Value, unsigned> Nodes;
  auto Sets = [&](mlir::ValueRange Operands) {
    SmallVector<unsigned, 4> Indices;
    for (mlir::Value S : Operands)
      Indices.push_back(Nodes.lookup(S));
    return Indices;
  };
  for (mlir::Operation &Op : Retrieve.getBody().front()) {
    std::optional<RetrievalPlan::Node> N;
    if (auto P = dyn_cast<mpir_index::PostingsOp>(Op)) {
      auto Kind = PostingKey::KeyKind(P.getKind());
      uint64_t Value =
          Kind == PostingKey::Global
              ? hashGlobalName(cast<mlir::StringAttr>(P.getKey()).getValue())
              : uint64_t(cast<mlir::IntegerAttr>(P.getKey()).getInt());
      N = RetrievalPlan::Postings{PostingKey{Kind, Value}};
    } else if (auto I = dyn_cast<mpir_index::IntersectOp>(Op)) {
      N = RetrievalPlan::Intersect{Sets(I.getSets())};
    } else if (auto U = dyn_cast<mpir_index::UnionOp>(Op)) {
      N = RetrievalPlan::Union{Sets(U.getSets())};
    } else if (isa<mpir_index::UniverseOp>(Op)) {
      N = RetrievalPlan::Universe();
    } else if (auto Result = dyn_cast<mpir_index::ResultOp>(Op)) {
      Plan.setRoot(Nodes.lookup(Result.getSet()));
    }
    if (N)
      Nodes[Op.getResult(0)] = Plan.add(std::move(*N));
  }
  return Plan;
}

} // namespace metaphir
} // namespace llvm
