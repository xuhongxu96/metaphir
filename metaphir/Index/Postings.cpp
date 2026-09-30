#include "metaphir/Index/Postings.h"
#include "metaphir/Matching/FeatureQuery.h"
#include "llvm/ADT/STLExtras.h"
#include "llvm/Support/DataExtractor.h"
#include "llvm/Support/Endian.h"
#include "llvm/Support/EndianStream.h"
#include "llvm/Support/LEB128.h"
#include "llvm/Support/raw_ostream.h"
#include <algorithm>
#include <iterator>

namespace llvm {
namespace metaphir {

PostingKey PostingRecord::readKey(const char *Record) {
  return PostingKey{PostingKey::KeyKind(uint8_t(Record[0])),
                    support::endian::read64le(Record + 1)};
}

PostingRecord PostingRecord::read(const char *Record) {
  PostingRecord Read;
  Read.Key = readKey(Record);
  Read.Count = support::endian::read32le(Record + 9);
  Read.Offset = support::endian::read64le(Record + 13);
  return Read;
}

void PostingRecord::write(raw_ostream &OS) const {
  support::endian::Writer W(OS, llvm::endianness::little);
  W.write<uint8_t>(Key.Kind);
  W.write<uint64_t>(Key.Value);
  W.write<uint32_t>(Count);
  W.write<uint64_t>(Offset);
}

SmallVector<PostingKey, 8>
getPostingKeys(const FeatureRequirement &Requirement) {
  FunctionFeatures Required;
  Required.Instructions = Requirement.Instructions;
  for (auto [User, Operand] : Requirement.Edges)
    Required.Edges.push_back(FunctionFeatures::getEdgeKey(User, Operand));
  Required.Siblings.assign(Requirement.Siblings.begin(),
                           Requirement.Siblings.end());
  Required.Globals.assign(Requirement.Globals.begin(),
                          Requirement.Globals.end());
  SmallVector<PostingKey, 8> Keys;
  forEachPostingKey(Required,
                    [&](const PostingKey &Key) { Keys.push_back(Key); });
  return Keys;
}

std::optional<std::vector<SmallVector<PostingKey, 3>>>
choosePostingKeys(const FeatureQuery &Query,
                  function_ref<uint64_t(const PostingKey &)> Count) {
  // The shortest few lists narrow the most.
  constexpr size_t MaxIntersected = 3;
  std::vector<SmallVector<PostingKey, 3>> Chosen(Query.size());
  for (unsigned Variant = 0; Variant != Query.size(); ++Variant) {
    SmallVector<std::pair<uint64_t, PostingKey>, 8> Keys;
    for (const PostingKey &Key : getPostingKeys(Query.getRequirement(Variant)))
      Keys.push_back({Count(Key), Key});
    if (Keys.empty())
      return std::nullopt;
    llvm::sort(Keys,
               [](const auto &L, const auto &R) { return L.first < R.first; });
    if (Keys.front().first == 0)
      continue;
    for (size_t I = 0; I != std::min(Keys.size(), MaxIntersected); ++I)
      Chosen[Variant].push_back(Keys[I].second);
  }
  return Chosen;
}

std::vector<uint32_t>
combinePostings(ArrayRef<SmallVector<PostingKey, 3>> Chosen,
                function_ref<ArrayRef<uint32_t>(const PostingKey &)> Lists) {
  std::vector<uint32_t> Candidates;
  for (const SmallVector<PostingKey, 3> &Keys : Chosen) {
    if (Keys.empty())
      continue;
    ArrayRef<uint32_t> First = Lists(Keys.front());
    std::vector<uint32_t> Matching(First.begin(), First.end());
    for (const PostingKey &Key : drop_begin(Keys)) {
      ArrayRef<uint32_t> Numbers = Lists(Key);
      std::vector<uint32_t> Common;
      std::set_intersection(Matching.begin(), Matching.end(), Numbers.begin(),
                            Numbers.end(), std::back_inserter(Common));
      Matching = std::move(Common);
    }
    std::vector<uint32_t> Union;
    std::set_union(Candidates.begin(), Candidates.end(), Matching.begin(),
                   Matching.end(), std::back_inserter(Union));
    Candidates = std::move(Union);
  }
  return Candidates;
}

Expected<std::vector<uint32_t>> readPostingList(StringRef Lists,
                                                uint64_t Offset, uint32_t Count,
                                                uint32_t NumFunctions) {
  DataExtractor Data(Lists, /*IsLittleEndian=*/true);
  DataExtractor::Cursor C(Offset);
  std::vector<uint32_t> Numbers;
  Numbers.reserve(Count);
  uint64_t Number = 0;
  for (uint32_t I = 0; I != Count && C; ++I) {
    Number += Data.getULEB128(C);
    Numbers.push_back(Number);
  }
  if (!C)
    return C.takeError();
  if (!Numbers.empty() && Numbers.back() >= NumFunctions)
    return createStringError("posting past the last function");
  return Numbers;
}

void writePostingList(raw_ostream &OS, ArrayRef<uint32_t> Numbers) {
  uint32_t Previous = 0;
  for (uint32_t N : Numbers) {
    encodeULEB128(N - Previous, OS);
    Previous = N;
  }
}

} // namespace metaphir
} // namespace llvm
