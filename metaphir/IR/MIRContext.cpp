#include "metaphir/IR/MIRContext.h"
#include "metaphir/IR/MIRContextImpl.h"

namespace llvm {
namespace metaphir {

MIRContext::MIRContext() : pImpl(new MIRContextImpl(*this)) {}
MIRContext::~MIRContext() { delete pImpl; }

} // namespace metaphir
} // namespace llvm
