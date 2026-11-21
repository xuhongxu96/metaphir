#ifndef METAPHIR_INDEX_POSTINGS_H
#define METAPHIR_INDEX_POSTINGS_H

#include "metaphir/Matching/Features.h"
#include "llvm/ADT/ArrayRef.h"
#include "llvm/ADT/STLFunctionalExtras.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/ADT/StringRef.h"
#include "llvm/Support/Error.h"
#include <cstdint>
#include <optional>
#include <tuple>
#include <vector>

namespace llvm {
class raw_ostream;
namespace metaphir {

/// A posted feature the index lists the functions of: an instruction kind, an
/// edge or sibling key (see FunctionFeatures), or a global's hash.
struct PostingKey {
  enum KeyKind : uint8_t { Instruction, Edge, Sibling, Global };
  KeyKind Kind;
  uint64_t Value;

  auto tie() const { return std::make_tuple(Kind, Value); }
  bool operator<(const PostingKey &Other) const { return tie() < Other.tie(); }
  bool operator==(const PostingKey &Other) const {
    return tie() == Other.tie();
  }
};

/// A posting key record: the key's kind (1 byte) and value (8), its list's
/// length (4) and offset among the lists (8), little-endian, so that keys
/// are looked up where they lie, sorted by key.
struct PostingRecord {
  static constexpr uint64_t Size = 21;

  PostingKey Key;
  uint32_t Count = 0;
  uint64_t Offset = 0;

  static PostingKey readKey(const char *Record);
  static PostingRecord read(const char *Record);
  void write(raw_ostream &OS) const;
};

/// The posting keys of a function's features.
template <typename Callback>
void forEachPostingKey(const FunctionFeatures &Features, Callback Add) {
  for (uint64_t IDs = Features.Instructions; IDs; IDs &= IDs - 1)
    Add(PostingKey{PostingKey::Instruction, uint64_t(llvm::countr_zero(IDs))});
  for (uint16_t Edge : Features.Edges)
    Add(PostingKey{PostingKey::Edge, Edge});
  for (uint16_t Sibling : Features.Siblings)
    Add(PostingKey{PostingKey::Sibling, Sibling});
  for (uint64_t Global : Features.Globals)
    Add(PostingKey{PostingKey::Global, Global});
}

/// Reads the list of Count function numbers that starts at Offset in Lists;
/// they must be below NumFunctions.
Expected<std::vector<uint32_t>> readPostingList(StringRef Lists,
                                                uint64_t Offset, uint32_t Count,
                                                uint32_t NumFunctions);
/// Appends the list of Numbers, sorted, to OS.
void writePostingList(raw_ostream &OS, ArrayRef<uint32_t> Numbers);

} // namespace metaphir
} // namespace llvm

#endif
