#ifndef METAPHIR_PARSER_MIR_PARSER_H
#define METAPHIR_PARSER_MIR_PARSER_H

#include "metaphir/IR/Pattern.h"
#include "metaphir/Parser/MIRLexer.h"
#include "llvm/ADT/STLFunctionalExtras.h"
#include "llvm/ADT/StringMap.h"

namespace llvm {
namespace metaphir {

class CompositeMatcher;
struct ParameterDef;

class MIRParser {
public:
  MIRParser(StringRef Buffer, SourceMgr &SM, SMDiagnostic &Error,
            MIRContext &Context)
      : Lex(Buffer, SM, Error, Context), Context(Context) {}

  /// Parses a complete pattern, loading the standard library into the context
  /// first if needed. Returns true on error, with the diagnostic in the
  /// SMDiagnostic given to the constructor.
  bool parse(Pattern *&Result);

  /// Name under which the embedded standard library is recorded in a context.
  static constexpr StringRef StdLibName = "stdlib";

  /// Parses Source as the library named Name into Context, registering its
  /// definitions; the standard library is loaded first. The context keeps a
  /// copy of Source. Does nothing if a library of that name is already
  /// loaded. Returns true on error, with the diagnostic in Diag; the library
  /// is then not recorded as loaded.
  static bool loadLibrary(MIRContext &Context, StringRef Name, StringRef Source,
                          SMDiagnostic &Diag);

private:
  using LocTy = MIRLexer::LocTy;

  MIRLexer Lex;
  MIRContext &Context;
  StringMap<MetaVariable *> MetaVariables;
  unsigned WildcardCaptureCounter = 0;
  StringMap<Instruction *> Instructions;
  Pattern *CurrentPattern = nullptr;
  MetaVariable *CurrentBlock = nullptr;
  PatternSettings Settings;

  /// Parses the whole buffer: definitions and an optional pattern body.
  bool parseModule(Pattern *&Result);

  bool error(const Twine &Message) { return Lex.ParseError(Message); }
  void next() { Lex.Lex(); }
  bool consume(tok::Kind K);
  bool expect(tok::Kind K, const Twine &Message);
  /// Describes the current token for a diagnostic: its source text, or "end
  /// of line" / "end of file".
  std::string describeToken() const;
  void skipNewlines();

  MetaVariable *getMeta(StringRef Name, MetaType Expected, LocTy Loc);
  bool infer(MetaVariable *M, MetaType Expected, LocTy Loc);
  bool parseBlockLabel();
  bool parsePatternSetting(PatternSettings::Setting Setting);

  bool parseInstruction(Instruction *&Result);
  bool parseType(Type *&Result, bool AllowVoid = false);
  bool parseValue(Value *&Result, MetaType Expected = MetaType::Value);
  bool parseTypedOperand(MatcherOperand &Result,
                         MetaType Expected = MetaType::Value);
  bool parseOperandMetaFlags(MatcherOperand &Result);
  bool parseArrayCapture(MatcherOperand &Result, bool WithTypes);
  bool parseMetaFlag(MetaFlag *&Result, MetaFlag::Placement &Allowed);
  bool parseMetaFlags(SmallVectorImpl<MetaFlag *> &Result,
                      MetaFlag::Placement Placement);

  // The pieces below are shared by built-in and composite matchers, which are
  // spelled the same way and differ only in what a flag is validated against.

  /// Parses an optional ':?var' result capture.
  bool parseInstructionCapture(MetaVariable *&Capture);

  /// Parses instruction-placement metaflags, rejecting ':c' unless the matcher
  /// named by OwnerName is commutative.
  bool parseInstructionMetaFlags(SmallVectorImpl<MetaFlag *> &Result,
                                 bool IsCommutative, StringRef OwnerName);

  /// Parses semantic flags with optional captures, rejecting any that
  /// IsSupported declines for the matcher named by OwnerName.
  bool
  parseSemanticFlags(function_ref<bool(InstructionFlag::FlagID)> IsSupported,
                     StringRef OwnerName,
                     SmallVectorImpl<InstructionFlag> &Result);

  /// Parses the operands of one of the shared archetypes. Custom grammars are
  /// specific to a built-in instruction and stay with the caller. Arity is the
  /// number of operands a Nary matcher named OpName takes.
  bool parseArchetypeOperands(Instruction::OperandSyntax Syntax, unsigned Arity,
                              StringRef OpName,
                              SmallVectorImpl<MatcherOperand> &Ops);

  /// Parses one line of a pattern body -- a ';;' setting or constraint, a
  /// block label, or an instruction -- into CurrentPattern. The line must end
  /// at a newline, the end of input, or Terminator (left unconsumed).
  bool parseBodyLine(tok::Kind Terminator);
  bool expectEndOfLine(tok::Kind Terminator, const Twine &Message);

  bool parseTopLevelMatch();
  /// Consumes an 'or' that introduces another match branch.
  bool consumeBranchSeparator();
  bool parseMatchParameters(Instruction::OperandSyntax Syntax,
                            SmallVectorImpl<ParameterDef> &Result);
  bool parseTopLevelConstraint();
  bool parseTopLevelMetaFlag();
  bool parseCompositeInstruction(Instruction *&Result, CompositeMatcher *CM,
                                 StringRef OpName, StringRef ResultName,
                                 LocTy Loc);

  bool parseConstraint(Constraint *&Result);
  bool parseConstraintOr(Constraint *&Result);
  bool parseConstraintAnd(Constraint *&Result);
  bool parseConstraintEquality(Constraint *&Result);
  bool parseConstraintAdd(Constraint *&Result);
  bool parseConstraintMul(Constraint *&Result);
  bool parseConstraintUnary(Constraint *&Result);
  bool parseConstraintPostfix(Constraint *&Result);
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
