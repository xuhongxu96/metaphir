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
    if (Error E = M.materializeAll())
      report_fatal_error(Twine(M.getModuleIdentifier()) + ": " +
                         toString(std::move(E)));
  }
  return std::nullopt;
}

} // namespace metaphir
} // namespace llvm
