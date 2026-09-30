#include "metaphir/Index/FunctionPack.h"
#include "llvm/ADT/SmallPtrSet.h"
#include "llvm/Bitcode/BitcodeReader.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/InstIterator.h"
#include "llvm/IR/Instruction.h"
#include "llvm/IR/Module.h"
#include "llvm/Support/DataExtractor.h"
#include "llvm/Support/LEB128.h"
#include "llvm/Support/MemoryBufferRef.h"
#include "llvm/Support/raw_ostream.h"

namespace llvm {
namespace metaphir {

// A pack is the function's index (ULEB128), the number of uses (ULEB128),
// two bits per use, four to a byte (OneUse, then OneUser, from the lowest
// bit), and the bitcode.

void FunctionPack::encode(std::string &Out) const {
  raw_string_ostream OS(Out);
  encodeULEB128(FunctionIndex, OS);
  encodeULEB128(Uses.size(), OS);
  for (size_t I = 0; I < Uses.size(); I += 4) {
    uint8_t Byte = 0;
    for (size_t J = I; J != std::min(I + 4, Uses.size()); ++J)
      Byte |= (Uses[J].OneUse | Uses[J].OneUser << 1) << 2 * (J - I);
    OS << char(Byte);
  }
  OS << Bitcode;
}

Expected<FunctionPack> FunctionPack::decode(StringRef Data) {
  DataExtractor Extractor(Data, /*IsLittleEndian=*/true);
  DataExtractor::Cursor C(0);
  FunctionPack Pack;
  Pack.FunctionIndex = Extractor.getULEB128(C);
  uint64_t NumUses = Extractor.getULEB128(C);
  if (C && NumUses > (Data.size() - C.tell()) * 4)
    return createStringError("function pack: uses past the end");
  StringRef Bits = Extractor.getBytes(C, (NumUses + 3) / 4);
  if (!C)
    return createStringError("function pack: " + toString(C.takeError()));
  Pack.Uses.reserve(NumUses);
  for (uint64_t I = 0; I != NumUses; ++I) {
    uint8_t Pair = uint8_t(Bits[I / 4]) >> 2 * (I % 4);
    Pack.Uses.push_back(ModuleUses{bool(Pair & 1), bool(Pair & 2)});
  }
  Pack.Bitcode = Data.drop_front(C.tell()).str();
  return Pack;
}

void forEachReferencedConstant(const Function &F,
                               function_ref<void(const Constant &)> Visit) {
  SmallPtrSet<const Constant *, 16> Seen;
  auto Enter = [&](const llvm::Value *V, auto &Self) -> void {
    const auto *C = dyn_cast<Constant>(V);
    if (!C || !isUsedAcrossFunctions(*C) || !Seen.insert(C).second)
      return;
    Visit(*C);
    // What globals refer to is not the function's.
    if (!isa<GlobalValue>(C))
      for (const llvm::Value *Operand : C->operands())
        Self(Operand, Self);
  };
  for (const llvm::Instruction &I : instructions(F))
    for (const llvm::Value *Operand : I.operands())
      Enter(Operand, Enter);
}

UnpackedFunction::UnpackedFunction() = default;
UnpackedFunction::~UnpackedFunction() = default;

Expected<std::unique_ptr<UnpackedFunction>>
UnpackedFunction::read(const FunctionPack &Pack, LLVMContext &Context) {
  Expected<std::unique_ptr<Module>> M = parseBitcodeFile(
      MemoryBufferRef(Pack.Bitcode, "<function pack>"), Context);
  if (!M)
    return M.takeError();
  std::unique_ptr<UnpackedFunction> Unpacked(new UnpackedFunction());
  Unpacked->M = std::move(*M);
  Module &Packed = *Unpacked->M;
  if (Pack.FunctionIndex >= Packed.size())
    return createStringError("function pack: no function " +
                             Twine(Pack.FunctionIndex));
  Unpacked->F = &*std::next(Packed.begin(), Pack.FunctionIndex);
  size_t Index = 0;
  bool Mismatch = false;
  forEachReferencedConstant(*Unpacked->F, [&](const Constant &C) {
    if (Index == Pack.Uses.size())
      Mismatch = true;
    else
      Unpacked->Uses[&C] = Pack.Uses[Index++];
  });
  if (Mismatch || Index != Pack.Uses.size())
    return createStringError(
        "function pack: its uses do not match the function's constants");
  return Unpacked;
}

std::optional<ModuleUses>
UnpackedFunction::getModuleUses(const llvm::Value &V) {
  auto It = Uses.find(&V);
  if (It == Uses.end())
    return std::nullopt;
  return It->second;
}

} // namespace metaphir
} // namespace llvm
