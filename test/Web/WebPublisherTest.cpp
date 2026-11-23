#include "metaphir/Web/WebPublisher.h"
#include "metaphir/Index/CorpusIndex.h"
#include "metaphir/Web/WebIndex.h"
#include "llvm/ADT/SmallString.h"
#include "llvm/Bitcode/BitcodeWriter.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/DerivedTypes.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/LLVMContext.h"
#include "llvm/IR/Module.h"
#include "llvm/Support/FileSystem.h"
#include "llvm/Support/Path.h"
#include "llvm/Support/raw_ostream.h"
#include "gtest/gtest.h"
#include <unistd.h>

using namespace llvm;
using namespace llvm::metaphir;

namespace {

// Two functions of the same length, so a file can change without changing
// its size.
constexpr StringLiteral FunctionF = "define i32 @f(i32 %x) {\n"
                                    "  ret i32 %x\n"
                                    "}\n";
constexpr StringLiteral FunctionG = "define i32 @g(i32 %x) {\n"
                                    "  ret i32 %x\n"
                                    "}\n";

class WebPublisherTest : public testing::Test {
protected:
  SmallString<128> Root;
  SmallString<128> Corpus;
  SmallString<128> IndexFile;
  std::optional<CorpusIndex> Index;

  void SetUp() override {
    ASSERT_FALSE(sys::fs::createUniqueDirectory("metaphir-publish-test", Root));
    Corpus = Root;
    sys::path::append(Corpus, "corpus");
    IndexFile = Root;
    sys::path::append(IndexFile, "corpus.mpidx");
    ASSERT_FALSE(sys::fs::create_directories(Corpus));
    writeCorpusFile("a.ll", std::string(FunctionF) + std::string(FunctionG));
  }

  void TearDown() override { (void)sys::fs::remove_directories(Root); }

  std::string pathIn(StringRef Directory, StringRef Name) {
    SmallString<128> Path(Directory);
    sys::path::append(Path, Name);
    return Path.str().str();
  }

  void writeCorpusFile(StringRef Name, StringRef Contents) {
    std::error_code EC;
    raw_fd_ostream OS(pathIn(Corpus, Name), EC);
    ASSERT_FALSE(EC);
    OS << Contents;
  }

  /// Rewrites a corpus file. With KeepStamp, its size and modification time
  /// stay the same, so the index still holds for it.
  void rewriteCorpusFile(StringRef Name, StringRef Contents, bool KeepStamp) {
    std::string Path = pathIn(Corpus, Name);
    sys::fs::file_status Before;
    ASSERT_FALSE(sys::fs::status(Path, Before));
    auto Time = Before.getLastModificationTime();
    writeCorpusFile(Name, Contents);
    if (KeepStamp) {
      ASSERT_FALSE(sys::fs::setLastAccessAndModificationTime(Path, Time));
    }
  }

  /// Indexes the corpus, as metaphir-index build does.
  void index() {
    SmallVector<std::string, 4> Paths;
    ASSERT_TRUE(succeeded(collectLLVMIRFiles(Corpus, Paths, errs())));
    std::vector<IndexedModule> Modules;
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
  }

  /// The options the tests publish with: small dictionaries, to be quick.
  static PublishOptions options() {
    PublishOptions Options;
    Options.SampleEvery = 1;
    Options.FeatureDictionarySize = 4096;
    Options.PackDictionarySize = 4096;
    return Options;
  }

  /// Publishes the indexed corpus to Output, returning the error text, or ""
  /// if there is none.
  std::string publish(StringRef Output, PublishOptions Options = options()) {
    return toString(publishCorpus(*Index, Output, Options));
  }
};

TEST_F(WebPublisherTest, PublishesTheIndexedCorpus) {
  index();
  SmallString<128> Output = Root;
  sys::path::append(Output, "published");
  std::string Progress;
  raw_string_ostream ProgressOS(Progress);
  PublishOptions Options = options();
  Options.Progress = &ProgressOS;
  EXPECT_EQ(publish(Output, Options), "");
  ProgressOS.flush();
  EXPECT_NE(Progress.find("trained the dictionaries"), std::string::npos);
  EXPECT_TRUE(sys::fs::exists(pathIn(Output, WebHeaderFileName)));
  EXPECT_TRUE(sys::fs::exists(pathIn(Output, getWebFileName(WebFile::Packs))));
}

TEST_F(WebPublisherTest, RejectsPacksPerFrameOutOfRange) {
  index();
  SmallString<128> Output = Root;
  sys::path::append(Output, "published");
  PublishOptions None = options();
  None.PacksPerFrame = 0;
  EXPECT_EQ(publish(Output, None),
            "packs per frame must be from 1 to " +
                std::to_string(1u << PackLocation::IndexBits));
  PublishOptions Many = options();
  Many.PacksPerFrame = 1u << PackLocation::IndexBits;
  Many.PacksPerFrame += 1;
  EXPECT_NE(publish(Output, Many), "");
}

TEST_F(WebPublisherTest, RejectsOutputsThatAreNotDirectories) {
  index();
  // A regular file where the output directory would be.
  std::string Blocker = pathIn(Root, "blocker");
  std::error_code EC;
  raw_fd_ostream(Blocker, EC) << "not a directory";
  ASSERT_FALSE(EC);
  EXPECT_NE(publish(pathIn(Blocker, "published")), "");
}

TEST_F(WebPublisherTest, RejectsFilesChangedSinceIndexed) {
  index();
  rewriteCorpusFile("a.ll",
                    std::string(FunctionF) + std::string(FunctionG) + "\n",
                    /*KeepStamp=*/false);
  EXPECT_NE(publish(pathIn(Root, "published"))
                .find("a.ll: changed since indexed; index it again"),
            std::string::npos);
}

TEST_F(WebPublisherTest, RejectsFilesThatNoLongerParse) {
  index();
  std::string Broken = std::string(FunctionF) + std::string(FunctionG);
  Broken.replace(Broken.find("  ret i32 %x\n}\n", FunctionF.size()), 2, "@@");
  rewriteCorpusFile("a.ll", Broken, /*KeepStamp=*/true);
  EXPECT_NE(publish(pathIn(Root, "published")).find("a.ll: "),
            std::string::npos);
}

TEST_F(WebPublisherTest, RejectsFunctionsRenamedSinceIndexed) {
  index();
  std::string Renamed = std::string(FunctionF) + std::string(FunctionG);
  Renamed.replace(Renamed.find("@g"), 2, "@h");
  rewriteCorpusFile("a.ll", Renamed, /*KeepStamp=*/true);
  EXPECT_NE(publish(pathIn(Root, "published"))
                .find("a.ll: differs from its index entry; index it again"),
            std::string::npos);
}

TEST_F(WebPublisherTest, RejectsFunctionsDeclaredSinceIndexed) {
  index();
  // @g becomes a declaration, of the same size: one function fewer.
  std::string Declared = std::string(FunctionF);
  std::string Declaration = "declare i32 @g(i32 %x)";
  Declared += Declaration +
              std::string(FunctionG.size() - Declaration.size() - 1, ' ') +
              "\n";
  ASSERT_EQ(Declared.size(), std::string(FunctionF).size() + FunctionG.size());
  rewriteCorpusFile("a.ll", Declared, /*KeepStamp=*/true);
  EXPECT_NE(publish(pathIn(Root, "published"))
                .find("a.ll: differs from its index entry; index it again"),
            std::string::npos);
}

TEST_F(WebPublisherTest, RejectsOutputsThatCannotBeWritten) {
  index();
  // Each file of the corpus, as a directory where the file should be.
  for (StringRef Name :
       {getWebFileName(WebFile::Features), getWebFileName(WebFile::Packs),
        getWebFileName(WebFile::Index), getWebFileName(WebFile::Keys),
        getWebFileName(WebFile::Lists), StringRef(WebHeaderFileName)}) {
    SmallString<128> Output = Root;
    sys::path::append(Output, "blocked-" + Name.str());
    ASSERT_FALSE(sys::fs::create_directories(pathIn(Output, Name)));
    EXPECT_NE(publish(Output), "") << Name.str();
  }
}

TEST_F(WebPublisherTest, ReportsOutputsThatFailWhileWritten) {
  index();
  // /dev/full accepts the file and fails every write.
  for (StringRef Name :
       {getWebFileName(WebFile::Features), getWebFileName(WebFile::Keys),
        StringRef(WebHeaderFileName)}) {
    SmallString<128> Output = Root;
    sys::path::append(Output, "full-" + Name.str());
    ASSERT_FALSE(sys::fs::create_directories(Output));
    ASSERT_EQ(symlink("/dev/full", pathIn(Output, Name).c_str()), 0);
    EXPECT_NE(publish(Output), "") << Name.str();
  }
}

TEST_F(WebPublisherTest, RejectsPacksTooLargeToLocate) {
  // A function returning a vector of random bytes, which compression cannot
  // shrink, makes its pack larger than a frame's size field can give.
  LLVMContext Context;
  Module M("blob", Context);
  std::vector<uint8_t> Noise(17u << 20);
  uint32_t State = 1;
  for (uint8_t &Byte : Noise) {
    State = State * 1103515245 + 12345;
    Byte = uint8_t(State >> 16);
  }
  Type *Bytes = FixedVectorType::get(Type::getInt8Ty(Context), Noise.size());
  Function *F = Function::Create(FunctionType::get(Bytes, false),
                                 GlobalValue::ExternalLinkage, "f", M);
  IRBuilder<> Builder(BasicBlock::Create(Context, "entry", F));
  Builder.CreateRet(ConstantDataVector::get(Context, Noise));
  std::error_code EC;
  raw_fd_ostream OS(pathIn(Corpus, "blob.bc"), EC);
  ASSERT_FALSE(EC);
  WriteBitcodeToFile(M, OS);
  OS.close();
  index();
  EXPECT_NE(publish(pathIn(Root, "published"))
                .find("the packs are too large to publish"),
            std::string::npos);
}

} // namespace
