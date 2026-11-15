#include "metaphir/Matching/UseOracle.h"
#include "llvm/IR/Module.h"
#include "llvm/Support/Error.h"
#include "llvm/Support/ErrorHandling.h"

namespace llvm {
namespace metaphir {

std::optional<ModuleUses>
MaterializingUseOracle::getModuleUses(const llvm::Value &) {
  if (!Materialized) {
    Materialized = true;
    // A lazily read module whose bitcode fails to materialize: the reader
    // checks the module's header first, and a corrupt body is left to here.
    // LCOV_EXCL_START
    if (Error E = M.materializeAll())
      report_fatal_error(Twine(M.getModuleIdentifier()) + ": " +
                         toString(std::move(E)));
    // LCOV_EXCL_STOP
  }
  return std::nullopt;
}

} // namespace metaphir
} // namespace llvm
