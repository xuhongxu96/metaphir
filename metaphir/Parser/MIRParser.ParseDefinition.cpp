//===- MIRParser.ParseDefinition.cpp - Library definitions ----------------===//
//
// Top-level definitions:
//
//   constraint name(?p, ...) { expr }
//   metaflag[:i][:o] :name(?subject, ?arg, ...) { expr }
//   match[:c] name [flags] Archetype (params) { body } or [fixed] { body } ...
//
//===----------------------------------------------------------------------===//

#include "metaphir/Parser/MIRParser.h"
#include "metaphir/IR/CompositeMatcher.h"
#include "metaphir/IR/Constraint.h"
#include "metaphir/IR/DerivedTypes.h"
#include "metaphir/IR/LibraryDefs.h"
#include "metaphir/IR/MIRContext.h"
#include "llvm/ADT/StringSet.h"
#include "llvm/ADT/Twine.h"
#include <deque>

namespace llvm {
namespace metaphir {

MIRParser::ClosedScope::ClosedScope(MIRParser &Parser)
    : Parser(Parser), MetaVariables(std::move(Parser.MetaVariables)),
      Instructions(std::move(Parser.Instructions)),
      CurrentPattern(Parser.CurrentPattern), CurrentBlock(Parser.CurrentBlock),
      Settings(Parser.Settings) {
  Parser.MetaVariables.clear();
  Parser.Instructions.clear();
  Parser.CurrentPattern = Pattern::create(Parser.Context);
  Parser.CurrentBlock = nullptr;
  Parser.Settings = PatternSettings();
}

MIRParser::ClosedScope::~ClosedScope() {
  Parser.MetaVariables = std::move(MetaVariables);
  Parser.Instructions = std::move(Instructions);
  Parser.CurrentPattern = CurrentPattern;
  Parser.CurrentBlock = CurrentBlock;
  Parser.Settings = Settings;
}

bool MIRParser::parseDefinitionParameters(
    StringRef Kind, SmallVectorImpl<StringRef> &Names,
    SmallVectorImpl<SourceRange> &Ranges) {
  if (expect(tok::lparen, "expected '(' after " + Kind + " name"))
    return true;
  StringSet<> Seen;
  if (parseCommaList(tok::rparen, [&] {
        // Parameters are meta variables, spelled '?name' as everywhere else.
        if (Lex.getKind() != tok::MetaVar)
          return error("expected '?' parameter meta variable");
        if (!Seen.insert(Lex.getStrVal()).second)
          return error("duplicate parameter '?" + Lex.getStrVal() + "' in " +
                       Kind + " declaration");
        Names.push_back(Context.saveString(Lex.getStrVal()));
        Ranges.push_back(SourceRange{Lex.getLoc(), Lex.getLoc()});
        next();
        return false;
      }))
    return true;
  return expect(tok::rparen, "expected ')' after parameters");
}

bool MIRParser::parseDefinitionBody(StringRef Kind, ArrayRef<StringRef> Names,
                                    ArrayRef<SourceRange> Ranges,
                                    SmallVectorImpl<MetaVariable *> &Vars,
                                    Constraint *&Body) {
  skipNewlines();
  if (expect(tok::lbrace, "expected '{' before " + Kind + " body"))
    return true;
  skipNewlines();

  // The body may only refer to the parameters.
  ClosedScope Scope(*this);
  for (unsigned I = 0; I != Names.size(); ++I) {
    MetaVariable *M =
        MetaVariable::create(Context, Names[I], MetaType::Unknown, Ranges[I]);
    MetaVariables[Names[I]] = M;
    Vars.push_back(M);
  }

  InDefinitionBody = true;
  bool Failed = parseConstraint(Body);
  InDefinitionBody = false;
  if (Failed)
    return true;
  skipNewlines();
  return expect(tok::rbrace, "expected '}' after " + Kind + " body");
}

bool MIRParser::parseTopLevelConstraint() {
  next();
  // Names of built-in operations, some of which lex as keywords ('ult'), are
  // reserved.
  if (Constraint::getOperatorID(Lex.getTokenText(), Constraint::Call) !=
      Constraint::UnknownOperator)
    return error(
        "'" + Lex.getTokenText() +
        "' is a built-in constraint operation and cannot be redefined");
  // A constraint name is an identifier, so a keyword token cannot name one.
  if (Lex.getKind() != tok::Identifier)
    return error("expected constraint name, which must be an identifier and "
                 "not a keyword");
  std::string Name = Lex.getStrVal();
  if (Context.getConstraintDef(Name))
    return error("redefinition of constraint '" + Name + "'");
  next();

  SmallVector<StringRef, 4> Params;
  SmallVector<SourceRange, 4> Ranges;
  SmallVector<MetaVariable *, 4> Vars;
  Constraint *Body = nullptr;
  if (parseDefinitionParameters("constraint", Params, Ranges) ||
      parseDefinitionBody("constraint", Params, Ranges, Vars, Body))
    return true;

  [[maybe_unused]] bool Registered = Context.registerConstraintDef(
      ConstraintDef::create(Context, Name, Params, Vars, Body));
  assert(Registered && "redefinition was checked above");
  return false;
}

bool MIRParser::parseTopLevelMetaFlag() {
  next();
  // An optional placement mark follows the keyword: 'metaflag:i' for
  // instructions, 'metaflag:o' for operands, 'metaflag:i:o' for both. Each mark
  // lexes as its own MetaFlag token. Without a mark the flag is operand-only.
  unsigned Placement = 0;
  while (Lex.getKind() == tok::MetaFlag &&
         (Lex.getStrVal() == "i" || Lex.getStrVal() == "o")) {
    Placement |= Lex.getStrVal() == "i" ? MetaFlag::InstructionPlacement
                                        : MetaFlag::OperandPlacement;
    next();
  }
  if (Placement == 0)
    Placement = MetaFlag::OperandPlacement;

  // A metaflag name is written directly after ':' and the lexer packages both
  // into one token. The prefix keeps it unambiguous, so the name may be
  // spelled like a keyword (':poison').
  if (Lex.getKind() != tok::MetaFlag)
    return error("expected ':' followed by a metaflag name");
  std::string Name = Lex.getStrVal();
  if (MetaFlag::getMetaFlagID(Name) != MetaFlag::UnknownMetaFlag)
    return error("':" + Name +
                 "' is a built-in metaflag and cannot be redefined");
  if (Context.getMetaFlagDef(Name))
    return error("redefinition of metaflag ':" + Name + "'");
  next();

  // The first parameter is the subject the flag is written on; any further ones
  // are its arguments, so ':f(1, 2)' is declared with three parameters.
  SmallVector<StringRef, 2> Params;
  SmallVector<SourceRange, 2> Ranges;
  SmallVector<MetaVariable *, 2> Vars;
  Constraint *Body = nullptr;
  if (parseDefinitionParameters("metaflag", Params, Ranges))
    return true;
  if (Params.empty())
    return error("a metaflag needs a '?' parameter for its subject");
  if (parseDefinitionBody("metaflag", Params, Ranges, Vars, Body) ||
      requireBooleanConstraint(*Body))
    return true;

  [[maybe_unused]] bool Registered =
      Context.registerMetaFlagDef(MetaFlagDef::create(
          Context, Name, static_cast<MetaFlag::Placement>(Placement), Params,
          Vars, Body));
  assert(Registered && "redefinition was checked above");
  return false;
}

bool MIRParser::parseMatchParameters(Instruction::OperandSyntax Syntax,
                                     SmallVectorImpl<ParameterDef> &Result) {
  auto TypeParameter = [&]() -> bool {
    ParameterDef P;
    P.Range = SourceRange{Lex.getLoc(), Lex.getLoc()};
    P.IsType = true;
    if (parseType(P.Ty))
      return true;
    // A name is bound only where the declaration leaves the type open; a
    // concrete type is recorded in P.Ty and matched against the caller's.
    if (auto *MetaTy = dyn_cast<MetaIRType>(P.Ty))
      P.Name = Context.saveString(MetaTy->getVariable()->getName());
    else if (auto *MetaInt = dyn_cast<MetaIntegerType>(P.Ty))
      P.Name = Context.saveString(MetaInt->getBitWidthVariable()->getName());
    Result.push_back(std::move(P));
    return false;
  };
  auto OperandParameter = [&]() -> bool {
    if (Lex.getKind() != tok::MetaVar)
      return error("expected operand meta variable in parameter list");
    ParameterDef P;
    P.Range = SourceRange{Lex.getLoc(), Lex.getLoc()};
    P.Name = Context.saveString(Lex.getStrVal());
    Result.push_back(std::move(P));
    next();
    return false;
  };
  auto Comma = [&]() -> bool {
    return expect(tok::comma, "expected ',' between operand parameters");
  };

  switch (Syntax) {
  case Instruction::OperandSyntax::Nary:
    // Any number of individually typed operands; the count becomes the
    // matcher's arity.
    if (Lex.getKind() == tok::rparen)
      return error("'Nary' matcher needs at least one operand parameter");
    return parseCommaList(
        tok::rparen, [&] { return TypeParameter() || OperandParameter(); });
  case Instruction::OperandSyntax::Binary:
    return TypeParameter() || OperandParameter() || Comma() ||
           OperandParameter();
  case Instruction::OperandSyntax::Cast:
    return TypeParameter() || OperandParameter() ||
           expect(tok::kw_to, "expected 'to' before the result type") ||
           TypeParameter();
  case Instruction::OperandSyntax::Custom:
    break;
  }
  llvm_unreachable("a match declaration has a shared archetype");
}

bool MIRParser::parseSemanticFlagName(InstructionFlag::FlagID &Result) {
  std::optional<InstructionFlag::FlagID> ID = getSemanticFlag(Lex.getKind());
  if (!ID)
    return error("expected semantic flag name");
  Result = *ID;
  next();
  return false;
}

bool MIRParser::parseMatchHeader(MatchHeader &Header) {
  // 'match:c' declares a commutative matcher.
  if (Lex.getKind() == tok::MetaFlag) {
    if (Lex.getStrVal() != "c")
      return error("expected ':c' in match declaration");
    Header.IsCommutative = true;
    next();
  }
  // A custom matcher's name must be an identifier, so that it can never
  // collide with a keyword or with a built-in matcher.
  if (Lex.getKind() != tok::Identifier)
    return error("expected matcher name in match declaration, which must be "
                 "an identifier and not a keyword");
  Header.Name = Lex.getStrVal();
  if (Context.getCompositeMatcher(Header.Name))
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

  // 'Unary' is spelling sugar for a Nary matcher with exactly one operand.
  LocTy ArchetypeLoc = Lex.getLoc();
  bool IsUnary = false;
  if (consume(tok::kw_Unary)) {
    Header.Syntax = Instruction::OperandSyntax::Nary;
    IsUnary = true;
  } else if (consume(tok::kw_Nary)) {
    Header.Syntax = Instruction::OperandSyntax::Nary;
  } else if (consume(tok::kw_Binary)) {
    Header.Syntax = Instruction::OperandSyntax::Binary;
  } else if (consume(tok::kw_Cast)) {
    Header.Syntax = Instruction::OperandSyntax::Cast;
  } else {
    return error("expected archetype 'Unary', 'Nary', 'Binary' or 'Cast'");
  }
  if (Header.IsCommutative &&
      Header.Syntax != Instruction::OperandSyntax::Binary)
    return error(
        "only 'Binary' matchers can be declared commutative with ':c'");

  if (expect(tok::lparen, "expected '(' before parameter list"))
    return true;
  {
    // parseType interns the meta variables it sees into the current scope and
    // pattern, while each branch binds its own copies. Parse against a
    // scratch scope so the enclosing pattern does not acquire them.
    ClosedScope Scope(*this);
    if (parseMatchParameters(Header.Syntax, Header.Parameters))
      return true;
  }
  if (expect(tok::rparen, "expected ')' after parameter list"))
    return true;

  Header.Arity = count_if(Header.Parameters,
                          [](const ParameterDef &P) { return !P.IsType; });
  if (IsUnary && Header.Arity != 1)
    return Lex.ParseError(
        ArchetypeLoc, "'Unary' matcher takes exactly one operand parameter");

  // Operand parameters are distinct values. A type parameter may repeat (so
  // several operands can share a type), but one name cannot denote both a
  // type and an operand.
  StringSet<> TypeNames, OperandNames;
  for (const ParameterDef &P : Header.Parameters)
    if (P.IsType && !P.Name.empty())
      TypeNames.insert(P.Name);
  for (const ParameterDef &P : Header.Parameters) {
    if (P.IsType || P.Name.empty())
      continue;
    if (!OperandNames.insert(P.Name).second || TypeNames.contains(P.Name))
      return Lex.ParseError(P.Range.Begin, "duplicate parameter '?" + P.Name +
                                               "' in match declaration");
  }
  return false;
}

bool MIRParser::parseBranchFlags(
    ArrayRef<InstructionFlag::FlagID> SupportedFlags,
    SmallVectorImpl<std::pair<InstructionFlag::FlagID, bool>> &Result) {
  if (!consume(tok::lsquare))
    return false;
  if (parseCommaList(tok::rsquare, [&] {
        LocTy Loc = Lex.getLoc();
        InstructionFlag::FlagID ID;
        if (parseSemanticFlagName(ID))
          return true;
        if (!is_contained(SupportedFlags, ID))
          return Lex.ParseError(Loc,
                                "flag '" + InstructionFlag::getName(ID) +
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

bool MIRParser::parseMatchBranch(const MatchHeader &Header,
                                 BranchStorage &Storage) {
  skipNewlines();
  if (parseBranchFlags(Header.SupportedFlags, Storage.FixedFlags))
    return true;
  if (expect(tok::lbrace, "expected '{' to start match branch"))
    return true;
  skipNewlines();

  // A branch is a closed scope: a matcher is expanded at each of its uses, so
  // the only names its body may refer to are its parameters. Leaving the
  // enclosing pattern's locals and meta variables visible would let a body
  // capture them and silently tie the matcher to one pattern. Settings start
  // from their defaults: settings written in a body override the use site,
  // and anything the body leaves alone is inherited from it when inlined.
  ClosedScope Scope(*this);
  for (const ParameterDef &P : Header.Parameters) {
    if (P.Name.empty()) {
      Storage.ParameterVars.push_back(nullptr);
      continue;
    }
    // A type parameter may be repeated to give operands the same type.
    MetaVariable *&M = MetaVariables[P.Name];
    if (!M)
      M = MetaVariable::create(Context, P.Name, MetaType::Unknown, P.Range);
    Storage.ParameterVars.push_back(M);
  }

  // The body is parsed into the scope's scratch pattern exactly like a
  // top-level pattern body.
  while (Lex.getKind() != tok::rbrace && Lex.getKind() != tok::Eof)
    if (parseBodyLine(tok::rbrace))
      return true;
  LocTy BranchEnd = Lex.getLoc();
  if (expect(tok::rbrace, "expected '}' to end match branch"))
    return true;

  const Pattern &Body = *CurrentPattern;
  if (Body.getInstructions().empty())
    return Lex.ParseError(BranchEnd,
                          "match branch must contain at least one instruction");

  // The branch's result is '%ret', or else its last instruction.
  Instruction *Root = nullptr;
  for (Instruction *I : Body.getInstructions()) {
    if (I->getResultName() != "ret")
      continue;
    if (Root)
      return Lex.ParseError(BranchEnd,
                            "multiple '%ret' instructions in match branch");
    Root = I;
  }
  if (!Root)
    Root = Body.getInstructions().back();

  // CompositeMatcher::create copies these arrays into the context.
  Storage.Branch.Instructions = Body.getInstructions();
  Storage.Branch.Constraints = Body.getConstraints();
  Storage.Branch.FixedFlags = Storage.FixedFlags;
  Storage.Branch.ParameterVars = Storage.ParameterVars;
  Storage.Branch.LocalVariables = Body.getMetaVariables();
  Storage.Branch.Root = Root;
  return false;
}

bool MIRParser::consumeBranchSeparator() {
  skipNewlines();
  if (Lex.getKind() != tok::kw_or)
    return false;
  LocTy OrLoc = Lex.getLoc();
  next();
  skipNewlines();
  if (Lex.getKind() == tok::lbrace || Lex.getKind() == tok::lsquare)
    return true;
  // Not a branch: the 'or' is an instruction of the enclosing pattern.
  Lex.resetTo(OrLoc);
  return false;
}

bool MIRParser::parseTopLevelMatch() {
  next();
  MatchHeader Header;
  if (parseMatchHeader(Header))
    return true;

  // Branches refer to their storage until CompositeMatcher::create copies it.
  std::deque<BranchStorage> Storage;
  SmallVector<CompositeMatcher::Branch, 2> Branches;
  do {
    if (parseMatchBranch(Header, Storage.emplace_back()))
      return true;
    Branches.push_back(Storage.back().Branch);
    // Another branch is introduced by 'or' followed by its '[flags]' or '{'.
    // Any other 'or' is an instruction of the enclosing pattern.
  } while (consumeBranchSeparator());

  [[maybe_unused]] bool Registered =
      Context.registerCompositeMatcher(CompositeMatcher::create(
          Context, Header.Name, Header.IsCommutative, Header.SupportedFlags,
          Header.Syntax, Header.Arity, Header.Parameters, Branches));
  assert(Registered && "redefinition was checked above");
  return false;
}

} // namespace metaphir
} // namespace llvm
