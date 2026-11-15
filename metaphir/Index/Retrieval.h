//===- Retrieval.h - Finding functions from posting lists -------*- C++ -*-===//
//
// A retrieval plan: a set expression over posting lists (unions,
// intersections, lists and the universe), as an mpir_index.retrieve
// computes it, and its evaluation against an index. An intersection reads
// only its shortest few lists: the functions it finds are a superset still,
// and the features are checked after.
//
//===----------------------------------------------------------------------===//

#ifndef METAPHIR_INDEX_RETRIEVAL_H
#define METAPHIR_INDEX_RETRIEVAL_H

#include "metaphir/Index/Postings.h"
#include "llvm/ADT/STLFunctionalExtras.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/Support/Error.h"
#include <optional>
#include <vector>

namespace llvm {
namespace metaphir {

class RetrievalPlan {
public:
  enum class Kind : uint8_t { Postings, Intersect, Union, Universe };
  struct Node {
    Kind K;
    PostingKey Key{PostingKey::Instruction, 0};
    SmallVector<unsigned, 4> Children;
  };

  unsigned add(Node N) {
    Nodes.push_back(std::move(N));
    return Nodes.size() - 1;
  }
  void setRoot(unsigned Index) { Root = Index; }

  /// The most lists an intersection reads.
  static constexpr size_t MaxIntersected = 3;

  /// The functions the plan finds, sorted; std::nullopt for every function.
  /// Count tells how many functions a list has, and List reads it.
  Expected<std::optional<std::vector<uint32_t>>>
  evaluate(function_ref<uint64_t(const PostingKey &)> Count,
           function_ref<Expected<ArrayRef<uint32_t>>(const PostingKey &)> List)
      const;

  /// The keys whose lists evaluating may read.
  SmallVector<PostingKey, 8> getKeys() const;

private:
  Expected<std::optional<std::vector<uint32_t>>>
  eval(unsigned Index, function_ref<uint64_t(const PostingKey &)> Count,
       function_ref<Expected<ArrayRef<uint32_t>>(const PostingKey &)> List)
      const;

  std::vector<Node> Nodes;
  unsigned Root = 0;
};

} // namespace metaphir
} // namespace llvm

#endif // METAPHIR_INDEX_RETRIEVAL_H
