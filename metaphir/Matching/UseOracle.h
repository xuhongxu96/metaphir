#ifndef METAPHIR_MATCHING_USEORACLE_H
#define METAPHIR_MATCHING_USEORACLE_H

#include "llvm/IR/Constants.h"
#include <optional>

namespace llvm {
class Module;
namespace metaphir {

/// Whether V can be used in other functions than the one being matched:
/// constants other than plain data are uniqued per module, and their use
/// lists span it.
inline bool isUsedAcrossFunctions(const llvm::Value &V) {
  return isa<llvm::Constant>(V) && !isa<ConstantData>(V);
}

/// How a value is used in its whole module.
struct ModuleUses {
  bool OneUse;
  bool OneUser;
};

/// Tells how values used across functions are used in their module, where
/// the IR at hand has only part of it: a lazily loaded module without all
/// its functions read, or a single function packed on its own.
class UseOracle {
public:
  virtual ~UseOracle() = default;

  /// How V, used across functions, is used in its module; std::nullopt if
  /// its use list is complete.
  virtual std::optional<ModuleUses> getModuleUses(const llvm::Value &V) = 0;
};

/// Reads the rest of a lazily loaded module the first time a value used
/// across functions is asked about, making every use list complete.
class MaterializingUseOracle : public UseOracle {
public:
  explicit MaterializingUseOracle(Module &M) : M(M) {}

  std::optional<ModuleUses> getModuleUses(const llvm::Value &V) override;

private:
  Module &M;
  bool Materialized = false;
};

} // namespace metaphir
} // namespace llvm

#endif
