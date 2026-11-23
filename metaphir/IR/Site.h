//===- Site.h - A place a pattern value occupies ----------------*- C++ -*-===//
//
// What the index knows of a pattern value: the sites it occupies. An index
// query writes them as mpir_index.sites elements (see IndexDialect.h).
//
//===----------------------------------------------------------------------===//

#ifndef METAPHIR_IR_SITE_H
#define METAPHIR_IR_SITE_H

#include "metaphir/IR/Instruction.h"
#include "llvm/ADT/SmallVector.h"
#include <cstdint>
#include <tuple>

namespace llvm {
namespace metaphir {

/// A place a pattern value certainly occupies in every match: an operand, at
/// one of Positions, of the instruction Node matches, or (Positions holding
/// ResultPosition) that instruction itself.
struct Site {
  /// The pattern instruction (an index query's mpir_index.node number), and
  /// the built-in matcher it is.
  int64_t Node = -1;
  instruction::InstructionID ID = instruction::InstructionID(0);
  /// Bit P is set for position P.
  uint8_t Positions = 0;

  auto tie() const { return std::make_tuple(Node, ID, Positions); }
  bool operator<(const Site &Other) const { return tie() < Other.tie(); }
  bool operator==(const Site &Other) const { return tie() == Other.tie(); }
};

using Sites = SmallVector<Site, 2>;

} // namespace metaphir
} // namespace llvm

#endif // METAPHIR_IR_SITE_H
