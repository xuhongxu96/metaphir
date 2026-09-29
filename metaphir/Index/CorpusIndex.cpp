#include "metaphir/Index/CorpusIndex.h"
#include "metaphir/IR/Instruction.h"
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
#include "llvm/Support/raw_ostream.h"
#include "llvm/Support/xxhash.h"
#include <algorithm>
#include <limits>

namespace llvm {
namespace metaphir {

static constexpr StringLiteral Magic = "MPIRIDX";
static constexpr uint32_t FormatVersion = 4;

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

/// The instruction matcher names, in ID order: features are only meaningful
/// for the matchers they were computed with.
static SmallVector<StringRef, 64> getSchema() {
  SmallVector<StringRef, 64> Names;
#define MIR_INSTRUCTION_MATCHER_ID(Name)                                       \
  Names.push_back(Instruction::getOpcodeName(Instruction::I_##Name));
#include "metaphir/IR/InstructionMatchers.def"
  return Names;
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

IndexedModule IndexedModule::compute(StringRef Path, const Module &Module) {
  IndexedModule Indexed;
  Indexed.Path = Path.str();
  Indexed.Parsed = true;
  for (const Function &F : Module) {
    if (F.isDeclaration())
      continue;
    IndexedFunction Function{IndexedFunction::hashName(F.getName()),
                             FunctionFeatures::compute(F)};
    Indexed.Summary.merge(Function.Features);
    Indexed.Functions.push_back(std::move(Function));
  }
  return Indexed;
}

Expected<IndexedModule> CorpusIndex::indexFile(StringRef Root, StringRef Path) {
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
    Indexed = IndexedModule::compute(Path, *M);
  else
    Indexed.Path = Path.str();
  Indexed.Stamp = stampOf(Status);
  return Indexed;
}

// Encoding. Numbers are ULEB128 unless noted. A feature set is its
// instruction mask; its shapes (a count, then for each the difference of its
// instruction matcher from the one before, and its flags and width); its edge
// and sibling keys (each a count, then each key as the difference from the
// one before); and its globals: a module summary lists their hashes (8 bytes
// each), and a function the positions of its own in its module's list (a
// count, then differences).

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

static void writeShapes(raw_ostream &OS, ArrayRef<uint32_t> Shapes) {
  encodeULEB128(Shapes.size(), OS);
  unsigned PreviousID = 0;
  for (uint32_t Shape : Shapes) {
    unsigned ID = FunctionFeatures::getShapeID(Shape);
    encodeULEB128(ID - PreviousID, OS);
    encodeULEB128(Shape - FunctionFeatures::getShapeKey(
                              Instruction::InstructionID(ID), 0, 0),
                  OS);
    PreviousID = ID;
  }
}

static void writeInstructionsAndEdges(raw_ostream &OS,
                                      const FunctionFeatures &Features) {
  encodeULEB128(Features.Instructions, OS);
  writeShapes(OS, Features.Shapes);
  writeSortedKeys<uint16_t>(OS, Features.Edges);
  writeSortedKeys<uint16_t>(OS, Features.Siblings);
}

static void writeSummary(raw_ostream &OS, const FunctionFeatures &Summary) {
  writeInstructionsAndEdges(OS, Summary);
  encodeULEB128(Summary.Globals.size(), OS);
  support::endian::Writer W(OS, llvm::endianness::little);
  for (uint64_t Global : Summary.Globals)
    W.write<uint64_t>(Global);
}

static void writeFunction(raw_ostream &OS, const IndexedFunction &Function,
                          ArrayRef<uint64_t> ModuleGlobals) {
  support::endian::Writer(OS, llvm::endianness::little)
      .write<uint64_t>(Function.NameHash);
  writeInstructionsAndEdges(OS, Function.Features);
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
    SmallVector<StringRef, 64> Schema = getSchema();
    encodeULEB128(Schema.size(), OS);
    for (StringRef Name : Schema)
      writeString(OS, Name);
    writeString(OS, canonicalPath(Root));
    encodeULEB128(Modules.size(), OS);
    encodeULEB128(Directory.size(), OS);
    OS << Directory;
    encodeULEB128(Summaries.size(), OS);
    OS << Summaries;
    OS << Functions;
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

/// Reads what writeShapes wrote. Returns false if a shape is not valid.
static bool readShapes(DataExtractor &Data, DataExtractor::Cursor &C,
                       SmallVectorImpl<uint32_t> &Shapes) {
  uint64_t NumShapes = Data.getULEB128(C);
  uint64_t ID = 0;
  for (uint64_t I = 0; I != NumShapes && C; ++I) {
    ID += Data.getULEB128(C);
    uint64_t FlagsAndWidth = Data.getULEB128(C);
    if (ID >= 64 || FlagsAndWidth >= (uint64_t(1) << 26))
      return false;
    Shapes.push_back(
        FunctionFeatures::getShapeKey(Instruction::InstructionID(ID), 0, 0) +
        FlagsAndWidth);
  }
  return true;
}

/// Reads what writeInstructionsAndEdges wrote. Returns false if the keys are
/// not valid.
static bool readInstructionsAndEdges(DataExtractor &Data,
                                     DataExtractor::Cursor &C,
                                     FunctionFeatures &Features) {
  Features.Instructions = Data.getULEB128(C);
  return readShapes(Data, C, Features.Shapes) &&
         readSortedKeys(Data, C, Features.Edges) &&
         readSortedKeys(Data, C, Features.Siblings);
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
  SmallVector<StringRef, 64> Schema = getSchema();
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
  Index.FunctionsStart = C.tell();
  if (!C)
    return malformed(File, toString(C.takeError()));
  return Index;
}

const IndexEntry *CorpusIndex::lookup(StringRef Path) const {
  auto Find = [&](StringRef Absolute) -> const IndexEntry * {
    if (!Absolute.consume_front(Root) ||
        !Absolute.consume_front(sys::path::get_separator()))
      return nullptr;
    auto It = ByPath.find(Absolute);
    return It == ByPath.end() ? nullptr : &Entries[It->second];
  };
  // Resolving symbolic links costs a system call per path component, so the
  // lexical path is tried first.
  if (const IndexEntry *Entry = Find(absolutePath(Path)))
    return Entry;
  return Find(canonicalPath(Path));
}

Expected<FunctionFeatures>
CorpusIndex::readSummary(const IndexEntry &Entry) const {
  DataExtractor Data(Buffer->getBuffer().slice(0, FunctionsStart),
                     /*IsLittleEndian=*/true);
  DataExtractor::Cursor C(SummariesStart + Entry.SummaryOffset);
  FunctionFeatures Summary;
  bool Valid = readInstructionsAndEdges(Data, C, Summary);
  uint64_t NumGlobals = Data.getULEB128(C);
  for (uint64_t I = 0; I != NumGlobals && C; ++I)
    Summary.Globals.push_back(Data.getU64(C));
  if (!C || !Valid)
    return malformedEntry(Buffer->getBufferIdentifier(), Entry, C);
  return Summary;
}

Expected<std::vector<IndexedFunction>>
CorpusIndex::readFunctions(const IndexEntry &Entry) const {
  Expected<FunctionFeatures> Summary = readSummary(Entry);
  if (!Summary)
    return Summary.takeError();
  DataExtractor Data(Buffer->getBuffer(), /*IsLittleEndian=*/true);
  DataExtractor::Cursor C(FunctionsStart + Entry.FunctionsOffset);
  std::vector<IndexedFunction> Functions(Entry.NumFunctions);
  bool Valid = true;
  for (IndexedFunction &Function : Functions) {
    Function.NameHash = Data.getU64(C);
    Valid &= readInstructionsAndEdges(Data, C, Function.Features);
    uint64_t NumGlobals = Data.getULEB128(C);
    uint64_t Position = 0;
    for (uint64_t I = 0; I != NumGlobals && C && Valid; ++I) {
      Position += Data.getULEB128(C);
      Valid = Position < Summary->Globals.size();
      if (Valid)
        Function.Features.Globals.push_back(Summary->Globals[Position]);
    }
    if (!C || !Valid)
      return malformedEntry(Buffer->getBufferIdentifier(), Entry, C);
  }
  if (!C)
    return malformedEntry(Buffer->getBufferIdentifier(), Entry, C);
  return Functions;
}

} // namespace metaphir
} // namespace llvm
