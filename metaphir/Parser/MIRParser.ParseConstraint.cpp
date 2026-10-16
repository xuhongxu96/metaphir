//===- MIRParser.ParseConstraint.cpp - Constraint expression parsing ------===//
//
// Constraint expressions, loosest binding first:
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
//
//===----------------------------------------------------------------------===//

#include "metaphir/Parser/MIRParser.h"
#include "metaphir/IR/CompositeMatcher.h"
#include "metaphir/IR/Constraint.h"
#include "metaphir/IR/LibraryDefs.h"
#include "metaphir/IR/MIRContext.h"

namespace llvm {
namespace metaphir {

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

/// "1 argument", "2 to 3 arguments".
static std::string describeArity(unsigned Min, unsigned Max) {
  if (Min == Max)
    return (Twine(Min) + " argument" + (Min == 1 ? "" : "s")).str();
  return (Twine(Min) + " to " + Twine(Max) + " arguments").str();
}

bool MIRParser::checkOperands(const OperatorConstraint &Operator,
                              StringRef Spelling) {
  if (Operator.isUserDefined())
    return false;
  ArrayRef<Constraint *> Arguments = Operator.getArguments();
  for (unsigned Index = 0; Index != Arguments.size(); ++Index) {
    Sort Expected =
        Constraint::getArgumentType(Operator.getOperatorID(), Index);
    if (Constraint::canCoerce(Arguments[Index]->getSort(), Expected))
      continue;
    std::string What =
        Operator.getConstraintID() == Constraint::Call
            ? ("argument " + Twine(Index + 1) + " of '" + Spelling + "'").str()
            : ("operand of '" + Spelling + "'").str();
    return Lex.ParseError(Arguments[Index]->getSourceRange().Begin,
                          What + " must be " + Constraint::describe(Expected));
  }
  return false;
}

bool MIRParser::makeOperator(Constraint *&Result, Constraint::ConstraintID Kind,
                             StringRef Spelling, ArrayRef<Constraint *> Args,
                             LocTy Loc) {
  SourceRange Range{Loc, Loc};
  Constraint::OperatorID ID = Constraint::getOperatorID(Spelling, Kind);
  assert(ID != Constraint::UnknownOperator && "operator token without an ID");
  auto *Operator = OperatorConstraint::createBuiltin(
      Context, Kind, Constraint::getOperatorSchema(ID)->Result, ID, Args,
      Range);
  Result = Operator;
  return checkOperands(*Operator, Spelling);
}

bool MIRParser::parseConstraint(Constraint *&Result) {
  return parseConstraintBinary(Result, 1);
}

bool MIRParser::parseConstraintBinary(Constraint *&Result,
                                      unsigned MinPrecedence) {
  if (parseConstraintUnary(Result))
    return true;
  while (const BinaryOperatorInfo *Op = findBinaryOperator(Lex.getKind())) {
    if (Op->Precedence < MinPrecedence)
      break;
    LocTy Loc = Lex.getLoc();
    next();
    Constraint *Right = nullptr;
    if (parseConstraintBinary(Right, Op->Precedence + 1))
      return true;
    Constraint *Args[] = {Result, Right};
    if (makeOperator(Result, Constraint::Binary, Op->Spelling, Args, Loc))
      return true;
    // 'a == b == c' compares a boolean with c, which is rarely meant.
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

bool MIRParser::parseConstraintUnary(Constraint *&Result) {
  if (Lex.getKind() != tok::exclaim && Lex.getKind() != tok::minus)
    return parseConstraintPostfix(Result);
  StringRef Spelling = Lex.getKind() == tok::exclaim ? "!" : "-";
  LocTy Loc = Lex.getLoc();
  next();
  Constraint *Operand = nullptr;
  if (parseConstraintUnary(Operand))
    return true;
  Constraint *Args[] = {Operand};
  return makeOperator(Result, Constraint::Unary, Spelling, Args, Loc);
}

bool MIRParser::parseConstraintPostfix(Constraint *&Result) {
  if (parseConstraintPrimary(Result))
    return true;
  while (Lex.getKind() == tok::lsquare) {
    LocTy Loc = Lex.getLoc();
    next();
    Constraint *Index = nullptr;
    if (parseConstraint(Index) ||
        expect(tok::rsquare, "expected ']' after array index"))
      return true;
    Sort ElementType;
    switch (Result->getSort()) {
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
    if (Index->getSort() != Sort::Integer)
      return Lex.ParseError(Index->getSourceRange().Begin,
                            "constraint array index must be an integer");
    Result = ArrayAccessConstraint::create(Context, ElementType, Result, Index,
                                           SourceRange{Loc, Loc});
  }
  return false;
}

bool MIRParser::parseConstraintArguments(SmallVectorImpl<Constraint *> &Args) {
  if (Lex.getKind() != tok::rparen) {
    do {
      Constraint *Argument = nullptr;
      if (parseConstraint(Argument))
        return true;
      Args.push_back(Argument);
    } while (consume(tok::comma));
  }
  return expect(tok::rparen, "expected ')' after constraint arguments");
}

bool MIRParser::parseConstraintCall(Constraint *&Result) {
  LocTy Loc = Lex.getLoc();
  SourceRange Range{Loc, Loc};
  std::string NameStorage = Lex.getStrVal();
  StringRef Name = NameStorage;
  next();
  if (expect(tok::lparen,
             "expected '(' after constraint operation '" + Name + "'"))
    return true;
  SmallVector<Constraint *, 4> Args;
  if (parseConstraintArguments(Args))
    return true;

  auto ArityError = [&](unsigned Min, unsigned Max) {
    return Lex.ParseError(Loc, "constraint operation '" + Name + "' expects " +
                                   describeArity(Min, Max) + ", got " +
                                   Twine(Args.size()));
  };

  Constraint::OperatorID ID = Constraint::getOperatorID(Name, Constraint::Call);
  if (std::optional<Constraint::OperatorSchema> Schema =
          Constraint::getOperatorSchema(ID)) {
    if (Args.size() < Schema->MinArity || Args.size() > Schema->MaxArity)
      return ArityError(Schema->MinArity, Schema->MaxArity);
    auto *Call = OperatorConstraint::createBuiltin(
        Context, Constraint::Call, Schema->Result, ID, Args, Range);
    Result = Call;
    return checkOperands(*Call, Name);
  }

  // A call names either a built-in operation or a 'constraint' definition,
  // which is how the operation vocabulary is extended. Reporting an unknown
  // name here points at the call, rather than surfacing much later as an
  // evaluation failure while a candidate match is being checked.
  const ConstraintDef *Def = Context.getConstraintDef(Name);
  if (!Def)
    return Lex.ParseError(Loc, "unknown constraint operation '" + Name + "'");
  unsigned Arity = Def->getParameters().size();
  if (Args.size() != Arity)
    return ArityError(Arity, Arity);
  // The call has the type of the definition's body.
  Result = OperatorConstraint::createUserDefined(
      Context, Constraint::Call, Def->getBody()->getSort(), Name, Args, Range);
  return false;
}

bool MIRParser::parseConstraintPrimary(Constraint *&Result) {
  LocTy Loc = Lex.getLoc();
  SourceRange Range{Loc, Loc};
  switch (Lex.getKind()) {
  case tok::APSInt: {
    Result = IntegerConstraint::create(Context, Lex.getAPSIntVal(), Range);
    next();
    return false;
  }
  case tok::kw_true:
  case tok::kw_false:
    Result = BooleanConstraint::create(Context, Lex.getKind() == tok::kw_true,
                                       Range);
    next();
    return false;
  case tok::StringConstant:
    Result = StringConstraint::create(Context, Lex.getStrVal(), Range);
    next();
    return false;
  case tok::lsquare:
    return parseConstraintArray(Result);
  case tok::MetaVar: {
    auto It = MetaVariables.find(Lex.getStrVal());
    if (It == MetaVariables.end())
      return error("constraint references unknown meta variable '?" +
                   Lex.getStrVal() + "'");
    MetaVariable *M = It->second;
    next();
    Result = VariableConstraint::create(Context, M,
                                        getRepresentation(M->getSort()), Range);
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

bool MIRParser::parseConstraintArray(Constraint *&Result) {
  LocTy Loc = Lex.getLoc();
  next();
  if (Lex.getKind() == tok::rsquare)
    return Lex.ParseError(Loc, "constraint array literal must not be empty");
  SmallVector<Constraint *, 4> Elements;
  do {
    Constraint *Element = nullptr;
    if (parseConstraint(Element))
      return true;
    Elements.push_back(Element);
  } while (consume(tok::comma));
  if (expect(tok::rsquare, "expected ']' after array literal"))
    return true;

  Sort ElementType = Elements.front()->getSort();
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
  if (!all_of(Elements, [ElementType](const Constraint *Element) {
        return Element->getSort() == ElementType;
      }))
    return Lex.ParseError(
        Loc, "constraint array literal elements must have the same type");
  Result = ArrayConstraint::create(Context, ArrayType, Elements,
                                   SourceRange{Loc, Loc});
  return false;
}

} // namespace metaphir
} // namespace llvm
