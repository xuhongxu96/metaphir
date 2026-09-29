#ifndef METAPHIR_INDEX_CORPUSINDEX_H
#define METAPHIR_INDEX_CORPUSINDEX_H

#include "metaphir/Matching/Features.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/ADT/StringMap.h"
#include "llvm/ADT/StringRef.h"
#include "llvm/Support/Error.h"
#include "llvm/Support/MemoryBuffer.h"
#include <cstdint>
#include <memory>
#include <string>
#include <vector>

namespace llvm {
class Module;
class raw_ostream;
namespace metaphir {

/// Adds Input, or the .ll and .bc files under it when it is a directory (in
/// sorted order), to Files. Reports a directory that cannot be read to Err.
bool collectLLVMIRFiles(StringRef Input, SmallVectorImpl<std::string> &Files,
                        raw_ostream &Err);

/// A defined function's entry in the index. Ordinal counts the module's
/// defined functions in order; Name checks it identifies the same one.
struct IndexedFunction {
  unsigned Ordinal = 0;
  std::string Name;
  FunctionFeatures Features;
};

/// An indexed file: its identity when indexed, whether it parsed, and the
/// features of its functions, summarized and one by one.
struct IndexedModule {
  std::string Path;
  uint64_t Size = 0;
  uint64_t ModificationTime = 0;
  bool Parsed = false;
  FunctionFeatures Summary;
  std::vector<IndexedFunction> Functions;

  /// Indexes Module, read from the file at Path (relative to the corpus).
  static IndexedModule compute(StringRef Path, const Module &Module);
};

/// Features of the modules under a corpus directory, for skipping the modules
/// and functions a pattern cannot match. The functions of a module are read
/// from the file only when asked for.
class CorpusIndex {
public:
  /// Writes the modules, indexed from the corpus at Root, to File.
  static Error write(StringRef File, StringRef Root,
                     ArrayRef<IndexedModule> Modules);
  static Expected<CorpusIndex> read(StringRef File);

  /// Indexes the file at Path, relative to Root: its size and modification
  /// time, and, when it parses, its functions.
  static Expected<IndexedModule> indexFile(StringRef Root, StringRef Path);

  StringRef getRoot() const { return Root; }
  size_t size() const { return Modules.size(); }

  /// The index entry of the file at Path, absolute or relative to the
  /// working directory, if it is under the root and was indexed; its
  /// functions are not read.
  const IndexedModule *lookup(StringRef Path) const;
  const IndexedModule &getModule(size_t Index) const { return Modules[Index]; }

  /// The number of functions of Module, an entry of this index.
  unsigned getNumFunctions(const IndexedModule &Module) const;
  /// Reads the functions of Module, an entry of this index.
  Expected<std::vector<IndexedFunction>>
  readFunctions(const IndexedModule &Module) const;

  /// Whether the file at Path still has the size and modification time it
  /// had when indexed.
  static bool isCurrent(const IndexedModule &Module, StringRef Path);

private:
  std::unique_ptr<MemoryBuffer> Buffer;
  std::string Root;
  std::vector<IndexedModule> Modules;
  /// Where each module's functions start in Buffer.
  std::vector<uint64_t> FunctionOffsets;
  StringMap<size_t> ByPath;
};

} // namespace metaphir
} // namespace llvm

#endif
