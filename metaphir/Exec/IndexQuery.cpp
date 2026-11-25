#include "metaphir/Exec/IndexQuery.h"
#include "metaphir/Dialect/Index/IndexDialect.h"
#include "metaphir/Exec/AbstractEvaluator.h"
#include "metaphir/Exec/ConcreteEvaluator.h"
#include "metaphir/Exec/TypePattern.h"
#include "metaphir/Matching/ConstraintCoercion.h"
#include "metaphir/Matching/TypeCode.h"

namespace llvm {
namespace metaphir {

using namespace detail;
using mlir::Operation;

struct IndexQuery::Typing {
  instruction::InstructionID ID;
  uint32_t Present = 0;
  uint32_t Absent = 0;
  bool TreatIntAsVec = false;
  /// Per unkeyed operand: its type pattern (null if it has none), and
  /// whether it is a value operand.
  SmallVector<mpir::TypePatternAttr, 4> Patterns;
  SmallVector<bool, 4> IsValue;
};

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
  ConcreteEvaluator Concrete;
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
                  uint8_t(Has.getPositions())},
             Atom::fromCode(Has.getAtom())});
      } else if (auto T = dyn_cast<mpir_index::TypingOp>(Op)) {
        Typing Each;
        Each.ID = T.getOpcode().getValue();
        Each.Present = T.getPresent();
        Each.Absent = T.getAbsent();
        Each.TreatIntAsVec = T.getTreatIntAsVec();
        for (auto [Pattern, IsValue] :
             zip(T.getOperandTypes(), T.getValueOperand())) {
          Each.Patterns.push_back(dyn_cast<mpir::TypePatternAttr>(Pattern));
          Each.IsValue.push_back(IsValue);
        }
        V.Typings.push_back(std::move(Each));
      } else if (auto Var = dyn_cast<mpir_index::TypeVarOp>(Op)) {
        V.NumTypeVariables = std::max(V.NumTypeVariables, Var.getSlot() + 1);
      } else if (auto Assume = dyn_cast<mpir_index::AssumeOp>(Op)) {
        mlir::Value Condition = Assume.getCondition();
        V.Constraints.push_back(Condition);
        // A closed constraint evaluates alike in every match, and rejects
        // it when it is false or fails to evaluate.
        if (Assume.getClosed()) {
          Expected<ConstraintValue> Result = Concrete.evaluate(
              Condition, [](unsigned) -> const Binding * { return nullptr; });
          Expected<bool> Holds = Result ? requireBoolean(*Result, Condition)
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
    Normalize(R);
    Variants.push_back(std::move(V));
  }
}

IndexQuery::~IndexQuery() = default;

//===----------------------------------------------------------------------===//
// Typing
//===----------------------------------------------------------------------===//

static constexpr size_t MaxTypings = 256;

SmallVector<IndexQuery::TypeBindings, 4>
IndexQuery::joinSignatures(const Variant &V,
                           const FunctionFeatures &Features) const {
  unsigned NumVars = V.NumTypeVariables;
  auto Unbound = [](const Binding &B) {
    return std::holds_alternative<std::monostate>(B.Data);
  };
  auto BindingsOf = [&](const Typing &T) {
    SmallVector<TypeBindings, 4> All;
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
      TypeBindings Bindings(NumVars);
      auto Unify = [&](unsigned Slot, const Binding &B) {
        if (Slot >= Bindings.size())
          Bindings.resize(Slot + 1);
        if (Unbound(Bindings[Slot])) {
          Bindings[Slot] = B;
          return true;
        }
        return Bindings[Slot] == B;
      };
      bool Fits = true;
      unsigned Position = 0;
      for (auto [Pattern, IsValue] : zip(T.Patterns, T.IsValue)) {
        TypeCode Code = NoType;
        if (IsValue) {
          unsigned Operand = Position++;
          if (!Pattern || Operand >= NumOperandPositions)
            continue;
          Code = It->Operands[Operand];
        } else if (T.ID != instruction::I_alloca &&
                   T.ID != instruction::I_getelementptr) {
          Code = It->Result;
        }
        const llvm::Type *Target = decodeType(Code, *TypeContext);
        if (!Pattern || !Target)
          continue;
        if (!matchTypePattern(Pattern, *Target, T.TreatIntAsVec, Unify)) {
          Fits = false;
          break;
        }
      }
      if (Fits && !is_contained(All, Bindings))
        All.push_back(std::move(Bindings));
    }
    return All;
  };

  SmallVector<TypeBindings, 4> Joined(1, TypeBindings(NumVars));
  bool Overflowed = false;
  for (const Typing &T : V.Typings) {
    SmallVector<TypeBindings, 4> BindingChoices = BindingsOf(T);
    if (BindingChoices.empty())
      return {};
    if (Overflowed || BindingChoices.size() > MaxTypings) {
      Overflowed = true;
      continue;
    }
    SmallVector<TypeBindings, 4> Next;
    for (const TypeBindings &Partial : Joined) {
      for (const TypeBindings &Bindings : BindingChoices) {
        TypeBindings Merged = Partial;
        Merged.resize(std::max(Merged.size(), Bindings.size()));
        bool Agrees = true;
        for (auto [Slot, B] : enumerate(Bindings)) {
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
    }
    if (Next.empty())
      return {};
    if (Next.size() > MaxTypings)
      Overflowed = true;
    else
      Joined = std::move(Next);
  }
  if (Overflowed)
    return SmallVector<TypeBindings, 4>(1, TypeBindings(NumVars));
  return Joined;
}

//===----------------------------------------------------------------------===//
// Constraints on features
//===----------------------------------------------------------------------===//

bool IndexQuery::constraintsMayHold(const Variant &V,
                                    const FunctionFeatures &Features,
                                    const TypeBindings &Types) const {
  AbstractEvaluator Evaluator(Features, Types);
  for (mlir::Value C : V.Constraints) {
    Expected<AbstractValue> Result = Evaluator.evaluate(C);
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
  return any_of(joinSignatures(V, Features), [&](const TypeBindings &Types) {
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
  for (unsigned Positions = S.Positions; Positions; Positions &= Positions - 1)
    if (Features.hasFact(S.ID, llvm::countr_zero(Positions), A))
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
