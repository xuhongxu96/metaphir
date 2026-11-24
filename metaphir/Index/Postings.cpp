#include "metaphir/Index/Postings.h"
#include "llvm/Support/DataExtractor.h"
#include "llvm/Support/Endian.h"
#include "llvm/Support/EndianStream.h"
#include "llvm/Support/LEB128.h"
#include "llvm/Support/raw_ostream.h"

namespace llvm {
namespace metaphir {

PostingKey PostingRecord::readKey(const char *Record) {
  return PostingKey{PostingKey::KeyKind(uint8_t(Record[0])),
                    support::endian::read64le(Record + 1)};
}

PostingRecord PostingRecord::read(const char *Record) {
  PostingRecord Read;
  Read.Key = readKey(Record);
  Read.Count = support::endian::read32le(Record + 9);
  Read.Offset = support::endian::read64le(Record + 13);
  return Read;
}

void PostingRecord::write(raw_ostream &OS) const {
  support::endian::Writer W(OS, llvm::endianness::little);
  W.write<uint8_t>(Key.Kind);
  W.write<uint64_t>(Key.Value);
  W.write<uint32_t>(Count);
  W.write<uint64_t>(Offset);
}

Expected<std::vector<uint32_t>> readPostingList(StringRef Lists,
                                                uint64_t Offset, uint32_t Count,
                                                uint32_t NumFunctions) {
  DataExtractor Data(Lists, /*IsLittleEndian=*/true);
  DataExtractor::Cursor C(Offset);
  std::vector<uint32_t> Numbers;
  Numbers.reserve(Count);
  uint64_t Number = 0;
  for (uint32_t I = 0; I != Count && C; ++I) {
    Number += Data.getULEB128(C);
    Numbers.push_back(Number);
  }
  if (!C)
    return C.takeError();
  if (!Numbers.empty() && Numbers.back() >= NumFunctions)
    return createStringError("posting past the last function");
  return Numbers;
}

void writePostingList(raw_ostream &OS, ArrayRef<uint32_t> Numbers) {
  uint32_t Previous = 0;
  for (uint32_t N : Numbers) {
    encodeULEB128(N - Previous, OS);
    Previous = N;
  }
}

} // namespace metaphir
} // namespace llvm
