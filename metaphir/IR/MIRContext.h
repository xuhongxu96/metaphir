#ifndef METAPHIR_IR_MIR_CONTEXT_H
#define METAPHIR_IR_MIR_CONTEXT_H

namespace llvm {
namespace metaphir {

class MIRContextImpl;

class MIRContext {
public:
  MIRContextImpl *const pImpl;

  MIRContext();
  MIRContext(const MIRContext &) = delete;
  MIRContext &operator=(const MIRContext &) = delete;
  ~MIRContext();
};

} // namespace metaphir
} // namespace llvm

#endif