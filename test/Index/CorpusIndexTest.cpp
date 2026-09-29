#include "metaphir/Index/CorpusIndex.h"
#include "llvm/ADT/SmallString.h"
#include "llvm/Support/FileSystem.h"
#include "llvm/Support/Path.h"
#include "llvm/Support/raw_ostream.h"
#include "gtest/gtest.h"

using namespace llvm;
using namespace llvm::metaphir;

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
  const IndexedModule *ReadA = Index->lookup(path("a.ll"));
  ASSERT_NE(ReadA, nullptr);
  EXPECT_TRUE(ReadA->Parsed);
  EXPECT_EQ(ReadA->Size, A.Size);
  EXPECT_EQ(ReadA->ModificationTime, A.ModificationTime);
  EXPECT_TRUE(ReadA->Summary == A.Summary);
  EXPECT_TRUE(ReadA->Functions.empty()) << "functions are read on demand";

  Expected<std::vector<IndexedFunction>> Functions =
      Index->readFunctions(*ReadA);
  ASSERT_TRUE(static_cast<bool>(Functions)) << toString(Functions.takeError());
  ASSERT_EQ(Functions->size(), 2u);
  for (auto [Read, Written] : zip_equal(*Functions, A.Functions)) {
    EXPECT_EQ(Read.Ordinal, Written.Ordinal);
    EXPECT_EQ(Read.Name, Written.Name);
    EXPECT_TRUE(Read.Features == Written.Features);
  }

  const IndexedModule *ReadBroken = Index->lookup(path("broken.ll"));
  ASSERT_NE(ReadBroken, nullptr);
  EXPECT_FALSE(ReadBroken->Parsed);
  EXPECT_EQ(Index->lookup(path("missing.ll")), nullptr);
  EXPECT_EQ(Index->lookup("/elsewhere/a.ll"), nullptr);
}

TEST_F(CorpusIndexTest, NoticesChangedFiles) {
  writeFile("a.ll", "define void @f() {\n  ret void\n}\n");
  IndexedModule A = index("a.ll");
  EXPECT_TRUE(CorpusIndex::isCurrent(A, path("a.ll")));
  writeFile("a.ll", "define void @f() {\n  ret void\n}\n\n");
  EXPECT_FALSE(CorpusIndex::isCurrent(A, path("a.ll")));
  EXPECT_FALSE(CorpusIndex::isCurrent(A, path("missing.ll")));
}

TEST_F(CorpusIndexTest, RejectsOtherFiles) {
  writeFile("not-an-index", "MPIRIDX");
  Expected<CorpusIndex> Short = CorpusIndex::read(path("not-an-index"));
  ASSERT_FALSE(static_cast<bool>(Short));
  EXPECT_NE(toString(Short.takeError()).find("not a MetaphIR index"),
            std::string::npos);

  writeFile("a.ll", "define void @f() {\n  ret void\n}\n");
  ASSERT_FALSE(
      static_cast<bool>(CorpusIndex::write(IndexFile, Root, {index("a.ll")})));
  // Truncate the index inside the module's record.
  ErrorOr<std::unique_ptr<MemoryBuffer>> Buffer =
      MemoryBuffer::getFile(IndexFile);
  ASSERT_TRUE(static_cast<bool>(Buffer));
  writeFile("truncated", (*Buffer)->getBuffer().drop_back(20));
  Expected<CorpusIndex> Truncated = CorpusIndex::read(path("truncated"));
  ASSERT_FALSE(static_cast<bool>(Truncated));
  consumeError(Truncated.takeError());
}

} // namespace
