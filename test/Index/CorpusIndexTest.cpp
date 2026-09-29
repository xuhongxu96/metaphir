#include "metaphir/Index/CorpusIndex.h"
#include "llvm/ADT/SmallString.h"
#include "llvm/Support/FileSystem.h"
#include "llvm/Support/Path.h"
#include "llvm/Support/raw_ostream.h"
#include "gtest/gtest.h"

using namespace llvm;
using namespace llvm::metaphir;
using MIRInstruction = llvm::metaphir::Instruction;

namespace {

class CorpusIndexTest : public testing::Test {
protected:
  SmallString<128> Root;
  SmallString<128> IndexFile;

  void SetUp() override {
    ASSERT_FALSE(sys::fs::createUniqueDirectory("metaphir-index-test", Root));
    IndexFile = Root;
    sys::path::append(IndexFile, "corpus.mpidx");
  }

  void TearDown() override { (void)sys::fs::remove_directories(Root); }

  std::string path(StringRef Relative) {
    SmallString<128> Path(Root);
    sys::path::append(Path, Relative);
    return std::string(Path);
  }

  void writeFile(StringRef Relative, StringRef Contents) {
    std::error_code EC;
    raw_fd_ostream OS(path(Relative), EC);
    ASSERT_FALSE(EC);
    OS << Contents;
  }

  IndexedModule index(StringRef Relative) {
    Expected<IndexedModule> Module = CorpusIndex::indexFile(Root, Relative);
    EXPECT_TRUE(static_cast<bool>(Module)) << toString(Module.takeError());
    return Module ? std::move(*Module) : IndexedModule();
  }
};

TEST_F(CorpusIndexTest, RoundTrips) {
  writeFile("a.ll", R"(
    declare i32 @g(i32)
    define i32 @f(i32 %x) {
      %r = call i32 @g(i32 %x)
      ret i32 %r
    }
    define i32 @h(i32 %x) {
      %r = add i32 %x, 1
      ret i32 %r
    }
  )");
  writeFile("broken.ll", "define i32 @broken( {");
  IndexedModule A = index("a.ll");
  IndexedModule Broken = index("broken.ll");
  ASSERT_TRUE(A.Parsed);
  EXPECT_FALSE(Broken.Parsed);
  ASSERT_EQ(A.Functions.size(), 2u);
  ASSERT_FALSE(
      static_cast<bool>(CorpusIndex::write(IndexFile, Root, {A, Broken})));

  Expected<CorpusIndex> Index = CorpusIndex::read(IndexFile);
  ASSERT_TRUE(static_cast<bool>(Index)) << toString(Index.takeError());
  ASSERT_EQ(Index->size(), 2u);
  const IndexEntry *ReadA = Index->lookup(path("a.ll"));
  ASSERT_NE(ReadA, nullptr);
  EXPECT_TRUE(ReadA->Parsed);
  EXPECT_TRUE(ReadA->Stamp == A.Stamp);
  EXPECT_EQ(ReadA->NumFunctions, 2u);
  Expected<FunctionFeatures> Summary = Index->readSummary(*ReadA);
  ASSERT_TRUE(static_cast<bool>(Summary)) << toString(Summary.takeError());
  EXPECT_TRUE(*Summary == A.Summary);
  EXPECT_EQ(Summary->Globals.size(), 1u);

  Expected<std::vector<IndexedFunction>> Functions =
      Index->readFunctions(*ReadA);
  ASSERT_TRUE(static_cast<bool>(Functions)) << toString(Functions.takeError());
  ASSERT_EQ(Functions->size(), 2u);
  for (auto [Read, Written] : zip_equal(*Functions, A.Functions)) {
    EXPECT_EQ(Read.NameHash, Written.NameHash);
    EXPECT_TRUE(Read.Features == Written.Features);
  }
  EXPECT_EQ((*Functions)[0].NameHash, IndexedFunction::hashName("f"));
  EXPECT_EQ((*Functions)[0].Features.Globals, Summary->Globals);

  const IndexEntry *ReadBroken = Index->lookup(path("broken.ll"));
  ASSERT_NE(ReadBroken, nullptr);
  EXPECT_FALSE(ReadBroken->Parsed);
  EXPECT_EQ(Index->lookup(path("missing.ll")), nullptr);
  EXPECT_EQ(Index->lookup("/elsewhere/a.ll"), nullptr);
}

TEST_F(CorpusIndexTest, ListsFunctionsByFeature) {
  writeFile("a.ll", R"(
    declare i32 @g(i32)
    define i32 @calls(i32 %x) {
      %r = call i32 @g(i32 %x)
      ret i32 %r
    }
    define i32 @adds(i32 %x) {
      %r = add i32 %x, 1
      ret i32 %r
    }
  )");
  writeFile("b.ll", R"(
    define i32 @muls(i32 %x) {
      %r = mul i32 %x, 3
      ret i32 %r
    }
    define i32 @adds_and_muls(i32 %x) {
      %a = add i32 %x, 1
      %r = mul i32 %a, 3
      ret i32 %r
    }
  )");
  ASSERT_FALSE(static_cast<bool>(
      CorpusIndex::write(IndexFile, Root, {index("a.ll"), index("b.ll")})));
  Expected<CorpusIndex> Index = CorpusIndex::read(IndexFile);
  ASSERT_TRUE(static_cast<bool>(Index)) << toString(Index.takeError());

  PostingKey Add{PostingKey::Instruction, MIRInstruction::I_add};
  EXPECT_EQ(Index->getPostingCount(Add), 2u);
  Expected<std::vector<uint32_t>> Adds = Index->readPostings(Add);
  ASSERT_TRUE(static_cast<bool>(Adds)) << toString(Adds.takeError());
  EXPECT_EQ(*Adds, (std::vector<uint32_t>{1, 3}));
  FunctionLocation Last = Index->locate(3);
  EXPECT_EQ(Last.Entry, 1u);
  EXPECT_EQ(Last.Ordinal, 1u);
  EXPECT_EQ(Index->getPostingCount(
                PostingKey{PostingKey::Global, hashGlobalName("g")}),
            1u);
  EXPECT_EQ(Index->getPostingCount(
                PostingKey{PostingKey::Instruction, MIRInstruction::I_udiv}),
            0u);
}

TEST_F(CorpusIndexTest, LooksUpThroughSymbolicLinks) {
  writeFile("a.ll", "define void @f() {\n  ret void\n}\n");
  ASSERT_FALSE(
      static_cast<bool>(CorpusIndex::write(IndexFile, Root, {index("a.ll")})));
  Expected<CorpusIndex> Index = CorpusIndex::read(IndexFile);
  ASSERT_TRUE(static_cast<bool>(Index)) << toString(Index.takeError());

  SmallString<128> Link(Root);
  Link += "-link";
  ASSERT_FALSE(sys::fs::create_link(Root, Link));
  SmallString<128> LinkedFile(Link);
  sys::path::append(LinkedFile, "a.ll");
  EXPECT_EQ(Index->lookup(LinkedFile), Index->lookup(path("a.ll")));
  EXPECT_NE(Index->lookup(LinkedFile), nullptr);
  (void)sys::fs::remove(Link);
}

TEST_F(CorpusIndexTest, NoticesChangedFiles) {
  writeFile("a.ll", "define void @f() {\n  ret void\n}\n");
  IndexedModule A = index("a.ll");
  EXPECT_TRUE(FileStamp::of(path("a.ll")) == A.Stamp);
  writeFile("a.ll", "define void @f() {\n  ret void\n}\n\n");
  EXPECT_FALSE(FileStamp::of(path("a.ll")) == A.Stamp);
  EXPECT_FALSE(FileStamp::of(path("missing.ll")).has_value());
}

TEST_F(CorpusIndexTest, RejectsOtherFiles) {
  writeFile("not-an-index", "NOTANIDX");
  Expected<CorpusIndex> Short = CorpusIndex::read(path("not-an-index"));
  ASSERT_FALSE(static_cast<bool>(Short));
  EXPECT_NE(toString(Short.takeError()).find("not a MetaphIR index"),
            std::string::npos);

  writeFile("a.ll", "define i32 @f(i32 %x) {\n  %r = add i32 %x, 1\n"
                    "  ret i32 %r\n}\n");
  ASSERT_FALSE(
      static_cast<bool>(CorpusIndex::write(IndexFile, Root, {index("a.ll")})));
  ErrorOr<std::unique_ptr<MemoryBuffer>> Buffer =
      MemoryBuffer::getFile(IndexFile);
  ASSERT_TRUE(static_cast<bool>(Buffer));

  // Cut inside the last posting list, the ret-ret siblings': only reading it
  // fails.
  writeFile("cut-postings", (*Buffer)->getBuffer().drop_back(1));
  Expected<CorpusIndex> CutPostings = CorpusIndex::read(path("cut-postings"));
  ASSERT_TRUE(static_cast<bool>(CutPostings))
      << toString(CutPostings.takeError());
  Expected<std::vector<uint32_t>> Postings = CutPostings->readPostings(
      PostingKey{PostingKey::Sibling,
                 FunctionFeatures::getEdgeKey(MIRInstruction::I_ret,
                                              MIRInstruction::I_ret)});
  ASSERT_FALSE(static_cast<bool>(Postings));
  consumeError(Postings.takeError());

  // Cut inside the header: reading the index fails.
  writeFile("cut-header", (*Buffer)->getBuffer().take_front(20));
  Expected<CorpusIndex> CutHeader = CorpusIndex::read(path("cut-header"));
  ASSERT_FALSE(static_cast<bool>(CutHeader));
  consumeError(CutHeader.takeError());
}

} // namespace
