#ifndef METAPHIR_MATCHING_TYPECODE_H
#define METAPHIR_MATCHING_TYPECODE_H

#include <cstdint>

namespace llvm {
class LLVMContext;
class Type;
namespace metaphir {

/// An LLVM type encoded as an integer, exactly for the types instructions
/// commonly have: void, labels, integers, bytes, floating point, pointers and
/// vectors of those. Other types (structs, arrays, functions, target
/// extension types) are all OpaqueType, and a missing type is NoType.
using TypeCode = uint64_t;

constexpr TypeCode NoType = 0;
constexpr TypeCode OpaqueType = 1;

TypeCode encodeType(const llvm::Type &Ty);

/// The type Code encodes, in Context; null for NoType and OpaqueType.
llvm::Type *decodeType(TypeCode Code, LLVMContext &Context);

/// The width of the integers of the type Code encodes, if it is an integer
/// type or a vector of them; otherwise 0.
unsigned getIntegerElementWidth(TypeCode Code);

} // namespace metaphir
} // namespace llvm

#endif
