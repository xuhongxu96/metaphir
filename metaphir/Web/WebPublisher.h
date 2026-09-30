#ifndef METAPHIR_WEB_WEBPUBLISHER_H
#define METAPHIR_WEB_WEBPUBLISHER_H

#include "llvm/ADT/StringRef.h"
#include "llvm/Support/Error.h"
#include <cstddef>

namespace llvm {
class raw_ostream;
namespace metaphir {

class CorpusIndex;

struct PublishOptions {
  /// How many modules to pack at once (0: one per hardware thread).
  unsigned Jobs = 1;
  /// The dictionaries are trained on every SampleEvery-th module.
  unsigned SampleEvery = 50;
  size_t FeatureDictionarySize = size_t(1) << 17;
  size_t PackDictionarySize = size_t(1) << 20;
  int CompressionLevel = 19;
  /// Where to report progress, if anywhere.
  raw_ostream *Progress = nullptr;
};

/// Publishes the corpus of Index, whose modules must be as indexed, into
/// the directory Output for matching over HTTP (see WebIndex.h): its
/// postings as they are, and each function's features and pack.
Error publishCorpus(const CorpusIndex &Index, StringRef Output,
                    const PublishOptions &Options);

} // namespace metaphir
} // namespace llvm

#endif
