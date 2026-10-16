#include "metaphir/IR/MIRContextImpl.h"
#include "metaphir/IR/Constraint.h"
#include "metaphir/IR/Pattern.h"

namespace llvm {
namespace metaphir {

MIRContextImpl::~MIRContextImpl() {
  while (!OwnedPatterns.empty())
    delete *OwnedPatterns.begin();
  for (Value *V : ValuesToDestroy)
    V->~Value();
  for (Constraint *C : ConstraintsToDestroy)
    C->~Constraint();
}

} // namespace metaphir
} // namespace llvm
