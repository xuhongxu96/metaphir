#include "metaphir/Exec/IndexQuery.h"
#include "metaphir/Dialect/Expr/ExprDialect.h"
#include "metaphir/Dialect/Index/IndexDialect.h"
#include "metaphir/Exec/ConstraintDispatch.inc"
#include "metaphir/Exec/ExprEvaluator.h"
#include "metaphir/Matching/ConstraintCoercion.h"
#include "metaphir/Matching/Operators/AbstractCall.h"
#include "metaphir/Matching/TypeCode.h"
#include "mlir/IR/SymbolTable.h"

namespace llvm {
namespace metaphir {

using namespace detail;
using mlir::Operation;

struct IndexQuery::Typing {
  instruction::InstructionID ID;
  uint32_t Present = 0;
  uint32_t Absent = 0;
  bool Commutative = false;
  bool TreatIntAsVec = false;
  /// Per unkeyed operand: its type pattern, if any, and whether it is a
  /// value operand.
  SmallVector<std::optional<unsigned>, 4> Patterns;
  SmallVector<bool, 4> IsValue;
};

/// The site an mpir_index.sites element is: [node, opcode, slots].
static Site siteOf(mlir::ArrayAttr Attr) {
  auto Int = [&](unsigned I) {
    return cast<mlir::IntegerAttr>(Attr[I]).getInt();
  };
  return Site{Int(0), instruction::InstructionID(Int(1)), uint8_t(Int(2))};
}

static RetrievalPlan compileRetrieval(mpir_index::RetrieveOp Retrieve);

/// Whether Op is a feature only the constraints need.
static bool isDerived(mlir::Operation &Op) {
  if (auto Has = dyn_cast<mpir_index::HasInstructionOp>(Op))
    return Has.getDerived();
  if (auto Has = dyn_cast<mpir_index::HasGlobalOp>(Op))
    return Has.getDerived();
  return false;
}

IndexQuery::IndexQuery(mpir_index::QueryOp Query)
    : TypeContext(std::make_unique<LLVMContext>()) {
  ExprEvaluator Concrete;
  for (auto Retrieve : Query.getBody().front().getOps<mpir_index::RetrieveOp>())
    Retrieval = compileRetrieval(Retrieve);
  for (auto VariantOp :
       Query.getBody().front().getOps<mpir_index::VariantOp>()) {
    Variant V;
    FeatureRequirement &R = V.Requirement;
    V.Impossible = VariantOp.getImpossible();
    // The features the constraints need are left for last, once the
    // structure's are known.
    SmallVector<Operation *, 2> Derived;
    for (Operation &Op : VariantOp.getBody().front()) {
      if (isDerived(Op)) {
        Derived.push_back(&Op);
        continue;
      }
      if (auto Has = dyn_cast<mpir_index::HasInstructionOp>(Op)) {
        R.Instructions |= uint64_t(1) << Has.getOpcode().getValue();
      } else if (auto Has = dyn_cast<mpir_index::HasEdgeOp>(Op)) {
        R.Edges.push_back(
            {Has.getUser().getValue(), Has.getOperand().getValue()});
      } else if (auto Has = dyn_cast<mpir_index::HasSiblingOp>(Op)) {
        R.Siblings.push_back(FunctionFeatures::getEdgeKey(
            Has.getFirst().getValue(), Has.getSecond().getValue()));
      } else if (auto Has = dyn_cast<mpir_index::HasGlobalOp>(Op)) {
        R.Globals.push_back(hashGlobalName(Has.getName()));
        V.GlobalNames.push_back(Has.getName().str());
      } else if (auto Has = dyn_cast<mpir_index::HasShapeOp>(Op)) {
        R.Shapes.push_back({Has.getOpcode().getValue(), Has.getPresent(),
                            Has.getAbsent(), Has.getWidth()});
      } else if (auto Has = dyn_cast<mpir_index::HasFactOp>(Op)) {
        R.SiteFacts.push_back(
            {Site{int64_t(Has.getNode()), Has.getOpcode().getValue(),
                  uint8_t(Has.getSlots())},
             Atom::fromCode(Has.getAtom())});
      } else if (auto T = dyn_cast<mpir_index::TypingOp>(Op)) {
        Typing Each;
        Each.ID = T.getOpcode().getValue();
        Each.Present = T.getPresent();
        Each.Absent = T.getAbsent();
        Each.Commutative = T.getCommutative();
        Each.TreatIntAsVec = T.getTreatIntAsVec();
        for (auto [Pattern, IsValue] :
             zip(T.getOperandTypes(), T.getValueOperand())) {
          auto Array = cast<mlir::ArrayAttr>(Pattern);
          Each.Patterns.push_back(
              Array.empty() ? std::nullopt : std::optional(Types.add(Array)));
          Each.IsValue.push_back(IsValue);
        }
        V.Typings.push_back(std::move(Each));
      } else if (auto Var = dyn_cast<mpir_index::TypeVarOp>(Op)) {
        V.NumTypeVariables = std::max(V.NumTypeVariables, Var.getSlot() + 1);
      } else if (auto Assume = dyn_cast<mpir_index::AssumeOp>(Op)) {
        V.Constraints.push_back(Assume.getCondition());
        // A closed constraint evaluates alike in every match, and rejects
        // it when it is false or fails to evaluate.
        if (Assume.getClosed()) {
          Expected<ConstraintValue> Result = Concrete.evaluate(
              Assume.getCondition(),
              [](unsigned) -> const Binding * { return nullptr; });
          mlir::Value Expression = Assume.getCondition();
          Expected<bool> Holds = Result ? requireBoolean(*Result, Expression)
                                        : Expected<bool>(Result.takeError());
          if (!Holds) {
            consumeError(Holds.takeError());
            V.Impossible = true;
          } else if (!*Holds) {
            V.Impossible = true;
          }
        }
      }
    }
    auto Normalize = [](FeatureRequirement &R) {
      llvm::sort(R.Shapes);
      llvm::sort(R.Siblings);
      R.Siblings.erase(std::unique(R.Siblings.begin(), R.Siblings.end()),
                       R.Siblings.end());
      llvm::sort(R.Globals);
      R.Globals.erase(std::unique(R.Globals.begin(), R.Globals.end()),
                      R.Globals.end());
      llvm::sort(R.SiteFacts);
    };
    Normalize(R);
    V.Structural = R;
    for (Operation *Op : Derived) {
      if (auto Has = dyn_cast<mpir_index::HasInstructionOp>(Op))
        R.Instructions |= uint64_t(1) << Has.getOpcode().getValue();
      else if (auto Has = dyn_cast<mpir_index::HasGlobalOp>(Op))
        R.Globals.push_back(hashGlobalName(Has.getName()));
    }
    llvm::sort(R.Shapes);
    llvm::sort(R.Siblings);
    R.Siblings.erase(std::unique(R.Siblings.begin(), R.Siblings.end()),
                     R.Siblings.end());
    llvm::sort(R.Globals);
    R.Globals.erase(std::unique(R.Globals.begin(), R.Globals.end()),
                    R.Globals.end());
    llvm::sort(R.SiteFacts);
    Variants.push_back(std::move(V));
  }
}

IndexQuery::~IndexQuery() = default;

/// The retrieval plan of Retrieve's set expression.
static RetrievalPlan compileRetrieval(mpir_index::RetrieveOp Retrieve) {
  RetrievalPlan Plan;
  DenseMap<mlir::Value, unsigned> Nodes;
  for (Operation &Op : Retrieve.getBody().front()) {
    RetrievalPlan::Node N;
    if (auto P = dyn_cast<mpir_index::PostingsOp>(Op)) {
      N.K = RetrievalPlan::Kind::Postings;
      auto Kind = PostingKey::KeyKind(P.getKind());
      uint64_t Value =
          Kind == PostingKey::Global
              ? hashGlobalName(cast<mlir::StringAttr>(P.getKey()).getValue())
              : uint64_t(cast<mlir::IntegerAttr>(P.getKey()).getInt());
      N.Key = PostingKey{Kind, Value};
    } else if (auto I = dyn_cast<mpir_index::IntersectOp>(Op)) {
      N.K = RetrievalPlan::Kind::Intersect;
      for (mlir::Value S : I.getSets())
        N.Children.push_back(Nodes.lookup(S));
    } else if (auto U = dyn_cast<mpir_index::UnionOp>(Op)) {
      N.K = RetrievalPlan::Kind::Union;
      for (mlir::Value S : U.getSets())
        N.Children.push_back(Nodes.lookup(S));
    } else if (isa<mpir_index::UniverseOp>(Op)) {
      N.K = RetrievalPlan::Kind::Universe;
    } else if (auto Result = dyn_cast<mpir_index::ResultOp>(Op)) {
      Plan.setRoot(Nodes.lookup(Result.getSet()));
      continue;
    } else {
      continue;
    }
    Nodes[Op.getResult(0)] = Plan.add(std::move(N));
  }
  return Plan;
}

//===----------------------------------------------------------------------===//
// Typing
//===----------------------------------------------------------------------===//

static constexpr size_t MaxTypings = 256;

SmallVector<IndexQuery::Row, 4>
IndexQuery::joinSignatures(const Variant &V,
                           const FunctionFeatures &Features) const {
  unsigned NumVars = V.NumTypeVariables;
  auto Unbound = [](const Binding &B) {
    return std::holds_alternative<std::monostate>(B.Data);
  };
  auto Typings = [&](const Typing &T) {
    SmallVector<Row, 4> Rows;
    Signature First;
    First.ID = T.ID;
    for (auto It =
             llvm::lower_bound(Features.Signatures, First,
                               [](const Signature &L, const Signature &R) {
                                 return L.ID < R.ID;
                               });
         It != Features.Signatures.end() && It->ID == T.ID; ++It) {
      if ((It->Flags & T.Present) != T.Present || (It->Flags & T.Absent) != 0)
        continue;
      for (bool Swapped : {false, true}) {
        if (Swapped && !T.Commutative)
          break;
        unsigned NumOperands = count(T.IsValue, true);
        SmallVector<unsigned, 4> Positions;
        for (unsigned P = 0; P != NumOperands; ++P)
          Positions.push_back(P);
        if (Swapped) {
          if (T.ID == instruction::I_call && NumOperands == 3)
            std::swap(Positions[1], Positions[2]);
          else if (NumOperands == 2)
            std::swap(Positions[0], Positions[1]);
        }
        Row R(NumVars);
        auto Unify = [&](unsigned Slot, const Binding &B) {
          if (Slot >= R.size())
            R.resize(Slot + 1);
          if (Unbound(R[Slot])) {
            R[Slot] = B;
            return true;
          }
          return R[Slot] == B;
        };
        bool Fits = true;
        unsigned Index = 0;
        for (auto [Pattern, IsValue] : zip(T.Patterns, T.IsValue)) {
          TypeCode Code = NoType;
          if (IsValue) {
            unsigned Position = Positions[Index++];
            if (!Pattern || Position >= NumOperandSlots)
              continue;
            Code = It->Operands[Position];
          } else if (T.ID != instruction::I_alloca &&
                     T.ID != instruction::I_getelementptr) {
            Code = It->Result;
          }
          const llvm::Type *Target = decodeType(Code, *TypeContext);
          if (!Pattern || !Target)
            continue;
          if (!Types.match(*Pattern, *Target, T.TreatIntAsVec, Unify)) {
            Fits = false;
            break;
          }
        }
        if (Fits && !is_contained(Rows, R))
          Rows.push_back(std::move(R));
      }
    }
    return Rows;
  };

  SmallVector<Row, 4> Joined(1, Row(NumVars));
  bool Overflowed = false;
  for (const Typing &T : V.Typings) {
    SmallVector<Row, 4> Each = Typings(T);
    if (Each.empty())
      return {};
    if (Overflowed || Each.size() > MaxTypings) {
      Overflowed = true;
      continue;
    }
    SmallVector<Row, 4> Next;
    for (const Row &Partial : Joined)
      for (const Row &Typing : Each) {
        Row Merged = Partial;
        Merged.resize(std::max(Merged.size(), Typing.size()));
        bool Agrees = true;
        for (auto [Slot, B] : enumerate(Typing)) {
          if (Unbound(B))
            continue;
          if (Unbound(Merged[Slot]))
            Merged[Slot] = B;
          else if (!(Merged[Slot] == B)) {
            Agrees = false;
            break;
          }
        }
        if (Agrees && !is_contained(Next, Merged))
          Next.push_back(std::move(Merged));
      }
    if (Next.empty())
      return {};
    if (Next.size() > MaxTypings)
      Overflowed = true;
    else
      Joined = std::move(Next);
  }
  if (Overflowed)
    return SmallVector<Row, 4>(1, Row(NumVars));
  return Joined;
}

//===----------------------------------------------------------------------===//
// Constraints on features
//===----------------------------------------------------------------------===//

namespace {
/// Evaluates mpir_expr on a function's features, where a constraint is
/// false only if no match in the function can satisfy it.
///
/// Operators on concrete operands compute their result as on the IR; on
/// others, they apply their abstract() faces, or are unknown. A concrete
/// boolean B stands for "B, or an evaluation error": either rejects a match
/// when B is false. An error is one the IR evaluation certainly has.
class AbstractEvaluator {
public:
  AbstractEvaluator(const FunctionFeatures &Features,
                    const IndexQuery::Row &Types)
      : Features(Features), Types(Types) {}

  struct Frame {
    DenseMap<mlir::Value, AbstractValue> Parameters;
  };

  Expected<AbstractValue> eval(mlir::Value E, Frame &F);

private:
  const FunctionFeatures &Features;
  const IndexQuery::Row &Types;
  unsigned CallDepth = 0;

  Expected<SmallVector<AbstractValue, 2>> evalAll(mlir::ValueRange Values,
                                                  Frame &F) {
    SmallVector<AbstractValue, 2> Result;
    for (mlir::Value V : Values) {
      Expected<AbstractValue> Value = eval(V, F);
      if (!Value)
        return Value.takeError();
      Result.push_back(std::move(*Value));
    }
    return Result;
  }
  static std::optional<SmallVector<ConstraintValue, 2>>
  allConcrete(ArrayRef<AbstractValue> Operands) {
    SmallVector<ConstraintValue, 2> Concrete;
    for (const AbstractValue &Operand : Operands) {
      if (!Operand.isConcrete())
        return std::nullopt;
      Concrete.push_back(Operand.getConcrete());
    }
    return Concrete;
  }
  Expected<AbstractValue> evalCall(mpir_expr::CallOp Call, Frame &F);
  Expected<AbstractValue> evalApply(mpir_expr::ApplyOp Apply, Frame &F);
};
} // namespace

Expected<AbstractValue> AbstractEvaluator::eval(mlir::Value E, Frame &F) {
  Operation *Def = E.getDefiningOp();
  auto Concrete = [](ConstraintValue V) {
    return AbstractValue::concrete(std::move(V));
  };
  if (!Def) {
    auto It = F.Parameters.find(E);
    return It == F.Parameters.end() ? AbstractValue::unknown() : It->second;
  }
  if (auto Int = dyn_cast<mpir_expr::IntOp>(Def))
    return Concrete(ConstraintValue::getInteger(Int.getAPSInt()));
  if (auto Bool = dyn_cast<mpir_expr::BoolOp>(Def))
    return Concrete(ConstraintValue::getBoolean(Bool.getValue()));
  if (auto Str = dyn_cast<mpir_expr::StrOp>(Def))
    return Concrete(ConstraintValue::getString(Str.getValue()));
  if (auto Read = dyn_cast<mpir_expr::ReadOp>(Def)) {
    mlir::Value V = Read.getValue();
    if (auto Sites = V.getDefiningOp<mpir_index::SitesOp>()) {
      ::llvm::metaphir::Sites Of;
      for (mlir::Attribute A : Sites.getSites())
        Of.push_back(siteOf(cast<mlir::ArrayAttr>(A)));
      return AbstractValue::sites(std::move(Of));
    }
    if (auto Var = V.getDefiningOp<mpir_index::TypeVarOp>()) {
      unsigned Slot = Var.getSlot();
      if (Slot < Types.size() &&
          !std::holds_alternative<std::monostate>(Types[Slot].Data)) {
        Expected<ConstraintValue> Value = readBinding(E, Types[Slot]);
        if (!Value)
          return Value.takeError();
        return Concrete(std::move(*Value));
      }
      return AbstractValue::unknown();
    }
    if (isa<mlir::BlockArgument>(V)) {
      auto It = F.Parameters.find(V);
      if (It != F.Parameters.end())
        return It->second;
    }
    // Whatever the IR binds it to is not known here.
    return AbstractValue::unknown();
  }
  if (auto Array = dyn_cast<mpir_expr::ArrayOp>(Def)) {
    Expected<SmallVector<AbstractValue, 2>> Elements =
        evalAll(Array.getElements(), F);
    if (!Elements)
      return Elements.takeError();
    std::optional<SmallVector<ConstraintValue, 2>> Values =
        allConcrete(*Elements);
    if (!Values)
      return AbstractValue::unknown();
    switch (cast<mpir::SortType>(Array.getType()).getSort()) {
    case Sort::TypeArray: {
      Binding::TypeArray Types;
      for (const ConstraintValue &V : *Values)
        Types.push_back(V.getType());
      return Concrete(ConstraintValue::getTypeArray(std::move(Types)));
    }
    case Sort::ValueArray: {
      Binding::ValueArray Vals;
      for (const ConstraintValue &V : *Values)
        Vals.push_back(V.getValue());
      return Concrete(ConstraintValue::getValueArray(std::move(Vals)));
    }
    default: {
      ConstraintValue::StringArrayStorage Strings;
      for (const ConstraintValue &V : *Values) {
        Expected<std::string> S = requireString(V, Array.getResult());
        if (!S)
          return S.takeError();
        Strings.push_back(std::move(*S));
      }
      return Concrete(ConstraintValue::getStringArray(std::move(Strings)));
    }
    }
  }
  if (isa<mpir_expr::IndexOp>(Def))
    // Arrays of the IR are not known here; literals rarely are indexed.
    return AbstractValue::unknown();
  if (auto Call = dyn_cast<mpir_expr::CallOp>(Def))
    return evalCall(Call, F);
  if (auto Apply = dyn_cast<mpir_expr::ApplyOp>(Def))
    return evalApply(Apply, F);
  return AbstractValue::unknown();
}

Expected<AbstractValue> AbstractEvaluator::evalApply(mpir_expr::ApplyOp Apply,
                                                     Frame &F) {
  mlir::Value Expression = Apply.getResult();
  auto Def = mlir::SymbolTable::lookupNearestSymbolFrom<mpir::ConstraintDefOp>(
      Apply, Apply.getCalleeAttr());
  if (!Def)
    return make_error<ConstraintEvaluationError>(
        Expression, Twine("unknown operator '") + Apply.getCallee() + "'");
  if (CallDepth == 256)
    return make_error<ConstraintEvaluationError>(
        Expression, "user-defined constraints are nested too deeply");
  mlir::Block &Body = Def.getBody().front();
  Frame Callee;
  for (auto [Index, Arg] : enumerate(Apply.getArgs())) {
    Expected<AbstractValue> Value = eval(Arg, F);
    if (!Value)
      return Value.takeError();
    Callee.Parameters.insert_or_assign(Body.getArgument(Index),
                                       std::move(*Value));
  }
  mlir::Value Result = (*Body.getOps<mpir::YieldOp>().begin()).getValue();
  ++CallDepth;
  Expected<AbstractValue> Value = eval(Result, Callee);
  --CallDepth;
  return Value;
}

Expected<AbstractValue> AbstractEvaluator::evalCall(mpir_expr::CallOp Call,
                                                    Frame &F) {
  mlir::Value Expression = Call.getResult();
  mlir::OperandRange Arguments = Call.getArgs();
  auto Boolean = [](bool B) {
    return AbstractValue::concrete(ConstraintValue::getBoolean(B));
  };

  auto Logical = [&](bool IsOr) -> Expected<AbstractValue> {
    Expected<AbstractValue> Left = eval(Arguments[0], F);
    if (!Left)
      return Left.takeError();
    if (Left->isConcrete()) {
      Expected<bool> Value = requireBoolean(Left->getConcrete(), Expression);
      if (!Value)
        return Value.takeError();
      if (*Value == IsOr)
        return Boolean(*Value);
    }
    // The right side: true, false (an error, which rejects, too), or
    // unknown.
    Expected<AbstractValue> Right = eval(Arguments[1], F);
    std::optional<bool> RightValue;
    if (!Right) {
      consumeError(Right.takeError());
      RightValue = false;
    } else if (Right->isConcrete()) {
      Expected<bool> Value = requireBoolean(Right->getConcrete(), Expression);
      if (Value) {
        RightValue = *Value;
      } else {
        consumeError(Value.takeError());
        RightValue = false;
      }
    }
    if (Left->isConcrete())
      return RightValue ? Boolean(*RightValue) : AbstractValue::unknown();
    if (RightValue && *RightValue == IsOr)
      return Boolean(*RightValue);
    return AbstractValue::unknown();
  };

  auto Builtin = [&](auto Descriptor) -> Expected<AbstractValue> {
    using Op = decltype(Descriptor);
    if constexpr (Op::ShortCircuits) {
      return Logical(Call.getOperatorID() == constraint::O_LogicalOr);
    } else {
      Expected<SmallVector<AbstractValue, 2>> Operands = evalAll(Arguments, F);
      if (!Operands)
        return Operands.takeError();
      if (std::optional<SmallVector<ConstraintValue, 2>> Concrete =
              allConcrete(*Operands)) {
        Expected<ConstraintValue> Result = Op::concrete(
            ConcreteCall{*Concrete, Expression, [](const llvm::Value &) {
                           return std::optional<ModuleUses>();
                         }});
        if (!Result)
          return Result.takeError();
        return AbstractValue::concrete(std::move(*Result));
      }
      if constexpr (detail::HasAbstract<Op>::value)
        return Op::abstract(AbstractCall{*Operands, Expression, Features});
      return AbstractValue::unknown();
    }
  };

  auto ValueTrack = [&](auto Descriptor,
                        unsigned BaseArity) -> Expected<AbstractValue> {
    using Op = decltype(Descriptor);
    Expected<SmallVector<AbstractValue, 2>> Operands =
        evalAll(Arguments.take_front(BaseArity), F);
    if (!Operands)
      return Operands.takeError();
    int64_t Context = -1;
    if (Arguments.size() > BaseArity) {
      Expected<AbstractValue> Explicit = eval(Arguments[BaseArity], F);
      if (!Explicit)
        return Explicit.takeError();
    } else if (mlir::Value Anchor = Call.getAnchor()) {
      if (auto Node = Anchor.getDefiningOp<mpir_index::NodeOp>())
        Context = Node.getNode();
    }
    if constexpr (detail::HasAbstract<Op>::value)
      if (Context >= 0)
        return Op::abstract(
            AbstractCall{*Operands, Expression, Features, Context});
    return AbstractValue::unknown();
  };

  return visitOperator<Expected<AbstractValue>>(
      Call.getOperatorID(), Builtin, ValueTrack,
      []() -> Expected<AbstractValue> { return AbstractValue::unknown(); });
}

bool IndexQuery::constraintsMayHold(const Variant &V,
                                    const FunctionFeatures &Features,
                                    const Row &Types) const {
  AbstractEvaluator Evaluator(Features, Types);
  for (mlir::Value C : V.Constraints) {
    AbstractEvaluator::Frame F;
    Expected<AbstractValue> Result = Evaluator.eval(C, F);
    // An error rejects every match, as on the IR.
    if (!Result) {
      consumeError(Result.takeError());
      return false;
    }
    if (!Result->isConcrete())
      continue;
    Expected<bool> Holds = requireBoolean(Result->getConcrete(), C);
    if (!Holds) {
      consumeError(Holds.takeError());
      return false;
    }
    if (!*Holds)
      return false;
  }
  return true;
}

bool IndexQuery::mayMatch(const FunctionFeatures &Features) const {
  for (unsigned Index = 0; Index != size(); ++Index)
    if (mayMatchVariant(Index, Features))
      return true;
  return false;
}

bool IndexQuery::mayMatchVariant(unsigned Index,
                                 const FunctionFeatures &Features) const {
  const Variant &V = Variants[Index];
  if (V.Impossible || !V.Requirement.isSatisfiedBy(Features))
    return false;
  if (!Features.HasDetail)
    return true;
  return any_of(joinSignatures(V, Features), [&](const Row &Types) {
    return constraintsMayHold(V, Features, Types);
  });
}

//===----------------------------------------------------------------------===//
// Explanations
//===----------------------------------------------------------------------===//

static std::string opcode(instruction::InstructionID ID) {
  return ("`" + instruction::getOpcodeName(ID) + "`").str();
}

static std::string joinWords(ArrayRef<std::string> Words, StringRef Last) {
  std::string Text;
  for (auto [Index, Word] : enumerate(Words))
    Text += (Index == 0                  ? std::string()
             : Index + 1 == Words.size() ? (" " + Last + " ").str()
                                         : std::string(", ")) +
            Word;
  return Text;
}

static std::string article(instruction::InstructionID ID) {
  return StringRef("aeiou").contains(instruction::getOpcodeName(ID).front())
             ? "an"
             : "a";
}

static bool hasSiteFact(const FunctionFeatures &Features, const Site &S,
                        Atom A) {
  for (unsigned Slots = S.Slots; Slots; Slots &= Slots - 1)
    if (Features.hasFact(S.ID, llvm::countr_zero(Slots), A))
      return true;
  return false;
}

SmallVector<std::string, 2>
IndexQuery::explainNoStructure(const FunctionFeatures &Features) const {
  SmallVector<std::string, 2> Reasons;
  for (const Variant &V : Variants) {
    const FeatureRequirement &R = V.Structural;
    std::optional<std::string> Lack;
    if (uint64_t Missing = R.Instructions & ~Features.Instructions) {
      SmallVector<std::string, 4> Names;
      for (; Missing; Missing &= Missing - 1)
        Names.push_back(
            opcode(instruction::InstructionID(llvm::countr_zero(Missing))));
      Lack = "it has no " + joinWords(Names, "or");
    }
    if (!Lack)
      for (auto [User, Operand] : R.Edges)
        if (!Features.mayHaveEdge(User, Operand)) {
          Lack = "no " + opcode(User) + " in it has " + article(Operand) + " " +
                 opcode(Operand) + " operand";
          break;
        }
    if (!Lack)
      for (uint16_t Sibling : R.Siblings)
        if (!std::binary_search(Features.Siblings.begin(),
                                Features.Siblings.end(), Sibling)) {
          auto [A, B] = FunctionFeatures::splitEdgeKey(Sibling);
          Lack = "no value in it is used by both " + article(A) + " " +
                 opcode(A) + " and " + article(B) + " " + opcode(B);
          break;
        }
    if (!Lack)
      for (const std::string &Name : V.GlobalNames)
        if (!Features.hasGlobal(hashGlobalName(Name))) {
          Lack = ("it uses no `@" + Name + "`");
          break;
        }
    if (!Lack && Features.HasDetail) {
      for (const ShapeRequirement &Shape : R.Shapes) {
        if (Shape.isSatisfiedBy(Features))
          continue;
        std::string Text = "no " + opcode(Shape.ID) + " in it";
        SmallVector<std::string, 4> Parts;
        for (unsigned Flag = 0; Flag != 32; ++Flag) {
          if (Shape.Present & (uint32_t(1) << Flag))
            Parts.push_back(("has " + instruction_flag::getName(
                                          instruction_flag::FlagID(Flag)))
                                .str());
          if (Shape.Absent & (uint32_t(1) << Flag))
            Parts.push_back(("lacks " + instruction_flag::getName(
                                            instruction_flag::FlagID(Flag)))
                                .str());
        }
        if (Shape.Width)
          Parts.push_back("has an i" + std::to_string(Shape.Width) + " result");
        if (!Parts.empty())
          Text += " " + joinWords(Parts, "and");
        Lack = Text;
        break;
      }
      if (!Lack)
        for (const auto &[S, A] : R.SiteFacts)
          if (!hasSiteFact(Features, S, A)) {
            Lack = "no " + opcode(S.ID) +
                   " in it has the constant operand the pattern gives it";
            break;
          }
    }
    std::string Reason;
    if (Lack)
      Reason = std::move(*Lack);
    else if (Features.HasDetail && joinSignatures(V, Features).empty())
      Reason = "it has the instructions the pattern needs, but not of the "
               "types the pattern gives them together";
    else
      Reason = "it has the instructions the pattern needs, but not as the "
               "pattern connects them";
    if (!is_contained(Reasons, Reason))
      Reasons.push_back(std::move(Reason));
  }
  return Reasons;
}

} // namespace metaphir
} // namespace llvm
