#include "metaphir/Web/Zstd.h"
#include <memory>
#include <zstd.h>

namespace llvm {
namespace metaphir {

/// Decompresses Frame with Dict, if any, on this thread's context.
static Expected<std::string> decompressFrame(StringRef Frame,
                                             const ZSTD_DDict *Dict) {
  unsigned long long Size =
      ZSTD_getFrameContentSize(Frame.data(), Frame.size());
  if (Size == ZSTD_CONTENTSIZE_ERROR || Size == ZSTD_CONTENTSIZE_UNKNOWN)
    return createStringError("not a zstd frame of known size");
  struct ContextDeleter {
    void operator()(ZSTD_DCtx *Context) const { ZSTD_freeDCtx(Context); }
  };
  thread_local std::unique_ptr<ZSTD_DCtx, ContextDeleter> Context(
      ZSTD_createDCtx());
  std::string Out(Size, '\0');
  size_t Result =
      Dict ? ZSTD_decompress_usingDDict(Context.get(), Out.data(), Out.size(),
                                        Frame.data(), Frame.size(), Dict)
           : ZSTD_decompressDCtx(Context.get(), Out.data(), Out.size(),
                                 Frame.data(), Frame.size());
  if (ZSTD_isError(Result))
    return createStringError(Twine("zstd: ") + ZSTD_getErrorName(Result));
  if (Result != Size)
    return createStringError("zstd: frame shorter than its size");
  return Out;
}

Expected<std::string> zstdDecompress(StringRef Frame) {
  return decompressFrame(Frame, nullptr);
}

Expected<ZstdDictionary> ZstdDictionary::create(StringRef Dictionary) {
  ZSTD_DDict *Dict = ZSTD_createDDict(Dictionary.data(), Dictionary.size());
  if (!Dict)
    return createStringError("zstd: invalid dictionary");
  return ZstdDictionary(Dict);
}

ZstdDictionary &ZstdDictionary::operator=(ZstdDictionary &&Other) {
  std::swap(Dict, Other.Dict);
  return *this;
}

ZstdDictionary::~ZstdDictionary() { ZSTD_freeDDict(Dict); }

Expected<std::string> ZstdDictionary::decompress(StringRef Frame) const {
  return decompressFrame(Frame, Dict);
}

} // namespace metaphir
} // namespace llvm
