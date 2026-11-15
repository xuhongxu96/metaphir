//===- IndexQuery.h - Run index queries on features -------------*- C++ -*-===//
//
// An mpir_index.query compiled for checking functions' features: for each
// of its variants (ways a match can go), a function may match the variant
// if it has the variant's features, its certain instructions can be typed
// by the function's signatures, and no constraint is false on the
// features.
//
//===----------------------------------------------------------------------===//

#ifndef METAPHIR_EXEC_INDEXQUERY_H
#define METAPHIR_EXEC_INDEXQUERY_H

#include "metaphir/Exec/TypePattern.h"
#include "metaphir/Index/Retrieval.h"
#include "metaphir/Matching/FeatureRequirement.h"
#include "mlir/IR/Value.h"
#include "llvm/IR/LLVMContext.h"
#include <memory>
#include <vector>

namespace llvm {
namespace metaphir {

namespace mpir_index {
class QueryOp;
} // namespace mpir_index

class IndexQuery {
public:
  /// Compiles Query, which must outlive this: its constraints are evaluated
  /// from its expressions.
  explicit IndexQuery(mpir_index::QueryOp Query);
  ~IndexQuery();

  /// The number of variants.
  size_t size() const { return Variants.size(); }
  /// The features every function a variant matches has.
  const FeatureRequirement &getRequirement(unsigned Index) const {
    return Variants[Index].Requirement;
  }
  /// Whether a constraint of the variant is false whatever it binds, so the
  /// variant matches no function.
  bool isImpossible(unsigned Index) const { return Variants[Index].Impossible; }

  /// Whether a function with Features may match some variant.
  bool mayMatch(const FunctionFeatures &Features) const;
  /// Whether a function with Features may match the variant, constraints
  /// included.
  bool mayMatchVariant(unsigned Index, const FunctionFeatures &Features) const;
  /// Whether a variant's instructions can match, whatever its constraints.
  bool mayMatchStructure(unsigned Index,
                         const FunctionFeatures &Features) const {
    return Variants[Index].Structural.isSatisfiedBy(Features);
  }
  /// Why a function with Features has no structural match, in words: for
  /// each variant whose features it lacks, the first of them; or, if it has
  /// a variant's features, that its instructions are not as the variant
  /// connects them. Without duplicates.
  SmallVector<std::string, 2>
  explainNoStructure(const FunctionFeatures &Features) const;

  /// The query's retrieval, if it has an mpir_index.retrieve.
  const RetrievalPlan *getRetrieval() const {
    return Retrieval ? &*Retrieval : nullptr;
  }

  struct Typing;
  /// A way to type a variant's instructions: its type variables' bindings.
  using Row = std::vector<Binding>;

private:
  struct Variant {
    /// What its instructions need, and what its constraints need too.
    FeatureRequirement Structural;
    FeatureRequirement Requirement;
    /// The names of the globals the requirement has the hashes of.
    SmallVector<std::string, 2> GlobalNames;
    std::vector<Typing> Typings;
    unsigned NumTypeVariables = 0;
    SmallVector<mlir::Value, 4> Constraints;
    bool Impossible = false;
  };

  SmallVector<Row, 4> joinSignatures(const Variant &V,
                                     const FunctionFeatures &Features) const;
  bool constraintsMayHold(const Variant &V, const FunctionFeatures &Features,
                          const Row &Types) const;

  std::vector<Variant> Variants;
  std::optional<RetrievalPlan> Retrieval;
  TypePatterns Types;
  /// Where the types of signatures are decoded; queries are therefore not
  /// thread-safe.
  std::unique_ptr<LLVMContext> TypeContext;
};

} // namespace metaphir
} // namespace llvm

#endif // METAPHIR_EXEC_INDEXQUERY_H
