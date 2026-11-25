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
#include <variant>
#include <vector>

namespace llvm {
namespace metaphir {

class RetrievalPlan {
public:
  /// The functions in a posting list.
  struct Postings {
    PostingKey Key;
  };
  /// The functions in every one of Sets, the nodes it is of.
  struct Intersect {
    SmallVector<unsigned, 4> Sets;
  };
  /// The functions in any of Sets, the nodes it is of.
  struct Union {
    SmallVector<unsigned, 4> Sets;
  };
  /// Every function.
  struct Universe {};
  using Node = std::variant<Postings, Intersect, Union, Universe>;

  /// Adds N, whose sets are nodes added before it; returns its index.
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

  /// The keys whose lists evaluating reads, given Count; std::nullopt if the
  /// plan finds every function, reading none.
  std::optional<SmallVector<PostingKey, 8>>
  chooseLists(function_ref<uint64_t(const PostingKey &)> Count) const;

private:
  using Set = std::optional<std::vector<uint32_t>>;
  using CountFn = function_ref<uint64_t(const PostingKey &)>;
  using ListFn = function_ref<Expected<ArrayRef<uint32_t>>(const PostingKey &)>;

  /// The sets of I that evaluating reads: its shortest few posting lists,
  /// then every other set; std::nullopt if one of its lists is empty, so it
  /// is too.
  std::optional<SmallVector<unsigned, 4>> readSets(const Intersect &I,
                                                   CountFn Count) const;

  Expected<Set> eval(unsigned Index, CountFn Count, ListFn List) const;
  Expected<Set> eval(const Postings &P, CountFn Count, ListFn List) const;
  Expected<Set> eval(const Intersect &I, CountFn Count, ListFn List) const;
  Expected<Set> eval(const Union &U, CountFn Count, ListFn List) const;
  Expected<Set> eval(const Universe &, CountFn, ListFn) const { return Set(); }

  /// Adds the lists node Index reads to Keys; returns false if it is every
  /// function.
  bool choose(unsigned Index, CountFn Count,
              SmallVectorImpl<PostingKey> &Keys) const;
  bool choose(const Postings &P, CountFn Count,
              SmallVectorImpl<PostingKey> &Keys) const;
  bool choose(const Intersect &I, CountFn Count,
              SmallVectorImpl<PostingKey> &Keys) const;
  bool choose(const Union &U, CountFn Count,
              SmallVectorImpl<PostingKey> &Keys) const;
  bool choose(const Universe &, CountFn, SmallVectorImpl<PostingKey> &) const {
    return false;
  }

  std::vector<Node> Nodes;
  unsigned Root = 0;
};

} // namespace metaphir
} // namespace llvm

#endif // METAPHIR_INDEX_RETRIEVAL_H
