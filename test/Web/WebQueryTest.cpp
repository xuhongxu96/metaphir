#include "metaphir/Web/WebQuery.h"
#include "metaphir/Index/CorpusIndex.h"
#include "metaphir/Web/WebIndex.h"
#include "metaphir/Web/WebPublisher.h"
#include "llvm/ADT/SmallString.h"
#include "llvm/Support/Endian.h"
#include "llvm/Support/FileSystem.h"
#include "llvm/Support/MemoryBuffer.h"
#include "llvm/Support/Path.h"
#include "llvm/Support/raw_ostream.h"
#include "gtest/gtest.h"

using namespace llvm;
using namespace llvm::metaphir;

namespace {

class WebQueryTest : public testing::Test {
protected:
  SmallString<128> Root;
  SmallString<128> Published;
  std::optional<CorpusIndex> Index;
  std::unique_ptr<WebIndex> Web;
  /// The published files, by WebFile.
  std::unique_ptr<MemoryBuffer> Files[NumWebFiles];

  void SetUp() override {
    ASSERT_FALSE(sys::fs::createUniqueDirectory("metaphir-web-test", Root));
    Published = Root;
    sys::path::append(Published, "published");
  }

  void TearDown() override { (void)sys::fs::remove_directories(Root); }

  void writeFile(StringRef Relative, StringRef Contents) {
    SmallString<128> Path(Root);
    sys::path::append(Path, "corpus", Relative);
    ASSERT_FALSE(sys::fs::create_directories(sys::path::parent_path(Path)));
    std::error_code EC;
    raw_fd_ostream OS(Path, EC);
    ASSERT_FALSE(EC);
    OS << Contents;
  }

  /// Indexes and publishes the corpus.
  void publish() {
    SmallString<128> Corpus(Root), IndexFile(Root);
    sys::path::append(Corpus, "corpus");
    sys::path::append(IndexFile, "corpus.mpidx");
    std::vector<IndexedModule> Modules;
    SmallVector<std::string, 4> Paths;
    ASSERT_TRUE(collectLLVMIRFiles(Corpus, Paths, errs()));
    for (const std::string &Path : Paths) {
      Expected<IndexedModule> Module =
          CorpusIndex::indexFile(Corpus, sys::path::filename(Path));
      ASSERT_TRUE(static_cast<bool>(Module)) << toString(Module.takeError());
      Modules.push_back(std::move(*Module));
    }
    ASSERT_FALSE(errorToBool(CorpusIndex::write(IndexFile, Corpus, Modules)));
    Expected<CorpusIndex> Read = CorpusIndex::read(IndexFile);
    ASSERT_TRUE(static_cast<bool>(Read)) << toString(Read.takeError());
    Index.emplace(std::move(*Read));

    PublishOptions Options;
    Options.SampleEvery = 1;
    Options.FeatureDictionarySize = 4096;
    Options.PackDictionarySize = 4096;
    Error E = publishCorpus(*Index, Published, Options);
    ASSERT_FALSE(static_cast<bool>(E)) << toString(std::move(E));

    std::unique_ptr<MemoryBuffer> Header = read(WebHeaderFileName);
    ASSERT_NE(Header, nullptr);
    Expected<std::unique_ptr<WebIndex>> Opened =
        WebIndex::read(Header->getBuffer());
    ASSERT_TRUE(static_cast<bool>(Opened)) << toString(Opened.takeError());
    Web = std::move(*Opened);
    for (unsigned File = 0; File != NumWebFiles; ++File) {
      Files[File] = read(getWebFileName(WebFile(File)));
      ASSERT_NE(Files[File], nullptr);
    }
  }

  std::unique_ptr<MemoryBuffer> read(StringRef Name) {
    SmallString<128> Path(Published);
    sys::path::append(Path, Name);
    ErrorOr<std::unique_ptr<MemoryBuffer>> Buffer =
        MemoryBuffer::getFile(Path, /*IsText=*/false,
                              /*RequiresNullTerminator=*/false);
    EXPECT_TRUE(static_cast<bool>(Buffer)) << Path;
    return Buffer ? std::move(*Buffer) : nullptr;
  }

  /// Reads Ranges into Cache, as a client over HTTP would.
  void fetch(ArrayRef<ByteRange> Ranges, ByteCache &Cache) {
    for (const ByteRange &Range : Ranges) {
      StringRef File = Files[unsigned(Range.File)]->getBuffer();
      ASSERT_LE(Range.getEnd(), File.size());
      Cache.add(Range.File, Range.Offset,
                File.substr(Range.Offset, Range.Size).str());
    }
  }

  struct Result {
    std::vector<uint32_t> Candidates;
    std::string Matches;
  };

  /// Matches Pattern, reading only the bytes each stage asks for.
  Result query(StringRef Pattern) {
    Result R;
    Expected<std::unique_ptr<WebQuery>> Query =
        WebQuery::compile(*Web, Pattern, "pattern.mpir");
    EXPECT_TRUE(static_cast<bool>(Query)) << toString(Query.takeError());
    if (!Query)
      return R;
    ByteCache Cache;
    fetch((*Query)->getKeyRanges(), Cache);
    using Stage =
        Expected<std::vector<ByteRange>> (WebQuery::*)(const ByteCache &);
    for (Stage Next : {&WebQuery::findLists, &WebQuery::findCandidates,
                       &WebQuery::findFeatures, &WebQuery::filterCandidates}) {
      Expected<std::vector<ByteRange>> Ranges = ((**Query).*Next)(Cache);
      EXPECT_TRUE(static_cast<bool>(Ranges)) << toString(Ranges.takeError());
      if (!Ranges)
        return R;
      fetch(*Ranges, Cache);
    }
    R.Candidates = (*Query)->getCandidates().vec();
    raw_string_ostream OS(R.Matches);
    for (uint32_t Function : (*Query)->getMatchable()) {
      Expected<StringRef> Frame = Cache.read((*Query)->getPackRange(Function));
      EXPECT_TRUE(static_cast<bool>(Frame)) << toString(Frame.takeError());
      if (!Frame)
        return R;
      Error E = (*Query)->match(Function, *Frame, OS);
      EXPECT_FALSE(static_cast<bool>(E)) << toString(std::move(E));
    }
    return R;
  }
};

TEST_F(WebQueryTest, MatchesWhatTheCorpusHas) {
  // Enough globals for the posting keys to take several blocks.
  std::string Many;
  raw_string_ostream OS(Many);
  for (unsigned I = 0; I != 600; ++I)
    OS << "@g" << I << " = global i32 0\n"
       << "define i32 @f" << I << "() {\n"
       << "  %v = load i32, ptr @g" << I << "\n"
       << "  %r = add i32 %v, " << I % 3 << "\n"
       << "  ret i32 %r\n"
       << "}\n";
  writeFile("many.ll", Many);
  writeFile("other.ll", R"(
    define i32 @muls(i32 %x) {
      %r = mul i32 %x, 3
      ret i32 %r
    }
  )");
  writeFile("broken.ll", "define i32 @broken( {");
  publish();
  ASSERT_GT(Web->getHeader().TopKeys.size(), 1u);

  Result Adds = query("%r = add i32 ?x, 1\n");
  std::string Want;
  raw_string_ostream WantOS(Want);
  for (unsigned I = 1; I < 600; I += 3)
    WantOS << "many.ll\t@f" << I << "\t{?x = %v}\n";
  EXPECT_EQ(Adds.Matches, Want);

  // The candidates are those the index finds.
  Result Globals = query("%v = load i32, ptr @g42\n");
  EXPECT_EQ(Globals.Matches, "many.ll\t@f42\t{}\n");
  EXPECT_EQ(Globals.Candidates, std::vector<uint32_t>{42});
  EXPECT_EQ(query("%r = mul i32 ?x, 3\n").Matches,
            "other.ll\t@muls\t{?x = %x}\n");
  EXPECT_EQ(query("%r = sdiv i32 ?x, 3\n").Matches, "");

  // The function's IR can be shown.
  StringRef Packs = Files[unsigned(WebFile::Packs)]->getBuffer();
  StringRef Entries = Files[unsigned(WebFile::Index)]->getBuffer();
  auto Offset = [&](uint32_t Function) {
    return support::endian::read64le(Entries.data() +
                                     Function * WebIndexEntrySize + 8);
  };
  Expected<std::string> IR =
      WebQuery::printFunction(*Web, Packs.slice(Offset(42), Offset(43)));
  ASSERT_TRUE(static_cast<bool>(IR)) << toString(IR.takeError());
  EXPECT_NE(IR->find("define i32 @f42()"), std::string::npos);
  EXPECT_NE(IR->find("load i32, ptr @g42"), std::string::npos);
}

TEST_F(WebQueryTest, CountsUsesInTheWholeModule) {
  writeFile("uses.ll", R"(
    @shared = global i32 0
    @single = global i32 0
    define i32 @load_shared() {
      %v = load i32, ptr @shared
      ret i32 %v
    }
    define void @store_shared() {
      store i32 1, ptr @shared
      ret void
    }
    define i32 @load_single() {
      %v = load i32, ptr @single
      ret i32 %v
    }
  )");
  publish();
  EXPECT_EQ(query("%v = load i32, ptr ?p\n;; hasOneUse(?p)\n").Matches,
            "uses.ll\t@load_single\t{?p = @single}\n");
}

TEST_F(WebQueryTest, ReportsPatternErrors) {
  writeFile("a.ll", "define void @f() {\n  ret void\n}\n");
  publish();
  Expected<std::unique_ptr<WebQuery>> Query =
      WebQuery::compile(*Web, "%r = frobnicate i32 ?x\n", "bad.mpir");
  ASSERT_FALSE(static_cast<bool>(Query));
  EXPECT_NE(toString(Query.takeError()).find("bad.mpir:1:"), std::string::npos);
}

TEST(ByteCacheTest, FindsRangesInOverlappedBlocks) {
  ByteCache Cache;
  std::string Bytes(100, '\0');
  for (unsigned I = 0; I != Bytes.size(); ++I)
    Bytes[I] = char(I);
  // A later, smaller block starts within the first, before the range.
  Cache.add(WebFile::Index, 0, Bytes);
  Cache.add(WebFile::Index, 50, Bytes.substr(50, 10));
  Cache.add(WebFile::Index, 200, std::string(4, 'x'));
  std::optional<StringRef> Range = Cache.get({WebFile::Index, 55, 15});
  ASSERT_TRUE(Range.has_value());
  EXPECT_EQ(*Range, StringRef(Bytes).substr(55, 15));
  EXPECT_FALSE(Cache.get({WebFile::Index, 95, 10}).has_value());
  EXPECT_FALSE(Cache.get({WebFile::Keys, 0, 1}).has_value());
}

TEST_F(WebQueryTest, RejectsOtherHeaders) {
  writeFile("a.ll", "define void @f() {\n  ret void\n}\n");
  publish();
  std::string Header = read(WebHeaderFileName)->getBuffer().str();
  Header[Header.size() / 2] ^= 0x55;
  EXPECT_FALSE(static_cast<bool>(WebIndex::read(Header)));
  EXPECT_FALSE(static_cast<bool>(WebIndex::read("")));
}

} // namespace
