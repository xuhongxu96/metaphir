#include "metaphir/Parser/MIRParser.h"
#include "metaphir/IR/CompositeMatcher.h"
#include "metaphir/IR/Constraint.h"
#include "metaphir/IR/DerivedTypes.h"
#include "metaphir/IR/Instruction.h"
#include "metaphir/IR/LibraryDefs.h"
#include "metaphir/IR/MIRContext.h"
#include "llvm/ADT/SmallString.h"
#include "llvm/ADT/StringSet.h"
#include "llvm/ADT/Twine.h"
#include <deque>

namespace llvm {
namespace metaphir {

static std::optional<PatternSettings::Setting>
settingFromKeyword(tok::Kind Kind) {
  switch (Kind) {
#define MIR_PATTERN_SETTING_TOKEN_KIND(Name)                                   \
  case tok::kw_##Name:                                                         \
    return PatternSettings::Name;
#include "metaphir/IR/PatternSettings.def"
  default:
    return std::nullopt;
  }
}

bool MIRParser::consume(tok::Kind K) {
  if (Lex.getKind() != K)
    return false;
  next();
  return true;
}

bool MIRParser::expect(tok::Kind K, const Twine &Message) {
  if (!consume(K))
    return error(Message + " (got " + describeToken() + ")");
  return false;
}

std::string MIRParser::describeToken() const {
  switch (Lex.getKind()) {
  case tok::Newline:
    return "end of line";
  case tok::Eof:
    return "end of file";
  default:
    return ("'" + Lex.getTokenText() + "'").str();
  }
}

bool MIRParser::parseCommaList(tok::Kind Close, function_ref<bool()> Element) {
  if (Lex.getKind() == Close)
    return false;
  do {
    if (Element())
      return true;
  } while (consume(tok::comma));
  return false;
}

void MIRParser::skipNewlines() {
  while (consume(tok::Newline)) {
  }
}

bool MIRParser::infer(MetaVariable *M, Sort Expected, LocTy Loc) {
  // The variable's sort is the meet of the sorts its occurrences require.
  std::optional<Sort> Meet = meetSorts(M->getInferredSort(), Expected);
  if (!Meet)
    return Lex.ParseError(Loc, "meta variable '?" + M->getName() +
                                   "' is used with an incompatible type");
  M->setSort(*Meet);
  return false;
}

MetaVariable *MIRParser::getMeta(StringRef Name, Sort Expected, LocTy Loc) {
  // Each '?_' is a variable of its own, of any sort: it matches anything
  // and binds nothing a match reports (as any '?_name').
  if (Name == "_")
    Name = Context.saveString(("_$" + Twine(NextWildcard++)).str());
  auto It = MetaVariables.find(Name);
  if (It != MetaVariables.end()) {
    if (infer(It->second, Expected, Loc))
      return nullptr;
    return It->second;
  }
  auto *M =
      MetaVariable::create(Context, Name, Expected, SourceRange{Loc, Loc});
  MetaVariables[M->getName()] = M;
  if (Instructions.count(Name))
    Lex.Warning(Loc, "meta variable '?" + Name +
                         "' shares a name with local variable '%" + Name + "'");
  CurrentPattern->addMetaVariable(M);
  return M;
}

bool MIRParser::parseBlockLabel() {
  LocTy Loc = Lex.getLoc();
  SmallString<16> Name;
  if (Lex.getKind() == tok::LabelStr) {
    Name = Lex.getStrVal();
    next();
    if (Name == "anyblock") {
      CurrentBlock = nullptr;
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
  return CurrentBlock == nullptr;
}

bool MIRParser::parsePatternSetting(PatternSettings::Setting Setting) {
  next(); // consume the setting name
  if (expect(tok::lparen,
             "expected '(' after '" + PatternSettings::getName(Setting) + "'"))
    return true;
  if (Lex.getKind() != tok::kw_true && Lex.getKind() != tok::kw_false)
    return error("expected 'true' or 'false' in '" +
                 PatternSettings::getName(Setting) + "'");
  bool Value = Lex.getKind() == tok::kw_true;
  if (Value)
    Settings.set(Setting);
  else
    Settings.clear(Setting);
  next();
  if (expect(tok::rparen, "expected ')' after setting value"))
    return true;
  return false;
}

#include "StdLibSource.inc"

bool MIRParser::loadLibrary(MIRContext &Context, StringRef Name,
                            StringRef Source, SMDiagnostic &Diag) {
  if (Context.isLibraryLoaded(Name))
    return false;
  // Every library may use the standard library's definitions.
  if (Name != StdLibName &&
      loadLibrary(Context, StdLibName, StdLibSource, Diag))
    return true;
  SourceMgr &SM = Context.getLibrarySourceMgr();
  // The library name doubles as the buffer identifier, so diagnostics inside a
  // library are reported against it.
  unsigned BufferID = SM.AddNewSourceBuffer(
      MemoryBuffer::getMemBufferCopy(Source, Name), SMLoc());
  MIRParser Parser(SM.getMemoryBuffer(BufferID)->getBuffer(), SM, Diag,
                   Context);
  Pattern *Unused = nullptr;
  if (Parser.parseModule(Unused))
    return true;
  Context.markLibraryLoaded(Name);
  return false;
}

bool parseMIRFile(StringRef Filename, SourceMgr &SM, MIRContext &Context,
                  Pattern *&Result, SMDiagnostic &Diag) {
  ErrorOr<std::unique_ptr<MemoryBuffer>> Buffer =
      MemoryBuffer::getFile(Filename);
  if (!Buffer) {
    Diag = SMDiagnostic(Filename, SourceMgr::DK_Error,
                        "cannot read file: " + Buffer.getError().message());
    return true;
  }
  return parseMIRBuffer(std::move(*Buffer), SM, Context, Result, Diag);
}

bool parseMIRBuffer(std::unique_ptr<MemoryBuffer> Buffer, SourceMgr &SM,
                    MIRContext &Context, Pattern *&Result, SMDiagnostic &Diag) {
  unsigned BufferID = SM.AddNewSourceBuffer(std::move(Buffer), SMLoc());
  MIRParser Parser(SM.getMemoryBuffer(BufferID)->getBuffer(), SM, Diag,
                   Context);
  return Parser.parse(Result);
}

bool MIRParser::parse(Pattern *&Result) {
  Result = nullptr;
  if (loadLibrary(Context, StdLibName, StdLibSource, Lex.getDiagnostic()))
    return true;
  return parseModule(Result);
}

bool MIRParser::parseModule(Pattern *&Result) {
  Result = nullptr;
  CurrentPattern = Pattern::create(Context);
  CurrentBlock = nullptr;
  bool HasParsedTopLevelDefinition = false;
  next();
  skipNewlines();
  while (Lex.getKind() != tok::Eof) {
    if (Lex.getKind() == tok::kw_match) {
      if (parseTopLevelMatch())
        return true;
      HasParsedTopLevelDefinition = true;
      skipNewlines();
      continue;
    }
    if (Lex.getKind() == tok::kw_constraint) {
      if (parseTopLevelConstraint())
        return true;
      HasParsedTopLevelDefinition = true;
      skipNewlines();
      continue;
    }
    if (Lex.getKind() == tok::kw_metaflag) {
      if (parseTopLevelMetaFlag())
        return true;
      HasParsedTopLevelDefinition = true;
      skipNewlines();
      continue;
    }
    if (parseBodyLine(tok::Eof))
      return true;
  }
  // Every lexer error yields an Error token that no production accepts, but a
  // diagnostic recorded anywhere must fail the parse regardless.
  if (Lex.hasError())
    return true;
  if (CurrentPattern->getInstructions().empty()) {
    if (HasParsedTopLevelDefinition) {
      // A library may hold only 'match', 'constraint' and 'metaflag'
      // definitions without patterns.
      Result = CurrentPattern;
      return false;
    }
    return error("expected at least one instruction matcher");
  }
  // A block needs an instruction in it, or one referring to it: else no
  // match binds its label.
  auto IsUsed = [&](const MetaVariable *Block) {
    for (const Instruction *I : CurrentPattern->getInstructions()) {
      if (I->getParentBlock() == Block)
        return true;
      for (const MatcherOperand &Op : I->getUnkeyedOperands())
        if (Op.Val == Block)
          return true;
    }
    return false;
  };
  for (const MetaVariable *M : CurrentPattern->getMetaVariables())
    if (M->getSort() == Sort::BasicBlock && !M->getName().starts_with("_") &&
        !IsUsed(M))
      return Lex.ParseError(M->getSourceRange().Begin,
                            "block '?" + M->getName() +
                                "' has no instruction, and no instruction "
                                "refers to it");
  Result = CurrentPattern;
  return false;
}

bool MIRParser::requireBooleanConstraint(const Constraint &C) {
  Sort Type = C.getSort();
  if (Type == Sort::Boolean || Type == Sort::Unknown)
    return false;
  return Lex.ParseError(C.getSourceRange().Begin,
                        "constraint must have a boolean result");
}

bool MIRParser::expectEndOfLine(tok::Kind Terminator, const Twine &Message) {
  if (Lex.getKind() != tok::Newline && Lex.getKind() != tok::Eof &&
      Lex.getKind() != Terminator)
    return error(Message);
  skipNewlines();
  return false;
}

bool MIRParser::parseBodyLine(tok::Kind Terminator) {
  if (consume(tok::ConstraintMarker)) {
    if (std::optional<PatternSettings::Setting> Setting =
            settingFromKeyword(Lex.getKind())) {
      if (parsePatternSetting(*Setting))
        return true;
      return expectEndOfLine(Terminator,
                             "unexpected token after pattern setting");
    }
    Constraint *C = nullptr;
    if (parseConstraint(C))
      return true;
    if (requireBooleanConstraint(*C))
      return true;
    // A value-tracking operator defaults to the instruction the constraint
    // follows. In a match branch, expansion rewrites this to the inlined copy
    // of that instruction.
    const Instruction *ContextInst =
        CurrentPattern->getInstructions().empty()
            ? nullptr
            : CurrentPattern->getInstructions().back();
    C->setDefaultContextInstruction(ContextInst);
    CurrentPattern->addConstraint(C);
    return expectEndOfLine(Terminator, "unexpected token after constraint");
  }
  if (Lex.getKind() == tok::LabelStr || Lex.getKind() == tok::LabelID ||
      Lex.getKind() == tok::MetaVar) {
    if (parseBlockLabel())
      return true;
    return expectEndOfLine(Terminator,
                           "unexpected token after basic block label");
  }
  if (!CurrentPattern->getInstructions().empty() &&
      CurrentPattern->getInstructions().back()->getParentBlock() ==
          CurrentBlock &&
      CurrentPattern->getInstructions().back()->getResultName().empty())
    return error("only the final instruction may omit a result assignment");
  Instruction *I = nullptr;
  if (parseInstruction(I))
    return true;
  CurrentPattern->addInstruction(I);
  return expectEndOfLine(Terminator, "unexpected token after instruction");
}

} // namespace metaphir
} // namespace llvm
