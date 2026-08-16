#ifndef METAPHIR_PARSER_MIR_PARSER_H
#define METAPHIR_PARSER_MIR_PARSER_H

#include "metaphir/IR/Pattern.h"
#include "metaphir/Parser/MIRLexer.h"
#include "llvm/ADT/StringMap.h"

namespace llvm {
namespace metaphir {

class MIRParser {
public:
  MIRParser(StringRef Buffer, SourceMgr &SM, SMDiagnostic &Error,
            MIRContext &Context)
      : Lex(Buffer, SM, Error, Context), Context(Context) {}

  /// Parse a complete pattern. Returns true on error.
  bool parse(Pattern *&Result);

private:
  using LocTy = MIRLexer::LocTy;

  MIRLexer Lex;
  MIRContext &Context;
  StringMap<MetaVariable *> MetaVariables;
  StringMap<Instruction *> Instructions;
  Pattern *CurrentPattern = nullptr;
  bool SawConstraint = false;

  bool error(const Twine &Message) { return Lex.ParseError(Message); }
  void next() { Lex.Lex(); }
  bool consume(tok::Kind K);
  bool expect(tok::Kind K, const Twine &Message);
  void skipNewlines();

  MetaVariable *getMeta(StringRef Name, MetaType Expected, LocTy Loc);
  bool infer(MetaVariable *M, MetaType Expected, LocTy Loc);

  bool parseInstruction(Instruction *&Result);
  bool parseType(Type *&Result, bool AllowVoid = false);
  bool parseValue(Value *&Result, MetaType Expected = MetaType::Value);
  bool parseTypedOperand(MatcherOperand &Result,
                         MetaType Expected = MetaType::Value);
  bool parseArrayCapture(MatcherOperand &Result, bool WithTypes);
  bool parseMetaFlag(MetaFlag *&Result);
  bool parseMetaFlags(SmallVectorImpl<MetaFlag *> &Result,
                      MetaFlag::Placement Placement);
  bool parseSemanticFlags(Instruction::InstructionID ID,
                          SmallVectorImpl<MatcherFlag> &Result);

  bool parseConstraint(Constraint *&Result);
  bool parseConstraintOr(Constraint *&Result);
  bool parseConstraintAnd(Constraint *&Result);
  bool parseConstraintEquality(Constraint *&Result);
  bool parseConstraintAdd(Constraint *&Result);
  bool parseConstraintMul(Constraint *&Result);
  bool parseConstraintUnary(Constraint *&Result);
  bool parseConstraintPrimary(Constraint *&Result);
  Constraint *makeConstraint(Constraint::ConstraintID K,
                             Constraint::ResultType Ty, StringRef Op,
                             int64_t Integer, bool Boolean,
                             MetaVariable *Variable,
                             ArrayRef<Constraint *> Args, LocTy Loc);
};

} // namespace metaphir
} // namespace llvm

#endif
