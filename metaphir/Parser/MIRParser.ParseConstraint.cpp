#include "metaphir/Parser/MIRParser.h"
#include "metaphir/IR/MIRContext.h"

namespace llvm {
namespace metaphir {

Constraint *MIRParser::makeConstraint(Constraint::ConstraintID K,
                                      Constraint::ResultType Ty, StringRef Op,
                                      int64_t Integer, bool Boolean,
                                      MetaVariable *Variable,
                                      ArrayRef<Constraint *> Args, LocTy Loc) {
  SourceRange R{Loc, Loc};
  switch (K) {
  case Constraint::Integer:
    return IntegerConstraint::get(Context, Integer, R);
  case Constraint::Boolean:
    return BooleanConstraint::get(Context, Boolean, R);
  case Constraint::String:
    llvm_unreachable("string constraints require a string value");
  case Constraint::Array:
    llvm_unreachable("array constraints require element values");
  case Constraint::Variable:
    return VariableConstraint::get(Context, Variable, Ty, R);
  case Constraint::ArrayAccess:
    llvm_unreachable("array access constraints require an array and index");
  case Constraint::Unary:
  case Constraint::Binary:
  case Constraint::Call:
    return OperatorConstraint::get(Context, K, Ty, Op, Args, R);
  }
  llvm_unreachable("invalid constraint kind");
}

bool MIRParser::parseConstraint(Constraint *&R) { return parseConstraintOr(R); }

bool MIRParser::parseConstraintOr(Constraint *&R) {
  if (parseConstraintAnd(R))
    return true;
  while (Lex.getKind() == tok::barbar) {
    LocTy L = Lex.getLoc();
    next();
    Constraint *B = nullptr;
    if (parseConstraintAnd(B))
      return true;
    Constraint *A = R;
    Constraint *Args[] = {A, B};
    R = makeConstraint(Constraint::Binary, Constraint::BooleanResult, "||", 0,
                       false, nullptr, Args, L);
  }
  return false;
}

bool MIRParser::parseConstraintAnd(Constraint *&R) {
  if (parseConstraintEquality(R))
    return true;
  while (Lex.getKind() == tok::ampamp) {
    LocTy L = Lex.getLoc();
    next();
    Constraint *B = nullptr;
    if (parseConstraintEquality(B))
      return true;
    Constraint *A = R;
    Constraint *Args[] = {A, B};
    R = makeConstraint(Constraint::Binary, Constraint::BooleanResult, "&&", 0,
                       false, nullptr, Args, L);
  }
  return false;
}

bool MIRParser::parseConstraintEquality(Constraint *&R) {
  if (parseConstraintAdd(R))
    return true;
  while (Lex.getKind() == tok::equalequal || Lex.getKind() == tok::notequal) {
    StringRef Op = Lex.getKind() == tok::equalequal ? "==" : "!=";
    LocTy L = Lex.getLoc();
    next();
    Constraint *B = nullptr;
    if (parseConstraintAdd(B))
      return true;
    Constraint *A = R;
    Constraint *Args[] = {A, B};
    R = makeConstraint(Constraint::Binary, Constraint::BooleanResult, Op, 0,
                       false, nullptr, Args, L);
  }
  if (Lex.getKind() == tok::less || Lex.getKind() == tok::greater ||
      Lex.getKind() == tok::lessequal || Lex.getKind() == tok::greaterequal)
    return error("use slt/ult/sle/ule/sgt/ugt/sge/uge for ordered comparisons");
  return false;
}

bool MIRParser::parseConstraintAdd(Constraint *&R) {
  if (parseConstraintMul(R))
    return true;
  while (Lex.getKind() == tok::plus || Lex.getKind() == tok::minus) {
    StringRef Op = Lex.getKind() == tok::plus ? "+" : "-";
    LocTy L = Lex.getLoc();
    next();
    Constraint *B = nullptr;
    if (parseConstraintMul(B))
      return true;
    Constraint *A = R;
    Constraint *Args[] = {A, B};
    R = makeConstraint(Constraint::Binary, Constraint::IntegerResult, Op, 0,
                       false, nullptr, Args, L);
  }
  return false;
}

bool MIRParser::parseConstraintMul(Constraint *&R) {
  if (parseConstraintUnary(R))
    return true;
  while (Lex.getKind() == tok::star) {
    LocTy L = Lex.getLoc();
    next();
    Constraint *B = nullptr;
    if (parseConstraintUnary(B))
      return true;
    Constraint *A = R;
    Constraint *Args[] = {A, B};
    R = makeConstraint(Constraint::Binary, Constraint::IntegerResult, "*", 0,
                       false, nullptr, Args, L);
  }
  if (Lex.getKind() == tok::slash || Lex.getKind() == tok::percent)
    return error("use sdiv/udiv/srem/urem for signed or unsigned arithmetic");
  return false;
}

bool MIRParser::parseConstraintUnary(Constraint *&R) {
  if (Lex.getKind() == tok::exclaim || Lex.getKind() == tok::minus) {
    bool IsNot = Lex.getKind() == tok::exclaim;
    StringRef Op = IsNot ? "!" : "-";
    LocTy L = Lex.getLoc();
    next();
    Constraint *A = nullptr;
    if (parseConstraintUnary(A))
      return true;
    Constraint *Args[] = {A};
    R = makeConstraint(Constraint::Unary,
                       IsNot ? Constraint::BooleanResult
                             : Constraint::IntegerResult,
                       Op, 0, false, nullptr, Args, L);
    return false;
  }
  return parseConstraintPostfix(R);
}

bool MIRParser::parseConstraintPostfix(Constraint *&R) {
  if (parseConstraintPrimary(R))
    return true;
  while (consume(tok::lsquare)) {
    LocTy L = Lex.getLoc();
    Constraint *Index = nullptr;
    if (parseConstraint(Index) ||
        expect(tok::rsquare, "expected ']' after array index"))
      return true;
    Constraint::ResultType ElementType;
    if (R->getResultType() == Constraint::TypeArrayResult)
      ElementType = Constraint::TypeResult;
    else if (R->getResultType() == Constraint::ValueArrayResult)
      ElementType = Constraint::ValueResult;
    else if (R->getResultType() == Constraint::StringArrayResult)
      ElementType = Constraint::StringResult;
    else
      return error("constraint subscript requires an array operand");
    if (Index->getResultType() != Constraint::IntegerResult)
      return error("constraint array index must be an integer");
    R = ArrayAccessConstraint::get(Context, ElementType, R, Index,
                                   SourceRange{L, L});
  }
  return false;
}

bool MIRParser::parseConstraintPrimary(Constraint *&R) {
  LocTy L = Lex.getLoc();
  if (Lex.getKind() == tok::APSInt) {
    if (!Lex.getAPSIntVal().isSignedIntN(64))
      return error("constraint integer is too large");
    int64_t V = Lex.getAPSIntVal().getExtValue();
    next();
    R = makeConstraint(Constraint::Integer, Constraint::IntegerResult, {}, V,
                       false, nullptr, {}, L);
    return false;
  }
  if (Lex.getKind() == tok::kw_true || Lex.getKind() == tok::kw_false) {
    bool V = Lex.getKind() == tok::kw_true;
    next();
    R = makeConstraint(Constraint::Boolean, Constraint::BooleanResult, {}, 0, V,
                       nullptr, {}, L);
    return false;
  }
  if (Lex.getKind() == tok::StringConstant) {
    R = StringConstraint::get(Context, Lex.getStrVal(), SourceRange{L, L});
    next();
    return false;
  }
  if (consume(tok::lsquare)) {
    SmallVector<Constraint *, 4> Elements;
    if (Lex.getKind() == tok::rsquare)
      return error("constraint array literal must not be empty");
    do {
      Constraint *Element = nullptr;
      if (parseConstraint(Element))
        return true;
      Elements.push_back(Element);
    } while (consume(tok::comma));
    if (expect(tok::rsquare, "expected ']' after array literal"))
      return true;

    Constraint::ResultType ElementType = Elements.front()->getResultType();
    Constraint::ResultType ArrayType;
    if (ElementType == Constraint::TypeResult)
      ArrayType = Constraint::TypeArrayResult;
    else if (ElementType == Constraint::ValueResult)
      ArrayType = Constraint::ValueArrayResult;
    else if (ElementType == Constraint::StringResult)
      ArrayType = Constraint::StringArrayResult;
    else
      return error(
          "constraint array literal requires type, value, or string elements");
    if (!llvm::all_of(Elements, [ElementType](const Constraint *Element) {
          return Element->getResultType() == ElementType;
        }))
      return error("constraint array literal elements must have the same type");
    R = ArrayConstraint::get(Context, ArrayType, Elements, SourceRange{L, L});
    return false;
  }
  if (Lex.getKind() == tok::MetaVar) {
    auto It = MetaVariables.find(Lex.getStrVal());
    if (It == MetaVariables.end())
      return error("constraint references unknown meta variable '?" +
                   Lex.getStrVal() + "'");
    MetaVariable *M = It->second;
    next();
    Constraint::ResultType Ty = Constraint::getResultType(M->getType());
    R = makeConstraint(Constraint::Variable, Ty, {}, 0, false, M, {}, L);
    return false;
  }
  if (consume(tok::lparen)) {
    if (parseConstraint(R) || expect(tok::rparen, "expected ')' in constraint"))
      return true;
    return false;
  }
  if (Lex.getKind() == tok::Identifier) {
    std::string NameStorage = Lex.getStrVal();
    StringRef Name = NameStorage;
    next();
    if (expect(tok::lparen, "expected '(' after constraint function"))
      return true;
    SmallVector<Constraint *, 4> Args;
    if (Lex.getKind() != tok::rparen) {
      do {
        Constraint *A = nullptr;
        if (parseConstraint(A))
          return true;
        Args.push_back(A);
      } while (consume(tok::comma));
    }
    if (expect(tok::rparen, "expected ')' after constraint arguments"))
      return true;
    Constraint::OperatorID ID =
        Constraint::getOperatorID(Name, Constraint::Call);
    std::optional<Constraint::OperatorSchema> Schema =
        Constraint::getOperatorSchema(ID);
    if (Schema && Args.size() != Schema->Arity)
      return error("built-in constraint operation expects " +
                   Twine(Schema->Arity) + " arguments");
    R = makeConstraint(Constraint::Call,
                       Schema ? Schema->Result : Constraint::Unknown, Name, 0,
                       false, nullptr, Args, L);
    return false;
  }
  return error("expected constraint expression");
}

} // namespace metaphir
} // namespace llvm
