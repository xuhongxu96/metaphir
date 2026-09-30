#include "metaphir/Index/CorpusIndex.h"
#include "metaphir/IR/Instruction.h"
#include "metaphir/Index/FeatureCoding.h"
#include "llvm/ADT/DenseMap.h"
#include "llvm/ADT/STLExtras.h"
#include "llvm/ADT/SmallString.h"
#include "llvm/Config/llvm-config.h"
#include "llvm/IR/LLVMContext.h"
#include "llvm/IR/Module.h"
#include "llvm/IRReader/IRReader.h"
#include "llvm/Support/DataExtractor.h"
#include "llvm/Support/EndianStream.h"
#include "llvm/Support/FileSystem.h"
#include "llvm/Support/LEB128.h"
#include "llvm/Support/Path.h"
#include "llvm/Support/SourceMgr.h"
#include "llvm/Support/VCSRevision.h"
#include "llvm/Support/raw_ostream.h"
#include "llvm/Support/xxhash.h"
#include <algorithm>
#include <limits>
#include <map>

namespace llvm {
namespace metaphir {

static constexpr StringLiteral Magic = "MPIRIDX";
static constexpr uint32_t FormatVersion = 7;

bool collectLLVMIRFiles(StringRef Input, SmallVectorImpl<std::string> &Files,
                        raw_ostream &Err) {
  bool IsDirectory = false;
  if (std::error_code EC = sys::fs::is_directory(Input, IsDirectory)) {
    Err << Input << ": " << EC.message() << '\n';
    return false;
  }

  if (!IsDirectory) {
    Files.push_back(Input.str());
    return true;
  }

  SmallVector<std::string, 16> DirectoryFiles;
  std::error_code EC;
  for (sys::fs::recursive_directory_iterator I(Input, EC, false), E;
       I != E && !EC; I.increment(EC)) {
    StringRef Path = I->path();
    StringRef Extension = sys::path::extension(Path);
    if (Extension != ".ll" && Extension != ".bc")
      continue;
    // The directory entry usually tells the file's type without a stat.
    sys::fs::file_type Type = I->type();
    if (Type == sys::fs::file_type::regular_file ||
        ((Type == sys::fs::file_type::symlink_file ||
          Type == sys::fs::file_type::type_unknown) &&
         sys::fs::is_regular_file(Path)))
      DirectoryFiles.push_back(Path.str());
  }

  if (EC) {
    Err << Input << ": " << EC.message() << '\n';
    return false;
  }

  llvm::sort(DirectoryFiles);
  Files.append(DirectoryFiles);
  return true;
}

/// Path made absolute and without dots.
static std::string absolutePath(StringRef Path) {
  SmallString<256> Absolute(Path);
  (void)sys::fs::make_absolute(Absolute);
  sys::path::remove_dots(Absolute, /*remove_dot_dot=*/true);
  return std::string(Absolute);
}

/// Path made absolute, without dots, and with symbolic links resolved when
/// it exists.
static std::string canonicalPath(StringRef Path) {
  SmallString<256> Real;
  if (!sys::fs::real_path(Path, Real))
    return std::string(Real);
  return absolutePath(Path);
}

static FileStamp stampOf(const sys::fs::file_status &Status) {
  return FileStamp{
      Status.getSize(),
      uint64_t(Status.getLastModificationTime().time_since_epoch().count())};
}

std::optional<FileStamp> FileStamp::of(StringRef Path) {
  sys::fs::file_status Status;
  if (sys::fs::status(Path, Status))
    return std::nullopt;
  return stampOf(Status);
}

uint64_t IndexedFunction::hashName(StringRef Name) { return xxh3_64bits(Name); }

IndexedModule IndexedModule::compute(StringRef Path, const Module &Module,
                                     const FeatureOptions &Options) {
  IndexedModule Indexed;
  Indexed.Path = Path.str();
  Indexed.Parsed = true;
  // Merging ands whether each function has value facts.
  Indexed.Summary.HasValueFacts = Options.ValueFacts;
  for (const Function &F : Module) {
    if (F.isDeclaration())
      continue;
    IndexedFunction Function{IndexedFunction::hashName(F.getName()),
                             FunctionFeatures::compute(F, Options)};
    Indexed.Summary.merge(Function.Features);
    Indexed.Functions.push_back(std::move(Function));
  }
  return Indexed;
}

Expected<IndexedModule> CorpusIndex::indexFile(StringRef Root, StringRef Path,
                                               const FeatureOptions &Options) {
  SmallString<256> FullPath(Root);
  sys::path::append(FullPath, Path);
  sys::fs::file_status Status;
  if (std::error_code EC = sys::fs::status(FullPath, Status))
    return createFileError(FullPath, EC);

  LLVMContext Context;
  SMDiagnostic Diag;
  std::unique_ptr<Module> M = parseIRFile(FullPath, Diag, Context);
  IndexedModule Indexed;
  if (M)
    Indexed = IndexedModule::compute(Path, *M, Options);
  else
    Indexed.Path = Path.str();
  Indexed.Stamp = stampOf(Status);
  return Indexed;
}

// Encoding. Numbers are ULEB128 unless noted. A feature set is its coarse
// features, which every query reads, then its fine ones, behind their size.
// The coarse ones are its instruction mask; its edge and sibling keys (each a
// count, then each key as the difference from the one before); and its
// globals: a module summary lists their hashes (8 bytes each), and a function
// the positions of its own in its module's list (a count, then differences).
// The fine ones are its signatures (a count, then for each the difference of
// its instruction matcher from the one before, its flags, and its result and
// operand type codes); its fact and measure keys (like the edge keys); and
// whether it has value facts (a byte).

static void writeSummary(raw_ostream &OS, const FunctionFeatures &Summary) {
  writeCoarseFeatures(OS, Summary);
  encodeULEB128(Summary.Globals.size(), OS);
  support::endian::Writer W(OS, llvm::endianness::little);
  for (uint64_t Global : Summary.Globals)
    W.write<uint64_t>(Global);
  writeFineFeatures(OS, Summary);
}

static void writeFunction(raw_ostream &OS, const IndexedFunction &Function,
                          ArrayRef<uint64_t> ModuleGlobals) {
  support::endian::Writer(OS, llvm::endianness::little)
      .write<uint64_t>(Function.NameHash);
  writeCoarseFeatures(OS, Function.Features);
  encodeULEB128(Function.Features.Globals.size(), OS);
  uint64_t Previous = 0;
  for (uint64_t Global : Function.Features.Globals) {
    uint64_t Position =
        llvm::lower_bound(ModuleGlobals, Global) - ModuleGlobals.begin();
    assert(Position < ModuleGlobals.size() &&
           ModuleGlobals[Position] == Global &&
           "function global missing from its module's summary");
    encodeULEB128(Position - Previous, OS);
    Previous = Position;
  }
  writeFineFeatures(OS, Function.Features);
}

/// Writes the posting keys and lists of the modules' functions, numbered in
/// order across them.
static void writePostings(raw_ostream &OS, ArrayRef<IndexedModule> Modules) {
  DenseMap<std::pair<uint8_t, uint64_t>, std::vector<uint32_t>> Postings;
  uint32_t Number = 0;
  for (const IndexedModule &Module : Modules)
    for (const IndexedFunction &Function : Module.Functions) {
      forEachPostingKey(Function.Features, [&](const PostingKey &Key) {
        Postings[{Key.Kind, Key.Value}].push_back(Number);
      });
      ++Number;
    }
  std::vector<std::pair<uint8_t, uint64_t>> Keys;
  Keys.reserve(Postings.size());
  for (const auto &Posting : Postings)
    Keys.push_back(Posting.first);
  llvm::sort(Keys);

  std::string Lists;
  raw_string_ostream ListsOS(Lists);
  encodeULEB128(Keys.size(), OS);
  for (const auto &Key : Keys) {
    const std::vector<uint32_t> &Numbers = Postings[Key];
    PostingRecord{PostingKey{PostingKey::KeyKind(Key.first), Key.second},
                  uint32_t(Numbers.size()), Lists.size()}
        .write(OS);
    writePostingList(ListsOS, Numbers);
  }
  OS << Lists;
}

Error CorpusIndex::write(StringRef File, StringRef Root,
                         ArrayRef<IndexedModule> Modules) {
  std::string Directory, Summaries, Functions;
  raw_string_ostream DirectoryOS(Directory), SummariesOS(Summaries),
      FunctionsOS(Functions);
  for (const IndexedModule &Module : Modules) {
    writeString(DirectoryOS, Module.Path);
    encodeULEB128(Module.Stamp.Size, DirectoryOS);
    encodeULEB128(Module.Stamp.ModificationTime, DirectoryOS);
    DirectoryOS << char(Module.Parsed);
    encodeULEB128(Module.Functions.size(), DirectoryOS);
    encodeULEB128(Summaries.size(), DirectoryOS);
    encodeULEB128(Functions.size(), DirectoryOS);
    writeSummary(SummariesOS, Module.Summary);
    for (const IndexedFunction &Function : Module.Functions)
      writeFunction(FunctionsOS, Function, Module.Summary.Globals);
  }

  return writeToOutput(File, [&](raw_ostream &OS) -> Error {
    OS << Magic;
    support::endian::Writer(OS, llvm::endianness::little)
        .write<uint32_t>(FormatVersion);
    writeString(OS, LLVM_VERSION_STRING);
    SmallVector<std::string, 96> Schema = getFeatureSchema();
    encodeULEB128(Schema.size(), OS);
    for (const std::string &Name : Schema)
      writeString(OS, Name);
    writeString(OS, canonicalPath(Root));
    encodeULEB128(Modules.size(), OS);
    encodeULEB128(Directory.size(), OS);
    OS << Directory;
    encodeULEB128(Summaries.size(), OS);
    OS << Summaries;
    encodeULEB128(Functions.size(), OS);
    OS << Functions;
    writePostings(OS, Modules);
    return Error::success();
  });
}

static Error malformed(StringRef File, const Twine &Message) {
  return createStringError(inconvertibleErrorCode(), File + ": " + Message);
}

/// The error for a read of Entry's features that went wrong.
static Error malformedEntry(StringRef File, const IndexEntry &Entry,
                            DataExtractor::Cursor &C) {
  Error E = C.takeError();
  std::string Reason = E ? toString(std::move(E)) : "invalid features";
  return malformed(File, "entry of " + Entry.Path + ": " + Reason);
}

Expected<CorpusIndex> CorpusIndex::read(StringRef File) {
  ErrorOr<std::unique_ptr<MemoryBuffer>> Buffer =
      MemoryBuffer::getFile(File, /*IsText=*/false,
                            /*RequiresNullTerminator=*/false);
  if (!Buffer)
    return createFileError(File, Buffer.getError());

  CorpusIndex Index;
  Index.Buffer = std::move(*Buffer);
  DataExtractor Data(Index.Buffer->getBuffer(), /*IsLittleEndian=*/true);
  DataExtractor::Cursor C(0);
  if (Data.getBytes(C, Magic.size()) != Magic) {
    consumeError(C.takeError());
    return malformed(File, "not a MetaphIR index");
  }
  if (uint32_t Version = Data.getU32(C); C && Version != FormatVersion)
    return malformed(File, "index format version " + Twine(Version) +
                               ", expected " + Twine(FormatVersion) +
                               "; rebuild it");
  if (StringRef Version = readString(Data, C);
      C && Version != LLVM_VERSION_STRING)
    return malformed(File, "index built with LLVM " + Version +
                               ", expected " LLVM_VERSION_STRING);
  SmallVector<std::string, 96> Schema = getFeatureSchema();
  uint64_t NumNames = Data.getULEB128(C);
  bool SameSchema = C && NumNames == Schema.size();
  for (uint64_t I = 0; I != NumNames && C; ++I)
    SameSchema &= I < Schema.size() && readString(Data, C) == Schema[I];
  if (C && !SameSchema)
    return malformed(File,
                     "index built for other instruction matchers; rebuild it");
  Index.Root = readString(Data, C).str();

  uint64_t NumModules = Data.getULEB128(C);
  uint64_t DirectorySize = Data.getULEB128(C);
  uint64_t DirectoryEnd = C.tell() + DirectorySize;
  for (uint64_t I = 0; I != NumModules && C; ++I) {
    IndexEntry Entry;
    Entry.Path = readString(Data, C);
    Entry.Stamp.Size = Data.getULEB128(C);
    Entry.Stamp.ModificationTime = Data.getULEB128(C);
    Entry.Parsed = Data.getU8(C);
    Entry.NumFunctions = Data.getULEB128(C);
    Entry.SummaryOffset = Data.getULEB128(C);
    Entry.FunctionsOffset = Data.getULEB128(C);
    Index.ByPath[Entry.Path] = Index.Entries.size();
    Index.Entries.push_back(Entry);
  }
  if (C && C.tell() != DirectoryEnd)
    return malformed(File, "directory size mismatch");
  uint64_t SummariesSize = Data.getULEB128(C);
  Index.SummariesStart = C.tell();
  Data.skip(C, SummariesSize);
  uint64_t FunctionsSize = Data.getULEB128(C);
  Index.FunctionsStart = C.tell();
  Data.skip(C, FunctionsSize);
  Index.NumPostingKeys = Data.getULEB128(C);
  Index.PostingKeysStart = C.tell();
  if (C && Index.NumPostingKeys >
               (Data.size() - Index.PostingKeysStart) / PostingRecord::Size)
    return malformed(File, "posting keys past the end");
  Data.skip(C, Index.NumPostingKeys * PostingRecord::Size);
  Index.PostingListsStart = C.tell();
  if (!C)
    return malformed(File, toString(C.takeError()));

  uint64_t First = 0;
  for (const IndexEntry &Entry : Index.Entries) {
    Index.FirstFunction.push_back(First);
    First += Entry.NumFunctions;
  }
  if (First > UINT32_MAX)
    return malformed(File, "too many functions");
  Index.NumFunctions = First;
  return Index;
}

std::optional<std::string> CorpusIndex::getRelativePath(StringRef Path) const {
  auto Relative = [&](StringRef Absolute) -> std::optional<std::string> {
    if (!Absolute.consume_front(Root))
      return std::nullopt;
    if (Absolute.empty())
      return std::string();
    if (!Absolute.consume_front(sys::path::get_separator()))
      return std::nullopt;
    return Absolute.str();
  };
  // Resolving symbolic links costs a system call per path component, so the
  // lexical path is tried first.
  if (std::optional<std::string> Lexical = Relative(absolutePath(Path)))
    return Lexical;
  return Relative(canonicalPath(Path));
}

const IndexEntry *CorpusIndex::lookup(StringRef Path) const {
  auto Find = [&](StringRef Absolute) -> const IndexEntry * {
    if (!Absolute.consume_front(Root) ||
        !Absolute.consume_front(sys::path::get_separator()))
      return nullptr;
    auto It = ByPath.find(Absolute);
    return It == ByPath.end() ? nullptr : &Entries[It->second];
  };
  if (const IndexEntry *Entry = Find(absolutePath(Path)))
    return Entry;
  return Find(canonicalPath(Path));
}

/// The record of Key, if the index has it.
static std::optional<uint64_t> findPostingKey(StringRef Buffer, uint64_t Start,
                                              uint64_t NumKeys,
                                              const PostingKey &Key) {
  uint64_t Low = 0, High = NumKeys;
  while (Low < High) {
    uint64_t Middle = Low + (High - Low) / 2;
    if (PostingRecord::readKey(Buffer.data() + Start +
                               Middle * PostingRecord::Size) < Key)
      Low = Middle + 1;
    else
      High = Middle;
  }
  if (Low == NumKeys ||
      !(PostingRecord::readKey(Buffer.data() + Start +
                               Low * PostingRecord::Size) == Key))
    return std::nullopt;
  return Low;
}

uint64_t CorpusIndex::getPostingCount(const PostingKey &Key) const {
  std::optional<uint64_t> Record = findPostingKey(
      Buffer->getBuffer(), PostingKeysStart, NumPostingKeys, Key);
  if (!Record)
    return 0;
  return support::endian::read32le(Buffer->getBufferStart() + PostingKeysStart +
                                   *Record * PostingRecord::Size + 9);
}

Expected<std::vector<uint32_t>>
CorpusIndex::readPostings(const PostingKey &Key) const {
  std::optional<uint64_t> Record = findPostingKey(
      Buffer->getBuffer(), PostingKeysStart, NumPostingKeys, Key);
  if (!Record)
    return std::vector<uint32_t>();
  PostingRecord Found =
      PostingRecord::read(Buffer->getBufferStart() + PostingKeysStart +
                          *Record * PostingRecord::Size);
  Expected<std::vector<uint32_t>> Numbers = readPostingList(
      getPostingLists(), Found.Offset, Found.Count, NumFunctions);
  if (!Numbers)
    return malformed(Buffer->getBufferIdentifier(),
                     toString(Numbers.takeError()));
  return Numbers;
}

FunctionLocation CorpusIndex::locate(uint32_t Number) const {
  size_t Entry =
      llvm::upper_bound(FirstFunction, Number) - FirstFunction.begin() - 1;
  return {Entry, Number - FirstFunction[Entry]};
}

Expected<std::optional<std::vector<FunctionLocation>>>
CorpusIndex::findCandidates(const FeatureQuery &Query) const {
  std::optional<std::vector<SmallVector<PostingKey, 3>>> Chosen =
      choosePostingKeys(
          Query, [&](const PostingKey &Key) { return getPostingCount(Key); });
  if (!Chosen)
    return std::nullopt;
  std::map<PostingKey, std::vector<uint32_t>> Lists;
  for (const SmallVector<PostingKey, 3> &Keys : *Chosen)
    for (const PostingKey &Key : Keys) {
      if (Lists.count(Key))
        continue;
      Expected<std::vector<uint32_t>> Numbers = readPostings(Key);
      if (!Numbers)
        return Numbers.takeError();
      Lists[Key] = std::move(*Numbers);
    }
  std::vector<uint32_t> Candidates =
      combinePostings(*Chosen, [&](const PostingKey &Key) {
        return ArrayRef<uint32_t>(Lists[Key]);
      });

  std::vector<FunctionLocation> Locations;
  Locations.reserve(Candidates.size());
  for (uint32_t Number : Candidates)
    Locations.push_back(locate(Number));
  return Locations;
}

Expected<FunctionFeatures> CorpusIndex::readSummary(
    const IndexEntry &Entry,
    function_ref<bool(const FunctionFeatures &)> NeedsFine) const {
  DataExtractor Data(Buffer->getBuffer().slice(0, FunctionsStart),
                     /*IsLittleEndian=*/true);
  DataExtractor::Cursor C(SummariesStart + Entry.SummaryOffset);
  FunctionFeatures Summary;
  bool Valid = readCoarseFeatures(Data, C, Summary);
  uint64_t NumGlobals = Data.getULEB128(C);
  for (uint64_t I = 0; I != NumGlobals && C; ++I)
    Summary.Globals.push_back(Data.getU64(C));
  Valid = Valid && readFineFeatures(Data, C, Summary, NeedsFine);
  if (!C || !Valid)
    return malformedEntry(Buffer->getBufferIdentifier(), Entry, C);
  return Summary;
}

Expected<std::vector<IndexedFunction>> CorpusIndex::readFunctions(
    const IndexEntry &Entry,
    function_ref<bool(const FunctionFeatures &)> NeedsFine) const {
  Expected<FunctionFeatures> Summary =
      readSummary(Entry, [](const FunctionFeatures &) { return false; });
  if (!Summary)
    return Summary.takeError();
  DataExtractor Data(Buffer->getBuffer(), /*IsLittleEndian=*/true);
  DataExtractor::Cursor C(FunctionsStart + Entry.FunctionsOffset);
  std::vector<IndexedFunction> Functions(Entry.NumFunctions);
  bool Valid = true;
  for (IndexedFunction &Function : Functions) {
    Function.NameHash = Data.getU64(C);
    Valid &= readCoarseFeatures(Data, C, Function.Features);
    uint64_t NumGlobals = Data.getULEB128(C);
    uint64_t Position = 0;
    for (uint64_t I = 0; I != NumGlobals && C && Valid; ++I) {
      Position += Data.getULEB128(C);
      Valid = Position < Summary->Globals.size();
      if (Valid)
        Function.Features.Globals.push_back(Summary->Globals[Position]);
    }
    Valid = Valid && readFineFeatures(Data, C, Function.Features, NeedsFine);
    if (!C || !Valid)
      return malformedEntry(Buffer->getBufferIdentifier(), Entry, C);
  }
  if (!C)
    return malformedEntry(Buffer->getBufferIdentifier(), Entry, C);
  return Functions;
}

} // namespace metaphir
} // namespace llvm
