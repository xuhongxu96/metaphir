//===- FeatureRequirement.h - Features a match needs ------------*- C++ -*-===//
//
// The features every function with a match of an index query's variant
// has, as IndexQuery compiles them from its mpir_index operations, checked
// against a function's features.
//
//===----------------------------------------------------------------------===//

#ifndef METAPHIR_MATCHING_FEATUREREQUIREMENT_H
#define METAPHIR_MATCHING_FEATUREREQUIREMENT_H

#include "metaphir/IR/Instruction.h"
#include "metaphir/Matching/Features.h"
#include "metaphir/Matching/Operators/AbstractCall.h"
#include "llvm/ADT/SmallVector.h"
#include <cstdint>
#include <tuple>
#include <utility>

namespace llvm {
namespace metaphir {

/// An instruction a match needs: one matched by ID, with all the Present
/// and none of the Absent flags, whose result has Width bits (unless 0).
struct ShapeRequirement {
  Instruction::InstructionID ID;
  uint32_t Present = 0;
  uint32_t Absent = 0;
  unsigned Width = 0;

  bool isSatisfiedBy(const FunctionFeatures &Features) const;

  auto tie() const { return std::make_tuple(ID, Present, Absent, Width); }
  bool operator<(const ShapeRequirement &Other) const {
    return tie() < Other.tie();
  }
  bool operator==(const ShapeRequirement &Other) const {
    return tie() == Other.tie();
  }
};

/// Features every function with a match of a variant has.
struct FeatureRequirement {
  uint64_t Instructions = 0;
  /// Sorted and unique.
  SmallVector<ShapeRequirement, 2> Shapes;
  SmallVector<std::pair<Instruction::InstructionID, Instruction::InstructionID>,
              4>
      Edges;
  /// Sorted and unique.
  SmallVector<uint16_t, 2> Siblings;
  /// Sorted and unique.
  SmallVector<uint64_t, 2> Globals;
  /// Sorted and unique: facts some slot of a site has, such as an integer
  /// constant the pattern names there.
  SmallVector<std::pair<Site, Atom>, 2> SiteFacts;

  bool isSatisfiedBy(const FunctionFeatures &Features) const;
};

} // namespace metaphir
} // namespace llvm

#endif // METAPHIR_MATCHING_FEATUREREQUIREMENT_H
