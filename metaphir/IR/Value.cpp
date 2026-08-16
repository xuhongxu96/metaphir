#include "metaphir/IR/Value.h"
#include "metaphir/IR/MIRContext.h"
#include "metaphir/IR/MIRContextImpl.h"

namespace llvm {
namespace metaphir {

void Value::setMetaFlags(MIRContext &Context, ArrayRef<MetaFlag *> NewFlags) {
  Flags = Context.pImpl->copyArray<MetaFlag *>(NewFlags);
}

} // namespace metaphir
} // namespace llvm
