//===- Requirement.h - What a variant of an index query needs ---*- C++ -*-===//
//
// The features a function needs for a pattern to match it, under a choice of
// an alternative of each mpir.alt: the instructions it matches, their shapes,
// edges and facts, the globals it names, and the sites of its values.
//
//===----------------------------------------------------------------------===//

#ifndef METAPHIR_TRANSFORMS_TOINDEX_REQUIREMENT_H
#define METAPHIR_TRANSFORMS_TOINDEX_REQUIREMENT_H

#include "metaphir/Dialect/Pattern/PatternDialect.h"
#include "metaphir/Matching/FeatureRequirement.h"
#include "metaphir/Matching/Operators/Facts.h"
#include "llvm/ADT/DenseMap.h"
#include "llvm/ADT/DenseSet.h"
#include "llvm/ADT/SmallVector.h"
#include <string>

namespace llvm {
namespace metaphir {
namespace toindex {

/// The features a pattern value needs (the instructions that match it and
/// what they use), keyed by canonical pattern values.
struct Requirement {
  /// The opcodes the function has an instruction of, one bit each
  /// (mpir_index.has_instruction).
  uint64_t Instructions = 0;
  /// The flags and result width some instruction of each opcode has
  /// (mpir_index.has_shape).
  SmallVector<ShapeRequirement, 2> Shapes;
  /// (user, operand): an instruction of the first opcode has one of the
  /// second as a direct operand (mpir_index.has_edge).
  SmallVector<std::pair<instruction::InstructionID, instruction::InstructionID>,
              4>
      Edges;
  /// The globals the pattern names, which the function refers to
  /// (mpir_index.has_global).
  SmallVector<std::string, 2> Globals;
  /// (node, slots, atom): some slot of the matched instruction node holds a
  /// value with the fact, such as the literal written there
  /// (mpir_index.has_fact).
  SmallVector<std::tuple<mlir::Operation *, uint8_t, Atom>, 2> SiteFacts;
  /// (value, opcode): an instruction of the opcode uses the pattern value.
  /// Two opcodes using one value are siblings (mpir_index.has_sibling). Only
  /// variables and matchers count: a constant written once can match
  /// different constants (a scalar and a splat).
  SmallVector<std::pair<mlir::Value, instruction::InstructionID>, 4> Uses;
  /// (value, node, slots): the pattern value is an operand of the matched
  /// instruction node in these slots; with the results of the matched
  /// instructions, what constraints read it as (mpir_index.sites).
  SmallVector<std::tuple<mlir::Value, mlir::Operation *, uint8_t>, 4>
      OperandSites;
  /// The instruction matchers every match of the variant matches: those its
  /// choices reach, and of an mpir.alt past MaxVariants, those all its
  /// alternatives reach.
  SmallVector<mlir::Operation *, 4> Matched;

  void unite(const Requirement &Other) {
    Instructions |= Other.Instructions;
    append_range(Shapes, Other.Shapes);
    append_range(Edges, Other.Edges);
    append_range(Globals, Other.Globals);
    append_range(SiteFacts, Other.SiteFacts);
    append_range(Uses, Other.Uses);
    append_range(OperandSites, Other.OperandSites);
    append_range(Matched, Other.Matched);
  }
  /// Keeps the values in Other as well, each once. Key projects a value to
  /// what is hashed of it.
  template <typename T, typename KeyFn>
  static void keep(SmallVectorImpl<T> &Values, ArrayRef<T> Other, KeyFn Key) {
    using K = decltype(Key(std::declval<const T &>()));
    DenseSet<K> InOther;
    for (const T &V : Other)
      InOther.insert(Key(V));
    DenseSet<K> Seen;
    llvm::erase_if(Values, [&](const T &V) {
      K Of = Key(V);
      return !InOther.contains(Of) || !Seen.insert(Of).second;
    });
  }
  template <typename T>
  static void keep(SmallVectorImpl<T> &Values, ArrayRef<T> Other) {
    keep(Values, Other, [](const T &V) { return V; });
  }
  /// Keeps only what Other needs too: what a match needs whichever of the two
  /// it is.
  void intersect(const Requirement &Other) {
    Instructions &= Other.Instructions;
    keep<ShapeRequirement>(Shapes, Other.Shapes,
                           [](const ShapeRequirement &S) { return S.tie(); });
    keep<decltype(Edges)::value_type>(Edges, Other.Edges);
    keep<std::string>(Globals, Other.Globals,
                      [](const std::string &G) { return StringRef(G); });
    keep<decltype(SiteFacts)::value_type>(
        SiteFacts, Other.SiteFacts, [](const auto &F) {
          return std::make_tuple(std::get<0>(F), std::get<1>(F),
                                 std::get<2>(F).getCode());
        });
    keep<decltype(Uses)::value_type>(Uses, Other.Uses);
    keep<decltype(OperandSites)::value_type>(OperandSites, Other.OperandSites);
    keep<mlir::Operation *>(Matched, Other.Matched);
  }
};

/// The most variants an index query has. Past it, an mpir.alt is not chosen
/// for but requires only what all its alternatives need.
inline constexpr unsigned MaxVariants = 64;

/// The pattern value V stands for: an alternative's own matcher is the
/// alternative.
mlir::Value canonical(mlir::Value V);

/// The shape of the instructions Node matches: its flags, and the width of
/// its result's integers if it fixes one.
ShapeRequirement shapeOf(mpir::InstOp Node);

/// The alternative each mpir.alt takes in a variant.
using AltChoices = DenseMap<mlir::Operation *, unsigned>;

/// The instruction matcher V stands for under Choices, if it stands for one:
/// what the alternative taken yields.
mpir::InstOp instructionOf(mlir::Value V, const AltChoices &Choices);

/// What a pattern needs, as RequirementBuilder::build finds it under the
/// choices made: known, or not yet.
struct BuildResult {
  /// The first mpir.alt reached with no choice made, if any: what a match
  /// needs is known once it is chosen for.
  mpir::AltOp Undecided;
  /// What a match needs, when no mpir.alt is undecided.
  Requirement Needs;
  /// The constraints a match is to satisfy, in order.
  SmallVector<mpir::RequireOp, 8> Constraints;
};

/// Gathers what a pattern needs under Choices: the alternative each mpir.alt
/// takes. An alt past MaxVariants requires what all its alternatives need.
class RequirementBuilder {
public:
  /// The alternative each mpir.alt takes.
  AltChoices Choices;
  /// The number of variants the choices made so far are among.
  unsigned Combinations = 1;

  /// What matching Block needs: its matchers and those they reach.
  BuildResult build(mlir::Block &Block);

private:
  mpir::AltOp Undecided;
  SmallVector<mpir::RequireOp, 8> Constraints;
  /// What every alternative of each mpir.alt past MaxVariants needs.
  DenseMap<mlir::Operation *, Requirement> Met;

  /// A requirement being gathered, and the matchers gathered into it: each
  /// once, also one reached along two paths or around a cycle.
  struct Walk {
    Requirement R;
    DenseSet<mlir::Operation *> Visited;
  };
  void visit(mlir::Value V, Walk &Into);
  void visitInstruction(mpir::InstOp Node, Walk &Into);
  void visitRegion(mlir::Region &Region, Walk &Into);
  void visitBlock(mlir::Block &Block, Walk &Into);
  const Requirement &requirementOfAlternatives(mpir::AltOp Alt);
};

} // namespace toindex
} // namespace metaphir
} // namespace llvm

#endif // METAPHIR_TRANSFORMS_TOINDEX_REQUIREMENT_H
