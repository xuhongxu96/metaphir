#include "metaphir/Index/Retrieval.h"
#include <algorithm>
#include <iterator>

namespace llvm {
namespace metaphir {

/// Adds Key to Keys if it is not there yet.
static void addKey(SmallVectorImpl<PostingKey> &Keys, const PostingKey &Key) {
  if (!is_contained(Keys, Key))
    Keys.push_back(Key);
}

std::optional<SmallVector<unsigned, 4>>
RetrievalPlan::readSets(const Intersect &I, CountFn Count) const {
  SmallVector<std::pair<uint64_t, unsigned>, 4> Lists;
  SmallVector<unsigned, 4> Others;
  for (unsigned Set : I.Sets) {
    if (const auto *P = std::get_if<Postings>(&Nodes[Set]))
      Lists.push_back({Count(P->Key), Set});
    else
      Others.push_back(Set);
  }
  llvm::sort(Lists);
  if (!Lists.empty() && Lists.front().first == 0)
    return std::nullopt;
  SmallVector<unsigned, 4> Read;
  for (size_t Index = 0; Index != std::min(Lists.size(), MaxIntersected);
       ++Index)
    Read.push_back(Lists[Index].second);
  Read.append(Others.begin(), Others.end());
  return Read;
}

Expected<RetrievalPlan::Set> RetrievalPlan::eval(unsigned Index, CountFn Count,
                                                 ListFn List) const {
  return std::visit([&](const auto &N) { return eval(N, Count, List); },
                    Nodes[Index]);
}

Expected<RetrievalPlan::Set> RetrievalPlan::eval(const Postings &P, CountFn,
                                                 ListFn List) const {
  Expected<ArrayRef<uint32_t>> Numbers = List(P.Key);
  if (!Numbers)
    return Numbers.takeError();
  return Set(std::vector<uint32_t>(Numbers->begin(), Numbers->end()));
}

Expected<RetrievalPlan::Set>
RetrievalPlan::eval(const Intersect &I, CountFn Count, ListFn List) const {
  std::optional<SmallVector<unsigned, 4>> Read = readSets(I, Count);
  if (!Read)
    return Set(std::vector<uint32_t>());
  Set Result;
  for (unsigned Index : *Read) {
    Expected<Set> Sub = eval(Index, Count, List);
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

Expected<RetrievalPlan::Set> RetrievalPlan::eval(const Union &U, CountFn Count,
                                                 ListFn List) const {
  std::vector<uint32_t> Result;
  for (unsigned Index : U.Sets) {
    Expected<Set> Sub = eval(Index, Count, List);
    if (!Sub)
      return Sub.takeError();
    if (!*Sub)
      return Set();
    std::vector<uint32_t> Merged;
    std::set_union(Result.begin(), Result.end(), (*Sub)->begin(), (*Sub)->end(),
                   std::back_inserter(Merged));
    Result = std::move(Merged);
  }
  return Set(std::move(Result));
}

Expected<RetrievalPlan::Set> RetrievalPlan::evaluate(CountFn Count,
                                                     ListFn List) const {
  if (Nodes.empty())
    return Set();
  return eval(Root, Count, List);
}

bool RetrievalPlan::choose(unsigned Index, CountFn Count,
                           SmallVectorImpl<PostingKey> &Keys) const {
  return std::visit([&](const auto &N) { return choose(N, Count, Keys); },
                    Nodes[Index]);
}

bool RetrievalPlan::choose(const Postings &P, CountFn,
                           SmallVectorImpl<PostingKey> &Keys) const {
  addKey(Keys, P.Key);
  return true;
}

bool RetrievalPlan::choose(const Intersect &I, CountFn Count,
                           SmallVectorImpl<PostingKey> &Keys) const {
  // As eval reads them.
  std::optional<SmallVector<unsigned, 4>> Read = readSets(I, Count);
  if (!Read)
    return true;
  bool Narrowed = false;
  for (unsigned Index : *Read)
    Narrowed |= choose(Index, Count, Keys);
  return Narrowed;
}

bool RetrievalPlan::choose(const Union &U, CountFn Count,
                           SmallVectorImpl<PostingKey> &Keys) const {
  bool Narrowed = true;
  for (unsigned Index : U.Sets)
    Narrowed &= choose(Index, Count, Keys);
  return Narrowed;
}

std::optional<SmallVector<PostingKey, 8>>
RetrievalPlan::chooseLists(CountFn Count) const {
  SmallVector<PostingKey, 8> Keys;
  if (Nodes.empty() || !choose(Root, Count, Keys))
    return std::nullopt;
  return Keys;
}

SmallVector<PostingKey, 8> RetrievalPlan::getKeys() const {
  SmallVector<PostingKey, 8> Keys;
  for (const Node &N : Nodes)
    if (const auto *P = std::get_if<Postings>(&N))
      addKey(Keys, P->Key);
  return Keys;
}

} // namespace metaphir
} // namespace llvm
