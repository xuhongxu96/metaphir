//===- Retrieval.cpp - Posting lookups of index queries -------------------===//
//
// mpir-index-retrieval adds to each index query the mpir_index.retrieve that
// finds the functions its variants may match: the union, over the variants
// that are possible, of the intersection of the lists of their coarse
// features (the universe for a variant that has none).
//
// mpir-index-factor factors a list common to every operand of a union out:
// (A & B) | (A & C) becomes A & (B | C). Every function the union finds has
// A, so the result is the same; it reads A once, and the intersections left
// read their own shortest lists besides.
//
//===----------------------------------------------------------------------===//

#include "metaphir/Transforms/ToIndex/Passes.h"
#include "metaphir/Dialect/Index/IndexDialect.h"
#include "metaphir/Matching/Features.h"
#include "mlir/IR/Builders.h"
#include "mlir/IR/BuiltinOps.h"
#include "mlir/Pass/Pass.h"
#include <map>
#include <tuple>

namespace llvm {
namespace metaphir {

#define GEN_PASS_DEF_INDEXRETRIEVALPASS
#define GEN_PASS_DEF_INDEXFACTORPASS
#include "metaphir/Transforms/ToIndex/Passes.h.inc"
namespace retrieval {

using mlir::Operation;
using mlir::Value;
using mlir::ValueRange;
namespace index = mpir_index;

/// The posting kinds, as PostingKey numbers them.
enum PostingKind : int32_t {
  Instruction_ = 0,
  Edge = 1,
  Sibling = 2,
  Global = 3
};

static void buildRetrieval(index::QueryOp Query) {
  mlir::Block &Body = Query.getBody().front();
  for (Operation &Op : llvm::make_early_inc_range(Body))
    if (isa<index::RetrieveOp>(Op))
      Op.erase();
  mlir::OpBuilder Builder(Query.getContext());
  Builder.setInsertionPointToEnd(&Body);
  mlir::Location Loc = Query.getLoc();
  auto Retrieve = index::RetrieveOp::create(Builder, Loc);
  Builder.setInsertionPointToEnd(&Retrieve.getBody().emplaceBlock());
  auto SetType = index::SetType::get(Query.getContext());
  auto I64 = [&](int64_t V) { return Builder.getI64IntegerAttr(V); };
  SmallVector<Value, 4> Variants;
  for (auto Variant : Body.getOps<index::VariantOp>()) {
    // A variant that matches nothing needs no list.
    if (Variant.getImpossible())
      continue;
    SmallVector<Value, 8> Lists;
    auto Postings = [&](PostingKind Kind, mlir::Attribute Key) {
      Lists.push_back(index::PostingsOp::create(
          Builder, Loc, SetType, Builder.getI32IntegerAttr(Kind), Key));
    };
    for (Operation &Op : Variant.getBody().front()) {
      if (auto Has = dyn_cast<index::HasInstructionOp>(Op))
        Postings(Instruction_, I64(Has.getOpcode().getValue()));
      else if (auto Has = dyn_cast<index::HasEdgeOp>(Op))
        Postings(Edge,
                 I64(FunctionFeatures::getEdgeKey(
                     Has.getUser().getValue(), Has.getOperand().getValue())));
      else if (auto Has = dyn_cast<index::HasSiblingOp>(Op))
        Postings(Sibling,
                 I64(FunctionFeatures::getEdgeKey(Has.getFirst().getValue(),
                                                  Has.getSecond().getValue())));
      else if (auto Has = dyn_cast<index::HasGlobalOp>(Op))
        Postings(Global, Has.getNameAttr());
    }
    Variants.push_back(
        Lists.empty()
            ? Value(index::UniverseOp::create(Builder, Loc, SetType))
            : Value(index::IntersectOp::create(Builder, Loc, SetType, Lists)));
  }
  Value All =
      Variants.size() == 1
          ? Variants.front()
          : Value(index::UnionOp::create(Builder, Loc, SetType, Variants));
  index::ResultOp::create(Builder, Loc, All);
}

/// The key of a postings operation, to compare lists by.
static std::pair<int32_t, mlir::Attribute> keyOf(index::PostingsOp P) {
  return {int32_t(P.getKind()), P.getKey()};
}

/// The lists an operand of a union intersects: itself, if it is one.
static SmallVector<index::PostingsOp, 4> listsOf(Value Set) {
  SmallVector<index::PostingsOp, 4> Lists;
  if (auto P = Set.getDefiningOp<index::PostingsOp>())
    Lists.push_back(P);
  else if (auto I = Set.getDefiningOp<index::IntersectOp>())
    for (Value S : I.getSets())
      if (auto P = S.getDefiningOp<index::PostingsOp>())
        Lists.push_back(P);
  return Lists;
}

/// Factors out of Union a list every operand intersects, until none is
/// left; returns the set Union became.
static Value factor(index::UnionOp Union, mlir::OpBuilder &Builder) {
  mlir::Location Loc = Union.getLoc();
  auto SetType = index::SetType::get(Union.getContext());
  SmallVector<Value, 4> Operands(Union.getSets().begin(),
                                 Union.getSets().end());
  if (Operands.size() < 2)
    return Union;
  // A list every operand has.
  SmallVector<index::PostingsOp, 4> First = listsOf(Operands.front());
  std::optional<std::pair<int32_t, mlir::Attribute>> Common;
  for (index::PostingsOp P : First)
    if (all_of(drop_begin(Operands), [&](Value O) {
          return any_of(listsOf(O), [&](index::PostingsOp Q) {
            return keyOf(Q) == keyOf(P);
          });
        })) {
      Common = keyOf(P);
      break;
    }
  if (!Common)
    return Union;
  Builder.setInsertionPoint(Union);
  // Each operand without the common list: the rest of its intersection, or
  // the universe if that was all of it.
  SmallVector<Value, 4> Rest;
  for (Value O : Operands) {
    SmallVector<Value, 4> Remaining;
    if (auto I = O.getDefiningOp<index::IntersectOp>())
      for (Value S : I.getSets()) {
        auto P = S.getDefiningOp<index::PostingsOp>();
        if (!P || keyOf(P) != *Common)
          Remaining.push_back(S);
      }
    Rest.push_back(Remaining.empty()
                       ? Value(index::UniverseOp::create(Builder, Loc, SetType))
                   : Remaining.size() == 1
                       ? Remaining.front()
                       : Value(index::IntersectOp::create(Builder, Loc, SetType,
                                                          Remaining)));
  }
  // A union with the universe is the universe.
  Value Inner;
  if (any_of(Rest,
             [](Value V) { return V.getDefiningOp<index::UniverseOp>(); }))
    Inner = Value();
  else
    Inner =
        factor(index::UnionOp::create(Builder, Loc, SetType, Rest), Builder);
  Builder.setInsertionPoint(Union);
  Value List = index::PostingsOp::create(
      Builder, Loc, SetType, Builder.getI32IntegerAttr(Common->first),
      Common->second);
  Value Result = Inner ? Value(index::IntersectOp::create(
                             Builder, Loc, SetType, ValueRange{List, Inner}))
                       : List;
  Union.getResult().replaceAllUsesWith(Result);
  Union.erase();
  return Result;
}

/// Merges the sets of Block that are the same (the same lists, intersected
/// or united alike), and the repeated operands of unions and intersections.
static void deduplicate(mlir::Block &Block) {
  std::map<std::tuple<std::string, const void *, SmallVector<const void *, 4>>,
           Value>
      Seen;
  for (Operation &Op : llvm::make_early_inc_range(Block)) {
    if (isa<index::ResultOp>(Op))
      continue;
    // Repeated operands, in order.
    if (isa<index::UnionOp, index::IntersectOp>(Op)) {
      SmallVector<Value, 4> Unique;
      for (Value V : Op.getOperands())
        if (!is_contained(Unique, V))
          Unique.push_back(V);
      if (Unique.size() != Op.getNumOperands())
        Op.setOperands(Unique);
      if (Unique.size() == 1) {
        Op.getResult(0).replaceAllUsesWith(Unique.front());
        Op.erase();
        continue;
      }
    }
    SmallVector<const void *, 4> Operands;
    for (Value V : Op.getOperands())
      Operands.push_back(V.getAsOpaquePointer());
    // Attributes are uniqued: the same key is the same pointer.
    const void *Attrs = nullptr;
    if (auto P = dyn_cast<index::PostingsOp>(Op))
      Attrs =
          mlir::ArrayAttr::get(Op.getContext(), {P.getKindAttr(), P.getKey()})
              .getAsOpaquePointer();
    auto Key =
        std::make_tuple(Op.getName().getStringRef().str(), Attrs, Operands);
    auto [It, Inserted] = Seen.try_emplace(Key, Op.getResult(0));
    if (!Inserted) {
      Op.getResult(0).replaceAllUsesWith(It->second);
      Op.erase();
    }
  }
}

static void factorRetrieval(index::QueryOp Query) {
  for (auto Retrieve : Query.getBody().front().getOps<index::RetrieveOp>()) {
    deduplicate(Retrieve.getBody().front());
    mlir::OpBuilder Builder(Query.getContext());
    for (auto Union : llvm::make_early_inc_range(
             Retrieve.getBody().front().getOps<index::UnionOp>()))
      factor(Union, Builder);
    deduplicate(Retrieve.getBody().front());
    // What nothing reads any more.
    bool Erased = true;
    while (Erased) {
      Erased = false;
      for (Operation &Op :
           llvm::make_early_inc_range(Retrieve.getBody().front()))
        if (!isa<index::ResultOp>(Op) && Op.use_empty()) {
          Op.erase();
          Erased = true;
        }
    }
  }
}

namespace {
struct IndexRetrievalPass : impl::IndexRetrievalPassBase<IndexRetrievalPass> {
  void runOnOperation() override {
    for (auto Query : getOperation().getOps<index::QueryOp>())
      buildRetrieval(Query);
  }
};

struct IndexFactorPass : impl::IndexFactorPassBase<IndexFactorPass> {
  void runOnOperation() override {
    for (auto Query : getOperation().getOps<index::QueryOp>())
      factorRetrieval(Query);
  }
};
} // namespace

} // namespace retrieval

} // namespace metaphir
} // namespace llvm
