#include "metaphir/Web/WebQuery.h"
#include "metaphir/Index/CorpusIndex.h"
#include "metaphir/Index/FunctionPack.h"
#include "metaphir/Web/WebIndex.h"
#include "metaphir/Web/WebPublisher.h"
#include "llvm/ADT/SmallString.h"
#include "llvm/Support/Endian.h"
#include "llvm/Support/FileSystem.h"
#include "llvm/Support/LEB128.h"
#include "llvm/Support/MemoryBuffer.h"
#include "llvm/Support/Path.h"
#include "llvm/Support/raw_ostream.h"
#include "gtest/gtest.h"
#include <zstd.h>

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
    ASSERT_TRUE(succeeded(collectLLVMIRFiles(Corpus, Paths, errs())));
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
    std::vector<PatternNote> Warnings;
    std::vector<RejectingConstraint> Rejecting;
    /// How many functions had a structural match.
    unsigned Structural = 0;
  };

  /// Matches Pattern, reading only the bytes each stage asks for; with
  /// PrintInstructions, the matches list the instructions they matched.
  Result query(StringRef Pattern, bool PrintInstructions = false,
               bool ReportRejecting = false,
               WebQueryMode Mode = WebQueryMode::Full) {
    Result R;
    Expected<std::unique_ptr<WebQuery>> Query =
        WebQuery::compile(*Web, Pattern, "pattern.mpir", Mode);
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
    R.Warnings = (*Query)->getWarnings().vec();
    raw_string_ostream OS(R.Matches);
    for (uint32_t Function : (*Query)->getMatchable()) {
      PackLocation Pack = (*Query)->getPackLocation(Function);
      Expected<StringRef> Frame = Cache.read(Pack.Frame);
      EXPECT_TRUE(static_cast<bool>(Frame)) << toString(Frame.takeError());
      if (!Frame)
        return R;
      bool Structural = false;
      Error E = (*Query)->match(
          Function, *Frame, Pack.Index, OS, PrintInstructions,
          ReportRejecting ? &R.Rejecting : nullptr, &Structural);
      R.Structural += Structural;
      EXPECT_FALSE(static_cast<bool>(E)) << toString(std::move(E));
    }
    return R;
  }

  /// Runs Query's first Stages steps (getKeyRanges, then findLists,
  /// findCandidates, findFeatures and filterCandidates), reading into Cache
  /// the bytes each asks for, each range's bytes first passed to Patch.
  /// Returns the first error.
  Error runStages(
      WebQuery &Query, ByteCache &Cache, unsigned Stages,
      function_ref<void(const ByteRange &, std::string &)> Patch = nullptr) {
    auto Fetch = [&](ArrayRef<ByteRange> Ranges) {
      for (const ByteRange &Range : Ranges) {
        std::string Bytes = Files[unsigned(Range.File)]
                                ->getBuffer()
                                .substr(Range.Offset, Range.Size)
                                .str();
        if (Patch)
          Patch(Range, Bytes);
        Cache.add(Range.File, Range.Offset, std::move(Bytes));
      }
    };
    Fetch(Query.getKeyRanges());
    if (Stages == 0)
      return Error::success();
    using Stage =
        Expected<std::vector<ByteRange>> (WebQuery::*)(const ByteCache &);
    for (Stage Next : {&WebQuery::findLists, &WebQuery::findCandidates,
                       &WebQuery::findFeatures, &WebQuery::filterCandidates}) {
      if (Stages-- == 1)
        return Error::success();
      Expected<std::vector<ByteRange>> Ranges = (Query.*Next)(Cache);
      if (!Ranges)
        return Ranges.takeError();
      Fetch(*Ranges);
    }
    return Error::success();
  }

  /// Compresses Payload with Dictionary, as the published frames are.
  static std::string compressWith(StringRef Dictionary, StringRef Payload) {
    ZSTD_CCtx *Context = ZSTD_createCCtx();
    std::string Frame(ZSTD_compressBound(Payload.size()), '\0');
    size_t Size = ZSTD_compress_usingDict(
        Context, Frame.data(), Frame.size(), Payload.data(), Payload.size(),
        Dictionary.data(), Dictionary.size(), /*level=*/1);
    ZSTD_freeCCtx(Context);
    Frame.resize(Size);
    return Frame;
  }

  /// Bytes that no format reads, as deterministic noise.
  static std::string noise(size_t Size) {
    std::string Bytes(Size, '\0');
    uint32_t State = 12345;
    for (char &C : Bytes) {
      State = State * 1103515245 + 12345;
      C = char(State >> 16);
    }
    return Bytes;
  }

  /// A frame of exactly Size bytes compressed with Dictionary, whose payload
  /// is noise: a raw block grows one byte for each byte of payload.
  static std::string frameOfSize(StringRef Dictionary, size_t Size) {
    size_t Length = Size;
    std::string Frame;
    for (unsigned Try = 0; Try != 16; ++Try) {
      Frame = compressWith(Dictionary, noise(Length));
      if (Frame.size() == Size)
        return Frame;
      if (Frame.size() > Size) {
        if (Length == 0 || Frame.size() - Size > Length)
          break;
        Length -= Frame.size() - Size;
      } else {
        Length += Size - Frame.size();
      }
    }
    return {};
  }

  /// A pack frame holding Payload, compressed with the packs' dictionary.
  std::string packFrame(StringRef Payload) {
    return compressWith(Web->getHeader().PackDictionary, Payload);
  }

  /// The error matching Function from Frame with Query, or "" if there is none.
  static std::string matchError(WebQuery &Query, uint32_t Function,
                                StringRef Frame, unsigned PackIndex) {
    std::string Matches;
    raw_string_ostream OS(Matches);
    return toString(Query.match(Function, Frame, PackIndex, OS));
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

  // A module's consecutive packs share frames.
  StringRef Packs = Files[unsigned(WebFile::Packs)]->getBuffer();
  StringRef Entries = Files[unsigned(WebFile::Index)]->getBuffer();
  auto Location = [&](uint32_t Function) {
    return PackLocation::decode(support::endian::read64le(
        Entries.data() + Function * WebIndexEntrySize + 8));
  };
  EXPECT_EQ(Location(40).Frame, Location(41).Frame);
  EXPECT_EQ(Location(41).Index, Location(40).Index + 1);
  EXPECT_LT(Location(47).Index, PublishOptions().PacksPerFrame);

  // The function's IR can be shown, and so can its frame's other packs'.
  auto Print = [&](uint32_t Function) {
    PackLocation Pack = Location(Function);
    return WebQuery::printFunction(
        *Web, Packs.slice(Pack.Frame.Offset, Pack.Frame.getEnd()), Pack.Index);
  };
  Expected<PrintedFunction> Neighbor = Print(41);
  ASSERT_TRUE(static_cast<bool>(Neighbor)) << toString(Neighbor.takeError());
  EXPECT_NE(Neighbor->IR.find("define i32 @f41()"), std::string::npos);
  Expected<PrintedFunction> Printed = Print(42);
  ASSERT_TRUE(static_cast<bool>(Printed)) << toString(Printed.takeError());
  EXPECT_NE(Printed->IR.find("define i32 @f42()"), std::string::npos);
  // Each instruction's line, counted from 1.
  SmallVector<StringRef, 8> Lines;
  StringRef(Printed->IR).split(Lines, '\n');
  ASSERT_EQ(Printed->Lines.size(), 3u);
  EXPECT_TRUE(Lines[Printed->Lines[0] - 1].contains("load i32, ptr @g42"));
  EXPECT_TRUE(Lines[Printed->Lines[1] - 1].contains("add i32 %v, 0"));
  EXPECT_TRUE(Lines[Printed->Lines[2] - 1].contains("ret i32 %r"));

  // Matches can list the instructions they matched, by position.
  std::string Listed = query("%v = load i32, ptr ?g\n%r = add i32 %v, 1\n",
                             /*PrintInstructions=*/true)
                           .Matches;
  EXPECT_EQ(StringRef(Listed).split('\n').first,
            "many.ll\t@f1\t{?g = @g1}\t{%v@1 = #0, %r@2 = #1}");
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

TEST_F(WebQueryTest, ReportsWarningsAndRejectingConstraints) {
  writeFile("adds.ll", R"(
    define i32 @f(i32 %x) {
      %r = add i32 %x, 1
      ret i32 %r
    }
  )");
  publish();
  Result Shadowed = query("%x = add i32 ?x, 1\n");
  ASSERT_EQ(Shadowed.Warnings.size(), 1u);
  EXPECT_EQ(Shadowed.Warnings[0].Message,
            "local variable '%x' shares a name with meta variable '?x'");
  EXPECT_EQ(Shadowed.Warnings[0].Line, 1u);

  // The index cannot tell how often ?x is used, so the function reaches the
  // matcher: it matches structurally, and hasNUses(?x, 2) rejects the match.
  Result False = query("%r = add i32 ?x, ?c\n;; hasNUses(?x, 2)\n",
                       /*PrintInstructions=*/false, /*ReportRejecting=*/true);
  EXPECT_EQ(False.Matches, "");
  EXPECT_EQ(False.Structural, 1u);
  ASSERT_EQ(False.Rejecting.size(), 1u);
  EXPECT_EQ(False.Rejecting[0].Constraint.Message, "(hasNUses ?x 2)");
  EXPECT_EQ(False.Rejecting[0].Constraint.Line, 2u);
  EXPECT_EQ(False.Rejecting[0].Constraint.Column, 4u);
  EXPECT_EQ(False.Rejecting[0].Reason, "");
  EXPECT_EQ(False.Rejecting[0].Function, "@f");
  // With the structural match it rejected.
  EXPECT_EQ(False.Rejecting[0].Bindings, "{?c = 1, ?x = %x}");
  EXPECT_NE(False.Rejecting[0].Instructions.find("= #0"), std::string::npos)
      << False.Rejecting[0].Instructions;

  // Arithmetic on an argument cannot be evaluated.
  Result Failed = query("%r = add i32 ?x, ?c\n;; ?x + 1 == 2\n",
                        /*PrintInstructions=*/false, /*ReportRejecting=*/true);
  ASSERT_EQ(Failed.Rejecting.size(), 1u);
  EXPECT_NE(Failed.Rejecting[0].Reason, "");

  // A match is not rejected, and is a structural match too.
  Result Matched =
      query("%r = add i32 ?x, ?c\n;; hasNUses(?x, 1)\n", false, true);
  EXPECT_TRUE(Matched.Rejecting.empty());
  EXPECT_EQ(Matched.Structural, 1u);
  EXPECT_EQ(query("%r = sub i32 ?x, ?c\n").Structural, 0u);
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

std::string uleb(uint64_t Value) {
  std::string Bytes;
  raw_string_ostream OS(Bytes);
  encodeULEB128(Value, OS);
  OS.flush();
  return Bytes;
}

std::string errorOf(Error E) { return toString(std::move(E)); }

TEST_F(WebQueryTest, MatchesTheSameInEveryMode) {
  writeFile("a.ll", R"(
    define i32 @f(i32 %x) {
      %r = add i32 %x, 1
      ret i32 %r
    }
    define i32 @g(i32 %x) {
      %r = mul i32 %x, 3
      ret i32 %r
    }
  )");
  publish();
  const char *Pattern = "%r = add i32 ?x, 1\n";
  Result Full = query(Pattern);
  EXPECT_EQ(Full.Matches, "a.ll\t@f\t{?x = %x}\n");
  EXPECT_EQ(query(Pattern, false, false, WebQueryMode::NoConstraints).Matches,
            Full.Matches);
  // Without the index every function is a candidate, and every pack is read.
  Result NoIndex = query(Pattern, false, false, WebQueryMode::NoIndex);
  EXPECT_EQ(NoIndex.Matches, Full.Matches);
  EXPECT_EQ(NoIndex.Candidates, (std::vector<uint32_t>{0, 1}));
}

// The intrinsic is a feature only the constraint needs: without the
// constraints, the posting lists do not look it up either.
TEST_F(WebQueryTest, NoConstraintsLooksUpNoFeatureAConstraintNeeds) {
  writeFile("a.ll", R"(
    define i32 @ctlz(i32 %x) {
      %r = call i32 @llvm.ctlz.i32(i32 %x, i1 false)
      ret i32 %r
    }
    define i32 @cttz(i32 %x) {
      %r = call i32 @llvm.cttz.i32(i32 %x, i1 false)
      ret i32 %r
    }
    declare i32 @llvm.ctlz.i32(i32, i1)
    declare i32 @llvm.cttz.i32(i32, i1)
  )");
  publish();
  const char *Pattern = "%c = call i32 @llvm.?id(i32 ?x, i1 ?z)\n"
                        ";; ?id == \"llvm.ctlz\"\n";
  Result Full = query(Pattern);
  EXPECT_EQ(Full.Candidates, (std::vector<uint32_t>{0}));
  Result NoConstraints =
      query(Pattern, false, false, WebQueryMode::NoConstraints);
  EXPECT_EQ(NoConstraints.Candidates, (std::vector<uint32_t>{0, 1}));
  EXPECT_EQ(NoConstraints.Matches, Full.Matches);
}

TEST_F(WebQueryTest, ReportsStagesThatLackTheirBytes) {
  writeFile("a.ll", R"(
    define i32 @f(i32 %x) {
      %r = add i32 %x, 1
      ret i32 %r
    }
  )");
  publish();
  auto Compile = [&] {
    Expected<std::unique_ptr<WebQuery>> Query =
        WebQuery::compile(*Web, "%r = add i32 ?x, 1\n", "p.mpir");
    EXPECT_TRUE(static_cast<bool>(Query)) << toString(Query.takeError());
    return Query ? std::move(*Query) : nullptr;
  };
  ByteCache Empty;

  // The lists are read to find the candidates.
  std::unique_ptr<WebQuery> Lists = Compile();
  ASSERT_NE(Lists, nullptr);
  EXPECT_TRUE(errorToBool(Lists->findLists(Empty).takeError()));

  std::unique_ptr<WebQuery> Candidates = Compile();
  ASSERT_NE(Candidates, nullptr);
  ByteCache Keys;
  ASSERT_FALSE(errorToBool(runStages(*Candidates, Keys, 2)));
  EXPECT_TRUE(errorToBool(Candidates->findCandidates(Empty).takeError()));

  // The features and packs are found from the index entries.
  std::unique_ptr<WebQuery> Features = Compile();
  ASSERT_NE(Features, nullptr);
  ByteCache Through;
  ASSERT_FALSE(errorToBool(runStages(*Features, Through, 3)));
  ASSERT_EQ(Features->getCandidates().size(), 1u);
  EXPECT_TRUE(errorToBool(Features->findFeatures(Empty).takeError()));
  EXPECT_TRUE(errorToBool(Features->filterCandidates(Empty).takeError()));
}

TEST_F(WebQueryTest, RejectsCorruptFeaturesAndIndexEntries) {
  writeFile("a.ll", R"(
    define i32 @f(i32 %x) {
      %r = add i32 %x, 1
      ret i32 %r
    }
  )");
  publish();
  auto Compile = [&] {
    Expected<std::unique_ptr<WebQuery>> Query =
        WebQuery::compile(*Web, "%r = add i32 ?x, 1\n", "p.mpir");
    EXPECT_TRUE(static_cast<bool>(Query)) << toString(Query.takeError());
    return Query ? std::move(*Query) : nullptr;
  };

  // Features that are no zstd frame.
  std::unique_ptr<WebQuery> NotAFrame = Compile();
  ASSERT_NE(NotAFrame, nullptr);
  ByteCache Cache;
  std::string Error = errorOf(runStages(
      *NotAFrame, Cache, 5, [](const ByteRange &Range, std::string &Bytes) {
        if (Range.File == WebFile::Features)
          Bytes = noise(Bytes.size());
      }));
  EXPECT_NE(Error.find("zstd"), std::string::npos) << Error;

  // Features that are a frame of no features.
  std::unique_ptr<WebQuery> NoFeatures = Compile();
  ASSERT_NE(NoFeatures, nullptr);
  ByteCache Other;
  Error = errorOf(runStages(
      *NoFeatures, Other, 5, [&](const ByteRange &Range, std::string &Bytes) {
        if (Range.File == WebFile::Features) {
          std::string Frame =
              frameOfSize(Web->getHeader().FeatureDictionary, Bytes.size());
          ASSERT_FALSE(Frame.empty());
          Bytes = Frame;
        }
      }));
  EXPECT_FALSE(Error.empty());

  // Index entries whose features start after they end.
  std::unique_ptr<WebQuery> Unordered = Compile();
  ASSERT_NE(Unordered, nullptr);
  ByteCache Entries;
  Error = errorOf(runStages(*Unordered, Entries, 4,
                            [](const ByteRange &Range, std::string &Bytes) {
                              if (Range.File == WebFile::Index)
                                for (unsigned I = 0; I != 8; ++I)
                                  Bytes[I] = '\xff';
                            }));
  EXPECT_EQ(Error, "function index out of order");
}

TEST_F(WebQueryTest, RejectsCorruptPackFrames) {
  writeFile("a.ll", R"(
    define i32 @f(i32 %x) {
      %r = add i32 %x, 1
      ret i32 %r
    }
  )");
  publish();
  Expected<std::unique_ptr<WebQuery>> Query =
      WebQuery::compile(*Web, "%r = add i32 ?x, 1\n", "p.mpir");
  ASSERT_TRUE(static_cast<bool>(Query)) << toString(Query.takeError());
  WebQuery &Q = **Query;

  // A pack whose size is past the frame's end.
  EXPECT_NE(
      matchError(Q, 0, packFrame(uleb(1000)), 0).find("a pack past the end"),
      std::string::npos);
  // An index past the frame's packs.
  EXPECT_NE(matchError(Q, 0, packFrame(uleb(0)), 1).find("no pack 1"),
            std::string::npos);
  // An empty pack, which is no function pack.
  EXPECT_NE(matchError(Q, 0, packFrame(uleb(0)), 0).find("function pack:"),
            std::string::npos);
  // A function pack whose bitcode does not read.
  FunctionPack Broken;
  Broken.Bitcode = "not bitcode";
  std::string Encoded;
  Broken.encode(Encoded);
  EXPECT_NE(matchError(Q, 0, packFrame(uleb(Encoded.size()) + Encoded), 0)
                .find("a.ll: function 0:"),
            std::string::npos);
  // A frame that no dictionary reads.
  EXPECT_NE(matchError(Q, 0, noise(40), 0), "");
}

} // namespace
