#include "metaphir/Web/WebIndex.h"
#include "metaphir/Index/FeatureCoding.h"
#include "llvm/ADT/STLExtras.h"
#include "llvm/Config/llvm-config.h"
#include "llvm/Support/DataExtractor.h"
#include "llvm/Support/EndianStream.h"
#include "llvm/Support/LEB128.h"
#include "llvm/Support/raw_ostream.h"
#include <algorithm>

namespace llvm {
namespace metaphir {

static constexpr StringLiteral Magic = "MPIRWEB";
static constexpr uint32_t FormatVersion = 1;

StringRef getWebFileName(WebFile File) {
  switch (File) {
  case WebFile::Keys:
    return "keys.bin";
  case WebFile::Lists:
    return "lists.bin";
  case WebFile::Index:
    return "functions.idx";
  case WebFile::Features:
    return "features.bin";
  case WebFile::Packs:
    return "packs.bin";
  }
  llvm_unreachable("unknown published file");
}

std::vector<ByteRange> mergeRanges(std::vector<ByteRange> Ranges) {
  llvm::sort(Ranges, [](const ByteRange &L, const ByteRange &R) {
    return std::make_pair(L.File, L.Offset) < std::make_pair(R.File, R.Offset);
  });
  std::vector<ByteRange> Merged;
  for (const ByteRange &Range : Ranges) {
    if (!Merged.empty() && Merged.back().File == Range.File &&
        Range.Offset <= Merged.back().getEnd()) {
      ByteRange &Last = Merged.back();
      Last.Size = std::max(Last.getEnd(), Range.getEnd()) - Last.Offset;
      continue;
    }
    Merged.push_back(Range);
  }
  return Merged;
}

void ByteCache::add(WebFile File, uint64_t Offset, std::string Bytes) {
  auto Owned = std::make_unique<std::string>(std::move(Bytes));
  StringRef View = *Owned;
  Block &Added = Blocks[unsigned(File)][Offset];
  if (Added.Bytes.size() > View.size())
    return;
  Added.Owned = std::move(Owned);
  Added.Bytes = View;
  MaxSize[unsigned(File)] =
      std::max<uint64_t>(MaxSize[unsigned(File)], View.size());
}

void ByteCache::addBorrowed(WebFile File, uint64_t Offset, StringRef Bytes) {
  Block &Added = Blocks[unsigned(File)][Offset];
  if (Added.Bytes.size() > Bytes.size())
    return;
  Added.Owned.reset();
  Added.Bytes = Bytes;
  MaxSize[unsigned(File)] =
      std::max<uint64_t>(MaxSize[unsigned(File)], Bytes.size());
}

std::optional<StringRef> ByteCache::get(const ByteRange &Range) const {
  const std::map<uint64_t, Block> &FileBlocks = Blocks[unsigned(Range.File)];
  // Any block starting at or before the range may hold it, back to those too
  // far before it for the largest block to reach its end.
  for (auto It = FileBlocks.upper_bound(Range.Offset);
       It != FileBlocks.begin();) {
    --It;
    if (It->first + MaxSize[unsigned(Range.File)] < Range.getEnd())
      break;
    uint64_t Start = Range.Offset - It->first;
    if (Start + Range.Size <= It->second.Bytes.size())
      return It->second.Bytes.substr(Start, Range.Size);
  }
  return std::nullopt;
}

void ByteCache::clear() {
  for (std::map<uint64_t, Block> &FileBlocks : Blocks)
    FileBlocks.clear();
  for (uint64_t &Size : MaxSize)
    Size = 0;
}

Expected<StringRef> ByteCache::read(const ByteRange &Range) const {
  if (std::optional<StringRef> Bytes = get(Range))
    return *Bytes;
  return createStringError("bytes " + Twine(Range.Offset) + ".." +
                           Twine(Range.getEnd()) + " of " +
                           getWebFileName(Range.File) + " are not read");
}

void WebHeader::write(raw_ostream &OS) const {
  OS << Magic;
  support::endian::Writer W(OS, llvm::endianness::little);
  W.write<uint32_t>(FormatVersion);
  writeString(OS, LLVM_VERSION_STRING);
  SmallVector<std::string, 96> Schema = getFeatureSchema();
  encodeULEB128(Schema.size(), OS);
  for (const std::string &Name : Schema)
    writeString(OS, Name);
  encodeULEB128(Modules.size(), OS);
  for (const WebModule &Module : Modules) {
    writeString(OS, Module.Path);
    encodeULEB128(Module.NumFunctions, OS);
  }
  encodeULEB128(NumFunctions, OS);
  encodeULEB128(NumPostingKeys, OS);
  encodeULEB128(TopKeys.size(), OS);
  for (auto [Key, Offset] : zip(TopKeys, TopListOffsets)) {
    W.write<uint8_t>(Key.Kind);
    W.write<uint64_t>(Key.Value);
    encodeULEB128(Offset, OS);
  }
  encodeULEB128(ListsSize, OS);
  writeString(OS, FeatureDictionary);
  writeString(OS, PackDictionary);
}

static Error malformedHeader(const Twine &Message) {
  return createStringError("published corpus header: " + Message);
}

Expected<WebHeader> WebHeader::read(StringRef Bytes) {
  DataExtractor Data(Bytes, /*IsLittleEndian=*/true);
  DataExtractor::Cursor C(0);
  if (Data.getBytes(C, Magic.size()) != Magic) {
    consumeError(C.takeError());
    return malformedHeader("not a published MetaphIR corpus");
  }
  if (uint32_t Version = Data.getU32(C); C && Version != FormatVersion)
    return malformedHeader("format version " + Twine(Version) + ", expected " +
                           Twine(FormatVersion) + "; publish it again");
  if (StringRef Version = readString(Data, C);
      C && Version != LLVM_VERSION_STRING)
    return malformedHeader("published with LLVM " + Version +
                           ", expected " LLVM_VERSION_STRING);
  SmallVector<std::string, 96> Schema = getFeatureSchema();
  uint64_t NumNames = Data.getULEB128(C);
  bool SameSchema = C && NumNames == Schema.size();
  for (uint64_t I = 0; I != NumNames && C; ++I)
    SameSchema &= I < Schema.size() && readString(Data, C) == Schema[I];
  if (C && !SameSchema)
    return malformedHeader(
        "published for other instruction matchers or another LLVM revision");

  WebHeader Header;
  uint64_t NumModules = Data.getULEB128(C);
  uint64_t First = 0;
  for (uint64_t I = 0; I != NumModules && C; ++I) {
    WebModule Module;
    Module.Path = readString(Data, C).str();
    Module.FirstFunction = First;
    Module.NumFunctions = Data.getULEB128(C);
    First += Module.NumFunctions;
    if (First > UINT32_MAX)
      return malformedHeader("too many functions");
    Header.Modules.push_back(std::move(Module));
  }
  Header.NumFunctions = Data.getULEB128(C);
  if (C && Header.NumFunctions != First)
    return malformedHeader("function count mismatch");
  Header.NumPostingKeys = Data.getULEB128(C);
  uint64_t NumTop = Data.getULEB128(C);
  if (C && NumTop != divideCeil(Header.NumPostingKeys, TopKeyStride))
    return malformedHeader("top key count mismatch");
  for (uint64_t I = 0; I != NumTop && C; ++I) {
    auto Kind = PostingKey::KeyKind(Data.getU8(C));
    uint64_t Value = Data.getU64(C);
    Header.TopKeys.push_back(PostingKey{Kind, Value});
    Header.TopListOffsets.push_back(Data.getULEB128(C));
  }
  Header.ListsSize = Data.getULEB128(C);
  Header.FeatureDictionary = readString(Data, C).str();
  Header.PackDictionary = readString(Data, C).str();
  if (!C)
    return malformedHeader(toString(C.takeError()));
  if (C.tell() != Bytes.size())
    return malformedHeader("bytes past the end");
  return Header;
}

Expected<std::unique_ptr<WebIndex>> WebIndex::read(StringRef Compressed) {
  Expected<std::string> Bytes = zstdDecompress(Compressed);
  if (!Bytes)
    return malformedHeader(toString(Bytes.takeError()));
  Expected<WebHeader> Header = WebHeader::read(*Bytes);
  if (!Header)
    return Header.takeError();
  auto Index = std::make_unique<WebIndex>();
  Index->Header = std::move(*Header);
  Expected<ZstdDictionary> Features =
      ZstdDictionary::create(Index->Header.FeatureDictionary);
  if (!Features)
    return Features.takeError();
  Index->Features.emplace(std::move(*Features));
  Expected<ZstdDictionary> Packs =
      ZstdDictionary::create(Index->Header.PackDictionary);
  if (!Packs)
    return Packs.takeError();
  Index->Packs.emplace(std::move(*Packs));
  return Index;
}

const WebModule &WebIndex::getModuleOf(uint32_t Function) const {
  // Modules without functions share their successor's first function.
  auto It = llvm::upper_bound(Header.Modules, Function,
                              [](uint32_t Number, const WebModule &Module) {
                                return Number < Module.FirstFunction;
                              });
  assert(It != Header.Modules.begin() && "function out of range");
  return *std::prev(It);
}

std::optional<ByteRange> WebIndex::getKeyBlock(const PostingKey &Key) const {
  auto It = llvm::upper_bound(Header.TopKeys, Key);
  if (It == Header.TopKeys.begin())
    return std::nullopt;
  uint64_t Block = It - Header.TopKeys.begin() - 1;
  uint64_t First = Block * WebHeader::TopKeyStride;
  uint64_t Count =
      std::min(Header.NumPostingKeys - First, WebHeader::TopKeyStride);
  return ByteRange{WebFile::Keys, First * PostingRecord::Size,
                   Count * PostingRecord::Size};
}

Expected<std::optional<WebPosting>>
WebIndex::findPosting(const PostingKey &Key, const ByteCache &Cache) const {
  std::optional<ByteRange> Block = getKeyBlock(Key);
  if (!Block)
    return std::nullopt;
  Expected<StringRef> Records = Cache.read(*Block);
  if (!Records)
    return Records.takeError();
  uint64_t NumRecords = Block->Size / PostingRecord::Size;
  auto KeyAt = [&](uint64_t I) {
    return PostingRecord::readKey(Records->data() + I * PostingRecord::Size);
  };
  uint64_t Low = 0, High = NumRecords;
  while (Low < High) {
    uint64_t Middle = Low + (High - Low) / 2;
    if (KeyAt(Middle) < Key)
      Low = Middle + 1;
    else
      High = Middle;
  }
  if (Low == NumRecords || !(KeyAt(Low) == Key))
    return std::nullopt;
  WebPosting Found;
  Found.Record =
      PostingRecord::read(Records->data() + Low * PostingRecord::Size);
  // The list ends where the next key's starts.
  uint64_t End;
  if (Low + 1 != NumRecords) {
    End = PostingRecord::read(Records->data() + (Low + 1) * PostingRecord::Size)
              .Offset;
  } else {
    uint64_t NextBlock =
        Block->Offset / PostingRecord::Size / WebHeader::TopKeyStride + 1;
    End = NextBlock < Header.TopListOffsets.size()
              ? Header.TopListOffsets[NextBlock]
              : Header.ListsSize;
  }
  if (End < Found.Record.Offset || End > Header.ListsSize)
    return createStringError("posting list out of order");
  Found.List =
      ByteRange{WebFile::Lists, Found.Record.Offset, End - Found.Record.Offset};
  return Found;
}

} // namespace metaphir
} // namespace llvm
