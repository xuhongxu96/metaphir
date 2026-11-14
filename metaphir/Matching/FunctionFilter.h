//===- FunctionFilter.h - What a function needs to match --------*- C++ -*-===//
//
// What the corpus index asks of a compiled pattern: for each of its variants
// (ways a match can go), the features a function needs, and whether a
// function's features may match. FeatureQuery computes it from MetaphIR IR;
// the mpir_index dialect from a lowered pattern.
//
//===----------------------------------------------------------------------===//

#ifndef METAPHIR_MATCHING_FUNCTIONFILTER_H
#define METAPHIR_MATCHING_FUNCTIONFILTER_H

#include "llvm/ADT/SmallVector.h"
#include <string>

namespace llvm {
namespace metaphir {

class FunctionFeatures;
struct FeatureRequirement;

class FunctionFilter {
public:
  virtual ~FunctionFilter();

  /// The number of variants.
  virtual size_t size() const = 0;
  /// The features every function a variant matches has.
  virtual const FeatureRequirement &getRequirement(unsigned Index) const = 0;
  /// Whether a constraint of the variant is false whatever it binds, so the
  /// variant matches no function.
  virtual bool isImpossible(unsigned Index) const = 0;

  /// Whether a function with Features may match some variant.
  virtual bool mayMatch(const FunctionFeatures &Features) const;
  /// Whether a function with Features may match the variant, constraints
  /// included.
  virtual bool mayMatchVariant(unsigned Index,
                               const FunctionFeatures &Features) const = 0;
  /// Whether a variant's instructions can match, whatever its constraints.
  virtual bool mayMatchStructure(unsigned Index,
                                 const FunctionFeatures &Features) const = 0;

  /// Why a function with Features has no structural match, in words (see
  /// FeatureQuery::explainNoStructure).
  virtual SmallVector<std::string, 2>
  explainNoStructure(const FunctionFeatures &Features) const = 0;
};

} // namespace metaphir
} // namespace llvm

#endif // METAPHIR_MATCHING_FUNCTIONFILTER_H
