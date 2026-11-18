//===- Structuralize.cpp - Constraints the index can look up --------------===//
//
// mpir-index-structuralize finds constraints of an index query that say
// what kind of instruction a value is, or which intrinsic a call calls, and
// requires that as a feature the corpus index has posting lists of:
//
//   ?id == "llvm.ctlz"             (for '@llvm.?id')   has_global "llvm.ctlz"
//   intrinsic(?c) == "llvm.ctlz"   (?c a call)         has_global "llvm.ctlz"
//   opcode(?v) == "mul"                                has_instruction <mul>
//
// Each holds only if the function has such an instruction or calls such an
// intrinsic: opcode() and intrinsic() fail on anything else, and a failing
// constraint rejects the match. A disjunction of such constraints splits
// the variant, one per disjunct, as the index looks up the variants' keys
// separately. The constraints stay: the features only narrow the functions
// to match.
//
//===----------------------------------------------------------------------===//

#include "metaphir/Transforms/Structuralize.h"
#include "metaphir/Dialect/Expr/ExprDialect.h"
#include "metaphir/Dialect/Index/IndexDialect.h"
#include "metaphir/Matching/Operators/Facts.h"
#include "mlir/IR/Builders.h"
#include "mlir/IR/BuiltinOps.h"
#include "mlir/IR/IRMapping.h"
#include "mlir/Pass/Pass.h"

namespace llvm {
namespace metaphir {
namespace structuralize {

using mlir::Operation;
using mlir::Value;
namespace index = mpir_index;

namespace {
/// A feature a function needs.
struct Atom_ {
  enum Kind { Instruction, Global } K;
  instruction::InstructionID ID = instruction::InstructionID(0);
  std::string Name;

  bool operator==(const Atom_ &Other) const {
    return K == Other.K && ID == Other.ID && Name == Other.Name;
  }
};
/// Features a function needs some conjunction of.
using Disjunction = SmallVector<SmallVector<Atom_, 2>, 2>;
} // namespace

/// The built-in instruction matcher that accepts exactly the instructions of
/// the LLVM opcode Name, if there is one.
static std::optional<instruction::InstructionID> matcherOf(StringRef Name) {
  // 'br' is two kinds of instruction in LLVM, which one matcher accepts.
  if (Name == "br")
    return std::nullopt;
  for (unsigned ID = 0; ID != instruction::NumInstructionIDs; ++ID)
    if (instruction::getOpcodeName(instruction::InstructionID(ID)) == Name)
      return instruction::InstructionID(ID);
  return std::nullopt;
}

/// The sites a read reads, if it reads a value at sites.
static index::SitesOp sitesRead(Value E) {
  auto Read = E.getDefiningOp<mpir_expr::ReadOp>();
  return Read ? Read.getValue().getDefiningOp<index::SitesOp>()
              : index::SitesOp();
}

/// Whether some site of Sites is the given slot of a call.
static bool atCallSlot(index::SitesOp Sites, unsigned SlotBits) {
  for (mlir::Attribute A : Sites.getSites()) {
    auto Site = cast<mlir::ArrayAttr>(A);
    auto Int = [&](unsigned I) {
      return cast<mlir::IntegerAttr>(Site[I]).getInt();
    };
    if (Int(1) == instruction::I_call && Int(2) == int64_t(SlotBits))
      return true;
  }
  return false;
}

static std::optional<Disjunction> derive(Value C);

/// What an equality of E and the string Literal needs.
static std::optional<Disjunction> deriveEquality(Value E, StringRef Literal) {
  // '@llvm.?id' read as its intrinsic's name.
  if (index::SitesOp Sites = sitesRead(E))
    if (cast<mpir::SortType>(E.getType()).getSort() == Sort::String &&
        atCallSlot(Sites, 1u << 0))
      return Disjunction{{{Atom_::Global, {}, Literal.str()}}};
  auto Call = E.getDefiningOp<mpir_expr::CallOp>();
  if (!Call || Call.getArgs().size() != 1)
    return std::nullopt;
  index::SitesOp Sites = sitesRead(Call.getArgs()[0]);
  if (!Sites)
    return std::nullopt;
  switch (Call.getOperatorID()) {
  case constraint::O_Intrinsic:
    // Only a call can call an intrinsic.
    if (atCallSlot(Sites, 1u << ResultSlot))
      return Disjunction{{{Atom_::Global, {}, Literal.str()}}};
    return std::nullopt;
  case constraint::O_Opcode: {
    std::optional<instruction::InstructionID> ID = matcherOf(Literal);
    // A value an instruction matcher matches as itself is of its kind: the
    // constraint holds only if that is the kind it names.
    for (mlir::Attribute A : Sites.getSites()) {
      auto Site = cast<mlir::ArrayAttr>(A);
      auto Kind =
          instruction::InstructionID(cast<mlir::IntegerAttr>(Site[1]).getInt());
      if (cast<mlir::IntegerAttr>(Site[2]).getInt() ==
              int64_t(1u << ResultSlot) &&
          matcherOf(instruction::getOpcodeName(Kind)) == Kind && ID != Kind)
        return Disjunction();
    }
    if (ID)
      return Disjunction{{{Atom_::Instruction, *ID, {}}}};
    return std::nullopt;
  }
  default:
    return std::nullopt;
  }
}

/// What a function needs for C to hold, if anything the index looks up: the
/// conjunctions of features, any one of which it needs; none if C cannot
/// hold.
static std::optional<Disjunction> derive(Value C) {
  auto Call = C.getDefiningOp<mpir_expr::CallOp>();
  if (!Call)
    return std::nullopt;
  mlir::OperandRange Args = Call.getArgs();
  switch (Call.getOperatorID()) {
  case constraint::O_Equal: {
    // The verifier admits only two operands for '=='.
    assert(Args.size() == 2 && "'==' takes two operands");
    for (unsigned Side : {0u, 1u})
      if (auto Str = Args[1 - Side].getDefiningOp<mpir_expr::StrOp>())
        return deriveEquality(Args[Side], Str.getValue());
    return std::nullopt;
  }
  case constraint::O_LogicalAnd: {
    // What either side needs; both, if both need something. A side that
    // cannot hold (no disjunct) makes the conjunction not hold either.
    std::optional<Disjunction> Left = derive(Args[0]);
    std::optional<Disjunction> Right = derive(Args[1]);
    if ((Left && Left->empty()) || (Right && Right->empty()))
      return Disjunction();
    if (!Left)
      return Right;
    if (!Right)
      return Left;
    Disjunction Product;
    for (auto &L : *Left)
      for (auto &R : *Right) {
        SmallVector<Atom_, 2> Both(L);
        Both.append(R.begin(), R.end());
        Product.push_back(std::move(Both));
      }
    return Product;
  }
  case constraint::O_LogicalOr: {
    // Either side, only if each needs something; a side that cannot hold
    // leaves the other.
    std::optional<Disjunction> Left = derive(Args[0]);
    std::optional<Disjunction> Right = derive(Args[1]);
    if (Left && Left->empty())
      return Right;
    if (Right && Right->empty())
      return Left;
    if (!Left || !Right)
      return std::nullopt;
    Left->append(Right->begin(), Right->end());
    return Left;
  }
  default:
    return std::nullopt;
  }
}

/// The most variants a query is split into.
static constexpr unsigned MaxVariants = 256;

static void addAtoms(mlir::OpBuilder &Builder, mlir::Location Loc,
                     ArrayRef<Atom_> Atoms) {
  for (const Atom_ &A : Atoms) {
    // What the constraints, not the instructions, need: a function without
    // it may still match the variant's instructions.
    if (A.K == Atom_::Global)
      index::HasGlobalOp::create(Builder, Loc, Builder.getStringAttr(A.Name),
                                 /*derived=*/true);
    else
      index::HasInstructionOp::create(
          Builder, Loc, mpir::OpcodeAttr::get(Builder.getContext(), A.ID),
          /*derived=*/true);
  }
}

static void structuralize(index::QueryOp Query) {
  mlir::OpBuilder Builder(Query.getContext());
  unsigned NumVariants = 0;
  for (auto V : Query.getBody().front().getOps<index::VariantOp>())
    (void)V, ++NumVariants;
  for (auto Variant : llvm::make_early_inc_range(
           Query.getBody().front().getOps<index::VariantOp>())) {
    // What every match needs, and the disjunctions that split the variant.
    SmallVector<Atom_, 4> Always;
    Disjunction Split{{}};
    for (auto Assume : Variant.getBody().front().getOps<index::AssumeOp>()) {
      std::optional<Disjunction> D = derive(Assume.getCondition());
      if (!D)
        continue;
      // A constraint that cannot hold: the variant matches nothing (its
      // instructions may still match).
      if (D->empty()) {
        Variant.setImpossible(true);
        continue;
      }
      if (D->size() == 1) {
        append_range(Always, D->front());
        continue;
      }
      if (NumVariants - 1 + Split.size() * D->size() > MaxVariants)
        continue;
      Disjunction Next;
      for (auto &S : Split)
        for (auto &E : *D) {
          SmallVector<Atom_, 2> Both(S);
          Both.append(E.begin(), E.end());
          Next.push_back(std::move(Both));
        }
      Split = std::move(Next);
    }
    mlir::Block &Body = Variant.getBody().front();
    Builder.setInsertionPointToStart(&Body);
    addAtoms(Builder, Variant.getLoc(), Always);
    if (Split.size() == 1) {
      addAtoms(Builder, Variant.getLoc(), Split.front());
      continue;
    }
    // A copy of the variant per disjunct, the variant itself the last.
    NumVariants += Split.size() - 1;
    for (auto [Index, Atoms] : enumerate(Split)) {
      index::VariantOp Target = Variant;
      if (Index + 1 != Split.size()) {
        Builder.setInsertionPoint(Variant);
        Target = cast<index::VariantOp>(Builder.clone(*Variant));
      }
      Builder.setInsertionPointToStart(&Target.getBody().front());
      addAtoms(Builder, Variant.getLoc(), Atoms);
    }
  }
}

namespace {
struct StructuralizePass
    : public mlir::PassWrapper<StructuralizePass,
                               mlir::OperationPass<mlir::ModuleOp>> {
  MLIR_DEFINE_EXPLICIT_INTERNAL_INLINE_TYPE_ID(StructuralizePass)
  StringRef getArgument() const override { return "mpir-index-structuralize"; }
  StringRef getDescription() const override {
    return "Require what constraints say of instructions as index features";
  }
  void runOnOperation() override {
    for (auto Query : getOperation().getOps<index::QueryOp>())
      structuralize(Query);
  }
};
} // namespace

} // namespace structuralize

std::unique_ptr<mlir::Pass> createIndexStructuralizePass() {
  return std::make_unique<structuralize::StructuralizePass>();
}

void registerIndexStructuralizePass() {
  mlir::PassRegistration<structuralize::StructuralizePass>();
}

} // namespace metaphir
} // namespace llvm
