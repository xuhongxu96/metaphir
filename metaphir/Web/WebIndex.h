#ifndef METAPHIR_WEB_WEBINDEX_H
#define METAPHIR_WEB_WEBINDEX_H

#include "metaphir/Index/Postings.h"
#include "metaphir/Web/Zstd.h"
#include "llvm/ADT/ArrayRef.h"
#include "llvm/ADT/StringRef.h"
#include "llvm/Support/Error.h"
#include <cstdint>
#include <map>
#include <memory>
#include <optional>
#include <string>
#include <vector>

namespace llvm {
class raw_ostream;
namespace metaphir {

// A corpus published for matching over HTTP: a small header, read first, and
// files read by byte ranges, only where a query needs them:
//
//   header.bin.zst  the header (see WebHeader), compressed with zstd
//   keys.bin        the posting key records, sorted (see PostingRecord)
//   lists.bin       the posting lists
//   functions.idx   per function, and once more past the last, where its
//                   features and pack start (two 64-bit little-endian
//                   offsets)
//   features.bin    per function, its features (see writeFunctionFeatures),
//                   a zstd frame with the header's feature dictionary
//   packs.bin       per function, its pack (see FunctionPack), a zstd frame
//                   with the header's pack dictionary
//   manifest.json   the build and the sizes of the files, for the site
//
// Functions are numbered as in the corpus index the files are published
// from: in the order of the modules and of their defined functions.

/// A file of a published corpus read by byte ranges.
enum class WebFile : uint8_t { Keys, Lists, Index, Features, Packs };
constexpr unsigned NumWebFiles = 5;
StringRef getWebFileName(WebFile File);
constexpr StringLiteral WebHeaderFileName = "header.bin.zst";
constexpr StringLiteral WebManifestFileName = "manifest.json";
/// The size of an entry of functions.idx.
constexpr uint64_t WebIndexEntrySize = 16;

/// Bytes of a published file.
struct ByteRange {
  WebFile File;
  uint64_t Offset = 0;
  uint64_t Size = 0;

  uint64_t getEnd() const { return Offset + Size; }
  bool operator==(const ByteRange &Other) const {
    return File == Other.File && Offset == Other.Offset && Size == Other.Size;
  }
};

/// Ranges sorted, with those that overlap or touch merged.
std::vector<ByteRange> mergeRanges(std::vector<ByteRange> Ranges);

/// The bytes of published files read so far.
class ByteCache {
public:
  /// Holds Bytes, read from File at Offset.
  void add(WebFile File, uint64_t Offset, std::string Bytes);
  /// Holds Bytes, read from File at Offset, without copying them: they must
  /// outlive the cache.
  void addBorrowed(WebFile File, uint64_t Offset, StringRef Bytes);
  /// The bytes of Range, if a block added holds them all.
  std::optional<StringRef> get(const ByteRange &Range) const;
  /// The bytes of Range, or an error naming it.
  Expected<StringRef> read(const ByteRange &Range) const;
  /// Drops every block.
  void clear();

private:
  struct Block {
    std::unique_ptr<std::string> Owned;
    StringRef Bytes;
  };
  /// By file, by offset. Blocks may overlap.
  std::map<uint64_t, Block> Blocks[NumWebFiles];
  /// By file, the size of its largest block, which bounds how far before a
  /// range a block holding it can start.
  uint64_t MaxSize[NumWebFiles] = {};
};

/// A posting key's record, and the bytes of lists.bin that hold its list.
struct WebPosting {
  PostingRecord Record;
  ByteRange List;
};

/// A module of a published corpus.
struct WebModule {
  std::string Path;
  uint32_t FirstFunction = 0;
  uint32_t NumFunctions = 0;
};

/// What a published corpus has, read before anything else.
struct WebHeader {
  std::vector<WebModule> Modules;
  uint32_t NumFunctions = 0;
  uint64_t NumPostingKeys = 0;
  /// Every TopKeyStride-th posting key, and the offset of its list; with
  /// them, a key's record is found in one block of keys.bin.
  static constexpr uint64_t TopKeyStride = 256;
  std::vector<PostingKey> TopKeys;
  std::vector<uint64_t> TopListOffsets;
  uint64_t ListsSize = 0;
  std::string FeatureDictionary;
  std::string PackDictionary;

  /// Writes the header, uncompressed.
  void write(raw_ostream &OS) const;
  /// Reads what write wrote, checking that it was published for this build.
  static Expected<WebHeader> read(StringRef Bytes);
};

/// A published corpus's header, ready for queries.
class WebIndex {
public:
  /// Reads the compressed header.
  static Expected<std::unique_ptr<WebIndex>> read(StringRef Compressed);

  const WebHeader &getHeader() const { return Header; }
  uint32_t getNumFunctions() const { return Header.NumFunctions; }
  /// The module the function numbered Function is in.
  const WebModule &getModuleOf(uint32_t Function) const;

  /// The block of keys.bin that holds the record of Key, if any does.
  std::optional<ByteRange> getKeyBlock(const PostingKey &Key) const;
  /// The record of Key and where its list is, found in the block of Key
  /// read into Cache; std::nullopt if no function has Key.
  Expected<std::optional<WebPosting>> findPosting(const PostingKey &Key,
                                                  const ByteCache &Cache) const;

  const ZstdDictionary &getFeatureDictionary() const { return *Features; }
  const ZstdDictionary &getPackDictionary() const { return *Packs; }

private:
  WebHeader Header;
  std::optional<ZstdDictionary> Features;
  std::optional<ZstdDictionary> Packs;
};

} // namespace metaphir
} // namespace llvm

#endif
