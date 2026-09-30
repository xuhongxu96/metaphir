#ifndef METAPHIR_WEB_ZSTD_H
#define METAPHIR_WEB_ZSTD_H

#include "llvm/ADT/StringRef.h"
#include "llvm/Support/Error.h"
#include <string>

struct ZSTD_DDict_s;

namespace llvm {
namespace metaphir {

/// Decompresses Frame, a zstd frame compressed without a dictionary.
Expected<std::string> zstdDecompress(StringRef Frame);

/// A zstd dictionary frames are decompressed with. Frames can be
/// decompressed with it on several threads at once.
class ZstdDictionary {
public:
  static Expected<ZstdDictionary> create(StringRef Dictionary);

  ZstdDictionary(ZstdDictionary &&Other) : Dict(Other.Dict) {
    Other.Dict = nullptr;
  }
  ZstdDictionary &operator=(ZstdDictionary &&Other);
  ~ZstdDictionary();

  /// Decompresses Frame, compressed with this dictionary.
  Expected<std::string> decompress(StringRef Frame) const;

private:
  explicit ZstdDictionary(ZSTD_DDict_s *Dict) : Dict(Dict) {}

  ZSTD_DDict_s *Dict = nullptr;
};

} // namespace metaphir
} // namespace llvm

#endif
