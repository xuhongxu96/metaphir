#ifndef METAPHIR_INDEX_CORPUSINDEX_H
#define METAPHIR_INDEX_CORPUSINDEX_H

#include "metaphir/Index/Postings.h"
#include "metaphir/Matching/FeatureQuery.h"
#include "metaphir/Matching/Features.h"
#include "llvm/ADT/STLFunctionalExtras.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/ADT/StringMap.h"
#include "llvm/ADT/StringRef.h"
#include "llvm/Support/Error.h"
#include "llvm/Support/MemoryBuffer.h"
#include <cstdint>
#include <memory>
#include <optional>
#include <string>
#include <tuple>
#include <vector>

namespace llvm {
class Module;
class raw_ostream;
namespace metaphir {

/// Adds Input, or the .ll and .bc files under it when it is a directory (in
/// sorted order), to Files. Reports a directory that cannot be read to Err.
bool collectLLVMIRFiles(StringRef Input, SmallVectorImpl<std::string> &Files,
                        raw_ostream &Err);

/// What tells whether a file changed since it was indexed.
struct FileStamp {
  uint64_t Size = 0;
  uint64_t ModificationTime = 0;

  /// The stamp of the file at Path, if it can be read.
  static std::optional<FileStamp> of(StringRef Path);

  bool operator==(const FileStamp &Other) const {
    return Size == Other.Size && ModificationTime == Other.ModificationTime;
  }
  bool operator!=(const FileStamp &Other) const { return !(*this == Other); }
};

/// A defined function's entry in the index, in the order of the module's
/// defined functions. NameHash checks it describes the same function.
struct IndexedFunction {
  uint64_t NameHash = 0;
  FunctionFeatures Features;

  static uint64_t hashName(StringRef Name);
};

/// An indexed file: its stamp when indexed, whether it parsed, and the
/// features of its functions, summarized and one by one.
struct IndexedModule {
  std::string Path;
  FileStamp Stamp;
  bool Parsed = false;
  FunctionFeatures Summary;
  std::vector<IndexedFunction> Functions;

  /// Indexes Module, read from the file at Path (relative to the corpus).
  static IndexedModule compute(StringRef Path, const Module &Module,
                               const FeatureOptions &Options = {});
};

/// A file's entry in a read index. Its features are read when asked for.
struct IndexEntry {
  StringRef Path;
  FileStamp Stamp;
  bool Parsed = false;
  uint64_t NumFunctions = 0;
  uint64_t SummaryOffset = 0;
  uint64_t FunctionsOffset = 0;
};

/// Where functions are: each by its entry's index and its ordinal there.
struct FunctionLocation {
  size_t Entry;
  unsigned Ordinal;
};

/// Features of the modules under a corpus directory, for skipping the modules
/// and functions a pattern cannot match.
///
/// The file starts with a directory of the modules, which is all that
/// reading an index decodes; the modules' summaries and functions follow, and
/// are decoded on demand, so a module's can be decoded on any thread.
class CorpusIndex {
public:
  /// Writes the modules, indexed from the corpus at Root, to File.
  static Error write(StringRef File, StringRef Root,
                     ArrayRef<IndexedModule> Modules);
  static Expected<CorpusIndex> read(StringRef File);

  /// Indexes the file at Path, relative to Root: its stamp, and, when it
  /// parses, its functions.
  static Expected<IndexedModule> indexFile(StringRef Root, StringRef Path,
                                           const FeatureOptions &Options = {
                                               /*ValueFacts=*/true});

  StringRef getRoot() const { return Root; }
  size_t size() const { return Entries.size(); }
  const IndexEntry &getEntry(size_t Index) const { return Entries[Index]; }

  /// The entry of the file at Path, absolute or relative to the working
  /// directory, if it is under the root and was indexed.
  const IndexEntry *lookup(StringRef Path) const;
  /// Path relative to the root, if it is under it ("" for the root itself).
  std::optional<std::string> getRelativePath(StringRef Path) const;
  size_t getEntryIndex(const IndexEntry &Entry) const {
    return &Entry - Entries.data();
  }

  /// The number of functions indexed.
  uint32_t getNumFunctions() const { return NumFunctions; }
  /// The number of the first function of the entry at Index.
  uint32_t getFirstFunction(size_t Index) const { return FirstFunction[Index]; }
  /// The posting key records, sorted by key (see PostingRecord), and the
  /// lists they point to.
  StringRef getPostingRecords() const {
    return Buffer->getBuffer().substr(PostingKeysStart,
                                      NumPostingKeys * PostingRecord::Size);
  }
  StringRef getPostingLists() const {
    return Buffer->getBuffer().substr(PostingListsStart);
  }

  /// The number of functions with Key.
  uint64_t getPostingCount(const PostingKey &Key) const;
  /// The functions with Key, numbered in the order of the entries and of
  /// their functions.
  Expected<std::vector<uint32_t>> readPostings(const PostingKey &Key) const;
  /// Where the function numbered Number is.
  FunctionLocation locate(uint32_t Number) const;

  /// The functions whose coarse features may match Query, sorted by entry
  /// and ordinal; none if the query needs no coarse feature, so that any
  /// function may match.
  Expected<std::optional<std::vector<FunctionLocation>>>
  findCandidates(const FeatureQuery &Query) const;

  /// Reads the summary of the functions of Entry, an entry of this index.
  /// Its fine features (see FunctionFeatures::Fine) are read only if
  /// NeedsFine, when given, asks for them, given the others.
  Expected<FunctionFeatures> readSummary(
      const IndexEntry &Entry,
      function_ref<bool(const FunctionFeatures &)> NeedsFine = nullptr) const;
  /// Reads the functions of Entry, an entry of this index; their fine
  /// features as readSummary does, calling NeedsFine for them in order.
  Expected<std::vector<IndexedFunction>> readFunctions(
      const IndexEntry &Entry,
      function_ref<bool(const FunctionFeatures &)> NeedsFine = nullptr) const;

private:
  std::unique_ptr<MemoryBuffer> Buffer;
  std::string Root;
  std::vector<IndexEntry> Entries;
  StringMap<size_t> ByPath;
  /// The number of the first function of each entry, and of all functions.
  std::vector<uint32_t> FirstFunction;
  uint32_t NumFunctions = 0;
  /// Where the summaries, the functions, the posting keys and the posting
  /// lists start in Buffer.
  uint64_t SummariesStart = 0;
  uint64_t FunctionsStart = 0;
  uint64_t PostingKeysStart = 0;
  uint64_t NumPostingKeys = 0;
  uint64_t PostingListsStart = 0;
};

} // namespace metaphir
} // namespace llvm

#endif
