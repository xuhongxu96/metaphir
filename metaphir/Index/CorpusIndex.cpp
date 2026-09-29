#include "metaphir/Index/CorpusIndex.h"
#include "metaphir/IR/Instruction.h"
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

/// What the recorded features mean: the instruction matcher names in ID
/// order, the fact and measure vocabulary, the type encoding, and the LLVM
/// revision, whose value tracking the facts come from.
static SmallVector<std::string, 96> getSchema() {
  SmallVector<std::string, 96> Schema;
#define MIR_INSTRUCTION_MATCHER_ID(Name)                                       \
  Schema.push_back(Instruction::getOpcodeName(Instruction::I_##Name).str());
#include "metaphir/IR/InstructionMatchers.def"
  for (unsigned P = 0; P != Atom::NumPredicates; ++P)
    Schema.push_back(("atom:" + Atom::getName(Atom::Predicate(P))).str());
#define MIR_LLVM_VALUE_CLASS(Class) Schema.push_back("class:" #Class);
#include "metaphir/Matching/LLVMValueClasses.def"
  for (unsigned M = 0; M != unsigned(Measure::NumMeasures); ++M)
    Schema.push_back(("measure:" + getMeasureName(Measure(M))).str());
  Schema.push_back(
      ("literals:" + Twine(Atom::MinLiteral) + ".." + Twine(Atom::MaxLiteral))
          .str());
  Schema.push_back("types:1");
  Schema.push_back("llvm:" LLVM_REVISION);
  return Schema;
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

static void writeString(raw_ostream &OS, StringRef String) {
  encodeULEB128(String.size(), OS);
  OS << String;
}

template <typename T>
static void writeSortedKeys(raw_ostream &OS, ArrayRef<T> Keys) {
  encodeULEB128(Keys.size(), OS);
  T Previous = 0;
  for (T Key : Keys) {
    encodeULEB128(Key - Previous, OS);
    Previous = Key;
  }
}

static void writeSignatures(raw_ostream &OS, ArrayRef<Signature> Signatures) {
  encodeULEB128(Signatures.size(), OS);
  unsigned PreviousID = 0;
  for (const Signature &Sig : Signatures) {
    encodeULEB128(Sig.ID - PreviousID, OS);
    encodeULEB128(Sig.Flags, OS);
    encodeULEB128(Sig.Result, OS);
    for (TypeCode Operand : Sig.Operands)
      encodeULEB128(Operand, OS);
    PreviousID = Sig.ID;
  }
}

static void writeCoarse(raw_ostream &OS, const FunctionFeatures &Features) {
  encodeULEB128(Features.Instructions, OS);
  writeSortedKeys<uint16_t>(OS, Features.Edges);
  writeSortedKeys<uint16_t>(OS, Features.Siblings);
}

/// Writes the fine features behind their size, so readers can skip them.
static void writeFine(raw_ostream &OS, const FunctionFeatures &Features) {
  std::string Fine;
  raw_string_ostream FineOS(Fine);
  writeSignatures(FineOS, Features.Signatures);
  writeSortedKeys<uint32_t>(FineOS, Features.Facts);
  writeSortedKeys<uint32_t>(FineOS, Features.Measures);
  FineOS << char(Features.HasValueFacts);
  encodeULEB128(Fine.size(), OS);
  OS << Fine;
}

static void writeSummary(raw_ostream &OS, const FunctionFeatures &Summary) {
  writeCoarse(OS, Summary);
  encodeULEB128(Summary.Globals.size(), OS);
  support::endian::Writer W(OS, llvm::endianness::little);
  for (uint64_t Global : Summary.Globals)
    W.write<uint64_t>(Global);
  writeFine(OS, Summary);
}

static void writeFunction(raw_ostream &OS, const IndexedFunction &Function,
                          ArrayRef<uint64_t> ModuleGlobals) {
  support::endian::Writer(OS, llvm::endianness::little)
      .write<uint64_t>(Function.NameHash);
  writeCoarse(OS, Function.Features);
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
  writeFine(OS, Function.Features);
}

/// A posting key record: the key's kind (1 byte) and value (8), its list's
/// length (4) and offset among the lists (8), little-endian, so that keys
/// are looked up where they lie.
static constexpr uint64_t PostingKeySize = 21;

/// The coarse posting keys of a function's features.
template <typename Callback>
static void forEachPostingKey(const FunctionFeatures &Features, Callback Add) {
  for (uint64_t IDs = Features.Instructions; IDs; IDs &= IDs - 1)
    Add(PostingKey{PostingKey::Instruction, uint64_t(llvm::countr_zero(IDs))});
  for (uint16_t Edge : Features.Edges)
    Add(PostingKey{PostingKey::Edge, Edge});
  for (uint16_t Sibling : Features.Siblings)
    Add(PostingKey{PostingKey::Sibling, Sibling});
  for (uint64_t Global : Features.Globals)
    Add(PostingKey{PostingKey::Global, Global});
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
  support::endian::Writer W(OS, llvm::endianness::little);
  for (const auto &Key : Keys) {
    const std::vector<uint32_t> &Numbers = Postings[Key];
    W.write<uint8_t>(Key.first);
    W.write<uint64_t>(Key.second);
    W.write<uint32_t>(Numbers.size());
    W.write<uint64_t>(Lists.size());
    uint32_t Previous = 0;
    for (uint32_t N : Numbers) {
      encodeULEB128(N - Previous, ListsOS);
      Previous = N;
    }
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
    SmallVector<std::string, 96> Schema = getSchema();
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

static StringRef readString(DataExtractor &Data, DataExtractor::Cursor &C) {
  uint64_t Size = Data.getULEB128(C);
  return Data.getBytes(C, Size);
}

/// Reads what writeSortedKeys wrote. Returns false if a key does not fit T.
template <typename T>
static bool readSortedKeys(DataExtractor &Data, DataExtractor::Cursor &C,
                           SmallVectorImpl<T> &Keys) {
  uint64_t NumKeys = Data.getULEB128(C);
  uint64_t Key = 0;
  for (uint64_t I = 0; I != NumKeys && C; ++I) {
    Key += Data.getULEB128(C);
    if (Key > std::numeric_limits<T>::max())
      return false;
    Keys.push_back(Key);
  }
  return true;
}

/// Reads what writeSignatures wrote. Returns false if a signature is not
/// valid.
static bool readSignatures(DataExtractor &Data, DataExtractor::Cursor &C,
                           SmallVectorImpl<Signature> &Signatures) {
  uint64_t NumSignatures = Data.getULEB128(C);
  uint64_t ID = 0;
  for (uint64_t I = 0; I != NumSignatures && C; ++I) {
    ID += Data.getULEB128(C);
    if (ID >= Instruction::NumInstructionIDs)
      return false;
    Signature Sig;
    Sig.ID = Instruction::InstructionID(ID);
    uint64_t Flags = Data.getULEB128(C);
    if (Flags > UINT32_MAX)
      return false;
    Sig.Flags = Flags;
    Sig.Result = Data.getULEB128(C);
    for (TypeCode &Operand : Sig.Operands)
      Operand = Data.getULEB128(C);
    Signatures.push_back(Sig);
  }
  return true;
}

/// Reads what writeCoarse wrote. Returns false if the keys are not valid.
static bool readCoarse(DataExtractor &Data, DataExtractor::Cursor &C,
                       FunctionFeatures &Features) {
  Features.Instructions = Data.getULEB128(C);
  return readSortedKeys(Data, C, Features.Edges) &&
         readSortedKeys(Data, C, Features.Siblings);
}

/// Reads what writeFine wrote if NeedsFine, given the coarse features, asks
/// for it; otherwise skips it. Returns false if the features are not valid.
static bool readFine(DataExtractor &Data, DataExtractor::Cursor &C,
                     FunctionFeatures &Features,
                     function_ref<bool(const FunctionFeatures &)> NeedsFine) {
  uint64_t Size = Data.getULEB128(C);
  uint64_t End = C.tell() + Size;
  Features.Fine = false;
  if (NeedsFine && !NeedsFine(Features)) {
    Data.skip(C, Size);
    return true;
  }
  Features.Fine = true;
  if (!readSignatures(Data, C, Features.Signatures) ||
      !readSortedKeys(Data, C, Features.Facts) ||
      !readSortedKeys(Data, C, Features.Measures))
    return false;
  Features.HasValueFacts = Data.getU8(C);
  return !C || C.tell() == End;
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
  SmallVector<std::string, 96> Schema = getSchema();
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
               (Data.size() - Index.PostingKeysStart) / PostingKeySize)
    return malformed(File, "posting keys past the end");
  Data.skip(C, Index.NumPostingKeys * PostingKeySize);
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

/// The key of the posting key record at Index.
static PostingKey postingKeyAt(StringRef Buffer, uint64_t Start,
                               uint64_t Index) {
  const char *Record = Buffer.data() + Start + Index * PostingKeySize;
  return PostingKey{PostingKey::KeyKind(uint8_t(Record[0])),
                    support::endian::read64le(Record + 1)};
}

/// The record of Key, if the index has it.
static std::optional<uint64_t> findPostingKey(StringRef Buffer, uint64_t Start,
                                              uint64_t NumKeys,
                                              const PostingKey &Key) {
  uint64_t Low = 0, High = NumKeys;
  while (Low < High) {
    uint64_t Middle = Low + (High - Low) / 2;
    if (postingKeyAt(Buffer, Start, Middle) < Key)
      Low = Middle + 1;
    else
      High = Middle;
  }
  if (Low == NumKeys || !(postingKeyAt(Buffer, Start, Low) == Key))
    return std::nullopt;
  return Low;
}

uint64_t CorpusIndex::getPostingCount(const PostingKey &Key) const {
  std::optional<uint64_t> Record = findPostingKey(
      Buffer->getBuffer(), PostingKeysStart, NumPostingKeys, Key);
  if (!Record)
    return 0;
  return support::endian::read32le(Buffer->getBufferStart() + PostingKeysStart +
                                   *Record * PostingKeySize + 9);
}

Expected<std::vector<uint32_t>>
CorpusIndex::readPostings(const PostingKey &Key) const {
  std::optional<uint64_t> Record = findPostingKey(
      Buffer->getBuffer(), PostingKeysStart, NumPostingKeys, Key);
  if (!Record)
    return std::vector<uint32_t>();
  const char *Fields =
      Buffer->getBufferStart() + PostingKeysStart + *Record * PostingKeySize;
  uint32_t Count = support::endian::read32le(Fields + 9);
  uint64_t Offset = support::endian::read64le(Fields + 13);
  DataExtractor Data(Buffer->getBuffer(), /*IsLittleEndian=*/true);
  DataExtractor::Cursor C(PostingListsStart + Offset);
  std::vector<uint32_t> Numbers;
  Numbers.reserve(Count);
  uint64_t Number = 0;
  for (uint32_t I = 0; I != Count && C; ++I) {
    Number += Data.getULEB128(C);
    Numbers.push_back(Number);
  }
  if (!C)
    return malformed(Buffer->getBufferIdentifier(), toString(C.takeError()));
  if (!Numbers.empty() && Numbers.back() >= NumFunctions)
    return malformed(Buffer->getBufferIdentifier(),
                     "posting past the last function");
  return Numbers;
}

FunctionLocation CorpusIndex::locate(uint32_t Number) const {
  size_t Entry =
      llvm::upper_bound(FirstFunction, Number) - FirstFunction.begin() - 1;
  return {Entry, Number - FirstFunction[Entry]};
}

Expected<std::optional<std::vector<FunctionLocation>>>
CorpusIndex::findCandidates(const FeatureQuery &Query) const {
  // The lists intersected per variant: the shortest few narrow the most.
  constexpr size_t MaxIntersected = 3;
  std::vector<uint32_t> Candidates;
  for (unsigned Variant = 0; Variant != Query.size(); ++Variant) {
    FunctionFeatures Required;
    const FeatureRequirement &Requirement = Query.getRequirement(Variant);
    Required.Instructions = Requirement.Instructions;
    for (auto [User, Operand] : Requirement.Edges)
      Required.Edges.push_back(FunctionFeatures::getEdgeKey(User, Operand));
    Required.Siblings.assign(Requirement.Siblings.begin(),
                             Requirement.Siblings.end());
    Required.Globals.assign(Requirement.Globals.begin(),
                            Requirement.Globals.end());
    SmallVector<std::pair<uint64_t, PostingKey>, 8> Keys;
    forEachPostingKey(Required, [&](const PostingKey &Key) {
      Keys.push_back({getPostingCount(Key), Key});
    });
    if (Keys.empty())
      return std::nullopt;
    llvm::sort(Keys,
               [](const auto &L, const auto &R) { return L.first < R.first; });
    if (Keys.front().first == 0)
      continue;

    std::vector<uint32_t> Matching;
    for (size_t I = 0; I != std::min(Keys.size(), MaxIntersected); ++I) {
      Expected<std::vector<uint32_t>> Numbers = readPostings(Keys[I].second);
      if (!Numbers)
        return Numbers.takeError();
      if (I == 0) {
        Matching = std::move(*Numbers);
        continue;
      }
      std::vector<uint32_t> Common;
      std::set_intersection(Matching.begin(), Matching.end(), Numbers->begin(),
                            Numbers->end(), std::back_inserter(Common));
      Matching = std::move(Common);
    }
    std::vector<uint32_t> Union;
    std::set_union(Candidates.begin(), Candidates.end(), Matching.begin(),
                   Matching.end(), std::back_inserter(Union));
    Candidates = std::move(Union);
  }

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
  bool Valid = readCoarse(Data, C, Summary);
  uint64_t NumGlobals = Data.getULEB128(C);
  for (uint64_t I = 0; I != NumGlobals && C; ++I)
    Summary.Globals.push_back(Data.getU64(C));
  Valid = Valid && readFine(Data, C, Summary, NeedsFine);
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
    Valid &= readCoarse(Data, C, Function.Features);
    uint64_t NumGlobals = Data.getULEB128(C);
    uint64_t Position = 0;
    for (uint64_t I = 0; I != NumGlobals && C && Valid; ++I) {
      Position += Data.getULEB128(C);
      Valid = Position < Summary->Globals.size();
      if (Valid)
        Function.Features.Globals.push_back(Summary->Globals[Position]);
    }
    Valid = Valid && readFine(Data, C, Function.Features, NeedsFine);
    if (!C || !Valid)
      return malformedEntry(Buffer->getBufferIdentifier(), Entry, C);
  }
  if (!C)
    return malformedEntry(Buffer->getBufferIdentifier(), Entry, C);
  return Functions;
}

} // namespace metaphir
} // namespace llvm
