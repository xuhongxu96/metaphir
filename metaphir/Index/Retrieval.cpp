#include "metaphir/Index/Retrieval.h"
#include <algorithm>
#include <iterator>

namespace llvm {
namespace metaphir {

using Set = std::optional<std::vector<uint32_t>>;

Expected<Set> RetrievalPlan::eval(
    unsigned Index, function_ref<uint64_t(const PostingKey &)> Count,
    function_ref<Expected<ArrayRef<uint32_t>>(const PostingKey &)> List) const {
  const Node &N = Nodes[Index];
  switch (N.K) {
  case Kind::Universe:
    return Set();
  case Kind::Postings: {
    Expected<ArrayRef<uint32_t>> Numbers = List(N.Key);
    if (!Numbers)
      return Numbers.takeError();
    return Set(std::vector<uint32_t>(Numbers->begin(), Numbers->end()));
  }
  case Kind::Union: {
    std::vector<uint32_t> Result;
    for (unsigned Child : N.Children) {
      Expected<Set> Sub = eval(Child, Count, List);
      if (!Sub)
        return Sub.takeError();
      if (!*Sub)
        return Set();
      std::vector<uint32_t> Merged;
      std::set_union(Result.begin(), Result.end(), (*Sub)->begin(),
                     (*Sub)->end(), std::back_inserter(Merged));
      Result = std::move(Merged);
    }
    return Set(std::move(Result));
  }
  case Kind::Intersect: {
    // The shortest few lists, and every other operand.
    SmallVector<std::pair<uint64_t, unsigned>, 4> Lists;
    SmallVector<unsigned, 4> Others;
    for (unsigned Child : N.Children) {
      if (Nodes[Child].K == Kind::Postings)
        Lists.push_back({Count(Nodes[Child].Key), Child});
      else
        Others.push_back(Child);
    }
    llvm::sort(Lists);
    if (!Lists.empty() && Lists.front().first == 0)
      return Set(std::vector<uint32_t>());
    SmallVector<unsigned, 4> Read;
    for (size_t I = 0; I != std::min(Lists.size(), MaxIntersected); ++I)
      Read.push_back(Lists[I].second);
    Read.append(Others.begin(), Others.end());
    Set Result;
    for (unsigned Child : Read) {
      Expected<Set> Sub = eval(Child, Count, List);
      if (!Sub)
        return Sub.takeError();
      if (!*Sub)
        continue;
      if (!Result) {
        Result = std::move(*Sub);
      } else {
        std::vector<uint32_t> Common;
        std::set_intersection(Result->begin(), Result->end(), (*Sub)->begin(),
                              (*Sub)->end(), std::back_inserter(Common));
        Result = std::move(Common);
      }
      if (Result->empty())
        break;
    }
    return Result;
  }
  }
  llvm_unreachable("invalid retrieval node");
}

Expected<Set> RetrievalPlan::evaluate(
    function_ref<uint64_t(const PostingKey &)> Count,
    function_ref<Expected<ArrayRef<uint32_t>>(const PostingKey &)> List) const {
  if (Nodes.empty())
    return Set();
  return eval(Root, Count, List);
}

bool RetrievalPlan::choose(unsigned Index,
                           function_ref<uint64_t(const PostingKey &)> Count,
                           SmallVectorImpl<PostingKey> &Keys) const {
  const Node &N = Nodes[Index];
  auto Add = [&](const PostingKey &Key) {
    if (!is_contained(Keys, Key))
      Keys.push_back(Key);
  };
  switch (N.K) {
  case Kind::Universe:
    return false;
  case Kind::Postings:
    Add(N.Key);
    return true;
  case Kind::Union: {
    bool Narrowed = true;
    for (unsigned Child : N.Children)
      Narrowed &= choose(Child, Count, Keys);
    return Narrowed;
  }
  case Kind::Intersect: {
    // As eval reads them: the shortest few lists, unless one is empty, and
    // every other operand.
    SmallVector<std::pair<uint64_t, unsigned>, 4> Lists;
    SmallVector<unsigned, 4> Others;
    for (unsigned Child : N.Children) {
      if (Nodes[Child].K == Kind::Postings)
        Lists.push_back({Count(Nodes[Child].Key), Child});
      else
        Others.push_back(Child);
    }
    llvm::sort(Lists);
    if (!Lists.empty() && Lists.front().first == 0)
      return true;
    bool Narrowed = false;
    for (size_t I = 0; I != std::min(Lists.size(), MaxIntersected); ++I) {
      Add(Nodes[Lists[I].second].Key);
      Narrowed = true;
    }
    for (unsigned Child : Others)
      Narrowed |= choose(Child, Count, Keys);
    return Narrowed;
  }
  }
  llvm_unreachable("invalid retrieval node");
}

std::optional<SmallVector<PostingKey, 8>> RetrievalPlan::chooseLists(
    function_ref<uint64_t(const PostingKey &)> Count) const {
  SmallVector<PostingKey, 8> Keys;
  if (Nodes.empty() || !choose(Root, Count, Keys))
    return std::nullopt;
  return Keys;
}

SmallVector<PostingKey, 8> RetrievalPlan::getKeys() const {
  SmallVector<PostingKey, 8> Keys;
  for (const Node &N : Nodes)
    if (N.K == Kind::Postings && !is_contained(Keys, N.Key))
      Keys.push_back(N.Key);
  return Keys;
}

} // namespace metaphir
} // namespace llvm
