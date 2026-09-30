#ifndef METAPHIR_INDEX_FUNCTIONPACKER_H
#define METAPHIR_INDEX_FUNCTIONPACKER_H

#include "metaphir/Index/FunctionPack.h"
#include "llvm/ADT/STLFunctionalExtras.h"
#include "llvm/Support/Error.h"

namespace llvm {
class Function;
class Module;
namespace metaphir {

/// Packs each function M defines, in order, and passes it to Add. M must be
/// fully read; it is left as it was.
Error packFunctions(Module &M,
                    function_ref<Error(const Function &, FunctionPack)> Add);

} // namespace metaphir
} // namespace llvm

#endif
