//===- ToIndex.cpp - Compile lowered patterns into index queries ----------===//
//
// mpir-to-index compiles each lowered mpir.pattern into an mpir_index.query
// after it: one mpir_index.variant per choice of branch of each matcher use
// (each region of an mpir.alt a use became). The other alternatives are not
// variants of their own: the two operand orders of ':c' make an operand's
// site either slot, and ':o' requires only what both its alternatives need.
//
//===----------------------------------------------------------------------===//

#include "metaphir/Transforms/ToIndex/Passes.h"
#include "metaphir/Dialect/Expr/ExprDialect.h"
#include "metaphir/Dialect/Index/IndexDialect.h"
#include "metaphir/Dialect/Pattern/PatternDialect.h"
#include "metaphir/Dialect/Plan/PlanDialect.h"
#include "metaphir/IR/PatternSettings.h"
#include "metaphir/Matching/FeatureRequirement.h"
#include "mlir/IR/Builders.h"
#include "mlir/IR/BuiltinOps.h"
#include "mlir/IR/BuiltinTypes.h"
#include "mlir/IR/IRMapping.h"
#include "mlir/Pass/Pass.h"
#include "llvm/ADT/DenseSet.h"
#include "llvm/ADT/MapVector.h"

namespace llvm {
namespace metaphir {

#define GEN_PASS_DEF_TOINDEXPASS
#include "metaphir/Transforms/ToIndex/Passes.h.inc"
namespace toindex {

using mlir::Attribute;
using mlir::Location;
using mlir::OpBuilder;
using mlir::Operation;
using mlir::Value;
using namespace mpir;
namespace index = mpir_index;

static bool isVariable(Value V) {
  return isa<mlir::BlockArgument>(V) || V.getDefiningOp<VarOp>();
}

static bool isMatcherAlt(AltOp Alt) {
  return !Alt.getCommuted() && !Alt.getOrSelfOf();
}

static Value yieldOf(mlir::Region &Region) {
  return (*Region.front().getOps<YieldOp>().begin()).getValue();
}

namespace {

/// The features a pattern value needs (the instructions that match it and
/// what they use), keyed by canonical pattern values.
struct Requirement {
  uint64_t Instructions = 0;
  SmallVector<ShapeRequirement, 2> Shapes;
  SmallVector<std::pair<instruction::InstructionID, instruction::InstructionID>,
              4>
      Edges;
  SmallVector<std::string, 2> Globals;
  /// Facts at sites, as (node, slots, atom).
  SmallVector<std::tuple<Operation *, uint8_t, Atom>, 2> SiteFacts;
  SmallVector<std::pair<Value, instruction::InstructionID>, 4> Uses;
  SmallVector<std::tuple<Value, Operation *, uint8_t>, 4> OperandSites;
  SmallVector<Operation *, 4> Selves;

  void unite(const Requirement &Other) {
    Instructions |= Other.Instructions;
    append_range(Shapes, Other.Shapes);
    append_range(Edges, Other.Edges);
    append_range(Globals, Other.Globals);
    append_range(SiteFacts, Other.SiteFacts);
    append_range(Uses, Other.Uses);
    append_range(OperandSites, Other.OperandSites);
    append_range(Selves, Other.Selves);
  }
  template <typename T>
  static void keep(SmallVectorImpl<T> &Values, ArrayRef<T> Other) {
    SmallVector<T, 4> Common;
    for (const T &V : Values)
      if (is_contained(Other, V) && !is_contained(Common, V))
        Common.push_back(V);
    Values.assign(Common.begin(), Common.end());
  }
  void intersect(const Requirement &Other) {
    Instructions &= Other.Instructions;
    keep<ShapeRequirement>(Shapes, Other.Shapes);
    keep<decltype(Edges)::value_type>(Edges, Other.Edges);
    keep<std::string>(Globals, Other.Globals);
    keep<decltype(SiteFacts)::value_type>(SiteFacts, Other.SiteFacts);
    keep<decltype(Uses)::value_type>(Uses, Other.Uses);
    keep<decltype(OperandSites)::value_type>(OperandSites, Other.OperandSites);
    keep<Operation *>(Selves, Other.Selves);
  }
};

class Compiler {
public:
  Compiler(PatternOp Pattern, OpBuilder &Builder)
      : Pattern(Pattern), Builder(Builder), Context(Builder.getContext()) {}

  void compile();

private:
  PatternOp Pattern;
  OpBuilder &Builder;
  mlir::MLIRContext *Context;

  /// The branch each matcher alternative takes in the variant.
  DenseMap<Operation *, unsigned> Choices;
  /// A matcher alternative the traversal reached with no choice made.
  Operation *Undecided = nullptr;
  /// The constraints of the variant, in order.
  SmallVector<RequireOp, 8> Constraints;
  /// Instruction matchers being visited, against cycles.
  DenseSet<Operation *> OnStack;

  void enumerate();
  void emitVariant(const Requirement &R);

  /// The pattern value V stands for: an alternative's own matcher is the
  /// alternative.
  Value canonical(Value V) const;
  /// The instruction matcher an alternative stands for in the variant, if it
  /// stands for one: what the branch taken (or ':c') yields.
  InstOp instructionOf(Value V);

  Requirement requirementOf(Value V);
  Requirement requirementOfInstruction(InstOp Node, bool Commutative);
  Requirement requirementOfRegion(mlir::Region &Region, bool Traverse);
  Requirement requirementOfBlock(mlir::Block &Block);
};

} // namespace

Value Compiler::canonical(Value V) const {
  Value Outer = V;
  while (true) {
    AltOp Yielding;
    for (Operation *User : Outer.getUsers())
      if (auto Yield = dyn_cast<YieldOp>(User))
        if (auto Alt = dyn_cast<AltOp>(Yield->getParentOp()))
          if (Outer.getDefiningOp() &&
              Outer.getDefiningOp()->getBlock() == Yield->getBlock())
            Yielding = Alt;
    if (!Yielding)
      return Outer;
    Outer = Yielding.getResult();
  }
}

InstOp Compiler::instructionOf(Value V) {
  Operation *Def = V.getDefiningOp();
  if (auto Inst = dyn_cast_or_null<InstOp>(Def))
    return Inst;
  auto Alt = dyn_cast_or_null<AltOp>(Def);
  if (!Alt || Alt->getNumRegions() == 0)
    return nullptr;
  if (Alt.getCommuted())
    return instructionOf(yieldOf(Alt->getRegion(0)));
  if (isMatcherAlt(Alt)) {
    auto It = Choices.find(Alt);
    if (It == Choices.end())
      return nullptr;
    return instructionOf(yieldOf(Alt->getRegion(It->second)));
  }
  return nullptr;
}

/// The width a type pattern fixes for the integers of the value it matches.
static unsigned fixedWidth(Value Ty) {
  if (!Ty)
    return 0;
  if (auto Int = Ty.getDefiningOp<IntTypeOp>())
    if (!Int.getByte())
      return Int.getWidth();
  return 0;
}

static uint32_t flagBit(unsigned Flag) { return uint32_t(1) << Flag; }

/// The shape of the instructions Node matches.
static ShapeRequirement shapeOf(InstOp Node) {
  instruction::InstructionID ID = Node.getOpcode().getValue();
  ShapeRequirement Shape{ID};
  for (auto [Flag, Mode] : zip(Node.getFlags(), Node.getFlagModes())) {
    if (FlagMode(Mode) == FlagMode::Captured)
      continue;
    (FlagMode(Mode) == FlagMode::Negated ? Shape.Absent : Shape.Present) |=
        flagBit(Flag);
  }
  for (const MatcherOperandView &Op : getMatcherOperands(Node)) {
    if (isKeyedOperand(Op.Kind) || Op.Kind == OperandKind::ValueArray ||
        Op.Kind == OperandKind::TypedValueArray)
      continue;
    bool OfResult =
        isValueOperand(Op.Kind)
            ? instruction::getOperandSyntax(ID) ==
                  instruction::OperandSyntax::Binary
            : ID != instruction::I_alloca && ID != instruction::I_getelementptr;
    if (OfResult && fixedWidth(Op.Type)) {
      Shape.Width = fixedWidth(Op.Type);
      break;
    }
  }
  return Shape;
}

Requirement Compiler::requirementOfInstruction(InstOp Node, bool Commutative) {
  if (!OnStack.insert(Node).second)
    return {};
  instruction::InstructionID ID = Node.getOpcode().getValue();
  SmallVector<MatcherOperandView, 8> Values;
  for (const MatcherOperandView &Op : getMatcherOperands(Node))
    if (isValueOperand(Op.Kind))
      Values.push_back(Op);
  Requirement Direct;
  Direct.Instructions = uint64_t(1) << ID;
  Direct.Selves.push_back(Node);
  ShapeRequirement Shape = shapeOf(Node);
  if (Shape.Present || Shape.Absent || Shape.Width)
    Direct.Shapes.push_back(Shape);
  bool UsesOperands = ID != instruction::I_phi &&
                      ID != instruction::I_extractvalue &&
                      ID != instruction::I_insertvalue;
  std::optional<std::pair<unsigned, unsigned>> Swapped;
  if (Commutative) {
    if (ID == instruction::I_call && Values.size() == 3)
      Swapped = {1u, 2u};
    else if (Values.size() == 2)
      Swapped = {0u, 1u};
  }
  auto SlotBit = [](unsigned P) {
    return uint8_t(1) << std::min(P, NumOperandSlots - 1);
  };
  for (auto [Position, Op] : llvm::enumerate(Values)) {
    if (Op.Kind == OperandKind::ValueArray ||
        Op.Kind == OperandKind::TypedValueArray || !Op.Val)
      continue;
    Direct.unite(requirementOf(Op.Val));
    uint8_t Slots = SlotBit(Position);
    if (Swapped) {
      if (Position == Swapped->first)
        Slots |= SlotBit(Swapped->second);
      else if (Position == Swapped->second)
        Slots |= SlotBit(Swapped->first);
    }
    Operation *Def = Op.Val.getDefiningOp();
    bool IsMatcher = isa_and_nonnull<InstOp, AltOp>(Def);
    if (isVariable(Op.Val) || IsMatcher)
      Direct.OperandSites.push_back({canonical(Op.Val), Node, Slots});
    if (auto Int = dyn_cast_or_null<IntOp>(Def)) {
      mlir::IntegerAttr Value = Int.getValueAttr();
      APSInt Number(Value.getValue(), Value.getType().isUnsignedInteger());
      if (std::optional<int64_t> V = Number.tryExtValue())
        if (std::optional<Atom> Literal = Atom::literal(*V))
          Direct.SiteFacts.push_back({Node, Slots, *Literal});
    }
    if (UsesOperands && (isVariable(Op.Val) || IsMatcher))
      Direct.Uses.push_back({canonical(Op.Val), ID});
    // An operand with ':o' may match an instruction of another kind.
    if (InstOp Child = instructionOf(Op.Val))
      Direct.Edges.push_back({ID, Child.getOpcode().getValue()});
  }
  OnStack.erase(Node);
  return Direct;
}

Requirement Compiler::requirementOf(Value V) {
  Operation *Def = V.getDefiningOp();
  if (auto Inst = dyn_cast_or_null<InstOp>(Def))
    return requirementOfInstruction(Inst, /*Commutative=*/false);
  if (auto Global = dyn_cast_or_null<GlobalOp>(Def)) {
    Requirement R;
    R.Globals.push_back(Global.getName().str());
    return R;
  }
  auto Alt = dyn_cast_or_null<AltOp>(Def);
  if (!Alt || Alt->getNumRegions() == 0)
    return {};
  if (Alt.getCommuted()) {
    auto Inst = yieldOf(Alt->getRegion(0)).getDefiningOp<InstOp>();
    return Inst ? requirementOfInstruction(Inst, /*Commutative=*/true)
                : Requirement();
  }
  if (Alt.getOrSelfOf()) {
    // The target matches either the matcher or its operand, so only what
    // both alternatives need is required.
    Requirement Itself = requirementOf(yieldOf(Alt->getRegion(0)));
    Itself.intersect(requirementOf(yieldOf(Alt->getRegion(1))));
    return Itself;
  }
  auto It = Choices.find(Alt);
  if (It == Choices.end()) {
    if (!Undecided)
      Undecided = Alt;
    return {};
  }
  return requirementOfRegion(Alt->getRegion(It->second), /*Traverse=*/true);
}

Requirement Compiler::requirementOfRegion(mlir::Region &Region, bool) {
  Requirement R = requirementOf(yieldOf(Region));
  // The branch's other matchers match too, and its constraints apply.
  R.unite(requirementOfBlock(Region.front()));
  return R;
}

Requirement Compiler::requirementOfBlock(mlir::Block &Block) {
  Requirement R;
  for (Operation *Root : getPatternRoots(Block))
    R.unite(requirementOf(Root->getResult(0)));
  for (RequireOp Require : Block.getOps<RequireOp>())
    if (!is_contained(Constraints, Require))
      Constraints.push_back(Require);
  return R;
}

/// Whether C refers to nothing a match binds, nor to definitions.
static bool isClosed(Value C) {
  Operation *Def = C.getDefiningOp();
  if (!Def || isa<mpir_expr::ReadOp, mpir_expr::ApplyOp>(Def))
    return false;
  if (auto Call = dyn_cast<mpir_expr::CallOp>(Def))
    return all_of(Call.getArgs(), isClosed);
  return all_of(Def->getOperands(), isClosed);
}

void Compiler::enumerate() {
  Undecided = nullptr;
  Constraints.clear();
  OnStack.clear();
  Requirement R = requirementOfBlock(Pattern.getBody().front());
  if (Operation *Alt = Undecided) {
    for (unsigned I = 0; I != Alt->getNumRegions(); ++I) {
      Choices[Alt] = I;
      enumerate();
    }
    Choices.erase(Alt);
    return;
  }
  emitVariant(R);
}

void Compiler::emitVariant(const Requirement &R) {
  Location Loc = Pattern.getLoc();
  auto Variant = index::VariantOp::create(Builder, Loc);
  mlir::Block &Body = Variant.getBody().emplaceBlock();
  OpBuilder::InsertionGuard Guard(Builder);
  Builder.setInsertionPointToEnd(&Body);
  auto Opcode = [&](instruction::InstructionID ID) {
    return OpcodeAttr::get(Context, ID);
  };

  // The instructions the variant is sure to match, in pattern order, and
  // their numbers.
  SmallVector<InstOp, 8> Certain;
  Pattern.walk([&](InstOp Inst) {
    if (is_contained(R.Selves, Inst.getOperation()))
      Certain.push_back(Inst);
  });
  DenseMap<Operation *, int64_t> Nodes;
  for (InstOp Inst : Certain)
    Nodes[Inst] = Nodes.size();
  auto NodeOf = [&](Operation *Op) {
    auto [It, Inserted] = Nodes.try_emplace(Op, Nodes.size());
    return It->second;
  };

  // Coarse features.
  for (uint64_t IDs = R.Instructions; IDs; IDs &= IDs - 1)
    index::HasInstructionOp::create(
        Builder, Loc,
        Opcode(instruction::InstructionID(llvm::countr_zero(IDs))));
  SmallVector<std::pair<instruction::InstructionID, instruction::InstructionID>,
              4>
      Edges(R.Edges.begin(), R.Edges.end());
  llvm::sort(Edges);
  Edges.erase(std::unique(Edges.begin(), Edges.end()), Edges.end());
  for (auto [User, Operand] : Edges)
    index::HasEdgeOp::create(Builder, Loc, Opcode(User), Opcode(Operand));
  // Instructions using the same value are siblings.
  SmallVector<std::pair<instruction::InstructionID, instruction::InstructionID>,
              4>
      Siblings;
  SmallVector<std::pair<const void *, instruction::InstructionID>, 8> Uses;
  for (auto [V, ID] : R.Uses)
    Uses.push_back({V.getAsOpaquePointer(), ID});
  llvm::sort(Uses);
  Uses.erase(std::unique(Uses.begin(), Uses.end()), Uses.end());
  for (auto I = Uses.begin(); I != Uses.end(); ++I)
    for (auto J = std::next(I); J != Uses.end() && J->first == I->first; ++J)
      Siblings.push_back(
          {std::min(I->second, J->second), std::max(I->second, J->second)});
  llvm::sort(Siblings);
  Siblings.erase(std::unique(Siblings.begin(), Siblings.end()), Siblings.end());
  for (auto [A, B] : Siblings)
    index::HasSiblingOp::create(Builder, Loc, Opcode(A), Opcode(B));
  SmallVector<std::string, 2> Globals(R.Globals.begin(), R.Globals.end());
  llvm::sort(Globals);
  Globals.erase(std::unique(Globals.begin(), Globals.end()), Globals.end());
  for (const std::string &Name : Globals)
    index::HasGlobalOp::create(Builder, Loc, Builder.getStringAttr(Name));

  // Fine features.
  SmallVector<ShapeRequirement, 2> Shapes(R.Shapes.begin(), R.Shapes.end());
  llvm::sort(Shapes);
  Shapes.erase(std::unique(Shapes.begin(), Shapes.end()), Shapes.end());
  for (const ShapeRequirement &Shape : Shapes)
    index::HasShapeOp::create(Builder, Loc, Opcode(Shape.ID), Shape.Present,
                              Shape.Absent, Shape.Width);
  for (auto [Node, Slots, A] : R.SiteFacts)
    index::HasFactOp::create(Builder, Loc, NodeOf(Node),
                             cast<InstOp>(Node).getOpcodeAttr(), Slots,
                             A.getCode());

  // Type variables, numbered for the typings and constraints.
  MapVector<Value, unsigned> TypeVars;
  std::function<mlir::ArrayAttr(Value)> TypePattern = [&](Value T) {
    SmallVector<Attribute, 8> Parts;
    auto Int = [&](int64_t V) {
      Parts.push_back(Builder.getI64IntegerAttr(V));
    };
    auto Var = [&](Value V) {
      auto [It, Inserted] = TypeVars.try_emplace(V, TypeVars.size());
      return It->second;
    };
    Operation *Def = T.getDefiningOp();
    if (!Def || isa<VarOp>(Def)) {
      Int(int64_t(mpir_plan::TypePatternKind::Variable));
      Int(Var(T));
    } else if (auto Prim = dyn_cast<PrimTypeOp>(Def)) {
      Int(int64_t(mpir_plan::TypePatternKind::Primitive));
      Int(Prim.getKind());
    } else if (auto IntTy = dyn_cast<IntTypeOp>(Def)) {
      Int(int64_t(mpir_plan::TypePatternKind::Integer));
      Int(IntTy.getWidth());
      Int(IntTy.getByte());
    } else if (auto Meta = dyn_cast<MetaIntTypeOp>(Def)) {
      Int(int64_t(mpir_plan::TypePatternKind::MetaInteger));
      Int(Var(Meta.getWidth()));
      Int(Meta.getByte());
    } else if (auto Ptr = dyn_cast<PtrTypeOp>(Def)) {
      Int(int64_t(mpir_plan::TypePatternKind::Pointer));
      std::optional<uint32_t> Space = Ptr.getAddressSpace();
      Int(Space ? int64_t(*Space) : -1);
      Int(!Ptr.getElement());
    } else if (auto Seq = dyn_cast<SeqTypeOp>(Def)) {
      Int(int64_t(mpir_plan::TypePatternKind::Sequence));
      Int(int64_t(Seq.getKind()));
      Int(Seq.getCount());
      Int(Seq.getCountVar() ? int64_t(Var(Seq.getCountVar())) : -1);
      Parts.push_back(TypePattern(Seq.getElement()));
    } else if (auto Struct = dyn_cast<StructTypeOp>(Def)) {
      Int(int64_t(mpir_plan::TypePatternKind::Struct));
      Int(Struct.getPacked());
      for (Value E : Struct.getElements())
        Parts.push_back(TypePattern(E));
    } else if (auto Func = dyn_cast<FuncTypeOp>(Def)) {
      Int(int64_t(mpir_plan::TypePatternKind::Function));
      Int(Func.getVarArg());
      Parts.push_back(TypePattern(Func.getReturnType()));
      for (Value P : Func.getParams())
        Parts.push_back(TypePattern(P));
    }
    return Builder.getArrayAttr(Parts);
  };

  // The typings of the certain instructions, numbered as they are.
  for (InstOp Inst : Certain) {
    ShapeRequirement Shape = shapeOf(Inst);
    SmallVector<Attribute, 4> Types;
    SmallVector<bool, 4> IsValue;
    for (const MatcherOperandView &Op : getMatcherOperands(Inst)) {
      if (isKeyedOperand(Op.Kind))
        continue;
      bool Array = Op.Kind == OperandKind::ValueArray ||
                   Op.Kind == OperandKind::TypedValueArray;
      Types.push_back(Op.Type && !Array ? Attribute(TypePattern(Op.Type))
                                        : Builder.getArrayAttr({}));
      IsValue.push_back(isValueOperand(Op.Kind));
    }
    bool Commutative = false;
    if (auto Alt = dyn_cast<AltOp>(Inst->getParentOp()))
      Commutative = Alt.getCommuted();
    auto Typing = index::TypingOp::create(
        Builder, Inst.getLoc(), Inst.getOpcodeAttr(),
        Builder.getI32IntegerAttr(Shape.Present),
        Builder.getI32IntegerAttr(Shape.Absent), mlir::UnitAttr(),
        mlir::UnitAttr(), Builder.getArrayAttr(Types),
        Builder.getDenseBoolArrayAttr(IsValue));
    if (Commutative)
      Typing.setCommutative(true);
    if (Inst.getTreatIntAsVec().value_or(
            pattern_setting::getDefault(pattern_setting::treatIntAsVec)))
      Typing.setTreatIntAsVec(true);
  }

  // The sites of the pattern's values: where they are operands and, for an
  // instruction matched as itself, its result. A capture is its instruction.
  MapVector<Value, SmallVector<Attribute, 2>> SitesOf;
  auto Site = [&](Operation *Node, uint8_t Slots) {
    return Builder.getArrayAttr(
        {Builder.getI64IntegerAttr(NodeOf(Node)),
         Builder.getI64IntegerAttr(cast<InstOp>(Node).getOpcode().getValue()),
         Builder.getI64IntegerAttr(Slots)});
  };
  for (auto [V, Node, Slots] : R.OperandSites) {
    Attribute S = Site(Node, Slots);
    if (!is_contained(SitesOf[V], S))
      SitesOf[V].push_back(S);
  }
  for (InstOp Inst : Certain)
    SitesOf[canonical(Inst.getResult())].push_back(
        Site(Inst, uint8_t(1u << ResultSlot)));
  // A capture is at its instruction's sites, whether or not the instruction
  // is sure to match as itself.
  Pattern.walk([&](InstOp Inst) {
    Value Capture = Inst.getCapture();
    if (!Capture)
      return;
    auto It = SitesOf.find(canonical(Inst.getResult()));
    if (It == SitesOf.end())
      return;
    SmallVector<Attribute, 2> Of = It->second;
    SitesOf[Capture] = std::move(Of);
  });

  // The constraints, reading the values as their sites.
  DenseMap<Value, Value> Readings;
  std::function<Value(Value)> Clone = [&](Value E) -> Value {
    if (Value Done = Readings.lookup(E))
      return Done;
    Operation *Def = E.getDefiningOp();
    Location L = E.getLoc();
    Value Result;
    auto NameOf = [&](Operation *Op, Value Original) {
      Value Canon = canonical(Original);
      if (Operation *D = Canon.getDefiningOp()) {
        if (auto Name =
                D->getAttrOfType<mlir::StringAttr>(mpir::ResultNameAttrName)) {
          Op->setAttr(mpir::ResultNameAttrName, Name);
          return;
        }
        if (auto Inst = dyn_cast<InstOp>(D)) {
          if (std::optional<StringRef> N = Inst.getResultName())
            Op->setAttr(mpir::ResultNameAttrName, Builder.getStringAttr(*N));
          return;
        }
      }
      if (auto Var = Original.getDefiningOp<VarOp>())
        Op->setAttr(mpir::VarNameAttrName, Var.getVarNameAttr());
    };
    if (!Def || isa<VarOp, InstOp, AltOp>(Def)) {
      Value Canon = canonical(E);
      auto It = SitesOf.find(Canon);
      if (It != SitesOf.end()) {
        auto Sites = index::SitesOp::create(Builder, L, E.getType(),
                                            Builder.getArrayAttr(It->second));
        NameOf(Sites, E);
        Result = Sites;
      } else if (TypeVars.count(E)) {
        auto Var = index::TypeVarOp::create(Builder, L, E.getType(),
                                            TypeVars.lookup(E));
        NameOf(Var, E);
        Result = Var;
      } else {
        auto Unknown = index::UnknownOp::create(Builder, L, E.getType());
        NameOf(Unknown, E);
        Result = Unknown;
      }
    } else if (auto Read = dyn_cast<mpir_expr::ReadOp>(Def);
               Read && Read.getValue().getDefiningOp<IntOp>()) {
      mlir::IntegerAttr Value =
          Read.getValue().getDefiningOp<IntOp>().getValueAttr();
      APSInt Number(Value.getValue(), Value.getType().isUnsignedInteger());
      if (sortOf(Read) == Sort::Boolean && Number.getBitWidth() == 1) {
        Result = mpir_expr::BoolOp::create(Builder, L, !Number.isZero());
      } else {
        bool Negative = Number.isSigned() && Number.isNegative();
        Result = mpir_expr::IntOp::create(
            Builder, L,
            Negative ? APSInt(Number.sextOrTrunc(
                                  std::max(64u, Number.getSignificantBits())),
                              false)
                     : APSInt(Number.zextOrTrunc(
                                  std::max(64u, Number.getActiveBits())),
                              true));
      }
    } else if (auto Call = dyn_cast<mpir_expr::CallOp>(Def)) {
      // A value-tracking operator is anchored only at an instruction every
      // match matches as itself.
      SmallVector<Value, 4> Args;
      for (Value A : Call.getArgs())
        Args.push_back(Clone(A));
      Value Anchor;
      if (Value Original = Call.getAnchor())
        if (InstOp Inst = instructionOf(canonical(Original)))
          if (is_contained(Certain, Inst)) {
            auto Node = index::NodeOp::create(Builder, Call.getLoc(),
                                              Original.getType(), NodeOf(Inst));
            Anchor = Node;
          }
      Result = mpir_expr::CallOp::create(Builder, L, Call.getType(),
                                         Call.getOpAttr(), Call.getKindAttr(),
                                         Args, Anchor);
    } else {
      mlir::IRMapping Mapping;
      for (Value Operand : Def->getOperands())
        Mapping.map(Operand, Clone(Operand));
      Result = Builder.clone(*Def, Mapping)->getResult(0);
    }
    Readings[E] = Result;
    return Result;
  };

  // A closed constraint that is false (or cannot be evaluated) rejects every
  // match: the variant is impossible. The executor checks; here they are
  // marked.
  for (RequireOp Require : Constraints) {
    Value C = Clone(Require.getCondition());
    index::AssumeOp::create(Builder, Require.getLoc(), C,
                            isClosed(Require.getCondition()));
  }
}

void Compiler::compile() {
  auto Query = index::QueryOp::create(Builder, Pattern.getLoc());
  mlir::Block &Body = Query.getBody().emplaceBlock();
  OpBuilder::InsertionGuard Guard(Builder);
  Builder.setInsertionPointToEnd(&Body);
  enumerate();
}

namespace {
struct ToIndexPass : impl::ToIndexPassBase<ToIndexPass> {
  void runOnOperation() override {
    OpBuilder Builder(&getContext());
    for (PatternOp Pattern :
         llvm::make_early_inc_range(getOperation().getOps<PatternOp>())) {
      Builder.setInsertionPointAfter(Pattern);
      Compiler(Pattern, Builder).compile();
    }
  }
};
} // namespace

} // namespace toindex

} // namespace metaphir
} // namespace llvm
