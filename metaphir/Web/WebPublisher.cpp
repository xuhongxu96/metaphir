#include "metaphir/Web/WebPublisher.h"
#include "metaphir/Index/CorpusIndex.h"
#include "metaphir/Index/FeatureCoding.h"
#include "metaphir/Index/FunctionPacker.h"
#include "metaphir/Web/WebIndex.h"
#include "llvm/ADT/SmallString.h"
#include "llvm/ADT/StringExtras.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/LLVMContext.h"
#include "llvm/IR/Module.h"
#include "llvm/IRReader/IRReader.h"
#include "llvm/Support/EndianStream.h"
#include "llvm/Support/FileSystem.h"
#include "llvm/Support/FormatVariadic.h"
#include "llvm/Support/JSON.h"
#include "llvm/Support/LEB128.h"
#include "llvm/Support/Parallel.h"
#include "llvm/Support/Path.h"
#include "llvm/Support/SourceMgr.h"
#include "llvm/Support/Threading.h"
#include "llvm/Support/raw_ostream.h"
#include "llvm/Support/xxhash.h"
#include <zdict.h>
#include <zstd.h>

namespace llvm {
namespace metaphir {

namespace {

/// The features and packs of a module's functions, encoded.
struct EncodedModule {
  std::vector<std::string> Features;
  std::vector<std::string> Packs;
};

/// Compresses with a dictionary, on any number of threads at once.
class Compressor {
public:
  Compressor(StringRef Dictionary, int Level)
      : Dict(ZSTD_createCDict(Dictionary.data(), Dictionary.size(), Level)) {}
  ~Compressor() { ZSTD_freeCDict(Dict); }

  Expected<std::string> compress(StringRef Bytes) const {
    struct ContextDeleter {
      void operator()(ZSTD_CCtx *Context) const { ZSTD_freeCCtx(Context); }
    };
    thread_local std::unique_ptr<ZSTD_CCtx, ContextDeleter> Context(
        ZSTD_createCCtx());
    std::string Out(ZSTD_compressBound(Bytes.size()), '\0');
    size_t Size =
        ZSTD_compress_usingCDict(Context.get(), Out.data(), Out.size(),
                                 Bytes.data(), Bytes.size(), Dict);
    if (ZSTD_isError(Size))
      return createStringError(Twine("zstd: ") + ZSTD_getErrorName(Size));
    Out.resize(Size);
    return Out;
  }

private:
  ZSTD_CDict *Dict;
};

} // namespace

/// Encodes the functions of Entry: their features as indexed, and their
/// packs from the module as it is now, which must be as indexed.
static Expected<EncodedModule> encodeModule(const CorpusIndex &Index,
                                            const IndexEntry &Entry) {
  EncodedModule Encoded;
  if (!Entry.Parsed || Entry.NumFunctions == 0)
    return Encoded;
  SmallString<256> Path(Index.getRoot());
  sys::path::append(Path, Entry.Path);
  if (FileStamp::of(Path) != Entry.Stamp)
    return createStringError(Entry.Path +
                             ": changed since indexed; index it again");

  Expected<std::vector<IndexedFunction>> Functions = Index.readFunctions(Entry);
  if (!Functions)
    return Functions.takeError();
  for (const IndexedFunction &Function : *Functions) {
    raw_string_ostream OS(Encoded.Features.emplace_back());
    writeFunctionFeatures(OS, Function.Features);
  }

  LLVMContext Context;
  SMDiagnostic Diag;
  std::unique_ptr<Module> M = parseIRFile(Path, Diag, Context);
  if (!M)
    return createStringError(Entry.Path + ": " + Diag.getMessage());
  size_t Ordinal = 0;
  Error E =
      packFunctions(*M, [&](const Function &F, FunctionPack Pack) -> Error {
        if (Ordinal == Functions->size() ||
            IndexedFunction::hashName(F.getName()) !=
                (*Functions)[Ordinal].NameHash)
          return createStringError(Entry.Path +
                                   ": differs from its index entry; index it "
                                   "again");
        ++Ordinal;
        Pack.encode(Encoded.Packs.emplace_back());
        return Error::success();
      });
  if (E)
    return createStringError(Entry.Path + ": " + toString(std::move(E)));
  if (Ordinal != Functions->size())
    return createStringError(Entry.Path +
                             ": differs from its index entry; index it again");
  return Encoded;
}

/// A module's packs, grouped to be compressed together: each frame's packs,
/// each after its size; and for each pack, its frame and slot in it.
struct PackFrames {
  std::vector<std::string> Frames;
  std::vector<std::pair<size_t, unsigned>> Of;
};

static PackFrames groupPacks(ArrayRef<std::string> Packs,
                             const PublishOptions &Options) {
  PackFrames Grouped;
  for (size_t I = 0; I != Packs.size();) {
    std::string Frame;
    raw_string_ostream OS(Frame);
    unsigned Slot = 0;
    do {
      encodeULEB128(Packs[I].size(), OS);
      OS << Packs[I];
      Grouped.Of.emplace_back(Grouped.Frames.size(), Slot++);
      ++I;
    } while (I != Packs.size() && Slot != Options.PacksPerFrame &&
             Frame.size() + Packs[I].size() <= Options.MaxFrameInput);
    Grouped.Frames.push_back(std::move(Frame));
  }
  return Grouped;
}

/// A dictionary trained on Samples, of at most Capacity bytes.
static std::string trainDictionary(ArrayRef<std::string> Samples,
                                   size_t Capacity) {
  std::string Buffer;
  std::vector<size_t> Sizes;
  for (const std::string &Sample : Samples) {
    Buffer += Sample;
    Sizes.push_back(Sample.size());
  }
  std::string Dictionary(Capacity, '\0');
  size_t Size =
      Samples.empty()
          ? size_t(-1)
          : ZDICT_trainFromBuffer(Dictionary.data(), Capacity, Buffer.data(),
                                  Sizes.data(), Sizes.size());
  if (ZDICT_isError(Size)) {
    // Too few samples to train on: the samples themselves serve as a raw
    // dictionary.
    Dictionary = Buffer.substr(0, Capacity);
    if (Dictionary.empty())
      Dictionary = "MetaphIR";
    return Dictionary;
  }
  Dictionary.resize(Size);
  return Dictionary;
}

static Error writeFile(StringRef Directory, StringRef Name, StringRef Bytes) {
  SmallString<256> Path(Directory);
  sys::path::append(Path, Name);
  std::error_code EC;
  raw_fd_ostream OS(Path, EC);
  if (EC)
    return createFileError(Path, EC);
  OS << Bytes;
  OS.close();
  if (OS.has_error())
    return createFileError(Path, OS.error());
  return Error::success();
}

Error publishCorpus(const CorpusIndex &Index, StringRef Output,
                    const PublishOptions &Options) {
  if (Options.PacksPerFrame == 0 ||
      Options.PacksPerFrame > (1u << PackLocation::SlotBits))
    return createStringError("packs per frame must be from 1 to " +
                             Twine(1u << PackLocation::SlotBits));
  if (std::error_code EC = sys::fs::create_directories(Output))
    return createFileError(Output, EC);
  parallel::strategy = hardware_concurrency(Options.Jobs);
  auto Report = [&](const Twine &Message) {
    if (Options.Progress)
      *Options.Progress << Message << '\n';
  };

  // Every module's encoding, in order, or its error.
  auto EncodeAll =
      [&](ArrayRef<size_t> Entries,
          function_ref<Error(size_t, EncodedModule)> Take) -> Error {
    constexpr size_t Batch = 512;
    for (size_t Start = 0; Start < Entries.size(); Start += Batch) {
      size_t End = std::min(Entries.size(), Start + Batch);
      std::vector<std::optional<Expected<EncodedModule>>> Encoded(End - Start);
      parallelFor(Start, End, [&](size_t I) {
        Encoded[I - Start].emplace(
            encodeModule(Index, Index.getEntry(Entries[I])));
      });
      for (size_t I = Start; I != End; ++I) {
        Expected<EncodedModule> &Module = *Encoded[I - Start];
        if (!Module)
          return Module.takeError();
        if (Error E = Take(Entries[I], std::move(*Module)))
          return E;
      }
      Report("published " + Twine(End) + " of " + Twine(Entries.size()) +
             " modules");
    }
    return Error::success();
  };

  // The dictionaries, trained on a sample of the modules.
  std::vector<size_t> All(Index.size()), Sampled;
  for (size_t I = 0; I != Index.size(); ++I) {
    All[I] = I;
    if (I % std::max(1u, Options.SampleEvery) == 0)
      Sampled.push_back(I);
  }
  std::vector<std::string> FeatureSamples, PackSamples;
  if (Error E = EncodeAll(Sampled, [&](size_t, EncodedModule Module) {
        for (std::string &Features : Module.Features)
          FeatureSamples.push_back(std::move(Features));
        for (std::string &Frame : groupPacks(Module.Packs, Options).Frames)
          PackSamples.push_back(std::move(Frame));
        return Error::success();
      }))
    return E;
  WebHeader Header;
  Header.FeatureDictionary =
      trainDictionary(FeatureSamples, Options.FeatureDictionarySize);
  Header.PackDictionary =
      trainDictionary(PackSamples, Options.PackDictionarySize);
  FeatureSamples.clear();
  PackSamples.clear();
  Report("trained the dictionaries");

  Compressor FeatureCompressor(Header.FeatureDictionary,
                               Options.CompressionLevel);
  Compressor PackCompressor(Header.PackDictionary, Options.CompressionLevel);
  auto OpenFile = [&](WebFile File,
                      std::optional<raw_fd_ostream> &OS) -> Error {
    SmallString<256> Path(Output);
    sys::path::append(Path, getWebFileName(File));
    std::error_code EC;
    OS.emplace(Path, EC);
    if (EC)
      return createFileError(Path, EC);
    return Error::success();
  };
  std::optional<raw_fd_ostream> FeaturesOS, PacksOS, IndexOS;
  if (Error E = OpenFile(WebFile::Features, FeaturesOS))
    return E;
  if (Error E = OpenFile(WebFile::Packs, PacksOS))
    return E;
  if (Error E = OpenFile(WebFile::Index, IndexOS))
    return E;
  support::endian::Writer IndexW(*IndexOS, llvm::endianness::little);
  uint64_t FeaturesSize = 0, PacksSize = 0;
  auto WriteEntry = [&](uint64_t Pack) {
    IndexW.write<uint64_t>(FeaturesSize);
    IndexW.write<uint64_t>(Pack);
  };
  struct CompressionModule {
    PackFrames Grouped;
    std::vector<std::optional<Expected<std::string>>> Results;
  };
  struct CompressionTask {
    size_t Module;
    size_t Item;
    bool Feature;
  };
  constexpr size_t Batch = 512;
  for (size_t Start = 0; Start < All.size(); Start += Batch) {
    size_t End = std::min(All.size(), Start + Batch);
    std::vector<std::optional<Expected<EncodedModule>>> Encoded(End - Start);
    parallelFor(Start, End, [&](size_t I) {
      Encoded[I - Start].emplace(
          encodeModule(Index, Index.getEntry(All[I])));
    });

    std::vector<CompressionModule> Modules(End - Start);
    std::vector<CompressionTask> Tasks;
    for (size_t I = Start; I != End; ++I) {
      Expected<EncodedModule> &Module = *Encoded[I - Start];
      if (!Module)
        return Module.takeError();
      CompressionModule &Work = Modules[I - Start];
      Work.Grouped = groupPacks(Module->Packs, Options);
      size_t NumFeatures = Module->Features.size();
      size_t NumFrames = Work.Grouped.Frames.size();
      Work.Results.resize(NumFeatures + NumFrames);
      for (size_t Feature = 0; Feature != NumFeatures; ++Feature)
        Tasks.push_back({I - Start, Feature, true});
      for (size_t Frame = 0; Frame != NumFrames; ++Frame)
        Tasks.push_back({I - Start, NumFeatures + Frame, false});
    }

    // Compress across modules as well as within them. Compressing each module
    // in turn left most workers idle when modules had only a few functions.
    parallelFor(0, Tasks.size(), [&](size_t I) {
      const CompressionTask &Task = Tasks[I];
      const EncodedModule &Module = **Encoded[Task.Module];
      size_t NumFeatures = Module.Features.size();
      StringRef Input = Task.Feature
                            ? StringRef(Module.Features[Task.Item])
                            : StringRef(Modules[Task.Module]
                                            .Grouped.Frames[Task.Item -
                                                           NumFeatures]);
      Modules[Task.Module].Results[Task.Item].emplace(
          Task.Feature ? FeatureCompressor.compress(Input)
                       : PackCompressor.compress(Input));
    });

    // Write in corpus order so the packed offsets and module directory stay
    // deterministic regardless of the compression task completion order.
    for (size_t I = Start; I != End; ++I) {
      size_t Local = I - Start;
      const IndexEntry &Indexed = Index.getEntry(All[I]);
      EncodedModule &Module = **Encoded[Local];
      CompressionModule &Work = Modules[Local];
      size_t NumFeatures = Module.Features.size();
      size_t NumFrames = Work.Grouped.Frames.size();
      Header.Modules.push_back(WebModule{Indexed.Path.str(),
                                         Header.NumFunctions,
                                         uint32_t(Module.Packs.size())});
      Header.NumFunctions += Module.Packs.size();

      std::vector<uint64_t> FrameOffsets;
      for (size_t Frame = 0; Frame != NumFrames; ++Frame) {
        Expected<std::string> &Packs = *Work.Results[NumFeatures + Frame];
        if (!Packs)
          return Packs.takeError();
        FrameOffsets.push_back(PacksSize);
        *PacksOS << *Packs;
        PacksSize += Packs->size();
      }
      for (size_t Feature = 0; Feature != NumFeatures; ++Feature) {
        Expected<std::string> &Features = *Work.Results[Feature];
        if (!Features)
          return Features.takeError();
        auto [Frame, Slot] = Work.Grouped.Of[Feature];
        uint64_t Size = (*Work.Results[NumFeatures + Frame])->size();
        if (!PackLocation::fits(FrameOffsets[Frame], Size, Slot))
          return createStringError(
              Indexed.Path + ": the packs are too large to publish");
        WriteEntry(PackLocation::encode(FrameOffsets[Frame], Size, Slot));
        *FeaturesOS << *Features;
        FeaturesSize += Features->size();
      }
    }
    Report("published " + Twine(End) + " of " + Twine(All.size()) +
           " modules");
  }
  if (!PackLocation::fits(PacksSize, 0, 0))
    return createStringError("the packs are too large to publish");
  WriteEntry(PackLocation::encode(PacksSize, 0, 0));
  if (Header.NumFunctions != Index.getNumFunctions())
    return createStringError("the index's functions differ from its modules'");
  for (std::optional<raw_fd_ostream> *OS : {&FeaturesOS, &PacksOS, &IndexOS}) {
    (*OS)->close();
    if ((*OS)->has_error())
      return createStringError("cannot write the published corpus: " +
                               (*OS)->error().message());
  }

  // The postings, as indexed.
  StringRef Records = Index.getPostingRecords();
  StringRef Lists = Index.getPostingLists();
  Header.NumPostingKeys = Records.size() / PostingRecord::Size;
  for (uint64_t I = 0; I < Header.NumPostingKeys;
       I += WebHeader::TopKeyStride) {
    PostingRecord Record =
        PostingRecord::read(Records.data() + I * PostingRecord::Size);
    Header.TopKeys.push_back(Record.Key);
    Header.TopListOffsets.push_back(Record.Offset);
  }
  Header.ListsSize = Lists.size();
  if (Error E = writeFile(Output, getWebFileName(WebFile::Keys), Records))
    return E;
  if (Error E = writeFile(Output, getWebFileName(WebFile::Lists), Lists))
    return E;

  std::string HeaderBytes;
  raw_string_ostream HeaderOS(HeaderBytes);
  Header.write(HeaderOS);
  // A corrupt header would mislead every query; it has a checksum.
  std::string Compressed(ZSTD_compressBound(HeaderBytes.size()), '\0');
  ZSTD_CCtx *Context = ZSTD_createCCtx();
  ZSTD_CCtx_setParameter(Context, ZSTD_c_compressionLevel,
                         Options.CompressionLevel);
  ZSTD_CCtx_setParameter(Context, ZSTD_c_checksumFlag, 1);
  size_t CompressedSize =
      ZSTD_compress2(Context, Compressed.data(), Compressed.size(),
                     HeaderBytes.data(), HeaderBytes.size());
  ZSTD_freeCCtx(Context);
  if (ZSTD_isError(CompressedSize))
    return createStringError(Twine("zstd: ") +
                             ZSTD_getErrorName(CompressedSize));
  Compressed.resize(CompressedSize);
  if (Error E = writeFile(Output, WebHeaderFileName, Compressed))
    return E;

  // The manifest names the build by what it holds.
  json::Object Files;
  uint64_t Build = xxh3_64bits(HeaderBytes);
  Files[WebHeaderFileName] = int64_t(Compressed.size());
  for (unsigned File = 0; File != NumWebFiles; ++File) {
    SmallString<256> Path(Output);
    StringRef Name = getWebFileName(WebFile(File));
    sys::path::append(Path, Name);
    uint64_t Size = 0;
    if (std::error_code EC = sys::fs::file_size(Path, Size))
      return createFileError(Path, EC);
    Files[Name] = int64_t(Size);
    Build = xxh3_64bits(Twine(Build).concat(Twine(Size)).str());
  }
  std::string Manifest;
  raw_string_ostream ManifestOS(Manifest);
  ManifestOS << formatv(
      "{0:2}", json::Value(json::Object{{"format", 1},
                                        {"build", utohexstr(Build, true)},
                                        {"files", std::move(Files)}}));
  ManifestOS << '\n';
  return writeFile(Output, WebManifestFileName, Manifest);
}

} // namespace metaphir
} // namespace llvm
