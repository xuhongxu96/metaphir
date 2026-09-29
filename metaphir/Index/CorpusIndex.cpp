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
#include "llvm/Support/Path.h"
#include "llvm/Support/SourceMgr.h"
#include "llvm/Support/raw_ostream.h"

namespace llvm {
namespace metaphir {

static constexpr StringLiteral Magic = "MPIRIDX1";
static constexpr uint32_t FormatVersion = 1;

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
    if (!sys::fs::is_regular_file(Path))
      continue;

    StringRef Extension = sys::path::extension(Path);
    if (Extension == ".ll" || Extension == ".bc")
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

/// Path made absolute, without dots, and with symbolic links resolved when
/// it exists.
static std::string canonicalPath(StringRef Path) {
  SmallString<256> Real;
  if (!sys::fs::real_path(Path, Real))
    return std::string(Real);
  SmallString<256> Absolute(Path);
  (void)sys::fs::make_absolute(Absolute);
  sys::path::remove_dots(Absolute, /*remove_dot_dot=*/true);
  return std::string(Absolute);
}

IndexedModule IndexedModule::compute(StringRef Path, const Module &Module) {
  IndexedModule Indexed;
  Indexed.Path = Path.str();
  Indexed.Parsed = true;
  unsigned Ordinal = 0;
  for (const Function &F : Module) {
    if (F.isDeclaration())
      continue;
    IndexedFunction Function{Ordinal++, F.getName().str(),
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
  Indexed.Size = Status.getSize();
  Indexed.ModificationTime =
      Status.getLastModificationTime().time_since_epoch().count();
  return Indexed;
}

bool CorpusIndex::isCurrent(const IndexedModule &Module, StringRef Path) {
  sys::fs::file_status Status;
  if (sys::fs::status(Path, Status))
    return false;
  return Status.getSize() == Module.Size &&
         uint64_t(
             Status.getLastModificationTime().time_since_epoch().count()) ==
             Module.ModificationTime;
}

static void writeString(support::endian::Writer &W, StringRef String) {
  W.write<uint32_t>(String.size());
  W.OS << String;
}

static void writeFeatures(support::endian::Writer &W,
                          const FunctionFeatures &Features) {
  W.write<uint64_t>(Features.Instructions);
  for (uint64_t Word : Features.Edges)
    W.write<uint64_t>(Word);
  W.write<uint32_t>(Features.Globals.size());
  for (uint64_t Global : Features.Globals)
    W.write<uint64_t>(Global);
}

Error CorpusIndex::write(StringRef File, StringRef Root,
                         ArrayRef<IndexedModule> Modules) {
  return writeToOutput(File, [&](raw_ostream &OS) -> Error {
    support::endian::Writer W(OS, llvm::endianness::little);
    OS << Magic;
    W.write<uint32_t>(FormatVersion);
    writeString(W, LLVM_VERSION_STRING);
    SmallVector<StringRef, 64> Schema = getSchema();
    W.write<uint32_t>(Schema.size());
    for (StringRef Name : Schema)
      writeString(W, Name);
    writeString(W, canonicalPath(Root));
    W.write<uint64_t>(Modules.size());
    for (const IndexedModule &Module : Modules) {
      writeString(W, Module.Path);
      W.write<uint64_t>(Module.Size);
      W.write<uint64_t>(Module.ModificationTime);
      W.write<uint8_t>(Module.Parsed);
      writeFeatures(W, Module.Summary);

      // The functions go last, behind their size, so readers can skip them.
      std::string Functions;
      raw_string_ostream FunctionsOS(Functions);
      support::endian::Writer FW(FunctionsOS, llvm::endianness::little);
      FW.write<uint32_t>(Module.Functions.size());
      for (const IndexedFunction &Function : Module.Functions) {
        FW.write<uint32_t>(Function.Ordinal);
        writeString(FW, Function.Name);
        writeFeatures(FW, Function.Features);
      }
      W.write<uint64_t>(Functions.size());
      OS << Functions;
    }
    return Error::success();
  });
}

static StringRef readString(DataExtractor &Data, DataExtractor::Cursor &C) {
  uint32_t Size = Data.getU32(C);
  return Data.getBytes(C, Size);
}

static FunctionFeatures readFeatures(DataExtractor &Data,
                                     DataExtractor::Cursor &C) {
  FunctionFeatures Features;
  Features.Instructions = Data.getU64(C);
  for (uint64_t &Word : Features.Edges)
    Word = Data.getU64(C);
  uint32_t NumGlobals = Data.getU32(C);
  for (uint32_t I = 0; I != NumGlobals && C; ++I)
    Features.Globals.push_back(Data.getU64(C));
  return Features;
}

static Error malformed(StringRef File, const Twine &Message) {
  return createStringError(inconvertibleErrorCode(), File + ": " + Message);
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
                               ", expected " + Twine(FormatVersion));
  if (StringRef Version = readString(Data, C);
      C && Version != LLVM_VERSION_STRING)
    return malformed(File, "index built with LLVM " + Version +
                               ", expected " LLVM_VERSION_STRING);
  SmallVector<StringRef, 64> Schema = getSchema();
  uint32_t NumNames = Data.getU32(C);
  bool SameSchema = C && NumNames == Schema.size();
  for (uint32_t I = 0; I != NumNames && C; ++I)
    SameSchema &= I < Schema.size() && readString(Data, C) == Schema[I];
  if (C && !SameSchema)
    return malformed(File,
                     "index built for other instruction matchers; rebuild it");
  Index.Root = readString(Data, C).str();

  uint64_t NumModules = Data.getU64(C);
  for (uint64_t I = 0; I != NumModules && C; ++I) {
    IndexedModule Module;
    Module.Path = readString(Data, C).str();
    Module.Size = Data.getU64(C);
    Module.ModificationTime = Data.getU64(C);
    Module.Parsed = Data.getU8(C);
    Module.Summary = readFeatures(Data, C);
    uint64_t FunctionsSize = Data.getU64(C);
    Index.FunctionOffsets.push_back(C.tell());
    Data.skip(C, FunctionsSize);
    Index.ByPath[Module.Path] = Index.Modules.size();
    Index.Modules.push_back(std::move(Module));
  }
  if (!C)
    return malformed(File, toString(C.takeError()));
  return Index;
}

const IndexedModule *CorpusIndex::lookup(StringRef Path) const {
  std::string Canonical = canonicalPath(Path);
  StringRef Relative(Canonical);
  if (!Relative.consume_front(Root) ||
      !Relative.consume_front(sys::path::get_separator()))
    return nullptr;
  auto It = ByPath.find(Relative);
  return It == ByPath.end() ? nullptr : &Modules[It->second];
}

unsigned CorpusIndex::getNumFunctions(const IndexedModule &Module) const {
  // read() checked the functions' size, which comes first.
  return support::endian::read32le(Buffer->getBufferStart() +
                                   FunctionOffsets[&Module - Modules.data()]);
}

Expected<std::vector<IndexedFunction>>
CorpusIndex::readFunctions(const IndexedModule &Module) const {
  assert(&Module >= Modules.data() &&
         &Module < Modules.data() + Modules.size() &&
         "module is not an entry of this index");
  DataExtractor Data(Buffer->getBuffer(), /*IsLittleEndian=*/true);
  DataExtractor::Cursor C(FunctionOffsets[&Module - Modules.data()]);
  std::vector<IndexedFunction> Functions;
  uint32_t NumFunctions = Data.getU32(C);
  for (uint32_t I = 0; I != NumFunctions && C; ++I) {
    IndexedFunction Function;
    Function.Ordinal = Data.getU32(C);
    Function.Name = readString(Data, C).str();
    Function.Features = readFeatures(Data, C);
    Functions.push_back(std::move(Function));
  }
  if (!C)
    return malformed(Buffer->getBufferIdentifier(), toString(C.takeError()));
  return Functions;
}

} // namespace metaphir
} // namespace llvm
