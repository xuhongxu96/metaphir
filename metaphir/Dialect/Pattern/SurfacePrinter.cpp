#include "metaphir/Dialect/Pattern/SurfacePrinter.h"
#include "metaphir/Dialect/Expr/ExprDialect.h"
#include "metaphir/Dialect/Pattern/PatternDialect.h"
#include "metaphir/IR/Constants.h"
#include "metaphir/IR/Type.h"
#include "llvm/ADT/SmallString.h"
#include "llvm/Support/raw_ostream.h"

using namespace mlir;

namespace llvm {
namespace metaphir {

using namespace mpir;

static Sort sortOf(mlir::Value V) {
  return cast<SortType>(V.getType()).getSort();
}

StringRef getMetaVariableName(mlir::Value V) {
  if (Operation *Def = V.getDefiningOp()) {
    // An mpir.var, or what stands for one elsewhere (a plan's slot).
    if (auto Name = Def->getAttrOfType<StringAttr>("var_name"))
      return Name.getValue();
    return "";
  }
  auto Arg = dyn_cast<BlockArgument>(V);
  if (!Arg)
    return "";
  Operation *Owner = Arg.getOwner()->getParentOp();
  unsigned Number = Arg.getArgNumber();
  auto NameAt = [](ArrayAttr Names, unsigned Index) -> StringRef {
    return Index < Names.size() ? cast<StringAttr>(Names[Index]).getValue()
                                : "";
  };
  if (auto Def = dyn_cast<ConstraintDefOp>(Owner))
    return NameAt(Def.getParamNames(), Number);
  if (auto Def = dyn_cast<MetaFlagDefOp>(Owner))
    return NameAt(Def.getParamNames(), Number);
  if (auto Branch = dyn_cast<BranchOp>(Owner)) {
    auto Matcher = Branch->getParentOfType<MatcherOp>();
    for (auto [Index, ArgNumber] : enumerate(Branch.getParamArgs()))
      if (ArgNumber == int32_t(Number))
        return NameAt(Matcher.getParamNames(), Index);
  }
  return "";
}

/// Prints a type pattern.
static void printType(raw_ostream &OS, mlir::Value T) {
  Operation *Def = T.getDefiningOp();
  if (!Def || isa<VarOp>(Def)) {
    OS << '?' << getMetaVariableName(T);
    return;
  }
  if (auto Int = dyn_cast<IntTypeOp>(Def)) {
    OS << (Int.getByte() ? 'b' : 'i') << Int.getWidth();
    return;
  }
  if (auto Meta = dyn_cast<MetaIntTypeOp>(Def)) {
    OS << (Meta.getByte() ? 'b' : 'i') << '?'
       << getMetaVariableName(Meta.getWidth());
    return;
  }
  if (auto Prim = dyn_cast<PrimTypeOp>(Def)) {
    switch (Type::TypeID(Prim.getKind())) {
#define MIR_TYPE(TypeID, Spelling)                                             \
  case Type::TypeID:                                                           \
    OS << #Spelling;                                                           \
    return;
#include "metaphir/IR/Types.def"
    default:
      break;
    }
    llvm_unreachable("not a primitive type");
  }
  if (auto Ptr = dyn_cast<PtrTypeOp>(Def)) {
    if (Ptr.getElement()) {
      printType(OS, Ptr.getElement());
      OS << '*';
    } else {
      OS << "ptr";
    }
    if (std::optional<uint32_t> Space = Ptr.getAddressSpace())
      OS << " addrspace(" << *Space << ')';
    return;
  }
  if (auto Struct = dyn_cast<StructTypeOp>(Def)) {
    if (Struct.getPacked())
      OS << '<';
    OS << '{';
    interleaveComma(Struct.getElements(), OS,
                    [&](mlir::Value E) { printType(OS, E); });
    OS << '}';
    if (Struct.getPacked())
      OS << '>';
    return;
  }
  if (auto Seq = dyn_cast<SeqTypeOp>(Def)) {
    bool Array = Seq.getKind() == 0;
    OS << (Array ? '[' : '<');
    if (Seq.getKind() == 2)
      OS << "vscale x ";
    if (Seq.getCountVar())
      OS << '?' << getMetaVariableName(Seq.getCountVar());
    else
      OS << Seq.getCount();
    OS << " x ";
    printType(OS, Seq.getElement());
    OS << (Array ? ']' : '>');
    return;
  }
  if (auto Func = dyn_cast<FuncTypeOp>(Def)) {
    printType(OS, Func.getReturnType());
    OS << " (";
    interleaveComma(Func.getParams(), OS,
                    [&](mlir::Value P) { printType(OS, P); });
    if (Func.getVarArg())
      OS << (Func.getParams().empty() ? "..." : ", ...");
    OS << ')';
    return;
  }
  OS << "<type>";
}

void printSurfaceValue(raw_ostream &OS, mlir::Value V) {
  Operation *Def = V.getDefiningOp();
  if (!Def || Def->hasAttr("var_name")) {
    if (sortOf(V) == Sort::IntrinsicID)
      OS << "@llvm.";
    OS << '?' << getMetaVariableName(V);
    return;
  }
  // An instruction matcher, or what stands for one elsewhere.
  if (!isa<InstOp, UseOp>(Def))
    if (auto Name = Def->getAttrOfType<StringAttr>("result_name")) {
      OS << '%' << Name.getValue();
      return;
    }
  if (auto Inst = dyn_cast<InstOp>(Def)) {
    OS << '%' << Inst.getResultName().value_or("");
    return;
  }
  if (auto Use = dyn_cast<UseOp>(Def)) {
    OS << '%' << Use.getResultName().value_or("");
    return;
  }
  if (auto Global = dyn_cast<GlobalOp>(Def)) {
    OS << '@' << Global.getName();
    return;
  }
  if (auto Int = dyn_cast<IntOp>(Def)) {
    IntegerAttr Value = Int.getValueAttr();
    OS << APSInt(Value.getValue(), Value.getType().isUnsignedInteger());
    return;
  }
  if (auto Float = dyn_cast<FloatOp>(Def)) {
    SmallString<16> Text;
    cast<FloatAttr>(Float.getValue()).getValue().toString(Text);
    if (StringRef(Text).find_first_of(".eEnN") == StringRef::npos)
      Text += ".0";
    OS << Text;
    return;
  }
  if (auto Keyword = dyn_cast<KeywordOp>(Def)) {
    OS << KeywordConstant::getKeywordName(
        KeywordConstant::KeywordID(Keyword.getKeyword()));
    return;
  }
  if (auto Aggregate = dyn_cast<AggregateOp>(Def)) {
    const char Open[] = {'[', '{', '<'};
    const char Close[] = {']', '}', '>'};
    OS << Open[Aggregate.getDelimiter()];
    mlir::OperandRange Elements = Aggregate.getElements();
    for (unsigned I = 0; I + 1 < Elements.size(); I += 2) {
      if (I)
        OS << ", ";
      printType(OS, Elements[I]);
      OS << ' ';
      printSurfaceValue(OS, Elements[I + 1]);
    }
    OS << Close[Aggregate.getDelimiter()];
    return;
  }
  printType(OS, V);
}

static void printMetaFlag(raw_ostream &OS, MetaFlagAttr Flag) {
  OS << ':' << Flag.getName().getValue();
  if (Flag.getArgs().empty())
    return;
  OS << '(';
  interleave(
      Flag.getArgs(), OS,
      [&](Attribute A) {
        if (auto Int = dyn_cast<IntegerAttr>(A))
          OS << Int.getInt();
        else
          printMetaFlag(OS, cast<MetaFlagAttr>(A));
      },
      ",");
  OS << ')';
}

namespace {
/// An operand of an instruction matcher, with its metaflags.
struct PrintedOperand {
  MatcherOperandView View;
  ArrayAttr MetaFlags;
};
} // namespace

/// As MatcherOperand's operator<< prints, with its type unless WithoutType.
static void printOperand(raw_ostream &OS, const PrintedOperand &O,
                         bool WithoutType = false) {
  const MatcherOperandView &V = O.View;
  if (V.Kind == OperandKind::ValueArray ||
      V.Kind == OperandKind::TypedValueArray) {
    OS << "...";
    if (V.Type) {
      OS << '?' << getMetaVariableName(V.Type) << ' ';
    }
    OS << '?' << getMetaVariableName(V.Val);
    return;
  }
  if (V.Type && !WithoutType) {
    printType(OS, V.Type);
    if (V.Val)
      OS << ' ';
  }
  if (V.Val)
    printSurfaceValue(OS, V.Val);
  if (O.MetaFlags)
    for (Attribute A : O.MetaFlags)
      printMetaFlag(OS, cast<MetaFlagAttr>(A));
}

static void printSeparated(raw_ostream &OS, ArrayRef<PrintedOperand> Ops,
                           unsigned Begin = 0) {
  interleaveComma(Ops.drop_front(Begin), OS,
                  [&](const PrintedOperand &O) { printOperand(OS, O); });
}

void printSurfaceInstruction(raw_ostream &OS, Operation *I) {
  auto Inst = dyn_cast<InstOp>(I);
  auto Use = dyn_cast<UseOp>(I);
  std::optional<StringRef> ResultName =
      Inst ? Inst.getResultName() : Use.getResultName();
  mlir::Value Capture = Inst ? Inst.getCapture() : Use.getCapture();
  std::optional<ArrayAttr> MetaFlags =
      Inst ? Inst.getMetaflags() : Use.getMetaflags();
  std::optional<ArrayAttr> OperandFlags =
      Inst ? Inst.getOperandMetaflags() : Use.getOperandMetaflags();
  ArrayRef<int32_t> Flags = Inst ? Inst.getFlags() : Use.getFlags();
  ArrayRef<int32_t> Modes = Inst ? Inst.getFlagModes() : Use.getFlagModes();
  mlir::OperandRange FlagCaptures =
      Inst ? Inst.getFlagCaptures() : Use.getFlagCaptures();

  SmallVector<PrintedOperand, 8> Unkeyed;
  SmallVector<PrintedOperand, 8> Keyed;
  for (auto [Index, View] : enumerate(getMatcherOperands(I))) {
    PrintedOperand O{View, OperandFlags
                               ? cast<ArrayAttr>((*OperandFlags)[Index])
                               : ArrayAttr()};
    (View.Kind >= OperandKind::Predicate ? Keyed : Unkeyed).push_back(O);
  }
  auto KeyedOf = [&](OperandKind Kind) -> const PrintedOperand * {
    for (const PrintedOperand &O : Keyed)
      if (O.View.Kind == Kind)
        return &O;
    return nullptr;
  };

  if (ResultName)
    OS << '%' << *ResultName << " = ";
  Instruction::OperandSyntax Syntax;
  if (Inst) {
    OS << Instruction::getOpcodeName(Inst.getOpcode().getValue());
    Syntax = Instruction::getOperandSyntax(Inst.getOpcode().getValue());
  } else {
    OS << Use.getMatcher();
    auto Matcher = SymbolTable::lookupNearestSymbolFrom<MatcherOp>(
        I, Use.getMatcherAttr());
    Syntax = Matcher ? Instruction::OperandSyntax(Matcher.getSyntax())
                     : Instruction::OperandSyntax::Nary;
  }
  if (Capture)
    OS << ":?" << getMetaVariableName(Capture);
  if (MetaFlags)
    for (Attribute A : *MetaFlags)
      printMetaFlag(OS, cast<MetaFlagAttr>(A));
  unsigned NextCapture = 0;
  for (auto [Flag, Mode] : zip(Flags, Modes)) {
    OS << ' ';
    if (FlagMode(Mode) == FlagMode::Negated)
      OS << '!';
    OS << InstructionFlag::getName(InstructionFlag::FlagID(Flag));
    if (FlagMode(Mode) == FlagMode::Captured)
      OS << ":?" << getMetaVariableName(FlagCaptures[NextCapture++]);
  }
  ArrayRef<PrintedOperand> Ops = Unkeyed;
  if (Ops.empty() && Syntax != Instruction::OperandSyntax::Custom)
    return;
  switch (Syntax) {
  case Instruction::OperandSyntax::Binary:
    OS << ' ';
    printOperand(OS, Ops[0]);
    OS << ", ";
    printOperand(OS, Ops[1], /*WithoutType=*/true);
    return;
  case Instruction::OperandSyntax::Cast:
    OS << ' ';
    printOperand(OS, Ops[0]);
    if (Ops.size() > 1 && Ops[1].View.Type) {
      OS << " to ";
      printType(OS, Ops[1].View.Type);
    }
    return;
  case Instruction::OperandSyntax::Nary:
    OS << ' ';
    printSeparated(OS, Ops);
    return;
  case Instruction::OperandSyntax::Custom:
    break;
  }
  using ID = Instruction::InstructionID;
  switch (Inst.getOpcode().getValue()) {
  case ID::I_icmp:
  case ID::I_fcmp:
    if (const PrintedOperand *Predicate = KeyedOf(OperandKind::Predicate)) {
      OS << ' ';
      printOperand(OS, *Predicate, true);
    }
    OS << ' ';
    printOperand(OS, Ops[0]);
    OS << ", ";
    printOperand(OS, Ops[1], true);
    return;
  case ID::I_phi:
    if (Ops.empty())
      return;
    if (Ops[0].View.Type) {
      OS << ' ';
      printType(OS, Ops[0].View.Type);
    }
    OS << ' ';
    for (unsigned Index = 0; Index < Ops.size(); Index += 2) {
      if (Index)
        OS << ", ";
      OS << '[';
      printOperand(OS, Ops[Index], true);
      if (Index + 1 < Ops.size()) {
        OS << ", ";
        printOperand(OS, Ops[Index + 1], true);
      }
      OS << ']';
    }
    return;
  case ID::I_call:
    if (Ops.size() < 2 || !Ops[0].View.Type) {
      OS << ' ';
      printSeparated(OS, Ops);
      return;
    }
    OS << ' ';
    printType(OS, Ops[0].View.Type);
    OS << ' ';
    printOperand(OS, Ops[1], true);
    OS << '(';
    printSeparated(OS, Ops, 2);
    OS << ')';
    return;
  case ID::I_getelementptr:
    if (const PrintedOperand *Lower = KeyedOf(OperandKind::InRangeLower)) {
      OS << " inrange(";
      printOperand(OS, *Lower, true);
      if (const PrintedOperand *Upper = KeyedOf(OperandKind::InRangeUpper)) {
        OS << ", ";
        printOperand(OS, *Upper, true);
      }
      OS << ')';
    }
    OS << ' ';
    printSeparated(OS, Ops);
    return;
  case ID::I_alloca:
  case ID::I_load:
  case ID::I_store:
    OS << ' ';
    printSeparated(OS, Ops);
    if (const PrintedOperand *Alignment = KeyedOf(OperandKind::Alignment)) {
      OS << ", align ";
      printOperand(OS, *Alignment);
    }
    if (const PrintedOperand *Space = KeyedOf(OperandKind::AddressSpace)) {
      OS << ", addrspace(";
      printOperand(OS, *Space);
      OS << ')';
    }
    return;
  case ID::I_ret:
    if (Ops.empty() || !Ops[0].View.Type)
      return;
    OS << ' ';
    printType(OS, Ops[0].View.Type);
    if (Ops[0].View.Val) {
      OS << ' ';
      printSurfaceValue(OS, Ops[0].View.Val);
    }
    return;
  default:
    OS << ' ';
    printSeparated(OS, Ops);
    return;
  }
}

void printSurfaceExpression(raw_ostream &OS, mlir::Value E) {
  Operation *Def = E.getDefiningOp();
  if (!Def) {
    OS << '?' << getMetaVariableName(E);
    return;
  }
  if (auto Int = dyn_cast<mpir_expr::IntOp>(Def)) {
    OS << Int.getAPSInt();
    return;
  }
  if (auto Bool = dyn_cast<mpir_expr::BoolOp>(Def)) {
    OS << (Bool.getValue() ? "true" : "false");
    return;
  }
  if (auto Str = dyn_cast<mpir_expr::StrOp>(Def)) {
    OS << '"' << Str.getValue() << '"';
    return;
  }
  if (auto Array = dyn_cast<mpir_expr::ArrayOp>(Def)) {
    OS << '[';
    interleave(
        Array.getElements(), OS,
        [&](mlir::Value V) { printSurfaceExpression(OS, V); }, ",");
    OS << ']';
    return;
  }
  if (auto Index = dyn_cast<mpir_expr::IndexOp>(Def)) {
    printSurfaceExpression(OS, Index.getArray());
    OS << '[';
    printSurfaceExpression(OS, Index.getIndex());
    OS << ']';
    return;
  }
  if (auto Read = dyn_cast<mpir_expr::ReadOp>(Def)) {
    mlir::Value V = Read.getValue();
    Operation *ValueDef = V.getDefiningOp();
    if (ValueDef && !ValueDef->hasAttr("var_name"))
      printSurfaceValue(OS, V);
    else if (StringRef Name = getMetaVariableName(V); !Name.empty())
      OS << '?' << Name;
    else
      printSurfaceValue(OS, V);
    return;
  }
  if (auto Call = dyn_cast<mpir_expr::CallOp>(Def)) {
    OS << '(' << Constraint::getOperatorName(Call.getOperatorID());
    for (mlir::Value A : Call.getArgs()) {
      OS << ' ';
      printSurfaceExpression(OS, A);
    }
    OS << ')';
    return;
  }
  if (auto Apply = dyn_cast<mpir_expr::ApplyOp>(Def)) {
    OS << '(' << Apply.getCallee();
    for (mlir::Value A : Apply.getArgs()) {
      OS << ' ';
      printSurfaceExpression(OS, A);
    }
    OS << ')';
    return;
  }
  printSurfaceValue(OS, E);
}

/// The parent block operand of an instruction matcher.
static mlir::Value parentBlockOf(Operation *I) {
  if (auto Inst = dyn_cast<InstOp>(I))
    return Inst.getParentBlock();
  return cast<UseOp>(I).getParentBlock();
}

void printSurfacePattern(raw_ostream &OS, PatternOp Pattern) {
  SmallVector<Operation *, 16> Instructions;
  SmallVector<RequireOp, 8> Constraints;
  SmallVector<VarOp, 16> Variables;
  if (Pattern)
    for (Operation &Op : Pattern.getBody().front()) {
      if (isa<InstOp, UseOp>(Op))
        Instructions.push_back(&Op);
      else if (auto Require = dyn_cast<RequireOp>(Op))
        Constraints.push_back(Require);
      else if (auto Var = dyn_cast<VarOp>(Op))
        Variables.push_back(Var);
    }
  OS << "pattern instructions=" << Instructions.size()
     << " constraints=" << Constraints.size() << '\n';
  mlir::Value CurrentBlock;
  for (Operation *I : Instructions) {
    mlir::Value Block = parentBlockOf(I);
    if (Block != CurrentBlock) {
      CurrentBlock = Block;
      if (CurrentBlock && !getMetaVariableName(CurrentBlock).empty())
        OS << '?' << getMetaVariableName(CurrentBlock) << ":\n";
    }
    printSurfaceInstruction(OS, I);
    OS << '\n';
  }
  for (RequireOp C : Constraints) {
    OS << "constraint ";
    printSurfaceExpression(OS, C.getCondition());
    OS << '\n';
  }
  for (VarOp Var : Variables)
    OS << "meta ?" << Var.getVarName()
       << " type=" << getSortName(resolveSort(sortOf(Var))) << '\n';
}

} // namespace metaphir
} // namespace llvm
