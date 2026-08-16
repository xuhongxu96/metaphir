#include "metaphir/IR/MIRContextImpl.h"
#include "metaphir/IR/Pattern.h"

namespace llvm {
namespace metaphir {

MIRContextImpl::~MIRContextImpl() {
  while (!OwnedPatterns.empty())
    delete *OwnedPatterns.begin();
}

} // namespace metaphir
} // namespace llvm
