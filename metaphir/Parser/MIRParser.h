#ifndef METAPHIR_PARSER_MIR_PARSER_H
#define METAPHIR_PARSER_MIR_PARSER_H

#include "metaphir/IR/CompositeMatcher.h"
#include "metaphir/IR/Pattern.h"
#include "metaphir/Parser/MIRLexer.h"
#include "llvm/ADT/STLFunctionalExtras.h"
#include "llvm/ADT/StringMap.h"

namespace llvm {
namespace metaphir {

/// Parses the MetaphIR file Filename into a pattern, adding its buffer to SM
/// (which must outlive the pattern). Returns true on error, with the
/// diagnostic in Diag.
bool parseMIRFile(StringRef Filename, SourceMgr &SM, MIRContext &Context,
                  Pattern *&Result, SMDiagnostic &Diag);

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
  /// Set while parsing a 'constraint'/'metaflag' body, whose expression may
  /// span lines.
  bool InDefinitionBody = false;

  /// Parses the whole buffer: definitions and an optional pattern body.
  bool parseModule(Pattern *&Result);

  bool error(const Twine &Message) { return Lex.ParseError(Message); }
  void next() {
    while (Lex.Lex() == tok::Newline && InDefinitionBody) {
    }
  }
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
  /// Parses an optional '%name =' into Name.
  bool parseInstructionResult(SmallVectorImpl<char> &Name);
  /// Checks what the operand grammar cannot: ':o' and ':c' against the
  /// operands, and that no keyed operand is given twice.
  bool validateInstruction(Instruction::InstructionID ID,
                           ArrayRef<MetaFlag *> MFlags,
                           ArrayRef<MatcherOperand> Ops);

  // Operand grammars. Each appends what it parses to Ops.
  bool parseCustomOperands(Instruction::InstructionID ID,
                           SmallVectorImpl<MatcherOperand> &Ops);
  /// A typed operand, 'i32 ?x'.
  bool parseOperand(SmallVectorImpl<MatcherOperand> &Ops,
                    MetaType Expected = MetaType::Value);
  /// A bare type that is not an operand, e.g. a load's result type.
  bool parseTypeOperand(SmallVectorImpl<MatcherOperand> &Ops);
  /// A value stored under Key, e.g. an alignment.
  bool parseKeyedOperand(SmallVectorImpl<MatcherOperand> &Ops,
                         MatcherOperand::KeyedOperandKind Key,
                         MetaType Expected);
  bool parseOperandComma();
  /// An optional ', align N'.
  bool parseAlign(SmallVectorImpl<MatcherOperand> &Ops);
  enum TrailingOperandKind {
    NatIndices,   ///< ', 0, 1' (extractvalue), or ', ...?values'
    TypedOperands ///< ', i64 ?i, ...' (GEP, call), or ', ...?types ?values'
  };
  /// Operands after a comma until the list ends, or an array capture.
  bool parseTrailingOperands(SmallVectorImpl<MatcherOperand> &Ops,
                             TrailingOperandKind Kind);
  bool parseAllocaOperands(SmallVectorImpl<MatcherOperand> &Ops);
  bool parseGEPOperands(SmallVectorImpl<MatcherOperand> &Ops);
  bool parseBranchOperands(SmallVectorImpl<MatcherOperand> &Ops);
  bool parseCompareOperands(SmallVectorImpl<MatcherOperand> &Ops);
  bool parsePhiOperands(SmallVectorImpl<MatcherOperand> &Ops);
  bool parseCallOperands(SmallVectorImpl<MatcherOperand> &Ops);
  bool parseType(Type *&Result, bool AllowVoid = false);
  bool parseBaseType(Type *&Result, bool AllowVoid);
  bool parsePointerType(Type *&Result);
  /// '[N x T]' or '<N x T>' after the opening bracket.
  bool parseSequenceType(Type *&Result, bool IsVector);
  /// '{T, ...}' after the opening brace; '<{...}>' when Packed.
  bool parseStructType(Type *&Result, bool Packed);
  /// Pointer ('*') and function ('(T, ...)') type suffixes.
  bool parseTypeSuffixes(Type *&Result);
  bool parseAggregateConstant(Value *&Result);
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

  /// Parses 'Element (, Element)*' unless the current token is Close, which
  /// is left for the caller.
  bool parseCommaList(tok::Kind Close, function_ref<bool()> Element);

  /// Saves the parser's naming state and opens a closed scope in its place:
  /// no meta variables, locals or block, a scratch pattern, and default
  /// settings. The saved state is restored when the scope ends.
  class ClosedScope {
  public:
    explicit ClosedScope(MIRParser &Parser);
    ~ClosedScope();
    ClosedScope(const ClosedScope &) = delete;
    ClosedScope &operator=(const ClosedScope &) = delete;

  private:
    MIRParser &Parser;
    StringMap<MetaVariable *> MetaVariables;
    StringMap<Instruction *> Instructions;
    Pattern *CurrentPattern;
    MetaVariable *CurrentBlock;
    PatternSettings Settings;
  };

  // 'constraint' and 'metaflag' definitions.
  bool parseTopLevelConstraint();
  bool parseTopLevelMetaFlag();
  bool parseDefinitionParameters(StringRef Kind,
                                 SmallVectorImpl<StringRef> &Names,
                                 SmallVectorImpl<SourceRange> &Ranges);
  bool parseDefinitionBody(StringRef Kind, ArrayRef<StringRef> Names,
                           ArrayRef<SourceRange> Ranges,
                           SmallVectorImpl<MetaVariable *> &Vars,
                           Constraint *&Body);

  // 'match' definitions.
  struct MatchHeader {
    std::string Name;
    bool IsCommutative = false;
    SmallVector<InstructionFlag::FlagID, 4> SupportedFlags;
    Instruction::OperandSyntax Syntax = Instruction::OperandSyntax::Nary;
    unsigned Arity = 0;
    SmallVector<ParameterDef, 4> Parameters;
  };
  /// A parsed branch and the arrays it refers to.
  struct BranchStorage {
    CompositeMatcher::Branch Branch;
    SmallVector<std::pair<InstructionFlag::FlagID, bool>, 2> FixedFlags;
    SmallVector<MetaVariable *, 4> ParameterVars;
  };
  bool parseTopLevelMatch();
  bool parseMatchHeader(MatchHeader &Header);
  bool parseMatchParameters(Instruction::OperandSyntax Syntax,
                            SmallVectorImpl<ParameterDef> &Result);
  bool parseMatchBranch(const MatchHeader &Header, BranchStorage &Storage);
  bool parseBranchFlags(
      ArrayRef<InstructionFlag::FlagID> SupportedFlags,
      SmallVectorImpl<std::pair<InstructionFlag::FlagID, bool>> &Result);
  /// Consumes an 'or' that introduces another match branch.
  bool consumeBranchSeparator();

  /// The semantic flag a token names, if any.
  static std::optional<InstructionFlag::FlagID> getSemanticFlag(tok::Kind K);
  bool parseSemanticFlagName(InstructionFlag::FlagID &Result);
  bool parseCompositeInstruction(Instruction *&Result, CompositeMatcher *CM,
                                 StringRef OpName, StringRef ResultName,
                                 LocTy Loc);

  // Constraint expressions; see MIRParser.ParseConstraint.cpp.
  bool parseConstraint(Constraint *&Result);
  /// Parses operators binding at least as tightly as MinPrecedence.
  bool parseConstraintBinary(Constraint *&Result, unsigned MinPrecedence);
  bool parseConstraintUnary(Constraint *&Result);
  bool parseConstraintPostfix(Constraint *&Result);
  bool parseConstraintPrimary(Constraint *&Result);
  bool parseConstraintArray(Constraint *&Result);
  bool parseConstraintCall(Constraint *&Result);
  bool parseConstraintArguments(SmallVectorImpl<Constraint *> &Args);
  /// Builds the built-in unary or binary operator Spelling and checks its
  /// operands.
  bool makeOperator(Constraint *&Result, Constraint::ConstraintID Kind,
                    StringRef Spelling, ArrayRef<Constraint *> Args, LocTy Loc);
  /// Reports an operand of a built-in operator whose type cannot be used.
  bool checkOperands(const OperatorConstraint &Operator, StringRef Spelling);
  /// Reports C unless it is (or may be, once matched) a boolean.
  bool requireBooleanConstraint(const Constraint &C);
};

} // namespace metaphir
} // namespace llvm

#endif
