//===- Records.h - Reading the language's tables -------------------------===//

#ifndef METAPHIR_TOOLS_TBLGEN_RECORDS_H
#define METAPHIR_TOOLS_TBLGEN_RECORDS_H

#include "llvm/ADT/STLExtras.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/TableGen/Record.h"

namespace metaphir_tblgen {

/// The records of a class in the order the tables define them. The order is
/// that of the generated enums, and so of what is persisted from them.
/// RecordKeeper::getAllDerivedDefinitions sorts by name instead.
inline llvm::SmallVector<const llvm::Record *, 32>
getDefinitionsInOrder(const llvm::RecordKeeper &Records,
                      llvm::StringRef ClassName) {
  llvm::SmallVector<const llvm::Record *, 32> Result(
      Records.getAllDerivedDefinitions(ClassName));
  llvm::sort(Result, [](const llvm::Record *L, const llvm::Record *R) {
    return L->getID() < R->getID();
  });
  return Result;
}

} // namespace metaphir_tblgen

#endif
