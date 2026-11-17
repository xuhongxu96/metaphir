//===- PatternParser.cpp - Parse patterns into the mpir dialect -----------===//
//
// Parses the MetaphIR language (see docs/) into operations of the mpir and
// mpir_expr dialects, with the lexer of MIRLexer. Each part of the grammar is
// parsed, and checked, in the section of its name below.
//
//===----------------------------------------------------------------------===//

#include "metaphir/Parser/PatternParser.h"
#include "metaphir/Dialect/Expr/ExprDialect.h"
#include "metaphir/Dialect/Pattern/PatternDialect.h"
#include "metaphir/Dialect/Pattern/SourceLocation.h"
#include "metaphir/IR/Constants.h"
#include "metaphir/IR/Constraint.h"
#include "metaphir/IR/Instruction.h"
#include "metaphir/IR/MetaFlag.h"
#include "metaphir/IR/PatternSettings.h"
#include "metaphir/IR/Sort.h"
#include "metaphir/IR/Type.h"
#include "metaphir/Parser/KeywordTokens.h"
#include "metaphir/Parser/MIRLexer.h"
#include "mlir/IR/Builders.h"
#include "mlir/IR/BuiltinTypes.h"
#include "mlir/IR/SymbolTable.h"
#include "mlir/IR/Verifier.h"
#include "llvm/ADT/SmallString.h"
#include "llvm/ADT/StringMap.h"
#include "llvm/ADT/StringSet.h"
#include "llvm/ADT/Twine.h"

namespace llvm {
namespace metaphir {

void loadPatternDialects(mlir::MLIRContext &Context) {
  Context.loadDialect<mpir::PatternDialect, mpir_expr::ExprDialect>();
}

// The parser's own names, where mlir::Value is the Value.
namespace parse {

using mlir::OpBuilder;
using mlir::Operation;
using mlir::Value;
using namespace mpir;

#include "StdLibSource.inc"

namespace {

/// The name under which the embedded standard library is parsed.
constexpr StringLiteral StdLibName = "stdlib";

Sort sortOf(Value V) { return cast<SortType>(V.getType()).getSort(); }

/// A matcher operand being parsed, as MatcherOperand is.
struct POperand {
  OperandKind Kind = OperandKind::TypedValue;
  Value Ty;
  Value Val;
  SmallVector<mlir::Attribute, 2> MetaFlags;
  /// Where the value was written, for diagnostics.
  SMLoc ValLoc;

  bool isValueOperand() const { return mpir::isValueOperand(Kind); }
  bool isArray() const {
    return Kind == OperandKind::ValueArray ||
           Kind == OperandKind::TypedValueArray;
  }
};

/// A semantic flag written on an instruction matcher.
struct PFlag {
  instruction_flag::FlagID ID;
  FlagMode Mode;
  Value Capture;
};

/// A metaflag as parsed, and where it was written.
struct PMetaFlag {
  MetaFlagAttr Attr;
  SMLoc Loc;
  /// Where the flag may be written, and whether it may be nested.
  metaflag::Placement Allowed = metaflag::AnyPlacement;
  bool Nestable = true;
  StringRef getName() const { return Attr.getName().getValue(); }
  metaflag::MetaFlagID getID() const {
    return metaflag::getMetaFlagID(getName());
  }
};

/// Parses one buffer into a module.
class Parser {
public:
  Parser(StringRef Buffer, SourceMgr &SM, SMDiagnostic &Error,
         mlir::ModuleOp Module)
      : SM(SM), Lex(Buffer, SM, Error), Context(Module.getContext()),
        Builder(Context), Module(Module) {}

  /// Parses the buffer: definitions, then an optional pattern body.
  /// Library is true for a library, which may hold only definitions.
  bool parseModule(bool Library);

private:
  using LocTy = MIRLexer::LocTy;

  SourceMgr &SM;
  MIRLexer Lex;
  mlir::MLIRContext *Context;
  OpBuilder Builder;
  mlir::ModuleOp Module;

  /// The naming state of a scope: a pattern body, a match branch or a
  /// definition body.
  StringMap<Value> MetaVariables;
  StringMap<Value> Instructions;
  /// The instruction matchers of the body, in order.
  SmallVector<Operation *, 16> BodyInstructions;
  Value CurrentBlock;
  PatternSettings Settings;

  unsigned Depth = 0;
  static constexpr unsigned MaxDepth = 256;
  struct Nesting {
    Parser &P;
    explicit Nesting(Parser &P) : P(P) { ++P.Depth; }
    ~Nesting() { --P.Depth; }
    bool tooDeep() {
      return P.Depth > MaxDepth && P.error("nesting is too deep");
    }
  };

  unsigned NextWildcard = 0;
  bool InDefinitionBody = false;

  /// Saves the naming state and the insertion point, and opens a closed scope
  /// in its place, inserting at the end of Body; both are restored when the
  /// scope ends.
  class ClosedScope {
  public:
    ClosedScope(Parser &P, mlir::Block *Body)
        : P(P), MetaVariables(std::move(P.MetaVariables)),
          Instructions(std::move(P.Instructions)),
          BodyInstructions(std::move(P.BodyInstructions)),
          CurrentBlock(P.CurrentBlock), Settings(P.Settings), Guard(P.Builder) {
      P.MetaVariables.clear();
      P.Instructions.clear();
      P.BodyInstructions.clear();
      P.CurrentBlock = Value();
      P.Settings = PatternSettings();
      P.Builder.setInsertionPointToEnd(Body);
    }
    ~ClosedScope() {
      P.MetaVariables = std::move(MetaVariables);
      P.Instructions = std::move(Instructions);
      P.BodyInstructions = std::move(BodyInstructions);
      P.CurrentBlock = CurrentBlock;
      P.Settings = Settings;
    }

  private:
    Parser &P;
    StringMap<Value> MetaVariables;
    StringMap<Value> Instructions;
    SmallVector<Operation *, 16> BodyInstructions;
    Value CurrentBlock;
    PatternSettings Settings;
    OpBuilder::InsertionGuard Guard;
  };

  // Tokens and diagnostics.
  bool error(const Twine &Message) { return Lex.ParseError(Message); }
  void next() {
    while (Lex.Lex() == tok::Newline && InDefinitionBody) {
    }
  }
  bool consume(tok::Kind K) {
    if (Lex.getKind() != K)
      return false;
    next();
    return true;
  }
  bool expect(tok::Kind K, const Twine &Message) {
    if (!consume(K))
      return error(Message + " (got " + describeToken() + ")");
    return false;
  }
  std::string describeToken() const;
  void skipNewlines() {
    while (consume(tok::Newline)) {
    }
  }
  bool expectEndOfLine(tok::Kind Terminator, const Twine &Message);
  bool parseCommaList(tok::Kind Close, function_ref<bool()> Element);

  mlir::Location loc(SMLoc Begin, SMLoc End = SMLoc()) {
    return getLocation(Context, SM,
                       SMRange(Begin, End.isValid() ? End : Begin));
  }
  /// Where V, or the operation defining it, was written.
  SMLoc locOf(Value V) const { return getSourceRange(V.getLoc()).Start; }
  mpir::SortType sortType(Sort S) { return getSortType(Context, S); }

  // Definitions in the module.
  template <typename OpT> OpT lookup(StringRef Name) {
    return dyn_cast_or_null<OpT>(
        mlir::SymbolTable::lookupSymbolIn(Module, Name));
  }
  /// Inserts a definition before the pattern, if there is one.
  void insertDefinition(Operation *Def);
  PatternOp ThePattern;

  // Meta variables.
  Value getMeta(StringRef Name, Sort Expected, LocTy Loc);
  bool infer(Value M, StringRef Name, Sort Expected, LocTy Loc);

  // Pattern bodies.
  bool parseBodyLine(tok::Kind Terminator);
  bool parseBlockLabel();
  bool parsePatternSetting(PatternSettings::Setting Setting);
  bool parseInstruction(Value &Result);
  bool parseInstructionResult(SmallVectorImpl<char> &Name);
  bool parseInstructionCapture(Value &Capture);
  bool parseInstructionMetaFlags(SmallVectorImpl<PMetaFlag> &Result,
                                 bool IsCommutative, StringRef OwnerName);
  bool
  parseSemanticFlags(function_ref<bool(instruction_flag::FlagID)> IsSupported,
                     StringRef OwnerName, SmallVectorImpl<PFlag> &Result);
  bool parseMetaFlag(PMetaFlag &Result, metaflag::Placement Position);
  bool parseMetaFlags(SmallVectorImpl<PMetaFlag> &Result,
                      metaflag::Placement Position);
  bool validateOrSelf(ArrayRef<PMetaFlag> MFlags, ArrayRef<POperand> Ops);
  bool validateInstruction(instruction::InstructionID ID,
                           ArrayRef<PMetaFlag> MFlags, ArrayRef<POperand> Ops);
  Operation *buildMatcherUse(StringRef OpName, mlir::NamedAttribute Matcher,
                             StringRef ResultName, ArrayRef<PFlag> Flags,
                             ArrayRef<PMetaFlag> MFlags, ArrayRef<POperand> Ops,
                             Value Capture, SMLoc Begin);
  bool parseCompositeInstruction(Value &Result, MatcherOp CM, StringRef OpName,
                                 StringRef ResultName, LocTy Loc);

  // Operands.
  bool parseArchetypeOperands(instruction::OperandSyntax Syntax, unsigned Arity,
                              StringRef OpName, SmallVectorImpl<POperand> &Ops);
  bool parseCustomOperands(instruction::InstructionID ID,
                           SmallVectorImpl<POperand> &Ops);
  bool parseOperand(SmallVectorImpl<POperand> &Ops,
                    Sort Expected = Sort::Operand);
  bool parseTypeOperand(SmallVectorImpl<POperand> &Ops);
  bool parseKeyedOperand(SmallVectorImpl<POperand> &Ops, OperandKind Key,
                         Sort Expected);
  bool parseOperandComma() {
    return expect(tok::comma, "expected ',' between operands");
  }
  bool parseAlign(SmallVectorImpl<POperand> &Ops);
  enum TrailingOperandKind { NatIndices, TypedOperands };
  bool parseTrailingOperands(SmallVectorImpl<POperand> &Ops,
                             TrailingOperandKind Kind);
  bool parseAllocaOperands(SmallVectorImpl<POperand> &Ops);
  bool parseGEPOperands(SmallVectorImpl<POperand> &Ops);
  bool parseBranchOperands(SmallVectorImpl<POperand> &Ops);
  bool parseCompareOperands(SmallVectorImpl<POperand> &Ops);
  bool parsePhiOperands(SmallVectorImpl<POperand> &Ops);
  bool parseCallOperands(SmallVectorImpl<POperand> &Ops);
  bool parseTypedOperand(POperand &Result, Sort Expected = Sort::Operand);
  bool parseOperandMetaFlags(POperand &Result);
  bool parseArrayCapture(POperand &Result, bool WithTypes);

  // Types and values.
  bool parseType(Value &Result, bool AllowVoid = false);
  bool parseBaseType(Value &Result, bool AllowVoid);
  bool parsePointerType(Value &Result);
  bool parseSequenceType(Value &Result, bool IsVector, LocTy Loc);
  bool parseStructType(Value &Result, bool Packed, LocTy Loc);
  bool parseTypeSuffixes(Value &Result, LocTy Loc);
  bool parseValue(Value &Result, Sort Expected = Sort::Operand);
  bool parseAggregateConstant(Value &Result);
  Value makeInteger(const APSInt &Number, SMLoc Loc);

  // Constraint expressions.
  bool parseConstraint(Value &Result);
  bool parseConstraintBinary(Value &Result, unsigned MinPrecedence);
  bool parseConstraintUnary(Value &Result);
  bool parseConstraintPostfix(Value &Result);
  bool parseConstraintPrimary(Value &Result);
  bool parseConstraintArray(Value &Result);
  bool parseConstraintCall(Value &Result);
  bool parseConstraintArguments(SmallVectorImpl<Value> &Args);
  bool makeOperator(Value &Result, constraint::OperatorKind Kind,
                    StringRef Spelling, ArrayRef<Value> Args, LocTy Loc);
  bool checkOperands(mpir_expr::CallOp Operator, StringRef Spelling);
  bool requireBooleanConstraint(Value C);
  /// Anchors the value-tracking operators of C that have no context at the
  /// instruction Anchor.
  void setDefaultContext(Value C, Value Anchor);

  // Definitions.
  bool parseTopLevelConstraint();
  bool parseTopLevelMetaFlag();
  bool parseDefinitionParameters(StringRef Kind,
                                 SmallVectorImpl<std::string> &Names,
                                 SmallVectorImpl<SMLoc> &Locs);
  bool parseDefinitionBody(StringRef Kind, ArrayRef<std::string> Names,
                           ArrayRef<SMLoc> Locs, mlir::Block &Body,
                           Value &Result);

  struct ParamDef {
    std::string Name;
    Value Ty;
    SMLoc Loc;
    bool IsType = false;
  };
  struct MatchHeader {
    std::string Name;
    bool IsCommutative = false;
    SmallVector<instruction_flag::FlagID, 4> SupportedFlags;
    instruction::OperandSyntax Syntax = instruction::OperandSyntax::Nary;
    unsigned Arity = 0;
    SmallVector<ParamDef, 4> Parameters;
  };
  bool parseTopLevelMatch();
  bool parseMatchHeader(MatchHeader &Header, MatcherOp &Matcher, LocTy Loc);
  bool parseMatchParameters(instruction::OperandSyntax Syntax,
                            SmallVectorImpl<ParamDef> &Result);
  bool parseMatchBranch(const MatchHeader &Header, MatcherOp Matcher);
  bool parseBranchFlags(
      ArrayRef<instruction_flag::FlagID> SupportedFlags,
      SmallVectorImpl<std::pair<instruction_flag::FlagID, bool>> &Result);
  bool consumeBranchSeparator();
  bool parseSemanticFlagName(instruction_flag::FlagID &Result);
};

} // namespace

//===----------------------------------------------------------------------===//
// Tokens
//===----------------------------------------------------------------------===//

static std::string pluralize(uint64_t Count, StringRef Noun) {
  return (Twine(Count) + " " + Noun + (Count == 1 ? "" : "s")).str();
}

std::string Parser::describeToken() const {
  switch (Lex.getKind()) {
  case tok::Newline:
    return "end of line";
  case tok::Eof:
    return "end of file";
  default:
    return ("'" + Lex.getTokenText() + "'").str();
  }
}

bool Parser::parseCommaList(tok::Kind Close, function_ref<bool()> Element) {
  if (Lex.getKind() == Close)
    return false;
  do {
    if (Element())
      return true;
  } while (consume(tok::comma));
  return false;
}

bool Parser::expectEndOfLine(tok::Kind Terminator, const Twine &Message) {
  if (Lex.getKind() != tok::Newline && Lex.getKind() != tok::Eof &&
      Lex.getKind() != Terminator)
    return error(Message);
  skipNewlines();
  return false;
}

void Parser::insertDefinition(Operation *Def) {
  if (ThePattern)
    Def->moveBefore(ThePattern);
}

//===----------------------------------------------------------------------===//
// Meta variables
//===----------------------------------------------------------------------===//

bool Parser::infer(Value M, StringRef Name, Sort Expected, LocTy Loc) {
  std::optional<Sort> Meet = meetSorts(sortOf(M), Expected);
  if (!Meet)
    return Lex.ParseError(Loc, "meta variable '?" + Name +
                                   "' is used with an incompatible type");
  M.setType(sortType(*Meet));
  return false;
}

Value Parser::getMeta(StringRef Name, Sort Expected, LocTy Loc) {
  std::string Wildcard;
  if (Name == "_") {
    Wildcard = ("_$" + Twine(NextWildcard++)).str();
    Name = Wildcard;
  }
  auto It = MetaVariables.find(Name);
  if (It != MetaVariables.end()) {
    if (infer(It->second, Name, Expected, Loc))
      return Value();
    return It->second;
  }
  Value M = VarOp::create(Builder, loc(Loc), sortType(Expected),
                          Builder.getStringAttr(Name));
  MetaVariables[Name] = M;
  if (Instructions.count(Name))
    Lex.Warning(Loc, "meta variable '?" + Name +
                         "' shares a name with local variable '%" + Name + "'");
  return M;
}

//===----------------------------------------------------------------------===//
// Pattern bodies
//===----------------------------------------------------------------------===//

bool Parser::parseBlockLabel() {
  LocTy Loc = Lex.getLoc();
  SmallString<16> Name;
  if (Lex.getKind() == tok::LabelStr) {
    Name = Lex.getStrVal();
    next();
    if (Name == "anyblock") {
      CurrentBlock = Value();
      return false;
    }
  } else if (Lex.getKind() == tok::LabelID) {
    Twine(Lex.getUIntVal()).toVector(Name);
    next();
  } else {
    assert(Lex.getKind() == tok::MetaVar && "expected a block label");
    Name = Lex.getStrVal();
    next();
    if (expect(tok::colon, "expected ':' after basic block meta variable"))
      return true;
  }
  CurrentBlock = getMeta(Name, Sort::BasicBlock, Loc);
  return !CurrentBlock;
}

bool Parser::parsePatternSetting(PatternSettings::Setting Setting) {
  next();
  if (expect(tok::lparen,
             "expected '(' after '" + pattern_setting::getName(Setting) + "'"))
    return true;
  if (Lex.getKind() != tok::kw_true && Lex.getKind() != tok::kw_false)
    return error("expected 'true' or 'false' in '" +
                 pattern_setting::getName(Setting) + "'");
  if (Lex.getKind() == tok::kw_true)
    Settings.set(Setting);
  else
    Settings.clear(Setting);
  next();
  return expect(tok::rparen, "expected ')' after setting value");
}

bool Parser::parseModule(bool Library) {
  bool HasParsedTopLevelDefinition = false;
  mlir::Block *ModuleBody = Module.getBody();
  Builder.setInsertionPointToEnd(ModuleBody);
  ThePattern = PatternOp::create(Builder, loc(Lex.getLoc()));
  ThePattern.getBody().emplaceBlock();
  Builder.setInsertionPointToEnd(&ThePattern.getBody().front());
  next();
  skipNewlines();
  while (Lex.getKind() != tok::Eof) {
    bool Definition = true;
    bool Failed = false;
    switch (Lex.getKind()) {
    case tok::kw_match:
      Failed = parseTopLevelMatch();
      break;
    case tok::kw_constraint:
      Failed = parseTopLevelConstraint();
      break;
    case tok::kw_metaflag:
      Failed = parseTopLevelMetaFlag();
      break;
    default:
      Definition = false;
      break;
    }
    if (Failed)
      return true;
    if (Definition) {
      HasParsedTopLevelDefinition = true;
      skipNewlines();
      continue;
    }
    if (parseBodyLine(tok::Eof))
      return true;
  }
  if (BodyInstructions.empty()) {
    ThePattern.erase();
    ThePattern = nullptr;
    if (HasParsedTopLevelDefinition)
      return false;
    return error("expected at least one instruction matcher");
  }
  // A block needs an instruction in it, or one referring to it: else no
  // match binds its label.
  auto IsUsed = [&](Value Block) {
    for (Operation *I : BodyInstructions) {
      auto Inst = dyn_cast<InstOp>(I);
      auto Use = dyn_cast<UseOp>(I);
      Value Parent = Inst ? Inst.getParentBlock() : Use.getParentBlock();
      if (Parent == Block)
        return true;
      for (const MatcherOperandView &Op : getMatcherOperands(I))
        if (Op.Kind != OperandKind::TypeOnly && Op.Val == Block)
          return true;
    }
    return false;
  };
  for (Operation &Op : ThePattern.getBody().front())
    if (auto Var = dyn_cast<VarOp>(Op))
      if (sortOf(Var) == Sort::BasicBlock &&
          !Var.getVarName().starts_with("_") && !IsUsed(Var))
        return Lex.ParseError(locOf(Var), "block '?" + Var.getVarName() +
                                              "' has no instruction, and no "
                                              "instruction refers to it");
  assert(!Library && "a library has definitions only, no pattern of its own");
  return false;
}

bool Parser::requireBooleanConstraint(Value C) {
  Sort Type = sortOf(C);
  if (Type == Sort::Boolean || Type == Sort::Unknown)
    return false;
  return Lex.ParseError(locOf(C), "constraint must have a boolean result");
}

void Parser::setDefaultContext(Value C, Value Anchor) {
  Operation *Def = C.getDefiningOp();
  if (!Def || !isa<mpir_expr::ExprDialect>(Def->getDialect()))
    return;
  if (auto Call = dyn_cast<mpir_expr::CallOp>(Def))
    if (!Call.getAnchor() && Anchor)
      Call.getAnchorMutable().assign(Anchor);
  if (isa<mpir_expr::ReadOp>(Def))
    return;
  for (Value Operand : Def->getOperands())
    if (Operand != Anchor)
      setDefaultContext(Operand, Anchor);
}

bool Parser::parseBodyLine(tok::Kind Terminator) {
  if (consume(tok::ConstraintMarker)) {
    LocTy Loc = Lex.getLoc();
    if (std::optional<PatternSettings::Setting> Setting =
            tok::getPatternSetting(Lex.getKind())) {
      if (parsePatternSetting(*Setting))
        return true;
      return expectEndOfLine(Terminator,
                             "unexpected token after pattern setting");
    }
    Value C;
    if (parseConstraint(C) || requireBooleanConstraint(C))
      return true;
    // A value-tracking operator defaults to the instruction the constraint
    // follows.
    Value Anchor = BodyInstructions.empty()
                       ? Value()
                       : BodyInstructions.back()->getResult(0);
    setDefaultContext(C, Anchor);
    RequireOp::create(Builder, loc(Loc, Lex.getPrevTokEnd()), C);
    return expectEndOfLine(Terminator, "unexpected token after constraint");
  }
  if (Lex.getKind() == tok::LabelStr || Lex.getKind() == tok::LabelID ||
      Lex.getKind() == tok::MetaVar) {
    if (parseBlockLabel())
      return true;
    return expectEndOfLine(Terminator,
                           "unexpected token after basic block label");
  }
  if (!BodyInstructions.empty()) {
    Operation *Last = BodyInstructions.back();
    auto Inst = dyn_cast<InstOp>(Last);
    auto Use = dyn_cast<UseOp>(Last);
    Value Parent = Inst ? Inst.getParentBlock() : Use.getParentBlock();
    std::optional<StringRef> Name =
        Inst ? Inst.getResultName() : Use.getResultName();
    if (Parent == CurrentBlock && !Name)
      return error("only the final instruction may omit a result assignment");
  }
  Value I;
  if (parseInstruction(I))
    return true;
  BodyInstructions.push_back(I.getDefiningOp());
  return expectEndOfLine(Terminator, "unexpected token after instruction");
}

//===----------------------------------------------------------------------===//
// Instructions
//===----------------------------------------------------------------------===//

bool Parser::parseInstructionCapture(Value &Capture) {
  Capture = Value();
  if (Lex.getKind() != tok::MetaCaptureVar)
    return false;
  Capture = getMeta(Lex.getStrVal(), Sort::Instruction, Lex.getLoc());
  if (!Capture)
    return true;
  next();
  return false;
}

bool Parser::parseInstructionMetaFlags(SmallVectorImpl<PMetaFlag> &Result,
                                       bool IsCommutative,
                                       StringRef OwnerName) {
  if (parseMetaFlags(Result, metaflag::InstructionPlacement))
    return true;
  for (const PMetaFlag &F : Result)
    if (F.getID() == metaflag::MF_c && !IsCommutative)
      return Lex.ParseError(F.Loc, "commutative matching is not valid for '" +
                                       OwnerName + "'");
  return false;
}

bool Parser::parseSemanticFlags(
    function_ref<bool(instruction_flag::FlagID)> IsSupported,
    StringRef OwnerName, SmallVectorImpl<PFlag> &Result) {
  while (true) {
    LocTy Loc = Lex.getLoc();
    bool Negated = consume(tok::exclaim);
    std::optional<instruction_flag::FlagID> Flag =
        tok::getSemanticFlag(Lex.getKind());
    if (!Flag) {
      if (Negated)
        return error("expected a flag after '!'");
      return false;
    }
    instruction_flag::FlagID FlagID = *Flag;
    StringRef FlagName = instruction_flag::getName(FlagID);
    if (!IsSupported(FlagID))
      return Lex.ParseError(Loc, "flag '" + FlagName + "' is not valid for '" +
                                     OwnerName + "'");
    if (any_of(Result, [FlagID](const PFlag &F) { return F.ID == FlagID; }))
      return Lex.ParseError(Loc, "flag '" + FlagName +
                                     "' is written more than once");
    next();
    Value Capture;
    if (Lex.getKind() == tok::MetaCaptureVar) {
      if (Negated)
        return error("a negated flag cannot be captured");
      StringRef CaptureName = Lex.getStrVal();
      if (CaptureName == "_")
        return error("flag '" + FlagName +
                     "' cannot be captured by '?_'; omit the flag, which "
                     "matches whether or not it is present");
      Capture = getMeta(CaptureName, Sort::Boolean, Lex.getLoc());
      if (!Capture)
        return true;
      next();
    }
    Result.push_back({FlagID,
                      Capture   ? FlagMode::Captured
                      : Negated ? FlagMode::Negated
                                : FlagMode::Required,
                      Capture});
  }
}

/// Parses one metaflag written in Position, the placement the flag it is
/// nested in allows. Its own placement is for the caller to check.
bool Parser::parseMetaFlag(PMetaFlag &Result, metaflag::Placement Position) {
  Nesting Nest(*this);
  if (Nest.tooDeep())
    return true;
  assert(Lex.getKind() == tok::MetaFlag && "expected a metaflag");
  LocTy Loc = Lex.getLoc();
  std::string Name = Lex.getStrVal();
  metaflag::MetaFlagID ID = metaflag::getMetaFlagID(Name);
  next();
  SmallVector<mlir::Attribute, 4> Args;
  unsigned NumFlagArgs = 0;
  SmallVector<PMetaFlag, 2> NestedFlags;
  if (consume(tok::lparen)) {
    if (Lex.getKind() != tok::rparen) {
      do {
        if (Lex.getKind() == tok::MetaFlag) {
          PMetaFlag NestedFlag;
          if (parseMetaFlag(NestedFlag, Position))
            return true;
          NestedFlags.push_back(NestedFlag);
          Args.push_back(NestedFlag.Attr);
          ++NumFlagArgs;
        } else if (Lex.getKind() == tok::APSInt) {
          if (!Lex.getAPSIntVal().isRepresentableByInt64())
            return error("metaflag integer argument is too large");
          Args.push_back(
              Builder.getI64IntegerAttr(Lex.getAPSIntVal().getExtValue()));
          next();
        } else {
          return error("expected integer or nested metaflag argument");
        }
      } while (consume(tok::comma));
    }
    if (expect(tok::rparen, "expected ')' after metaflag arguments"))
      return true;
  }
  metaflag::Placement Allowed;
  bool Nestable = true;
  if (std::optional<metaflag::Schema> Schema = metaflag::getSchema(ID)) {
    Allowed = Schema->AllowedPlacement;
    Nestable = Schema->Nestable;
    if (Args.size() < Schema->MinArguments ||
        Args.size() > Schema->MaxArguments)
      return Lex.ParseError(
          Loc, "invalid number of arguments for metaflag ':" + Name + "'");
    if (Schema->Arguments == metaflag::IntegerArgument && NumFlagArgs)
      return Lex.ParseError(Loc, "metaflag ':" + Name +
                                     "' expects integer arguments");
    if (Schema->Arguments == metaflag::FlagArgument &&
        NumFlagArgs != Args.size())
      return Lex.ParseError(Loc, "metaflag ':" + Name +
                                     "' expects nested metaflags");
  } else if (auto Def = lookup<MetaFlagDefOp>(Name)) {
    Allowed = metaflag::Placement(Def.getPlacement());
    unsigned NumArguments = Def.getParamNames().size() - 1;
    if (Args.size() != NumArguments)
      return Lex.ParseError(Loc, "metaflag ':" + Name + "' expects " +
                                     pluralize(NumArguments, "argument") +
                                     ", got " + Twine(Args.size()));
  } else {
    return Lex.ParseError(Loc, "unknown metaflag ':" + Name + "'");
  }
  // A nested metaflag is written where the flag holding it is.
  for (const PMetaFlag &N : NestedFlags) {
    if (!N.Nestable)
      return Lex.ParseError(N.Loc,
                            "metaflag ':" + N.getName() + "' cannot be nested");
    if (!(N.Allowed & Position))
      return Lex.ParseError(N.Loc, "metaflag ':" + N.getName() +
                                       "' is not valid in this position");
  }
  Result.Allowed = Allowed;
  Result.Nestable = Nestable;
  Result.Attr = MetaFlagAttr::get(Context, Builder.getStringAttr(Name),
                                  Builder.getArrayAttr(Args), loc(Loc));
  Result.Loc = Loc;
  return false;
}

bool Parser::parseMetaFlags(SmallVectorImpl<PMetaFlag> &Result,
                            metaflag::Placement Position) {
  while (Lex.getKind() == tok::MetaFlag) {
    PMetaFlag F;
    if (parseMetaFlag(F, Position))
      return true;
    if (!(F.Allowed & Position))
      return Lex.ParseError(F.Loc, "metaflag ':" + F.getName() +
                                       "' is not valid in this position");
    Result.push_back(F);
  }
  return false;
}

bool Parser::parseInstructionResult(SmallVectorImpl<char> &Name) {
  if (Lex.getKind() != tok::LocalVar && Lex.getKind() != tok::LocalVarID)
    return false;
  if (Lex.getKind() == tok::LocalVar)
    Name.append(Lex.getStrVal().begin(), Lex.getStrVal().end());
  else
    Twine(Lex.getUIntVal()).toVector(Name);
  StringRef ResultName(Name.data(), Name.size());
  if (Instructions.count(ResultName))
    return error("duplicate instruction result '%" + ResultName + "'");
  next();
  return expect(tok::equal, "expected '=' after instruction result");
}

Operation *Parser::buildMatcherUse(StringRef OpName,
                                   mlir::NamedAttribute Matcher,
                                   StringRef ResultName, ArrayRef<PFlag> Flags,
                                   ArrayRef<PMetaFlag> MFlags,
                                   ArrayRef<POperand> Ops, Value Capture,
                                   SMLoc Begin) {
  mlir::OperationState State(loc(Begin, Lex.getPrevTokEnd()), OpName);
  State.addAttribute(Matcher.getName(), Matcher.getValue());
  if (!ResultName.empty())
    State.addAttribute("result_name", Builder.getStringAttr(ResultName));
  SmallVector<int32_t, 4> FlagIDs, Modes;
  SmallVector<Value, 2> FlagCaptures;
  for (const PFlag &F : Flags) {
    FlagIDs.push_back(F.ID);
    Modes.push_back(int32_t(F.Mode));
    if (F.Capture)
      FlagCaptures.push_back(F.Capture);
  }
  State.addAttribute("flags", Builder.getDenseI32ArrayAttr(FlagIDs));
  State.addAttribute("flag_modes", Builder.getDenseI32ArrayAttr(Modes));
  SmallVector<int32_t, 8> Kinds;
  SmallVector<Value, 8> Values;
  SmallVector<mlir::Attribute, 8> OperandFlags;
  bool AnyOperandFlags = false;
  for (const POperand &Op : Ops) {
    Kinds.push_back(int32_t(Op.Kind));
    switch (Op.Kind) {
    case OperandKind::TypedValue:
    case OperandKind::TypedValueArray:
      Values.push_back(Op.Ty);
      Values.push_back(Op.Val);
      break;
    case OperandKind::TypeOnly:
      Values.push_back(Op.Ty);
      break;
    default:
      Values.push_back(Op.Val);
      break;
    }
    OperandFlags.push_back(Builder.getArrayAttr(Op.MetaFlags));
    AnyOperandFlags |= !Op.MetaFlags.empty();
  }
  State.addAttribute("operand_kinds", Builder.getDenseI32ArrayAttr(Kinds));
  if (!MFlags.empty()) {
    SmallVector<mlir::Attribute, 4> Attrs;
    for (const PMetaFlag &F : MFlags)
      Attrs.push_back(F.Attr);
    State.addAttribute("metaflags", Builder.getArrayAttr(Attrs));
  }
  if (AnyOperandFlags)
    State.addAttribute("operand_metaflags", Builder.getArrayAttr(OperandFlags));
  if (Settings.isSpecified(pattern_setting::treatIntAsVec))
    State.addAttribute(
        "treat_int_as_vec",
        Builder.getBoolAttr(Settings.has(pattern_setting::treatIntAsVec)));
  if (Capture)
    State.addOperands(Capture);
  if (CurrentBlock)
    State.addOperands(CurrentBlock);
  State.addOperands(FlagCaptures);
  State.addOperands(Values);
  State.addAttribute(
      "operandSegmentSizes",
      Builder.getDenseI32ArrayAttr({Capture ? 1 : 0, CurrentBlock ? 1 : 0,
                                    int32_t(FlagCaptures.size()),
                                    int32_t(Values.size())}));
  State.addTypes(sortType(Sort::Instruction));
  return Builder.create(State);
}

bool Parser::parseInstruction(Value &Result) {
  LocTy Loc = Lex.getLoc();
  SmallString<16> ResultNameStorage;
  if (parseInstructionResult(ResultNameStorage))
    return true;
  StringRef ResultName = ResultNameStorage;
  if (!tok::getInstruction(Lex.getKind())) {
    if (Lex.getKind() == tok::Identifier) {
      std::string OpName = Lex.getStrVal();
      if (auto CM = lookup<MatcherOp>(OpName))
        return parseCompositeInstruction(Result, CM, OpName, ResultName, Loc);
    }
    return error("expected instruction matcher");
  }
  instruction::InstructionID ID = *tok::getInstruction(Lex.getKind());
  StringRef Op = instruction::getOpcodeName(ID);
  next();
  Value Capture;
  SmallVector<PMetaFlag, 4> MFlags;
  SmallVector<PFlag, 8> Flags;
  if (parseInstructionCapture(Capture) ||
      parseInstructionMetaFlags(MFlags, instruction::isCommutative(ID), Op) ||
      parseSemanticFlags(
          [ID](instruction_flag::FlagID F) {
            return (instruction::getSupportedFlags(ID) &
                    instruction::mask(F)) != 0;
          },
          Op, Flags))
    return true;
  SmallVector<POperand, 8> Ops;
  instruction::OperandSyntax Syntax = instruction::getOperandSyntax(ID);
  if (Syntax == instruction::OperandSyntax::Custom
          ? parseCustomOperands(ID, Ops)
          : parseArchetypeOperands(Syntax, instruction::getOperandArity(ID), Op,
                                   Ops))
    return true;
  if (validateInstruction(ID, MFlags, Ops))
    return true;
  Operation *I = buildMatcherUse(
      InstOp::getOperationName(),
      Builder.getNamedAttr("opcode", OpcodeAttr::get(Context, ID)), ResultName,
      Flags, MFlags, Ops, Capture, Loc);
  Result = I->getResult(0);
  if (!ResultName.empty()) {
    auto It = MetaVariables.find(ResultName);
    if (It != MetaVariables.end()) {
      Value SameName = It->second;
      bool IsThisCapture =
          SameName == Capture ||
          any_of(Flags, [&](const PFlag &F) { return F.Capture == SameName; });
      if (!IsThisCapture)
        Lex.Warning(Loc, "local variable '%" + ResultName +
                             "' shares a name with meta variable '?" +
                             ResultName + "'");
    }
    Instructions[ResultName] = Result;
  }
  return false;
}

bool Parser::parseCompositeInstruction(Value &Result, MatcherOp CM,
                                       StringRef OpName, StringRef ResultName,
                                       LocTy Loc) {
  next();
  Value Capture;
  if (parseInstructionCapture(Capture))
    return true;
  SmallVector<PMetaFlag, 4> MFlags;
  if (parseInstructionMetaFlags(MFlags, CM.getCommutative(), OpName))
    return true;
  SmallVector<PFlag, 8> Flags;
  ArrayRef<int32_t> Supported = CM.getSupportedFlags();
  if (parseSemanticFlags(
          [Supported](instruction_flag::FlagID F) {
            return is_contained(Supported, int32_t(F));
          },
          OpName, Flags))
    return true;
  SmallVector<POperand, 8> Ops;
  // A 'match' is declared with one of the shared archetypes.
  auto Syntax = instruction::OperandSyntax(CM.getSyntax());
  if (parseArchetypeOperands(Syntax, CM.getArity(), OpName, Ops) ||
      validateOrSelf(MFlags, Ops))
    return true;
  Operation *I = buildMatcherUse(
      UseOp::getOperationName(),
      Builder.getNamedAttr("matcher",
                           mlir::FlatSymbolRefAttr::get(Context, OpName)),
      ResultName, Flags, MFlags, Ops, Capture, Loc);
  Result = I->getResult(0);
  if (!ResultName.empty())
    Instructions[ResultName] = Result;
  return false;
}

bool Parser::validateOrSelf(ArrayRef<PMetaFlag> MFlags,
                            ArrayRef<POperand> Ops) {
  for (const PMetaFlag &F : MFlags) {
    if (F.getID() != metaflag::MF_o)
      continue;
    uint64_t Index = 0;
    ArrayRef<mlir::Attribute> Args = F.Attr.getArgs().getValue();
    if (!Args.empty()) {
      auto Arg = dyn_cast<mlir::IntegerAttr>(Args.front());
      if (Args.size() != 1 || !Arg || Arg.getInt() < 0)
        return Lex.ParseError(
            F.Loc, "metaflag ':o' expects one non-negative operand index");
      Index = Arg.getInt();
    }
    uint64_t OperandCount = count_if(Ops, [](const POperand &O) {
      return O.isValueOperand() && !O.isArray();
    });
    bool HasArray = any_of(Ops, [](const POperand &O) { return O.isArray(); });
    if (!HasArray && Index >= OperandCount)
      return Lex.ParseError(F.Loc,
                            "metaflag ':o' operand index is out of range");
  }
  return false;
}

bool Parser::validateInstruction(instruction::InstructionID ID,
                                 ArrayRef<PMetaFlag> MFlags,
                                 ArrayRef<POperand> Ops) {
  if (validateOrSelf(MFlags, Ops))
    return true;
  for (const PMetaFlag &F : MFlags) {
    if (F.getID() == metaflag::MF_c && ID == instruction::I_call) {
      unsigned ArgumentCount = Ops.size() >= 2 ? Ops.size() - 2 : 0;
      bool HasArray =
          any_of(Ops, [](const POperand &O) { return O.isArray(); });
      if (ArgumentCount != 2 || HasArray)
        return Lex.ParseError(
            F.Loc, "metaflag ':c' requires a call with exactly two arguments");
    }
  }
  SmallVector<bool, 16> Seen(16, false);
  for (const POperand &Operand : Ops) {
    if (!isKeyedOperand(Operand.Kind))
      continue;
    if (Seen[unsigned(Operand.Kind)])
      return Lex.ParseError(Operand.ValLoc, "duplicate keyed operand");
    Seen[unsigned(Operand.Kind)] = true;
  }
  return false;
}

//===----------------------------------------------------------------------===//
// Operands
//===----------------------------------------------------------------------===//

/// The integer width a type pattern fixes, if it is 'iN'.
static std::optional<unsigned> integerWidth(Value Ty) {
  if (auto Int = Ty.getDefiningOp<IntTypeOp>())
    if (!Int.getByte())
      return Int.getWidth();
  return std::nullopt;
}

/// Whether a type pattern is the primitive type ID.
static bool isPrimitive(Value Ty, primitive_type::TypeID ID) {
  if (auto Prim = Ty.getDefiningOp<PrimTypeOp>())
    return Prim.getKind() == unsigned(ID);
  return false;
}

bool Parser::parseTypedOperand(POperand &Result, Sort Expected) {
  if (parseType(Result.Ty))
    return true;
  Result.Kind = OperandKind::TypedValue;
  if (Expected == Sort::Operand) {
    if (integerWidth(Result.Ty) == 1u)
      Expected = Sort::Boolean;
    else if (isPrimitive(Result.Ty, primitive_type::LabelTyID))
      Expected = Sort::BasicBlock;
  }
  Result.ValLoc = Lex.getLoc();
  if (parseValue(Result.Val, Expected))
    return true;
  return parseOperandMetaFlags(Result);
}

bool Parser::parseOperandMetaFlags(POperand &Result) {
  SmallVector<PMetaFlag, 4> Flags;
  if (parseMetaFlags(Flags, metaflag::OperandPlacement))
    return true;
  if (Flags.empty())
    return false;
  for (const PMetaFlag &F : Flags)
    Result.MetaFlags.push_back(F.Attr);
  // A defined metaflag constrains the operand's value: a meta variable's, or
  // a local's. A constant's is known.
  bool IsVariable = Result.Val && (Result.Val.getDefiningOp<VarOp>() ||
                                   isa<mlir::BlockArgument>(Result.Val) ||
                                   Result.Val.getDefiningOp<InstOp>() ||
                                   Result.Val.getDefiningOp<UseOp>());
  if (!IsVariable)
    for (const PMetaFlag &F : Flags)
      if (lookup<MetaFlagDefOp>(F.getName()))
        return error("metaflag ':" + F.getName() +
                     "' can only be applied to a meta variable or a local "
                     "value");
  return false;
}

bool Parser::parseArrayCapture(POperand &Result, bool WithTypes) {
  assert(Lex.getKind() == tok::dotdotdot && "expected a '...' capture");
  next();
  Result.Kind =
      WithTypes ? OperandKind::TypedValueArray : OperandKind::ValueArray;
  if (WithTypes) {
    if (Lex.getKind() != tok::MetaVar)
      return error("expected type-array meta variable");
    Result.Ty = getMeta(Lex.getStrVal(), Sort::TypeArray, Lex.getLoc());
    if (!Result.Ty)
      return true;
    next();
  }
  if (Lex.getKind() != tok::MetaVar)
    return error("expected value-array meta variable");
  Result.ValLoc = Lex.getLoc();
  Result.Val = getMeta(Lex.getStrVal(), Sort::ValueArray, Lex.getLoc());
  if (!Result.Val)
    return true;
  next();
  return false;
}

bool Parser::parseArchetypeOperands(instruction::OperandSyntax Syntax,
                                    unsigned Arity, StringRef OpName,
                                    SmallVectorImpl<POperand> &Ops) {
  auto Typed = [&]() -> bool {
    POperand O;
    if (parseTypedOperand(O))
      return true;
    Ops.push_back(O);
    return false;
  };
  auto Comma = [&]() -> bool {
    return expect(tok::comma, "expected ',' between operands");
  };
  switch (Syntax) {
  case instruction::OperandSyntax::Nary:
    for (unsigned I = 0; I < Arity; ++I)
      if ((I && Comma()) || Typed())
        return true;
    if (Lex.getKind() == tok::comma)
      return error("'" + OpName + "' takes " + pluralize(Arity, "operand"));
    return false;
  case instruction::OperandSyntax::Binary: {
    POperand A;
    if (parseTypedOperand(A))
      return true;
    Ops.push_back(A);
    if (Comma())
      return true;
    POperand B;
    B.Ty = A.Ty;
    B.ValLoc = Lex.getLoc();
    if (parseValue(B.Val) || parseOperandMetaFlags(B))
      return true;
    Ops.push_back(B);
    return false;
  }
  case instruction::OperandSyntax::Cast: {
    if (Typed())
      return true;
    if (Lex.getKind() != tok::kw_to)
      return error("expected 'to' in conversion");
    next();
    POperand Dst;
    Dst.Kind = OperandKind::TypeOnly;
    if (parseType(Dst.Ty, true))
      return true;
    Ops.push_back(Dst);
    return false;
  }
  case instruction::OperandSyntax::Custom:
    llvm_unreachable("custom operand syntax is not a shared archetype");
  }
  llvm_unreachable("invalid operand syntax");
}

bool Parser::parseOperand(SmallVectorImpl<POperand> &Ops, Sort Expected) {
  POperand O;
  if (parseTypedOperand(O, Expected))
    return true;
  Ops.push_back(O);
  return false;
}

bool Parser::parseTypeOperand(SmallVectorImpl<POperand> &Ops) {
  POperand O;
  O.Kind = OperandKind::TypeOnly;
  if (parseType(O.Ty, /*AllowVoid=*/true))
    return true;
  Ops.push_back(O);
  return false;
}

bool Parser::parseKeyedOperand(SmallVectorImpl<POperand> &Ops, OperandKind Key,
                               Sort Expected) {
  POperand O;
  O.Kind = Key;
  O.ValLoc = Lex.getLoc();
  if (parseValue(O.Val, Expected))
    return true;
  Ops.push_back(O);
  return false;
}

bool Parser::parseAlign(SmallVectorImpl<POperand> &Ops) {
  if (!consume(tok::comma))
    return false;
  if (!consume(tok::kw_align))
    return error("expected 'align'");
  return parseKeyedOperand(Ops, OperandKind::Alignment, Sort::Nat);
}

bool Parser::parseTrailingOperands(SmallVectorImpl<POperand> &Ops,
                                   TrailingOperandKind Kind) {
  while (consume(tok::comma)) {
    POperand O;
    if (Lex.getKind() == tok::dotdotdot) {
      if (parseArrayCapture(O, /*WithTypes=*/Kind != NatIndices))
        return true;
      Ops.push_back(O);
      return false;
    }
    if (Kind == NatIndices) {
      O.Kind = OperandKind::Value;
      O.ValLoc = Lex.getLoc();
      if (parseValue(O.Val, Sort::Nat))
        return true;
    } else if (parseTypedOperand(O)) {
      return true;
    }
    Ops.push_back(O);
  }
  return false;
}

bool Parser::parseCustomOperands(instruction::InstructionID ID,
                                 SmallVectorImpl<POperand> &Ops) {
  switch (ID) {
  case instruction::I_extractelement:
    return parseOperand(Ops) || parseOperandComma() ||
           parseOperand(Ops, Sort::Nat);
  case instruction::I_extractvalue:
    return parseOperand(Ops) || parseTrailingOperands(Ops, NatIndices);
  case instruction::I_insertvalue:
    return parseOperand(Ops) || parseOperandComma() || parseOperand(Ops) ||
           parseTrailingOperands(Ops, NatIndices);
  case instruction::I_alloca:
    return parseAllocaOperands(Ops);
  case instruction::I_load:
    return parseTypeOperand(Ops) || parseOperandComma() || parseOperand(Ops) ||
           parseAlign(Ops);
  case instruction::I_store:
    return parseOperand(Ops) || parseOperandComma() || parseOperand(Ops) ||
           parseAlign(Ops);
  case instruction::I_getelementptr:
    return parseGEPOperands(Ops);
  case instruction::I_ret: {
    POperand O;
    if (parseType(O.Ty, /*AllowVoid=*/true))
      return true;
    if (isPrimitive(O.Ty, primitive_type::VoidTyID)) {
      O.Kind = OperandKind::TypeOnly;
    } else {
      O.Kind = OperandKind::TypedValue;
      O.ValLoc = Lex.getLoc();
      if (parseValue(O.Val))
        return true;
    }
    Ops.push_back(O);
    return false;
  }
  case instruction::I_br:
    return parseBranchOperands(Ops);
  case instruction::I_icmp:
  case instruction::I_fcmp:
    return parseCompareOperands(Ops);
  case instruction::I_phi:
    return parsePhiOperands(Ops);
  case instruction::I_call:
    return parseCallOperands(Ops);
  default:
    llvm_unreachable("a matcher of custom syntax has no parser");
  }
}

bool Parser::parseAllocaOperands(SmallVectorImpl<POperand> &Ops) {
  if (parseTypeOperand(Ops))
    return true;
  while (consume(tok::comma)) {
    if (consume(tok::kw_align)) {
      if (parseKeyedOperand(Ops, OperandKind::Alignment, Sort::Nat))
        return true;
    } else if (consume(tok::kw_addrspace)) {
      if (expect(tok::lparen, "expected '(' after 'addrspace'") ||
          parseKeyedOperand(Ops, OperandKind::AddressSpace, Sort::Nat) ||
          expect(tok::rparen, "expected ')' after 'addrspace'"))
        return true;
    } else if (parseOperand(Ops, Sort::Nat)) {
      return true;
    }
  }
  return false;
}

bool Parser::parseGEPOperands(SmallVectorImpl<POperand> &Ops) {
  if (consume(tok::kw_inrange)) {
    if (expect(tok::lparen, "expected '(' after 'inrange'") ||
        parseKeyedOperand(Ops, OperandKind::InRangeLower, Sort::Nat) ||
        parseOperandComma() ||
        parseKeyedOperand(Ops, OperandKind::InRangeUpper, Sort::Nat) ||
        expect(tok::rparen, "expected ')' after 'inrange'"))
      return true;
  }
  return parseTypeOperand(Ops) || parseOperandComma() || parseOperand(Ops) ||
         parseTrailingOperands(Ops, TypedOperands);
}

bool Parser::parseBranchOperands(SmallVectorImpl<POperand> &Ops) {
  POperand First;
  if (parseType(First.Ty))
    return true;
  bool IsLabel = isPrimitive(First.Ty, primitive_type::LabelTyID);
  bool IsBool = integerWidth(First.Ty) == 1u;
  First.ValLoc = Lex.getLoc();
  if (parseValue(First.Val, IsLabel  ? Sort::BasicBlock
                            : IsBool ? Sort::Boolean
                                     : Sort::Operand))
    return true;
  Ops.push_back(First);
  if (IsLabel)
    return false;
  return parseOperandComma() || parseOperand(Ops, Sort::BasicBlock) ||
         parseOperandComma() || parseOperand(Ops, Sort::BasicBlock);
}

bool Parser::parseCompareOperands(SmallVectorImpl<POperand> &Ops) {
  POperand Pred;
  Pred.Kind = OperandKind::Predicate;
  Pred.ValLoc = Lex.getLoc();
  if (Lex.getKind() == tok::MetaVar) {
    Pred.Val = getMeta(Lex.getStrVal(), Sort::CmpPredicate, Lex.getLoc());
    if (!Pred.Val)
      return true;
  } else if (std::optional<keyword_constant::KeywordID> Predicate =
                 tok::getPredicateKeyword(Lex.getKind())) {
    Pred.Val = KeywordOp::create(Builder, loc(Lex.getLoc()),
                                 sortType(Sort::Value), *Predicate);
  } else {
    return error("expected comparison predicate");
  }
  next();
  Ops.push_back(Pred);
  return parseArchetypeOperands(instruction::OperandSyntax::Binary, 2, "", Ops);
}

bool Parser::parsePhiOperands(SmallVectorImpl<POperand> &Ops) {
  Value Ty;
  if (parseType(Ty))
    return true;
  do {
    POperand Incoming, Block;
    Incoming.Ty = Ty;
    Block.Kind = OperandKind::Value;
    if (expect(tok::lsquare, "expected '[' in phi"))
      return true;
    Incoming.ValLoc = Lex.getLoc();
    if (parseValue(Incoming.Val) || parseOperandComma())
      return true;
    Block.ValLoc = Lex.getLoc();
    if (parseValue(Block.Val, Sort::BasicBlock) ||
        expect(tok::rsquare, "expected ']' in phi"))
      return true;
    Ops.push_back(Incoming);
    Ops.push_back(Block);
  } while (consume(tok::comma));
  return false;
}

bool Parser::parseCallOperands(SmallVectorImpl<POperand> &Ops) {
  POperand Callee;
  Callee.Kind = OperandKind::Value;
  if (parseTypeOperand(Ops))
    return true;
  Callee.ValLoc = Lex.getLoc();
  if (parseValue(Callee.Val, Sort::Function))
    return true;
  Ops.push_back(Callee);
  if (expect(tok::lparen, "expected '(' in call"))
    return true;
  if (Lex.getKind() != tok::rparen) {
    if (Lex.getKind() == tok::dotdotdot) {
      POperand Array;
      if (parseArrayCapture(Array, /*WithTypes=*/true))
        return true;
      Ops.push_back(Array);
    } else if (parseOperand(Ops) || parseTrailingOperands(Ops, TypedOperands)) {
      return true;
    }
  }
  return expect(tok::rparen, "expected ')' after call arguments");
}

//===----------------------------------------------------------------------===//
// Types and values
//===----------------------------------------------------------------------===//

bool Parser::parseType(Value &Result, bool AllowVoid) {
  Nesting Nest(*this);
  if (Nest.tooDeep())
    return true;
  LocTy Loc = Lex.getLoc();
  return parseBaseType(Result, AllowVoid) || parseTypeSuffixes(Result, Loc);
}

bool Parser::parseBaseType(Value &Result, bool AllowVoid) {
  LocTy Loc = Lex.getLoc();
  auto TypeSort = sortType(Sort::Type);
  switch (Lex.getKind()) {
  case tok::Type: {
    IntTypeToken T = Lex.getTyVal();
    auto Op = IntTypeOp::create(Builder, loc(Loc), TypeSort, T.Bits);
    if (T.Byte)
      Op.setByte(true);
    Result = Op;
    next();
    return false;
  }
  case tok::MetaIntVar: {
    Value Width = getMeta(Lex.getStrVal(), Sort::Nat, Loc);
    if (!Width)
      return true;
    auto Op = MetaIntTypeOp::create(Builder, loc(Loc), TypeSort, Width);
    if (Lex.getMetaIntPrefix() == 'b')
      Op.setByte(true);
    Result = Op;
    next();
    return false;
  }
  case tok::MetaVar: {
    Result = getMeta(Lex.getStrVal(), Sort::Type, Loc);
    if (!Result)
      return true;
    next();
    return false;
  }
  case tok::kw_ptr:
    return parsePointerType(Result);
  case tok::lsquare:
    next();
    return parseSequenceType(Result, /*IsVector=*/false, Loc);
  case tok::lbrace:
    next();
    return parseStructType(Result, /*Packed=*/false, Loc);
  case tok::less:
    next();
    if (consume(tok::lbrace))
      return parseStructType(Result, /*Packed=*/true, Loc);
    return parseSequenceType(Result, /*IsVector=*/true, Loc);
  default:
    break;
  }
  std::optional<primitive_type::TypeID> ID =
      tok::getPrimitiveType(Lex.getKind());
  if (!ID)
    return error("expected type");
  if (*ID == primitive_type::VoidTyID && !AllowVoid)
    return error("void type is not allowed here");
  Result = PrimTypeOp::create(Builder, loc(Loc), TypeSort, unsigned(*ID));
  next();
  return false;
}

bool Parser::parsePointerType(Value &Result) {
  LocTy Loc = Lex.getLoc();
  next();
  std::optional<unsigned> AddressSpace;
  if (consume(tok::kw_addrspace)) {
    if (expect(tok::lparen, "expected '(' after 'addrspace'"))
      return true;
    if (Lex.getKind() != tok::APSInt || Lex.getAPSIntVal().isNegative() ||
        !Lex.getAPSIntVal().isIntN(24))
      return error("expected an address space number");
    AddressSpace = Lex.getAPSIntVal().getZExtValue();
    next();
    if (expect(tok::rparen, "expected ')' after address space"))
      return true;
  }
  auto Op = PtrTypeOp::create(Builder, loc(Loc), sortType(Sort::Type), Value(),
                              mlir::IntegerAttr());
  if (AddressSpace)
    Op.setAddressSpace(*AddressSpace);
  Result = Op;
  return false;
}

bool Parser::parseSequenceType(Value &Result, bool IsVector, LocTy Loc) {
  StringRef What = IsVector ? "vector" : "array";
  bool Scalable = false;
  if (IsVector && consume(tok::kw_vscale)) {
    Scalable = true;
    if (!consume(tok::kw_x))
      return error("expected 'x' after vscale");
  }
  uint64_t Count = 0;
  Value CountVar;
  if (Lex.getKind() == tok::APSInt) {
    if (Lex.getAPSIntVal().isNegative() ||
        Lex.getAPSIntVal().getActiveBits() > 64)
      return error("invalid " + What + " size");
    Count = Lex.getAPSIntVal().getZExtValue();
  } else if (Lex.getKind() == tok::MetaVar) {
    CountVar = getMeta(Lex.getStrVal(), Sort::Nat, Lex.getLoc());
    if (!CountVar)
      return true;
  } else {
    return error("expected " + What + " size (got " + describeToken() + ")");
  }
  next();
  if (!consume(tok::kw_x))
    return error("expected 'x' after " + What + " size");
  Value Element;
  if (parseType(Element) || expect(IsVector ? tok::greater : tok::rsquare,
                                   "expected '" + Twine(IsVector ? '>' : ']') +
                                       "' after " + What + " type"))
    return true;
  Result = SeqTypeOp::create(Builder, loc(Loc), sortType(Sort::Type),
                             IsVector ? (Scalable ? 2 : 1) : 0, Count, Element,
                             CountVar);
  return false;
}

bool Parser::parseStructType(Value &Result, bool Packed, LocTy Loc) {
  SmallVector<Value, 8> Elements;
  if (parseCommaList(tok::rbrace,
                     [&] { return parseType(Elements.emplace_back()); }))
    return true;
  if (Packed) {
    if (expect(tok::rbrace, "expected '}' after packed struct") ||
        expect(tok::greater, "expected '>' after packed struct"))
      return true;
  } else if (expect(tok::rbrace, "expected '}' after struct type")) {
    return true;
  }
  auto Op =
      StructTypeOp::create(Builder, loc(Loc), sortType(Sort::Type), Elements);
  if (Packed)
    Op.setPacked(true);
  Result = Op;
  return false;
}

bool Parser::parseTypeSuffixes(Value &Result, LocTy Loc) {
  while (true) {
    if (consume(tok::star)) {
      Result = PtrTypeOp::create(Builder, loc(Loc), sortType(Sort::Type),
                                 Result, mlir::IntegerAttr());
      continue;
    }
    if (!consume(tok::lparen))
      return false;
    SmallVector<Value, 8> Parameters;
    bool VarArg = false;
    if (Lex.getKind() != tok::rparen) {
      do {
        if (consume(tok::dotdotdot)) {
          VarArg = true;
          break;
        }
        if (parseType(Parameters.emplace_back()))
          return true;
      } while (consume(tok::comma));
    }
    if (expect(tok::rparen, "expected ')' after function type"))
      return true;
    auto Op = FuncTypeOp::create(Builder, loc(Loc), sortType(Sort::Type),
                                 Result, Parameters);
    if (VarArg)
      Op.setVarArg(true);
    Result = Op;
  }
}

Value Parser::makeInteger(const APSInt &Number, SMLoc Loc) {
  auto Type =
      mlir::IntegerType::get(Context, Number.getBitWidth(),
                             Number.isUnsigned() ? mlir::IntegerType::Unsigned
                                                 : mlir::IntegerType::Signed);
  return IntOp::create(Builder, loc(Loc), sortType(Sort::Value),
                       mlir::IntegerAttr::get(Type, Number));
}

bool Parser::parseValue(Value &Result, Sort Expected) {
  LocTy Loc = Lex.getLoc();
  switch (Lex.getKind()) {
  case tok::MetaVar: {
    Result = getMeta(Lex.getStrVal(), Expected, Loc);
    if (!Result)
      return true;
    next();
    return false;
  }
  case tok::LocalVar:
  case tok::LocalVarID: {
    SmallString<16> NameStorage;
    StringRef Name = Lex.getKind() == tok::LocalVar
                         ? StringRef(Lex.getStrVal())
                         : Twine(Lex.getUIntVal()).toStringRef(NameStorage);
    if (Expected == Sort::BasicBlock) {
      Result = getMeta(Name, Sort::BasicBlock, Loc);
      if (!Result)
        return true;
    } else {
      auto It = Instructions.find(Name);
      if (It == Instructions.end())
        return error("undefined or forward local reference '%" + Name + "'");
      Result = It->second;
    }
    next();
    return false;
  }
  case tok::IntrinsicPrefix: {
    next();
    if (Lex.getKind() != tok::MetaVar)
      return error("expected intrinsic ID meta variable");
    Result = getMeta(Lex.getStrVal(), Sort::IntrinsicID, Lex.getLoc());
    if (!Result)
      return true;
    next();
    return false;
  }
  case tok::GlobalVar:
  case tok::GlobalID: {
    SmallString<32> Name;
    if (Lex.getKind() == tok::GlobalVar)
      Name = Lex.getStrVal();
    else
      Twine(Lex.getUIntVal()).toVector(Name);
    next();
    Result = GlobalOp::create(Builder, loc(Loc), sortType(Sort::Value),
                              Builder.getStringAttr(Name));
    return false;
  }
  case tok::APSInt:
    Result = makeInteger(Lex.getAPSIntVal(), Loc);
    next();
    return false;
  case tok::APFloat:
    Result = FloatOp::create(
        Builder, loc(Loc), sortType(Sort::Value),
        Builder.getFloatAttr(Builder.getF64Type(), Lex.getAPFloatVal()));
    next();
    return false;
  case tok::kw_true:
  case tok::kw_false:
    Result = makeInteger(
        APSInt(APInt(1, Lex.getKind() == tok::kw_true), /*isUnsigned=*/true),
        Loc);
    next();
    return false;
  case tok::lsquare:
  case tok::lbrace:
  case tok::less:
    return parseAggregateConstant(Result);
  default:
    if (std::optional<keyword_constant::KeywordID> Constant =
            tok::getConstantKeyword(Lex.getKind())) {
      Result = KeywordOp::create(Builder, loc(Loc), sortType(Sort::Value),
                                 unsigned(*Constant));
      next();
      return false;
    }
    return error("expected value");
  }
}

bool Parser::parseAggregateConstant(Value &Result) {
  LocTy Loc = Lex.getLoc();
  tok::Kind Open = Lex.getKind();
  tok::Kind Close = Open == tok::lsquare  ? tok::rsquare
                    : Open == tok::lbrace ? tok::rbrace
                                          : tok::greater;
  aggregate_constant::Delimiter Delimiter =
      Open == tok::lsquare ? aggregate_constant::Square
      : Open == tok::less  ? aggregate_constant::Angle
                           : aggregate_constant::Brace;
  next();
  SmallVector<Value, 16> Elements;
  if (parseCommaList(Close,
                     [&] {
                       Value Ty, Val;
                       if (parseType(Ty) || parseValue(Val))
                         return true;
                       Elements.push_back(Ty);
                       Elements.push_back(Val);
                       return false;
                     }) ||
      expect(Close, "expected end of aggregate constant"))
    return true;
  Result = AggregateOp::create(Builder, loc(Loc), sortType(Sort::Value),
                               unsigned(Delimiter), Elements);
  return false;
}

//===----------------------------------------------------------------------===//
// Constraint expressions
//
// Loosest binding first:
//
//   expr     ::= expr '||' expr | expr '&&' expr
//              | expr ('==' | '!=') expr          (not chained)
//              | expr ('+' | '-') expr | expr '*' expr
//              | ('!' | '-') expr | postfix
//   postfix  ::= primary ('[' expr ']')*
//   primary  ::= integer | 'true' | 'false' | string | '[' expr, ... ']'
//              | ?var | '(' expr ')' | name '(' expr, ... ')'
//
// Operands are type-checked against the operator as they are parsed; a type
// that is only known once matched (Unknown) is accepted.
//===----------------------------------------------------------------------===//

namespace {
struct BinaryOperatorInfo {
  tok::Kind Token;
  StringRef Spelling;
  unsigned Precedence;
};
} // namespace

static constexpr unsigned ComparisonPrecedence = 3;

static const BinaryOperatorInfo BinaryOperators[] = {
    {tok::barbar, "||", 1},
    {tok::ampamp, "&&", 2},
    {tok::equalequal, "==", ComparisonPrecedence},
    {tok::notequal, "!=", ComparisonPrecedence},
    {tok::plus, "+", 4},
    {tok::minus, "-", 4},
    {tok::star, "*", 5},
};

static const BinaryOperatorInfo *findBinaryOperator(tok::Kind Kind) {
  for (const BinaryOperatorInfo &Info : BinaryOperators)
    if (Info.Token == Kind)
      return &Info;
  return nullptr;
}

static std::string describeArity(unsigned Min, unsigned Max) {
  if (Min == Max)
    return (Twine(Min) + " argument" + (Min == 1 ? "" : "s")).str();
  return (Twine(Min) + " to " + Twine(Max) + " arguments").str();
}

bool Parser::checkOperands(mpir_expr::CallOp Operator, StringRef Spelling) {
  mlir::OperandRange Arguments = Operator.getArgs();
  for (unsigned Index = 0; Index != Arguments.size(); ++Index) {
    Sort Expected =
        constraint::getArgumentType(Operator.getOperatorID(), Index);
    if (constraint::canCoerce(sortOf(Arguments[Index]), Expected))
      continue;
    std::string What =
        Operator.getKind() == unsigned(constraint::Call)
            ? ("argument " + Twine(Index + 1) + " of '" + Spelling + "'").str()
            : ("operand of '" + Spelling + "'").str();
    return Lex.ParseError(locOf(Arguments[Index]),
                          What + " must be " + constraint::describe(Expected));
  }
  return false;
}

bool Parser::makeOperator(Value &Result, constraint::OperatorKind Kind,
                          StringRef Spelling, ArrayRef<Value> Args, LocTy Loc) {
  constraint::OperatorID ID = constraint::getOperatorID(Spelling, Kind);
  assert(ID != constraint::UnknownOperator && "operator token without an ID");
  auto Operator = mpir_expr::CallOp::create(
      Builder, loc(Loc), sortType(constraint::getOperatorSchema(ID)->Result),
      unsigned(ID), unsigned(Kind), Args, Value());
  Result = Operator;
  return checkOperands(Operator, Spelling);
}

bool Parser::parseConstraint(Value &Result) {
  Nesting Nest(*this);
  if (Nest.tooDeep())
    return true;
  return parseConstraintBinary(Result, 1);
}

bool Parser::parseConstraintBinary(Value &Result, unsigned MinPrecedence) {
  if (parseConstraintUnary(Result))
    return true;
  while (const BinaryOperatorInfo *Op = findBinaryOperator(Lex.getKind())) {
    if (Op->Precedence < MinPrecedence)
      break;
    LocTy Loc = Lex.getLoc();
    next();
    Value Right;
    if (parseConstraintBinary(Right, Op->Precedence + 1))
      return true;
    Value Args[] = {Result, Right};
    if (makeOperator(Result, constraint::Binary, Op->Spelling, Args, Loc))
      return true;
    if (Op->Precedence == ComparisonPrecedence) {
      const BinaryOperatorInfo *Next = findBinaryOperator(Lex.getKind());
      if (Next && Next->Precedence == ComparisonPrecedence)
        return error("comparisons cannot be chained; add parentheses");
    }
  }
  if (Lex.getKind() == tok::less || Lex.getKind() == tok::greater ||
      Lex.getKind() == tok::lessequal || Lex.getKind() == tok::greaterequal)
    return error("use slt/ult/sle/ule/sgt/ugt/sge/uge for ordered comparisons");
  if (Lex.getKind() == tok::slash || Lex.getKind() == tok::percent)
    return error("use sdiv/udiv/srem/urem for signed or unsigned arithmetic");
  return false;
}

bool Parser::parseConstraintUnary(Value &Result) {
  Nesting Nest(*this);
  if (Nest.tooDeep())
    return true;
  if (Lex.getKind() != tok::exclaim && Lex.getKind() != tok::minus)
    return parseConstraintPostfix(Result);
  StringRef Spelling = Lex.getKind() == tok::exclaim ? "!" : "-";
  LocTy Loc = Lex.getLoc();
  next();
  Value Operand;
  if (parseConstraintUnary(Operand))
    return true;
  Value Args[] = {Operand};
  return makeOperator(Result, constraint::Unary, Spelling, Args, Loc);
}

bool Parser::parseConstraintPostfix(Value &Result) {
  if (parseConstraintPrimary(Result))
    return true;
  while (Lex.getKind() == tok::lsquare) {
    LocTy Loc = Lex.getLoc();
    next();
    Value Index;
    if (parseConstraint(Index) ||
        expect(tok::rsquare, "expected ']' after array index"))
      return true;
    Sort ElementType;
    switch (sortOf(Result)) {
    case Sort::TypeArray:
      ElementType = Sort::Type;
      break;
    case Sort::ValueArray:
      ElementType = Sort::Value;
      break;
    case Sort::StringArray:
      ElementType = Sort::String;
      break;
    default:
      return Lex.ParseError(Loc,
                            "constraint subscript requires an array operand");
    }
    if (sortOf(Index) != Sort::Integer)
      return Lex.ParseError(locOf(Index),
                            "constraint array index must be an integer");
    Result = mpir_expr::IndexOp::create(Builder, loc(Loc),
                                        sortType(ElementType), Result, Index);
  }
  return false;
}

bool Parser::parseConstraintArguments(SmallVectorImpl<Value> &Args) {
  if (Lex.getKind() != tok::rparen) {
    do {
      Value Argument;
      if (parseConstraint(Argument))
        return true;
      Args.push_back(Argument);
    } while (consume(tok::comma));
  }
  return expect(tok::rparen, "expected ')' after constraint arguments");
}

/// The sort of what a definition's body yields.
static Sort bodySort(mlir::Block &Body) {
  for (mlir::Operation &Op : llvm::reverse(Body))
    if (auto Yield = dyn_cast<YieldOp>(Op))
      return sortOf(Yield.getValue());
  llvm_unreachable("a definition's body yields its result");
}

bool Parser::parseConstraintCall(Value &Result) {
  LocTy Loc = Lex.getLoc();
  std::string Name = Lex.getStrVal();
  next();
  if (expect(tok::lparen,
             "expected '(' after constraint operation '" + Name + "'"))
    return true;
  SmallVector<Value, 4> Args;
  if (parseConstraintArguments(Args))
    return true;
  auto ArityError = [&](unsigned Min, unsigned Max) {
    return Lex.ParseError(Loc, "constraint operation '" + Name + "' expects " +
                                   describeArity(Min, Max) + ", got " +
                                   Twine(Args.size()));
  };
  constraint::OperatorID ID = constraint::getOperatorID(Name, constraint::Call);
  if (std::optional<constraint::OperatorSchema> Schema =
          constraint::getOperatorSchema(ID)) {
    if (Args.size() < Schema->MinArity || Args.size() > Schema->MaxArity)
      return ArityError(Schema->MinArity, Schema->MaxArity);
    auto Call = mpir_expr::CallOp::create(
        Builder, loc(Loc), sortType(Schema->Result), unsigned(ID),
        unsigned(constraint::Call), Args, Value());
    Result = Call;
    return checkOperands(Call, Name);
  }
  auto Def = lookup<ConstraintDefOp>(Name);
  if (!Def)
    return Lex.ParseError(Loc, "unknown constraint operation '" + Name + "'");
  unsigned Arity = Def.getParamNames().size();
  if (Args.size() != Arity)
    return ArityError(Arity, Arity);
  Result = mpir_expr::ApplyOp::create(
      Builder, loc(Loc), sortType(bodySort(Def.getBody().front())),
      mlir::FlatSymbolRefAttr::get(Context, Name), Args);
  return false;
}

bool Parser::parseConstraintPrimary(Value &Result) {
  LocTy Loc = Lex.getLoc();
  switch (Lex.getKind()) {
  case tok::APSInt: {
    // A non-negative literal is unsigned and a negative one signed, each at
    // least 64 bits wide.
    const APSInt &Number = Lex.getAPSIntVal();
    bool Negative = Number.isSigned() && Number.isNegative();
    APSInt Literal =
        Negative
            ? APSInt(Number.sextOrTrunc(
                         std::max(64u, Number.getSignificantBits())),
                     /*isUnsigned=*/false)
            : APSInt(Number.zextOrTrunc(std::max(64u, Number.getActiveBits())),
                     /*isUnsigned=*/true);
    Result = mpir_expr::IntOp::create(Builder, loc(Loc), Literal);
    next();
    return false;
  }
  case tok::kw_true:
  case tok::kw_false:
    Result = mpir_expr::BoolOp::create(Builder, loc(Loc),
                                       Lex.getKind() == tok::kw_true);
    next();
    return false;
  case tok::StringConstant:
    Result = mpir_expr::StrOp::create(Builder, loc(Loc), Lex.getStrVal());
    next();
    return false;
  case tok::lsquare:
    return parseConstraintArray(Result);
  case tok::MetaVar: {
    if (Lex.getStrVal() == "_")
      return error("a constraint cannot refer to '?_', which stands for a "
                   "different value each time; name the variable");
    auto It = MetaVariables.find(Lex.getStrVal());
    if (It == MetaVariables.end())
      return error("constraint references unknown meta variable '?" +
                   Lex.getStrVal() + "'");
    Value M = It->second;
    next();
    // Read as the variable's sort so far.
    Result = mpir_expr::ReadOp::create(
        Builder, loc(Loc), sortType(getRepresentation(resolveSort(sortOf(M)))),
        M);
    return false;
  }
  case tok::lparen:
    next();
    return parseConstraint(Result) ||
           expect(tok::rparen, "expected ')' in constraint");
  case tok::Identifier:
    return parseConstraintCall(Result);
  default:
    return error("expected constraint expression");
  }
}

bool Parser::parseConstraintArray(Value &Result) {
  LocTy Loc = Lex.getLoc();
  next();
  if (Lex.getKind() == tok::rsquare)
    return Lex.ParseError(Loc, "constraint array literal must not be empty");
  SmallVector<Value, 4> Elements;
  do {
    Value Element;
    if (parseConstraint(Element))
      return true;
    Elements.push_back(Element);
  } while (consume(tok::comma));
  if (expect(tok::rsquare, "expected ']' after array literal"))
    return true;
  Sort ElementType = sortOf(Elements.front());
  Sort ArrayType;
  switch (ElementType) {
  case Sort::Type:
    ArrayType = Sort::TypeArray;
    break;
  case Sort::Value:
    ArrayType = Sort::ValueArray;
    break;
  case Sort::String:
    ArrayType = Sort::StringArray;
    break;
  default:
    return Lex.ParseError(
        Loc,
        "constraint array literal requires type, value, or string elements");
  }
  if (!all_of(Elements, [ElementType](Value Element) {
        return sortOf(Element) == ElementType;
      }))
    return Lex.ParseError(
        Loc, "constraint array literal elements must have the same type");
  Result = mpir_expr::ArrayOp::create(Builder, loc(Loc), sortType(ArrayType),
                                      Elements);
  return false;
}

//===----------------------------------------------------------------------===//
// 'constraint' and 'metaflag' definitions
//===----------------------------------------------------------------------===//

bool Parser::parseDefinitionParameters(StringRef Kind,
                                       SmallVectorImpl<std::string> &Names,
                                       SmallVectorImpl<SMLoc> &Locs) {
  if (expect(tok::lparen, "expected '(' after " + Kind + " name"))
    return true;
  StringSet<> Seen;
  if (parseCommaList(tok::rparen, [&] {
        if (Lex.getKind() != tok::MetaVar)
          return error("expected '?' parameter meta variable");
        if (!Seen.insert(Lex.getStrVal()).second)
          return error("duplicate parameter '?" + Lex.getStrVal() + "' in " +
                       Kind + " declaration");
        Names.push_back(Lex.getStrVal());
        Locs.push_back(Lex.getLoc());
        next();
        return false;
      }))
    return true;
  return expect(tok::rparen, "expected ')' after parameters");
}

bool Parser::parseDefinitionBody(StringRef Kind, ArrayRef<std::string> Names,
                                 ArrayRef<SMLoc> Locs, mlir::Block &Body,
                                 Value &Result) {
  skipNewlines();
  if (expect(tok::lbrace, "expected '{' before " + Kind + " body"))
    return true;
  skipNewlines();
  ClosedScope Scope(*this, &Body);
  for (unsigned I = 0; I != Names.size(); ++I)
    MetaVariables[Names[I]] =
        Body.addArgument(sortType(Sort::Unknown), loc(Locs[I]));
  InDefinitionBody = true;
  bool Failed = parseConstraint(Result);
  InDefinitionBody = false;
  if (Failed)
    return true;
  skipNewlines();
  if (expect(tok::rbrace, "expected '}' after " + Kind + " body"))
    return true;
  YieldOp::create(Builder, Result.getLoc(), Result);
  return false;
}

static mlir::ArrayAttr stringArray(OpBuilder &Builder,
                                   ArrayRef<std::string> Strings) {
  SmallVector<mlir::Attribute, 4> Attrs;
  for (const std::string &S : Strings)
    Attrs.push_back(Builder.getStringAttr(S));
  return Builder.getArrayAttr(Attrs);
}

bool Parser::parseTopLevelConstraint() {
  next();
  if (constraint::getOperatorID(Lex.getTokenText(), constraint::Call) !=
      constraint::UnknownOperator)
    return error(
        "'" + Lex.getTokenText() +
        "' is a built-in constraint operation and cannot be redefined");
  if (Lex.getKind() != tok::Identifier)
    return error("expected constraint name, which must be an identifier and "
                 "not a keyword");
  LocTy Loc = Lex.getLoc();
  std::string Name = Lex.getStrVal();
  if (lookup<ConstraintDefOp>(Name))
    return error("redefinition of constraint '" + Name + "'");
  next();
  SmallVector<std::string, 4> Params;
  SmallVector<SMLoc, 4> Locs;
  if (parseDefinitionParameters("constraint", Params, Locs))
    return true;
  OpBuilder::InsertionGuard Guard(Builder);
  Builder.setInsertionPointToEnd(Module.getBody());
  auto Def =
      ConstraintDefOp::create(Builder, loc(Loc), Builder.getStringAttr(Name),
                              mlir::StringAttr(), stringArray(Builder, Params));
  insertDefinition(Def);
  mlir::Block &Body = Def.getBody().emplaceBlock();
  Value Result;
  if (parseDefinitionBody("constraint", Params, Locs, Body, Result)) {
    Def.erase();
    return true;
  }
  return false;
}

bool Parser::parseTopLevelMetaFlag() {
  next();
  unsigned Placement = 0;
  while (Lex.getKind() == tok::MetaFlag &&
         (Lex.getStrVal() == "i" || Lex.getStrVal() == "o")) {
    Placement |= Lex.getStrVal() == "i" ? metaflag::InstructionPlacement
                                        : metaflag::OperandPlacement;
    next();
  }
  if (Placement == 0)
    Placement = metaflag::OperandPlacement;
  if (Lex.getKind() != tok::MetaFlag)
    return error("expected ':' followed by a metaflag name");
  LocTy Loc = Lex.getLoc();
  std::string Name = Lex.getStrVal();
  if (metaflag::getMetaFlagID(Name) != metaflag::UnknownMetaFlag)
    return error("':" + Name +
                 "' is a built-in metaflag and cannot be redefined");
  if (lookup<MetaFlagDefOp>(Name))
    return error("redefinition of metaflag ':" + Name + "'");
  next();
  SmallVector<std::string, 2> Params;
  SmallVector<SMLoc, 2> Locs;
  if (parseDefinitionParameters("metaflag", Params, Locs))
    return true;
  if (Params.empty())
    return error("a metaflag needs a '?' parameter for its subject");
  OpBuilder::InsertionGuard Guard(Builder);
  Builder.setInsertionPointToEnd(Module.getBody());
  auto Def = MetaFlagDefOp::create(
      Builder, loc(Loc), Builder.getStringAttr(Name), mlir::StringAttr(),
      stringArray(Builder, Params), Placement);
  insertDefinition(Def);
  mlir::Block &Body = Def.getBody().emplaceBlock();
  Value Result;
  if (parseDefinitionBody("metaflag", Params, Locs, Body, Result) ||
      requireBooleanConstraint(Result)) {
    Def.erase();
    return true;
  }
  return false;
}

//===----------------------------------------------------------------------===//
// 'match' definitions
//===----------------------------------------------------------------------===//

bool Parser::parseMatchParameters(instruction::OperandSyntax Syntax,
                                  SmallVectorImpl<ParamDef> &Result) {
  auto TypeParameter = [&]() -> bool {
    ParamDef P;
    P.Loc = Lex.getLoc();
    P.IsType = true;
    if (parseType(P.Ty))
      return true;
    if (auto Var = P.Ty.getDefiningOp<VarOp>())
      P.Name = Var.getVarName().str();
    else if (auto MetaInt = P.Ty.getDefiningOp<MetaIntTypeOp>())
      P.Name = MetaInt.getWidth().getDefiningOp<VarOp>().getVarName().str();
    Result.push_back(std::move(P));
    return false;
  };
  auto OperandParameter = [&]() -> bool {
    if (Lex.getKind() != tok::MetaVar)
      return error("expected operand meta variable in parameter list");
    ParamDef P;
    P.Loc = Lex.getLoc();
    P.Name = Lex.getStrVal();
    Result.push_back(std::move(P));
    next();
    return false;
  };
  auto Comma = [&]() -> bool {
    return expect(tok::comma, "expected ',' between operand parameters");
  };
  switch (Syntax) {
  case instruction::OperandSyntax::Nary:
    if (Lex.getKind() == tok::rparen)
      return error("'Nary' matcher needs at least one operand parameter");
    return parseCommaList(
        tok::rparen, [&] { return TypeParameter() || OperandParameter(); });
  case instruction::OperandSyntax::Binary:
    return TypeParameter() || OperandParameter() || Comma() ||
           OperandParameter();
  case instruction::OperandSyntax::Cast:
    return TypeParameter() || OperandParameter() ||
           expect(tok::kw_to, "expected 'to' before the result type") ||
           TypeParameter();
  case instruction::OperandSyntax::Custom:
    llvm_unreachable("a match declaration has a shared archetype");
  }
  llvm_unreachable("invalid operand syntax");
}

bool Parser::parseSemanticFlagName(instruction_flag::FlagID &Result) {
  std::optional<instruction_flag::FlagID> ID =
      tok::getSemanticFlag(Lex.getKind());
  if (!ID)
    return error("expected semantic flag name");
  Result = *ID;
  next();
  return false;
}

bool Parser::parseMatchHeader(MatchHeader &Header, MatcherOp &Matcher,
                              LocTy Loc) {
  if (Lex.getKind() == tok::MetaFlag) {
    if (Lex.getStrVal() != "c")
      return error("expected ':c' in match declaration");
    Header.IsCommutative = true;
    next();
  }
  if (Lex.getKind() != tok::Identifier)
    return error("expected matcher name in match declaration, which must be "
                 "an identifier and not a keyword");
  Header.Name = Lex.getStrVal();
  LocTy NameLoc = Lex.getLoc();
  if (lookup<MatcherOp>(Header.Name))
    return error("redefinition of matcher '" + Header.Name + "'");
  next();
  if (expect(tok::lsquare, "expected '[' before supported flags") ||
      parseCommaList(tok::rsquare,
                     [&] {
                       return parseSemanticFlagName(
                           Header.SupportedFlags.emplace_back());
                     }) ||
      expect(tok::rsquare, "expected ']' after supported flags"))
    return true;
  LocTy ArchetypeLoc = Lex.getLoc();
  bool IsUnary = false;
  if (consume(tok::kw_Unary)) {
    Header.Syntax = instruction::OperandSyntax::Nary;
    IsUnary = true;
  } else if (consume(tok::kw_Nary)) {
    Header.Syntax = instruction::OperandSyntax::Nary;
  } else if (consume(tok::kw_Binary)) {
    Header.Syntax = instruction::OperandSyntax::Binary;
  } else if (consume(tok::kw_Cast)) {
    Header.Syntax = instruction::OperandSyntax::Cast;
  } else {
    return error("expected archetype 'Unary', 'Nary', 'Binary' or 'Cast'");
  }
  if (Header.IsCommutative &&
      Header.Syntax != instruction::OperandSyntax::Binary)
    return error(
        "only 'Binary' matchers can be declared commutative with ':c'");
  if (expect(tok::lparen, "expected '(' before parameter list"))
    return true;

  // The matcher, whose region holds the parameters' type patterns. Its
  // attributes are filled in once the parameters are known.
  OpBuilder::InsertionGuard Guard(Builder);
  Builder.setInsertionPointToEnd(Module.getBody());
  Matcher = MatcherOp::create(
      Builder, loc(NameLoc), Builder.getStringAttr(Header.Name),
      mlir::StringAttr(), mlir::UnitAttr(), Builder.getDenseI32ArrayAttr({}),
      Builder.getI32IntegerAttr(0), Builder.getI32IntegerAttr(0),
      Builder.getArrayAttr({}), Builder.getDenseBoolArrayAttr({}));
  insertDefinition(Matcher);
  mlir::Block &Body = Matcher.getBody().emplaceBlock();
  {
    ClosedScope Scope(*this, &Body);
    if (parseMatchParameters(Header.Syntax, Header.Parameters))
      return true;
    SmallVector<Value, 4> Types;
    for (const ParamDef &P : Header.Parameters)
      if (P.IsType)
        Types.push_back(P.Ty);
    SignatureOp::create(Builder, loc(Loc), Types);
  }
  if (expect(tok::rparen, "expected ')' after parameter list"))
    return true;
  Header.Arity =
      count_if(Header.Parameters, [](const ParamDef &P) { return !P.IsType; });
  if (IsUnary && Header.Arity != 1)
    return Lex.ParseError(
        ArchetypeLoc, "'Unary' matcher takes exactly one operand parameter");
  StringSet<> TypeNames, OperandNames;
  for (const ParamDef &P : Header.Parameters)
    if (P.IsType && !P.Name.empty())
      TypeNames.insert(P.Name);
  for (const ParamDef &P : Header.Parameters) {
    if (P.IsType || P.Name.empty())
      continue;
    if (!OperandNames.insert(P.Name).second || TypeNames.contains(P.Name))
      return Lex.ParseError(P.Loc, "duplicate parameter '?" + P.Name +
                                       "' in match declaration");
  }

  SmallVector<int32_t, 4> Flags(Header.SupportedFlags.begin(),
                                Header.SupportedFlags.end());
  SmallVector<std::string, 4> Names;
  SmallVector<bool, 4> IsType;
  for (const ParamDef &P : Header.Parameters) {
    Names.push_back(P.Name);
    IsType.push_back(P.IsType);
  }
  if (Header.IsCommutative)
    Matcher.setCommutative(true);
  Matcher.setSupportedFlags(Flags);
  Matcher.setSyntax(unsigned(Header.Syntax));
  Matcher.setArity(Header.Arity);
  Matcher.setParamNamesAttr(stringArray(Builder, Names));
  Matcher.setParamIsType(IsType);
  return false;
}

bool Parser::parseBranchFlags(
    ArrayRef<instruction_flag::FlagID> SupportedFlags,
    SmallVectorImpl<std::pair<instruction_flag::FlagID, bool>> &Result) {
  if (!consume(tok::lsquare))
    return false;
  if (parseCommaList(tok::rsquare, [&] {
        LocTy Loc = Lex.getLoc();
        instruction_flag::FlagID ID;
        if (parseSemanticFlagName(ID))
          return true;
        if (!is_contained(SupportedFlags, ID))
          return Lex.ParseError(Loc,
                                "flag '" + instruction_flag::getName(ID) +
                                    "' is not declared in matcher's supported "
                                    "flags");
        bool Value = true;
        if (consume(tok::equal)) {
          if (Lex.getKind() != tok::kw_true && Lex.getKind() != tok::kw_false)
            return error("expected 'true' or 'false' after '='");
          Value = Lex.getKind() == tok::kw_true;
          next();
        }
        Result.push_back({ID, Value});
        return false;
      }))
    return true;
  if (expect(tok::rsquare, "expected ']' after branch flags"))
    return true;
  skipNewlines();
  return false;
}

bool Parser::parseMatchBranch(const MatchHeader &Header, MatcherOp Matcher) {
  skipNewlines();
  SmallVector<std::pair<instruction_flag::FlagID, bool>, 2> FixedFlags;
  if (parseBranchFlags(Header.SupportedFlags, FixedFlags))
    return true;
  LocTy Loc = Lex.getLoc();
  if (expect(tok::lbrace, "expected '{' to start match branch"))
    return true;
  skipNewlines();

  OpBuilder::InsertionGuard Guard(Builder);
  Builder.setInsertionPointToEnd(&Matcher.getBody().front());
  SmallVector<int32_t, 2> FlagIDs;
  SmallVector<bool, 2> FlagValues;
  for (auto [ID, Value] : FixedFlags) {
    FlagIDs.push_back(ID);
    FlagValues.push_back(Value);
  }
  auto Branch =
      BranchOp::create(Builder, loc(Loc), Builder.getDenseI32ArrayAttr({}),
                       Builder.getDenseI32ArrayAttr(FlagIDs),
                       Builder.getDenseBoolArrayAttr(FlagValues));
  mlir::Block &Body = Branch.getBody().emplaceBlock();

  ClosedScope Scope(*this, &Body);
  SmallVector<int32_t, 4> ParamArgs;
  for (const ParamDef &P : Header.Parameters) {
    if (P.Name.empty()) {
      ParamArgs.push_back(-1);
      continue;
    }
    Value &M = MetaVariables[P.Name];
    if (!M)
      M = Body.addArgument(sortType(Sort::Unknown), loc(P.Loc));
    ParamArgs.push_back(cast<mlir::BlockArgument>(M).getArgNumber());
  }
  Branch.setParamArgs(ParamArgs);
  while (Lex.getKind() != tok::rbrace && Lex.getKind() != tok::Eof)
    if (parseBodyLine(tok::rbrace))
      return true;
  LocTy BranchEnd = Lex.getLoc();
  if (expect(tok::rbrace, "expected '}' to end match branch"))
    return true;
  if (BodyInstructions.empty())
    return Lex.ParseError(BranchEnd,
                          "match branch must contain at least one instruction");
  Operation *Root = nullptr;
  for (Operation *I : BodyInstructions) {
    auto Inst = dyn_cast<InstOp>(I);
    auto Use = dyn_cast<UseOp>(I);
    std::optional<StringRef> Name =
        Inst ? Inst.getResultName() : Use.getResultName();
    // Results are named once, so there is one '%ret' at most.
    if (Name == "ret")
      Root = I;
  }
  if (!Root)
    Root = BodyInstructions.back();
  YieldOp::create(Builder, Root->getLoc(), Root->getResult(0));
  return false;
}

bool Parser::consumeBranchSeparator() {
  skipNewlines();
  if (Lex.getKind() != tok::kw_or)
    return false;
  LocTy OrLoc = Lex.getLoc();
  next();
  skipNewlines();
  if (Lex.getKind() == tok::lbrace || Lex.getKind() == tok::lsquare)
    return true;
  Lex.resetTo(OrLoc);
  return false;
}

bool Parser::parseTopLevelMatch() {
  LocTy Loc = Lex.getLoc();
  next();
  MatchHeader Header;
  MatcherOp Matcher;
  if (parseMatchHeader(Header, Matcher, Loc)) {
    if (Matcher)
      Matcher.erase();
    return true;
  }
  do {
    if (parseMatchBranch(Header, Matcher)) {
      Matcher.erase();
      return true;
    }
  } while (consumeBranchSeparator());
  return false;
}

} // namespace parse

//===----------------------------------------------------------------------===//
// Entry points
//===----------------------------------------------------------------------===//

static bool parseInto(mlir::ModuleOp Module, unsigned BufferID, SourceMgr &SM,
                      SMDiagnostic &Diag, bool Library) {
  parse::Parser P(SM.getMemoryBuffer(BufferID)->getBuffer(), SM, Diag, Module);
  return P.parseModule(Library);
}

/// Adds the standard library to SM and parses it into Module.
static bool parseStdLib(mlir::ModuleOp Module, SourceMgr &SM,
                        SMDiagnostic &Diag) {
  unsigned BufferID = SM.AddNewSourceBuffer(
      MemoryBuffer::getMemBuffer(parse::StdLibSource, parse::StdLibName),
      SMLoc());
  return parseInto(Module, BufferID, SM, Diag, /*Library=*/true);
}

mlir::OwningOpRef<mlir::ModuleOp>
parsePatternBuffer(std::unique_ptr<MemoryBuffer> Buffer, SourceMgr &SM,
                   mlir::MLIRContext &Context, SMDiagnostic &Diag) {
  loadPatternDialects(Context);
  unsigned BufferID = SM.AddNewSourceBuffer(std::move(Buffer), SMLoc());
  mlir::OwningOpRef<mlir::ModuleOp> Module(
      mlir::ModuleOp::create(mlir::UnknownLoc::get(&Context)));
  if (parseStdLib(*Module, SM, Diag) ||
      parseInto(*Module, BufferID, SM, Diag, /*Library=*/false))
    return nullptr;
  // What the parser builds is valid by construction; a module that is not is
  // a bug here, reported rather than handed on.
  // LCOV_EXCL_START
  if (mlir::failed(mlir::verify(*Module))) {
    Diag = SMDiagnostic(SM.getMemoryBuffer(BufferID)->getBufferIdentifier(),
                        SourceMgr::DK_Error,
                        "internal error: the parsed pattern is not valid MLIR");
    return nullptr;
  }
  // LCOV_EXCL_STOP
  return Module;
}

mlir::OwningOpRef<mlir::ModuleOp> parsePatternFile(StringRef Filename,
                                                   SourceMgr &SM,
                                                   mlir::MLIRContext &Context,
                                                   SMDiagnostic &Diag) {
  ErrorOr<std::unique_ptr<MemoryBuffer>> Buffer =
      MemoryBuffer::getFile(Filename);
  if (!Buffer) {
    Diag = SMDiagnostic(Filename, SourceMgr::DK_Error,
                        "cannot read file: " + Buffer.getError().message());
    return nullptr;
  }
  return parsePatternBuffer(std::move(*Buffer), SM, Context, Diag);
}

} // namespace metaphir
} // namespace llvm
