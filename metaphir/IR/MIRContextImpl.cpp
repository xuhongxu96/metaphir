#include "metaphir/IR/MIRContextImpl.h"
#include "metaphir/IR/Pattern.h"

namespace llvm {
namespace metaphir {

MIRContextImpl::~MIRContextImpl() {
  while (!OwnedPatterns.empty())
    delete *OwnedPatterns.begin();
  for (Value *V : ValuesToDestroy)
    V->~Value();
}

} // namespace metaphir
} // namespace llvm
