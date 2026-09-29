#ifndef METAPHIR_IR_PATTERN_VARIANTS_H
#define METAPHIR_IR_PATTERN_VARIANTS_H

#include "metaphir/IR/Pattern.h"
#include "llvm/ADT/ArrayRef.h"
#include "llvm/ADT/SmallVector.h"

namespace llvm {
namespace metaphir {

/// The patterns a lowered pattern stands for; a match of any one is a match.
class PatternVariants {
public:
  PatternVariants() = default;

  /* implicit */ PatternVariants(Pattern *P) {
    if (P)
      Variants.push_back(P);
  }

  explicit PatternVariants(ArrayRef<Pattern *> Patterns)
      : Variants(Patterns.begin(), Patterns.end()) {}

  explicit PatternVariants(SmallVector<Pattern *, 2> &&Patterns)
      : Variants(std::move(Patterns)) {}

  ArrayRef<Pattern *> getVariants() const { return Variants; }

  bool empty() const { return Variants.empty(); }
  size_t size() const { return Variants.size(); }

  Pattern *operator[](size_t Index) const { return Variants[Index]; }

  SmallVector<Pattern *, 2>::iterator begin() { return Variants.begin(); }
  SmallVector<Pattern *, 2>::iterator end() { return Variants.end(); }
  SmallVector<Pattern *, 2>::const_iterator begin() const {
    return Variants.begin();
  }
  SmallVector<Pattern *, 2>::const_iterator end() const {
    return Variants.end();
  }

  void addVariant(Pattern *P) { Variants.push_back(P); }

private:
  SmallVector<Pattern *, 2> Variants;
};

} // namespace metaphir
} // namespace llvm

#endif
