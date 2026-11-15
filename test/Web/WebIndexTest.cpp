#include "metaphir/Index/FeatureCoding.h"
#include "metaphir/Index/Postings.h"
#include "metaphir/Web/WebIndex.h"
#include "metaphir/Web/Zstd.h"
#include "llvm/Config/llvm-config.h"
#include "llvm/Support/raw_ostream.h"
#include "gtest/gtest.h"
#include <zstd.h>

using namespace llvm;
using namespace llvm::metaphir;

namespace {

// The start of every header, and where its format version is.
constexpr size_t VersionOffset = 7;

std::string bytesOf(const WebHeader &Header) {
  std::string Bytes;
  raw_string_ostream OS(Bytes);
  Header.write(OS);
  OS.flush();
  return Bytes;
}

std::string compress(StringRef Bytes) {
  std::string Compressed(ZSTD_compressBound(Bytes.size()), '\0');
  size_t Size = ZSTD_compress(Compressed.data(), Compressed.size(),
                              Bytes.data(), Bytes.size(), /*level=*/1);
  Compressed.resize(Size);
  return Compressed;
}

/// A header of two functions in one module, with no posting keys.
WebHeader sampleHeader() {
  WebHeader Header;
  Header.Modules.push_back(WebModule{"a.bc", 0, 2});
  Header.NumFunctions = 2;
  return Header;
}

/// Replaces the first occurrence of From in Bytes with To, of the same size.
void replaceOnce(std::string &Bytes, StringRef From, StringRef To) {
  ASSERT_EQ(From.size(), To.size());
  size_t Pos = Bytes.find(From.str());
  ASSERT_NE(Pos, std::string::npos) << "not in the header: " << From.str();
  Bytes.replace(Pos, From.size(), To.str());
}

/// The error a header read reports, or "" if it reads.
std::string headerError(StringRef Bytes) {
  Expected<WebHeader> Header = WebHeader::read(Bytes);
  if (Header)
    return "";
  return toString(Header.takeError());
}

std::string errorText(Error E) { return toString(std::move(E)); }

/// The posting key record bytes of Records, one after another.
std::string keyRecords(ArrayRef<PostingRecord> Records) {
  std::string Bytes;
  raw_string_ostream OS(Bytes);
  for (const PostingRecord &Record : Records)
    Record.write(OS);
  OS.flush();
  return Bytes;
}

PostingRecord record(PostingKey::KeyKind Kind, uint64_t Value, uint64_t Offset) {
  PostingRecord Record;
  Record.Key = PostingKey{Kind, Value};
  Record.Count = 1;
  Record.Offset = Offset;
  return Record;
}

std::unique_ptr<WebIndex> indexOf(const WebHeader &Header) {
  Expected<std::unique_ptr<WebIndex>> Index =
      WebIndex::read(compress(bytesOf(Header)));
  EXPECT_TRUE(static_cast<bool>(Index)) << toString(Index.takeError());
  return Index ? std::move(*Index) : nullptr;
}

TEST(ByteCacheTest, KeepsTheLongestBlockAtAnOffset) {
  ByteCache Cache;
  auto Lookup = [&](uint64_t Size) {
    std::optional<StringRef> Bytes =
        Cache.get(ByteRange{WebFile::Lists, 0, Size});
    return Bytes ? Bytes->str() : std::string("<none>");
  };
  Cache.add(WebFile::Lists, 0, "abcd");
  // A shorter block at the same offset does not replace the longer one.
  Cache.add(WebFile::Lists, 0, "ab");
  EXPECT_EQ(Lookup(4), "abcd");
  Cache.addBorrowed(WebFile::Lists, 0, "xy");
  EXPECT_EQ(Lookup(4), "abcd");
  // A longer one does.
  Cache.addBorrowed(WebFile::Lists, 0, "efghijkl");
  EXPECT_EQ(Lookup(8), "efghijkl");
}

TEST(ByteCacheTest, ReportsTheBytesItDoesNotHold) {
  ByteCache Cache;
  Cache.add(WebFile::Keys, 0, "abc");
  Expected<StringRef> Bytes = Cache.read(ByteRange{WebFile::Keys, 1, 5});
  ASSERT_FALSE(static_cast<bool>(Bytes));
  EXPECT_EQ(errorText(Bytes.takeError()),
            "bytes 1..6 of keys.bin are not read");
  Cache.clear();
  EXPECT_FALSE(Cache.get(ByteRange{WebFile::Keys, 0, 3}));
}

TEST(WebHeaderTest, ReadsWhatItWrites) {
  Expected<WebHeader> Header = WebHeader::read(bytesOf(sampleHeader()));
  ASSERT_TRUE(static_cast<bool>(Header)) << toString(Header.takeError());
  ASSERT_EQ(Header->Modules.size(), 1u);
  EXPECT_EQ(Header->Modules[0].Path, "a.bc");
  EXPECT_EQ(Header->NumFunctions, 2u);
}

TEST(WebHeaderTest, RejectsFilesThatAreNotHeaders) {
  EXPECT_EQ(headerError(""),
            "published corpus header: not a published MetaphIR corpus");
  EXPECT_EQ(headerError("NOTAHEADER-------"),
            "published corpus header: not a published MetaphIR corpus");
}

TEST(WebHeaderTest, RejectsOtherFormatVersions) {
  std::string Bytes = bytesOf(sampleHeader());
  Bytes[VersionOffset] = Bytes[VersionOffset] + 1;
  EXPECT_NE(headerError(Bytes).find("format version"), std::string::npos);
}

TEST(WebHeaderTest, RejectsOtherLLVMVersions) {
  std::string Bytes = bytesOf(sampleHeader());
  std::string Version = LLVM_VERSION_STRING;
  Version[0] = Version[0] == 'x' ? 'y' : 'x';
  replaceOnce(Bytes, LLVM_VERSION_STRING, Version);
  EXPECT_NE(headerError(Bytes).find("published with LLVM"), std::string::npos);
}

TEST(WebHeaderTest, RejectsOtherFeatureSchemas) {
  std::string Bytes = bytesOf(sampleHeader());
  std::string Name = getFeatureSchema()[0];
  Name[0] = Name[0] == '#' ? '%' : '#';
  replaceOnce(Bytes, getFeatureSchema()[0], Name);
  EXPECT_NE(headerError(Bytes).find("another LLVM revision"),
            std::string::npos);
}

TEST(WebHeaderTest, RejectsCountsThatDoNotAddUp) {
  WebHeader TooMany = sampleHeader();
  TooMany.Modules = {WebModule{"a.bc", 0, UINT32_MAX},
                     WebModule{"b.bc", 0, 1}};
  EXPECT_EQ(headerError(bytesOf(TooMany)),
            "published corpus header: too many functions");

  WebHeader Mismatched = sampleHeader();
  Mismatched.NumFunctions = 5;
  EXPECT_EQ(headerError(bytesOf(Mismatched)),
            "published corpus header: function count mismatch");

  WebHeader Keys = sampleHeader();
  Keys.NumPostingKeys = 1;
  EXPECT_EQ(headerError(bytesOf(Keys)),
            "published corpus header: top key count mismatch");
}

TEST(WebHeaderTest, RejectsTruncatedAndExtendedHeaders) {
  std::string Bytes = bytesOf(sampleHeader());
  EXPECT_NE(headerError(StringRef(Bytes).drop_back(1)), "");
  EXPECT_EQ(headerError(Bytes + "x"),
            "published corpus header: bytes past the end");
}

TEST(WebIndexTest, RejectsWhatIsNotAHeader) {
  EXPECT_FALSE(static_cast<bool>(WebIndex::read("not compressed")));
  Expected<std::unique_ptr<WebIndex>> Index =
      WebIndex::read(compress("NOTAHEADER-------"));
  ASSERT_FALSE(static_cast<bool>(Index));
  EXPECT_NE(errorText(Index.takeError()).find("not a published MetaphIR"),
            std::string::npos);
}

TEST(WebIndexTest, FindsTheBlockOfAKeyInTheTopKeys) {
  WebHeader Header = sampleHeader();
  Header.NumPostingKeys = 2;
  Header.TopKeys = {PostingKey{PostingKey::Instruction, 5}};
  Header.TopListOffsets = {0};
  std::unique_ptr<WebIndex> Index = indexOf(Header);
  ASSERT_NE(Index, nullptr);
  // Keys below the first top key are in no block.
  EXPECT_FALSE(Index->getKeyBlock(PostingKey{PostingKey::Instruction, 1}));
  std::optional<ByteRange> Block =
      Index->getKeyBlock(PostingKey{PostingKey::Instruction, 5});
  ASSERT_TRUE(Block.has_value());
  EXPECT_EQ(Block->Offset, 0u);
  EXPECT_EQ(Block->Size, 2 * PostingRecord::Size);
}

TEST(WebIndexTest, FindsPostingsInTheirBlock) {
  WebHeader Header = sampleHeader();
  Header.NumPostingKeys = 2;
  Header.TopKeys = {PostingKey{PostingKey::Instruction, 0}};
  Header.TopListOffsets = {0};
  Header.ListsSize = 8;
  std::unique_ptr<WebIndex> Index = indexOf(Header);
  ASSERT_NE(Index, nullptr);
  std::string Records = keyRecords({record(PostingKey::Instruction, 0, 0),
                                    record(PostingKey::Instruction, 2, 4)});
  ByteCache Cache;
  Cache.add(WebFile::Keys, 0, Records);

  auto Find = [&](PostingKey Key) {
    Expected<std::optional<WebPosting>> Posting = Index->findPosting(Key, Cache);
    EXPECT_TRUE(static_cast<bool>(Posting)) << toString(Posting.takeError());
    return Posting ? std::move(*Posting) : std::nullopt;
  };
  // Keys between or beyond the records are not there.
  EXPECT_FALSE(Find(PostingKey{PostingKey::Instruction, 1}));
  EXPECT_FALSE(Find(PostingKey{PostingKey::Instruction, 3}));
  // A key's list ends where the next key's starts.
  std::optional<WebPosting> First = Find(PostingKey{PostingKey::Instruction, 0});
  ASSERT_TRUE(First.has_value());
  EXPECT_EQ(First->List.Offset, 0u);
  EXPECT_EQ(First->List.Size, 4u);
}

TEST(WebIndexTest, ReportsPostingsInBlocksNotRead) {
  WebHeader Header = sampleHeader();
  Header.NumPostingKeys = 1;
  Header.TopKeys = {PostingKey{PostingKey::Instruction, 0}};
  Header.TopListOffsets = {0};
  std::unique_ptr<WebIndex> Index = indexOf(Header);
  ASSERT_NE(Index, nullptr);
  ByteCache Cache;
  Expected<std::optional<WebPosting>> Posting =
      Index->findPosting(PostingKey{PostingKey::Instruction, 0}, Cache);
  ASSERT_FALSE(static_cast<bool>(Posting));
  EXPECT_NE(errorText(Posting.takeError()).find("are not read"),
            std::string::npos);
}

TEST(WebIndexTest, RejectsPostingListsOutOfOrder) {
  WebHeader Header = sampleHeader();
  Header.NumPostingKeys = 2;
  Header.TopKeys = {PostingKey{PostingKey::Instruction, 0}};
  Header.TopListOffsets = {0};
  Header.ListsSize = 8;
  std::unique_ptr<WebIndex> Index = indexOf(Header);
  ASSERT_NE(Index, nullptr);
  // The first list would end before it starts.
  ByteCache Cache;
  Cache.add(WebFile::Keys, 0,
            keyRecords({record(PostingKey::Instruction, 0, 5),
                        record(PostingKey::Instruction, 1, 3)}));
  Expected<std::optional<WebPosting>> Posting =
      Index->findPosting(PostingKey{PostingKey::Instruction, 0}, Cache);
  ASSERT_FALSE(static_cast<bool>(Posting));
  EXPECT_EQ(errorText(Posting.takeError()), "posting list out of order");
}

TEST(WebIndexTest, RejectsDictionariesThatDoNotLoad) {
  // A dictionary that starts with zstd's dictionary magic number, and then
  // holds no entropy tables.
  std::string Corrupt("\x37\xa4\x30\xec", 4);
  Corrupt.append(16, '\xff');
  EXPECT_FALSE(static_cast<bool>(ZstdDictionary::create(Corrupt)));

  WebHeader Features = sampleHeader();
  Features.FeatureDictionary = Corrupt;
  Expected<std::unique_ptr<WebIndex>> Read =
      WebIndex::read(compress(bytesOf(Features)));
  EXPECT_FALSE(static_cast<bool>(Read));
  consumeError(Read.takeError());

  WebHeader Packs = sampleHeader();
  Packs.PackDictionary = Corrupt;
  Read = WebIndex::read(compress(bytesOf(Packs)));
  EXPECT_FALSE(static_cast<bool>(Read));
  consumeError(Read.takeError());
}

TEST(ZstdTest, RejectsFramesShorterThanTheirSize) {
  // A frame of three bytes that declares four: the frame's content size is
  // the byte after the magic number and the frame header descriptor.
  std::string Frame = compress("abc");
  ASSERT_GT(Frame.size(), 5u);
  Frame[5] = 4;
  Expected<std::string> Bytes = zstdDecompress(Frame);
  ASSERT_FALSE(static_cast<bool>(Bytes));
  EXPECT_NE(errorText(Bytes.takeError()).find("zstd"), std::string::npos);
}

TEST(ZstdTest, ReadsDictionariesOfAnyContent) {
  Expected<ZstdDictionary> First = ZstdDictionary::create("");
  ASSERT_TRUE(static_cast<bool>(First)) << toString(First.takeError());
  Expected<ZstdDictionary> Second = ZstdDictionary::create("");
  ASSERT_TRUE(static_cast<bool>(Second)) << toString(Second.takeError());
  // Assigning moves the dictionary over and frees the one it replaces.
  *First = std::move(*Second);
  Expected<std::string> Bytes = First->decompress(compress("abc"));
  ASSERT_TRUE(static_cast<bool>(Bytes)) << toString(Bytes.takeError());
  EXPECT_EQ(*Bytes, "abc");
}

} // namespace
