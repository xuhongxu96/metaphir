#ifndef METAPHIR_IR_TYPE_H
#define METAPHIR_IR_TYPE_H

namespace llvm {
namespace metaphir {

/// The primitive types a pattern can name ('half', 'float', 'void',
/// 'label', ...), from Types.def. The others (integers, pointers,
/// aggregates, vectors, functions and meta types) are ops of the mpir
/// dialect.
struct Type {
  enum TypeID {
#define MIR_TYPE_ID(TypeID) TypeID,
#include "metaphir/IR/Types.def"
  };

  Type() = delete;
};

} // namespace metaphir
} // namespace llvm

#endif
