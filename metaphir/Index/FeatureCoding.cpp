#include "metaphir/Index/FeatureCoding.h"
#include "metaphir/IR/Instruction.h"
#include "llvm/Support/EndianStream.h"
#include "llvm/Support/LEB128.h"
#include "llvm/Support/VCSRevision.h"
#include "llvm/Support/raw_ostream.h"
#include <limits>

namespace llvm {
namespace metaphir {

void writeString(raw_ostream &OS, StringRef String) {
  encodeULEB128(String.size(), OS);
  OS << String;
}

StringRef readString(DataExtractor &Data, DataExtractor::Cursor &C) {
  uint64_t Size = Data.getULEB128(C);
  return Data.getBytes(C, Size);
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

void writeCoarseFeatures(raw_ostream &OS, const FunctionFeatures &Features) {
  encodeULEB128(Features.Instructions, OS);
  writeSortedKeys<uint16_t>(OS, Features.Edges);
  writeSortedKeys<uint16_t>(OS, Features.Siblings);
}

bool readCoarseFeatures(DataExtractor &Data, DataExtractor::Cursor &C,
                        FunctionFeatures &Features) {
  Features.Instructions = Data.getULEB128(C);
  return readSortedKeys(Data, C, Features.Edges) &&
         readSortedKeys(Data, C, Features.Siblings);
}

void writeFineFeatures(raw_ostream &OS, const FunctionFeatures &Features) {
  std::string Fine;
  raw_string_ostream FineOS(Fine);
  writeSignatures(FineOS, Features.Signatures);
  writeSortedKeys<uint32_t>(FineOS, Features.Facts);
  writeSortedKeys<uint32_t>(FineOS, Features.Measures);
  FineOS << char(Features.HasValueFacts);
  encodeULEB128(Fine.size(), OS);
  OS << Fine;
}

bool readFineFeatures(DataExtractor &Data, DataExtractor::Cursor &C,
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

void writeFunctionFeatures(raw_ostream &OS, const FunctionFeatures &Features) {
  writeCoarseFeatures(OS, Features);
  writeSortedKeys<uint64_t>(OS, Features.Globals);
  writeFineFeatures(OS, Features);
}

Expected<FunctionFeatures> readFunctionFeatures(StringRef Bytes) {
  DataExtractor Data(Bytes, /*IsLittleEndian=*/true);
  DataExtractor::Cursor C(0);
  FunctionFeatures Features;
  bool Valid = readCoarseFeatures(Data, C, Features) &&
               readSortedKeys(Data, C, Features.Globals) &&
               readFineFeatures(Data, C, Features, nullptr);
  if (!C)
    return createStringError("function features: " + toString(C.takeError()));
  if (!Valid || C.tell() != Bytes.size())
    return createStringError("function features: invalid");
  return Features;
}

SmallVector<std::string, 96> getFeatureSchema() {
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

} // namespace metaphir
} // namespace llvm
