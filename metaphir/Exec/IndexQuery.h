//===- IndexQuery.h - Run index queries on features -------------*- C++ -*-===//
//
// An mpir_index.query compiled for checking functions' features, as
// FeatureQuery checks them: a function may match a variant if it has the
// variant's features, its certain instructions can be typed by the
// function's signatures, and no constraint is false on the features.
//
//===----------------------------------------------------------------------===//

#ifndef METAPHIR_EXEC_INDEXQUERY_H
#define METAPHIR_EXEC_INDEXQUERY_H

#include "metaphir/Exec/TypePattern.h"
#include "metaphir/Matching/FeatureQuery.h"
#include "metaphir/Matching/FunctionFilter.h"
#include "mlir/IR/Value.h"
#include "llvm/IR/LLVMContext.h"
#include <memory>
#include <vector>

namespace llvm {
namespace metaphir {

namespace mpir_index {
class QueryOp;
} // namespace mpir_index

class IndexQuery : public FunctionFilter {
public:
  /// Compiles Query, which must outlive this: its constraints are evaluated
  /// from its expressions.
  explicit IndexQuery(mpir_index::QueryOp Query);
  ~IndexQuery() override;

  size_t size() const override { return Variants.size(); }
  const FeatureRequirement &getRequirement(unsigned Index) const override {
    return Variants[Index].Requirement;
  }
  bool isImpossible(unsigned Index) const override {
    return Variants[Index].Impossible;
  }
  bool mayMatchVariant(unsigned Index,
                       const FunctionFeatures &Features) const override;
  bool mayMatchStructure(unsigned Index,
                         const FunctionFeatures &Features) const override {
    return Variants[Index].Requirement.isSatisfiedBy(Features);
  }
  SmallVector<std::string, 2>
  explainNoStructure(const FunctionFeatures &Features) const override;

  struct Typing;
  /// A way to type a variant's instructions: its type variables' bindings.
  using Row = std::vector<Instantiation::Binding>;

private:
  struct Variant {
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
  TypePatterns Types;
  /// Where the types of signatures are decoded; queries are therefore not
  /// thread-safe.
  std::unique_ptr<LLVMContext> TypeContext;
};

} // namespace metaphir
} // namespace llvm

#endif // METAPHIR_EXEC_INDEXQUERY_H
