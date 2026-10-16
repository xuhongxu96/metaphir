#ifndef METAPHIR_MATCHING_FEATUREQUERY_H
#define METAPHIR_MATCHING_FEATUREQUERY_H

#include "metaphir/IR/Instruction.h"
#include "metaphir/Matching/Features.h"
#include "metaphir/Matching/IndexDomain.h"
#include "metaphir/Matching/Operators/AbstractCall.h"
#include "llvm/ADT/SmallPtrSet.h"
#include "llvm/ADT/SmallVector.h"
#include "llvm/IR/LLVMContext.h"
#include <cstdint>
#include <memory>
#include <tuple>
#include <utility>

namespace llvm {
namespace metaphir {

class MIRContext;
class Pattern;
class PatternVariants;

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

/// Features every function with a match of a pattern has.
struct FeatureRequirement {
  uint64_t Instructions = 0;
  /// Sorted and unique.
  SmallVector<ShapeRequirement, 2> Shapes;
  /// Sorted and unique.
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

  // While a pattern's requirement is computed, what its instructions
  // certainly are; FeatureQuery turns them into Siblings and the bindings
  // of its constraints. All sorted and unique.
  /// The values the instructions use, and by which instruction matchers.
  SmallVector<std::pair<const Value *, Instruction::InstructionID>, 4> Uses;
  /// The values the instructions have as operands, and where.
  SmallVector<std::pair<const Value *, Site>, 4> OperandSites;
  /// The instructions matched as themselves (not as an or-self operand).
  SmallVector<const Instruction *, 4> Selves;

  bool isTrivial() const {
    return Instructions == 0 && Shapes.empty() && Edges.empty() &&
           Siblings.empty() && Globals.empty() && SiteFacts.empty();
  }
  bool isSatisfiedBy(const FunctionFeatures &Features) const;

  /// Requires Other's features too.
  void unite(const FeatureRequirement &Other);
  /// Keeps only the features Other requires as well.
  void intersect(const FeatureRequirement &Other);
};

/// The features a function needs for a lowered pattern to match: those of
/// any one variant, whose constraints must also be satisfiable on them.
class FeatureQuery {
public:
  /// Definitions holds the 'constraint' definitions the patterns call;
  /// without it, constraints are not checked.
  static FeatureQuery compute(const PatternVariants &Variants,
                              const MIRContext *Definitions = nullptr);

  FeatureQuery();
  FeatureQuery(FeatureQuery &&);
  FeatureQuery &operator=(FeatureQuery &&);
  ~FeatureQuery();

  size_t size() const { return Variants.size(); }
  const FeatureRequirement &getRequirement(unsigned Index) const {
    return Variants[Index].Requirement;
  }

  /// Whether a constraint of the variant is false whatever it binds, such as
  /// ';; false', so the variant matches no function.
  bool isImpossible(unsigned Index) const { return Variants[Index].Impossible; }

  bool mayMatch(const FunctionFeatures &Features) const;
  bool mayMatchVariant(unsigned Index, const FunctionFeatures &Features) const;
  /// Whether a variant's instructions can match, whatever its constraints.
  bool mayMatchStructure(unsigned Index,
                         const FunctionFeatures &Features) const {
    return Variants[Index].Requirement.isSatisfiedBy(Features);
  }

private:
  struct Variant {
    FeatureRequirement Requirement;
    const Pattern *Lowered = nullptr;
    /// The sites of the pattern's values.
    AbstractBindings Bindings;
    /// The instructions matched as themselves, and in pattern order.
    SmallPtrSet<const Instruction *, 8> Certain;
    SmallVector<const Instruction *, 4> CertainInOrder;
    bool Impossible = false;
  };

  /// The ways the certain instructions of V can be typed by the signatures
  /// of Features, as bindings of its type variables; empty if none. Past a
  /// limit, one way with no bindings stands for all.
  SmallVector<Instantiation, 4>
  joinSignatures(const Variant &V, const FunctionFeatures &Features) const;

  /// Whether no constraint of V is false on Features, with its type
  /// variables bound as in Types.
  bool constraintsMayHold(const Variant &V, const FunctionFeatures &Features,
                          const Instantiation &Types) const;

  SmallVector<Variant, 2> Variants;
  const MIRContext *Definitions = nullptr;
  /// Where the types of signatures are decoded; queries are therefore not
  /// thread-safe.
  std::unique_ptr<LLVMContext> TypeContext;
};

} // namespace metaphir
} // namespace llvm

#endif
