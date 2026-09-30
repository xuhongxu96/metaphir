#ifndef METAPHIR_INDEX_FUNCTIONPACK_H
#define METAPHIR_INDEX_FUNCTIONPACK_H

#include "metaphir/Matching/UseOracle.h"
#include "llvm/ADT/DenseMap.h"
#include "llvm/ADT/STLFunctionalExtras.h"
#include "llvm/ADT/StringRef.h"
#include "llvm/Support/Error.h"
#include <memory>
#include <string>
#include <vector>

namespace llvm {
class Constant;
class Function;
class LLVMContext;
class Module;
namespace metaphir {

/// A function packed on its own: a module of the function alone, with stubs
/// for the globals it refers to, and how the constants it refers to are used
/// in its module. Matching the function read back gives what matching it in
/// its module gives, but for how metadata is numbered.
struct FunctionPack {
  /// Which function of the module is the packed one.
  unsigned FunctionIndex = 0;
  /// How each constant forEachReferencedConstant visits is used in the
  /// function's module, in the order visited.
  std::vector<ModuleUses> Uses;
  /// The module, as bitcode.
  std::string Bitcode;

  /// Appends the pack to Out.
  void encode(std::string &Out) const;
  /// The pack Data holds; its bitcode is only checked when read.
  static Expected<FunctionPack> decode(StringRef Data);
};

/// Calls Visit once on each constant, other than plain data, that F's
/// instructions have as operands or as operands of such constants, in a
/// fixed order.
void forEachReferencedConstant(const Function &F,
                               function_ref<void(const Constant &)> Visit);

/// A packed function read back, which tells how the constants it refers to
/// are used in its module.
class UnpackedFunction : public UseOracle {
public:
  static Expected<std::unique_ptr<UnpackedFunction>>
  read(const FunctionPack &Pack, LLVMContext &Context);

  ~UnpackedFunction() override;

  Function &getFunction() const { return *F; }

  std::optional<ModuleUses> getModuleUses(const llvm::Value &V) override;

private:
  UnpackedFunction();

  std::unique_ptr<Module> M;
  Function *F = nullptr;
  DenseMap<const llvm::Value *, ModuleUses> Uses;
};

} // namespace metaphir
} // namespace llvm

#endif
