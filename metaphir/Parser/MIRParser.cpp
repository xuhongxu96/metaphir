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

/// "1 argument", "2 arguments".
static std::string pluralize(uint64_t Count, StringRef Noun) {
  return (Twine(Count) + " " + Noun + (Count == 1 ? "" : "s")).str();
}

static bool isOpcode(tok::Kind K) {
  switch (K) {
#define MIR_INSTRUCTION_MATCHER_TOKEN_KIND(Name) case tok::kw_##Name:
#include "metaphir/IR/InstructionMatchers.def"
    return true;
  default:
    return false;
  }
}

static Instruction::InstructionID instructionID(tok::Kind K) {
  switch (K) {
#define MIR_INSTRUCTION_MATCHER_NAME(Name)                                     \
  case tok::kw_##Name:                                                         \
    return Instruction::I_##Name;
#include "metaphir/IR/InstructionMatchers.def"
  default:
    llvm_unreachable("not an instruction token");
  }
}

static std::optional<KeywordConstant::KeywordID>
predicateKeywordID(tok::Kind K) {
  switch (K) {
#define MIR_PREDICATE_KEYWORD(ID, Spelling)                                    \
  case tok::kw_##Spelling:                                                     \
    return KeywordConstant::K_##ID;
#include "metaphir/IR/KeywordConstants.def"
  default:
    return std::nullopt;
  }
}

static std::optional<Type::TypeID> primitiveTypeID(tok::Kind K) {
  switch (K) {
#define MIR_TYPE(TypeID, TokenKind)                                            \
  case tok::kw_##TokenKind:                                                    \
    return Type::TypeID;
#include "metaphir/IR/Types.def"
  default:
    return std::nullopt;
  }
}

static bool isSemanticFlag(tok::Kind K) {
  switch (K) {
#define MIR_FLAG(Flag) case tok::kw_##Flag:
#define MIR_FAST_MATH_FLAG(Flag) case tok::kw_##Flag:
#include "metaphir/IR/Flags.def"
    return true;
  default:
    return false;
  }
}

static InstructionFlag::FlagID semanticFlagID(tok::Kind K) {
  switch (K) {
#define MIR_FLAG(Name)                                                         \
  case tok::kw_##Name:                                                         \
    return InstructionFlag::F_##Name;
#define MIR_FAST_MATH_FLAG(Name)                                               \
  case tok::kw_##Name:                                                         \
    return InstructionFlag::F_##Name;
#include "metaphir/IR/Flags.def"
  default:
    llvm_unreachable("not a semantic flag token");
  }
}

static bool compatibleMeta(MetaType A, MetaType B) {
  if (A == B || A == MetaType::Unknown || B == MetaType::Unknown)
    return true;
  auto IsValue = [](MetaType T) {
    return T == MetaType::Value || T == MetaType::Instruction ||
           T == MetaType::Function || T == MetaType::Nat || T == MetaType::Bool;
  };
  if ((A == MetaType::Value && IsValue(B)) ||
      (B == MetaType::Value && IsValue(A)))
    return true;
  return (A == MetaType::Nat && B == MetaType::Bool) ||
         (A == MetaType::Bool && B == MetaType::Nat);
}

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

void MIRParser::skipNewlines() {
  while (consume(tok::Newline)) {
  }
}

bool MIRParser::infer(MetaVariable *M, MetaType Expected, LocTy Loc) {
  if (!compatibleMeta(M->getType(), Expected))
    return Lex.ParseError(Loc, "meta variable '?" + M->getName() +
                                   "' is used with an incompatible type");
  if (M->getType() == MetaType::Unknown ||
      (M->getType() == MetaType::Value && Expected != MetaType::Value) ||
      (M->getType() == MetaType::Nat && Expected == MetaType::Bool))
    M->setType(Expected);
  return false;
}

MetaVariable *MIRParser::getMeta(StringRef Name, MetaType Expected, LocTy Loc) {
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

  CurrentBlock = getMeta(Name, MetaType::BasicBlock, Loc);
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
  Result = CurrentPattern;
  return false;
}

bool MIRParser::requireBooleanConstraint(const Constraint &C) {
  Constraint::ResultType Type = C.getResultType();
  if (Type == Constraint::BooleanResult || Type == Constraint::Unknown)
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

bool MIRParser::parseInstructionCapture(MetaVariable *&Capture) {
  Capture = nullptr;
  if (Lex.getKind() != tok::MetaCaptureVar)
    return false;
  Capture = getMeta(Lex.getStrVal(), MetaType::Instruction, Lex.getLoc());
  if (!Capture)
    return true;
  next();
  return false;
}

bool MIRParser::parseInstructionMetaFlags(SmallVectorImpl<MetaFlag *> &Result,
                                          bool IsCommutative,
                                          StringRef OwnerName) {
  if (parseMetaFlags(Result, MetaFlag::InstructionPlacement))
    return true;
  for (MetaFlag *F : Result)
    if (F->getMetaFlagID() == MetaFlag::MF_c && !IsCommutative)
      return Lex.ParseError(F->getSourceRange().Begin,
                            "commutative matching is not valid for '" +
                                OwnerName + "'");
  return false;
}

bool MIRParser::parseSemanticFlags(
    function_ref<bool(InstructionFlag::FlagID)> IsSupported,
    StringRef OwnerName, SmallVectorImpl<InstructionFlag> &Result) {
  while (isSemanticFlag(Lex.getKind())) {
    LocTy Loc = Lex.getLoc();
    InstructionFlag::FlagID FlagID = semanticFlagID(Lex.getKind());
    if (!IsSupported(FlagID))
      return Lex.ParseError(Loc, "flag '" + InstructionFlag::getName(FlagID) +
                                     "' is not valid for '" + OwnerName + "'");
    next();
    MetaVariable *Capture = nullptr;
    if (Lex.getKind() == tok::MetaCaptureVar) {
      StringRef CaptureName = Lex.getStrVal();
      if (CaptureName == "_") {
        CaptureName = Context.saveString(
            (Twine("_flag$") + Twine(WildcardCaptureCounter++)).str());
      }
      Capture = getMeta(CaptureName, MetaType::Bool, Lex.getLoc());
      if (!Capture)
        return true;
      next();
    }
    Result.push_back({FlagID, Capture});
  }
  return false;
}

/// Parses one metaflag and reports through Allowed where it may be written.
/// Resolving the flag -- built-in schema or 'metaflag' definition -- happens
/// here, so callers need not look it up again.
bool MIRParser::parseMetaFlag(MetaFlag *&Result, MetaFlag::Placement &Allowed) {
  if (Lex.getKind() != tok::MetaFlag)
    return error("expected metaflag");
  LocTy Loc = Lex.getLoc();
  SmallString<16> Name;
  Name = Lex.getStrVal();
  MetaFlag::MetaFlagID ID = MetaFlag::getMetaFlagID(Name);
  next();
  SmallVector<MetaFlag::Argument, 4> Args;
  if (consume(tok::lparen)) {
    if (Lex.getKind() != tok::rparen) {
      do {
        MetaFlag::Argument Arg;
        if (Lex.getKind() == tok::MetaFlag) {
          Arg.K = MetaFlag::Argument::Flag;
          MetaFlag::Placement NestedAllowed = MetaFlag::OperandPlacement;
          if (parseMetaFlag(Arg.FlagValue, NestedAllowed))
            return true;
          // A nested flag is tested against the operand its parent applies to.
          if (!(NestedAllowed & MetaFlag::OperandPlacement))
            return Lex.ParseError(Arg.FlagValue->getSourceRange().Begin,
                                  "metaflag ':" + Arg.FlagValue->getName() +
                                      "' is not valid as a nested metaflag");
        } else if (Lex.getKind() == tok::APSInt) {
          if (!Lex.getAPSIntVal().isRepresentableByInt64())
            return error("metaflag integer argument is too large");
          Arg.K = MetaFlag::Argument::Integer;
          Arg.IntegerValue = Lex.getAPSIntVal().getExtValue();
          next();
        } else {
          return error("expected integer or nested metaflag argument");
        }
        Args.push_back(Arg);
      } while (consume(tok::comma));
    }
    if (expect(tok::rparen, "expected ')' after metaflag arguments"))
      return true;
  }
  if (std::optional<MetaFlag::Schema> Schema = MetaFlag::getSchema(ID)) {
    Allowed = Schema->AllowedPlacement;
    if (Args.size() < Schema->MinArguments ||
        Args.size() > Schema->MaxArguments)
      return Lex.ParseError(
          Loc, "invalid number of arguments for metaflag ':" + Name + "'");
    for (const MetaFlag::Argument &Arg : Args) {
      if (Schema->Arguments == MetaFlag::IntegerArgument &&
          Arg.K != MetaFlag::Argument::Integer)
        return Lex.ParseError(Loc, "metaflag ':" + Name +
                                       "' expects integer arguments");
      if (Schema->Arguments == MetaFlag::FlagArgument &&
          Arg.K != MetaFlag::Argument::Flag)
        return Lex.ParseError(Loc, "metaflag ':" + Name +
                                       "' expects nested metaflags");
    }
  } else if (MetaFlagDef *Def = Context.getMetaFlagDef(Name)) {
    Allowed = Def->getPlacement();
    // The first parameter is the subject the flag is written on, so a use
    // supplies every parameter but that one.
    if (Args.size() != Def->getNumArguments())
      return Lex.ParseError(Loc,
                            "metaflag ':" + Name + "' expects " +
                                pluralize(Def->getNumArguments(), "argument") +
                                ", got " + Twine(Args.size()));
  } else {
    // A flag is either built in or introduced by a 'metaflag' definition, which
    // is how the flag vocabulary is extended. An unknown name cannot be lowered
    // into a constraint and has no implementation in the matcher, so it is
    // reported here rather than silently failing to match.
    return Lex.ParseError(Loc, "unknown metaflag ':" + Name + "'");
  }

  if (ID != MetaFlag::UnknownMetaFlag)
    Result = MetaFlag::createBuiltin(Context, ID, Args, SourceRange{Loc, Loc});
  else
    Result =
        MetaFlag::createUserDefined(Context, Name, Args, SourceRange{Loc, Loc});
  return false;
}

bool MIRParser::parseMetaFlags(SmallVectorImpl<MetaFlag *> &Result,
                               MetaFlag::Placement Placement) {
  while (Lex.getKind() == tok::MetaFlag) {
    MetaFlag *F = nullptr;
    MetaFlag::Placement Allowed = MetaFlag::OperandPlacement;
    if (parseMetaFlag(F, Allowed))
      return true;

    if (!(Allowed & Placement))
      return Lex.ParseError(F->getSourceRange().Begin,
                            "metaflag ':" + F->getName() +
                                "' is not valid in this position");

    Result.push_back(F);
  }
  return false;
}

bool MIRParser::parseType(Type *&Result, bool AllowVoid) {
  LocTy Loc = Lex.getLoc();
  if (Lex.getKind() == tok::Type) {
    Result = Lex.getTyVal();
    next();
  } else if (Lex.getKind() == tok::MetaIntVar) {
    auto *M = getMeta(Lex.getStrVal(), MetaType::Nat, Loc);
    if (!M)
      return true;
    Result = MetaIntegerType::get(Context, M, Lex.getMetaIntPrefix() == 'b');
    next();
  } else if (Lex.getKind() == tok::MetaVar) {
    auto *M = getMeta(Lex.getStrVal(), MetaType::Type, Loc);
    if (!M)
      return true;
    Result = MetaIRType::get(Context, M);
    next();
  } else if (std::optional<Type::TypeID> ID = primitiveTypeID(Lex.getKind())) {
    if (*ID == Type::VoidTyID && !AllowVoid)
      return error("void type is not allowed here");
    Result = Type::get(Context, *ID);
    next();
  } else if (Lex.getKind() == tok::kw_ptr) {
    next();
    unsigned AddressSpace = PointerType::AnyAddressSpace;
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
    Result = PointerType::get(Context, nullptr, AddressSpace);
  } else if (consume(tok::lsquare)) {
    uint64_t Count = 0;
    MetaVariable *CountVar = nullptr;
    if (Lex.getKind() == tok::APSInt) {
      if (Lex.getAPSIntVal().isNegative() ||
          Lex.getAPSIntVal().getActiveBits() > 64)
        return error("invalid array size");
      Count = Lex.getAPSIntVal().getZExtValue();
      next();
    } else if (Lex.getKind() == tok::MetaVar) {
      CountVar = getMeta(Lex.getStrVal(), MetaType::Nat, Lex.getLoc());
      if (!CountVar)
        return true;
      next();
    } else
      return error("expected array size");
    if (Lex.getKind() != tok::kw_x)
      return error("expected 'x' after array size");
    next();
    Type *Elt = nullptr;
    if (parseType(Elt) || expect(tok::rsquare, "expected ']' after array type"))
      return true;
    Result = ArrayType::get(Context, Elt, Count, CountVar);
  } else if (consume(tok::lbrace)) {
    SmallVector<Type *, 8> Elts;
    if (Lex.getKind() != tok::rbrace) {
      do {
        Type *Elt = nullptr;
        if (parseType(Elt))
          return true;
        Elts.push_back(Elt);
      } while (consume(tok::comma));
    }
    if (expect(tok::rbrace, "expected '}' after struct type"))
      return true;
    Result = StructType::get(Context, Elts);
  } else if (consume(tok::less)) {
    if (consume(tok::lbrace)) {
      SmallVector<Type *, 8> Elts;
      if (Lex.getKind() != tok::rbrace) {
        do {
          Type *Elt = nullptr;
          if (parseType(Elt))
            return true;
          Elts.push_back(Elt);
        } while (consume(tok::comma));
      }
      if (expect(tok::rbrace, "expected '}' after packed struct") ||
          expect(tok::greater, "expected '>' after packed struct"))
        return true;
      Result = StructType::get(Context, Elts, true);
    } else {
      bool Scalable = false;
      if (Lex.getKind() == tok::kw_vscale) {
        Scalable = true;
        next();
        if (Lex.getKind() != tok::kw_x)
          return error("expected 'x' after vscale");
        next();
      }
      uint64_t Count = 0;
      MetaVariable *CountVar = nullptr;
      if (Lex.getKind() == tok::APSInt) {
        if (Lex.getAPSIntVal().isNegative() ||
            Lex.getAPSIntVal().getActiveBits() > 64)
          return error("invalid vector size");
        Count = Lex.getAPSIntVal().getZExtValue();
        next();
      } else if (Lex.getKind() == tok::MetaVar) {
        CountVar = getMeta(Lex.getStrVal(), MetaType::Nat, Lex.getLoc());
        if (!CountVar)
          return true;
        next();
      } else
        return error("expected vector size (got " + describeToken() + ")");
      if (Lex.getKind() != tok::kw_x)
        return error("expected 'x' after vector size");
      next();
      Type *Elt = nullptr;
      if (parseType(Elt) ||
          expect(tok::greater, "expected '>' after vector type"))
        return true;
      Result = VectorType::get(Context, Scalable, Elt, Count, CountVar);
    }
  } else {
    return error("expected type");
  }

  while (true) {
    if (consume(tok::star)) {
      Result = PointerType::get(Context, Result);
      continue;
    }
    if (consume(tok::lparen)) {
      SmallVector<Type *, 8> Parameters;
      bool VarArg = false;
      if (Lex.getKind() != tok::rparen) {
        do {
          if (consume(tok::dotdotdot)) {
            VarArg = true;
            break;
          }
          Type *Parameter = nullptr;
          if (parseType(Parameter))
            return true;
          Parameters.push_back(Parameter);
        } while (consume(tok::comma));
      }
      if (expect(tok::rparen, "expected ')' after function type"))
        return true;
      Result = FunctionType::get(Context, Result, Parameters, VarArg);
      continue;
    }
    break;
  }
  return false;
}

bool MIRParser::parseValue(Value *&Result, MetaType Expected) {
  LocTy Loc = Lex.getLoc();
  SourceRange Range{Loc, Loc};
  if (Lex.getKind() == tok::plus || Lex.getKind() == tok::minus) {
    bool Negative = Lex.getKind() == tok::minus;
    next();
    if (Lex.getKind() == tok::APSInt) {
      APSInt Number = Lex.getAPSIntVal();
      if (Negative)
        Number = -Number;
      Result = IntegerConstant::create(Context, Number, Range);
      next();
      return false;
    }
    if (Lex.getKind() == tok::APFloat) {
      APFloat Number = Lex.getAPFloatVal();
      if (Negative)
        Number.changeSign();
      Result = FloatingConstant::create(Context, Number, Range);
      next();
      return false;
    }
    return error("expected numeric literal after sign");
  }
  if (Lex.getKind() == tok::MetaVar) {
    auto *M = getMeta(Lex.getStrVal(), Expected, Loc);
    if (!M)
      return true;
    Result = M;
    next();
    return false;
  }
  if (Lex.getKind() == tok::LocalVar || Lex.getKind() == tok::LocalVarID) {
    SmallString<16> NameStorage;
    StringRef Name = Lex.getStrVal();
    if (Lex.getKind() == tok::LocalVarID)
      Name = Twine(Lex.getUIntVal()).toStringRef(NameStorage);
    if (Expected == MetaType::BasicBlock) {
      auto *M = getMeta(Name, MetaType::BasicBlock, Loc);
      if (!M)
        return true;
      Result = M;
      next();
      return false;
    }
    auto It = Instructions.find(Name);
    if (It == Instructions.end())
      return error("undefined or forward local reference '%" + Name + "'");
    Result = It->second;
    next();
    return false;
  }
  if (Lex.getKind() == tok::IntrinsicPrefix) {
    next();
    if (Lex.getKind() == tok::MetaVar) {
      auto *M = getMeta(Lex.getStrVal(), MetaType::IntrinsicID, Lex.getLoc());
      if (!M)
        return true;
      next();
      Result = M;
      return false;
    }
    if (Lex.getKind() == tok::Identifier) {
      SmallString<32> Name("llvm.");
      Name += Lex.getStrVal();
      next();
      Result = GlobalValue::create(Context, Name, Range);
      return false;
    }
    return error("expected intrinsic ID meta variable or intrinsic name");
  }
  if (Lex.getKind() == tok::GlobalVar || Lex.getKind() == tok::GlobalID) {
    // The name has to outlive the lexer's buffer, which next() overwrites.
    SmallString<32> NameStorage;
    if (Lex.getKind() == tok::GlobalVar)
      NameStorage = Lex.getStrVal();
    else
      Twine(Lex.getUIntVal()).toVector(NameStorage);
    next();
    Result = GlobalValue::create(Context, NameStorage, Range);
    return false;
  }
  if (Lex.getKind() == tok::APSInt) {
    APSInt V = Lex.getAPSIntVal();
    Result = IntegerConstant::create(Context, V, Range);
    next();
    return false;
  }
  if (Lex.getKind() == tok::APFloat) {
    APFloat V = Lex.getAPFloatVal();
    Result = FloatingConstant::create(Context, V, Range);
    next();
    return false;
  }
  if (Lex.getKind() == tok::kw_true || Lex.getKind() == tok::kw_false) {
    bool V = Lex.getKind() == tok::kw_true;
    APSInt I(APInt(1, V), /*isUnsigned=*/true);
    Result = IntegerConstant::create(Context, I, Range);
    next();
    return false;
  }
#define MIR_CONSTANT_KEYWORD(ID, Kind)                                         \
  if (Lex.getKind() == tok::kw_##Kind) {                                       \
    Result = KeywordConstant::create(Context, KeywordConstant::K_##ID, Range); \
    next();                                                                    \
    return false;                                                              \
  }
#include "metaphir/Parser/MIRKeywords.def"
  tok::Kind Open = Lex.getKind();
  tok::Kind Close = Open == tok::lsquare  ? tok::rsquare
                    : Open == tok::lbrace ? tok::rbrace
                                          : tok::greater;
  if (Open == tok::lsquare || Open == tok::lbrace || Open == tok::less) {
    next();
    SmallVector<Type *, 8> Types;
    SmallVector<Value *, 8> Values;
    if (Lex.getKind() != Close) {
      do {
        Type *T = nullptr;
        Value *V = nullptr;
        if (parseType(T) || parseValue(V))
          return true;
        Types.push_back(T);
        Values.push_back(V);
      } while (consume(tok::comma));
    }
    if (expect(Close, "expected end of aggregate constant"))
      return true;
    AggregateConstant::Delimiter Delimiter =
        Open == tok::lsquare ? AggregateConstant::Square
        : Open == tok::less  ? AggregateConstant::Angle
                             : AggregateConstant::Brace;
    Result =
        AggregateConstant::create(Context, Types, Values, Delimiter, Range);
    return false;
  }
  return error("expected value");
}

bool MIRParser::parseTypedOperand(MatcherOperand &Result, MetaType Expected) {
  if (parseType(Result.Ty))
    return true;
  if (Expected == MetaType::Value) {
    if (auto *Integer = dyn_cast<IntegerType>(Result.Ty)) {
      if (Integer->getNumBits() == 1)
        Expected = MetaType::Bool;
    } else if (Result.Ty->getTypeID() == Type::LabelTyID) {
      Expected = MetaType::BasicBlock;
    }
  }
  if (parseValue(Result.Val, Expected))
    return true;
  return parseOperandMetaFlags(Result);
}

bool MIRParser::parseOperandMetaFlags(MatcherOperand &Result) {
  SmallVector<MetaFlag *, 4> Flags;
  if (parseMetaFlags(Flags, MetaFlag::OperandPlacement))
    return true;
  if (Flags.empty())
    return false;
  Result.setMetaFlags(Context, Flags);
  if (!isa_and_nonnull<MetaVariable>(Result.Val))
    for (const MetaFlag *Flag : Flags)
      if (Context.getMetaFlagDef(Flag->getName()))
        return error("metaflag ':" + Flag->getName() +
                     "' can only be applied to a meta variable operand");
  return false;
}

bool MIRParser::parseArrayCapture(MatcherOperand &Result, bool WithTypes) {
  if (!consume(tok::dotdotdot))
    return error("expected '...' operand capture");
  Result.IsArray = true;
  if (WithTypes) {
    if (Lex.getKind() != tok::MetaVar)
      return error("expected type-array meta variable");
    Result.TypeArray =
        getMeta(Lex.getStrVal(), MetaType::TypeArray, Lex.getLoc());
    if (!Result.TypeArray)
      return true;
    next();
  }
  if (Lex.getKind() != tok::MetaVar)
    return error("expected value-array meta variable");
  Result.ValueArray =
      getMeta(Lex.getStrVal(), MetaType::ValueArray, Lex.getLoc());
  if (!Result.ValueArray)
    return true;
  next();
  return false;
}

// Parsing is schema-driven here so the stored representation stays uniform
// while syntax and arity remain instruction-specific.
bool MIRParser::parseArchetypeOperands(Instruction::OperandSyntax Syntax,
                                       unsigned Arity, StringRef OpName,
                                       SmallVectorImpl<MatcherOperand> &Ops) {
  auto Typed = [&](MetaType E = MetaType::Value) -> bool {
    MatcherOperand O;
    if (parseTypedOperand(O, E))
      return true;
    Ops.push_back(O);
    return false;
  };
  auto Comma = [&]() -> bool {
    return expect(tok::comma, "expected ',' between operands");
  };

  switch (Syntax) {
  case Instruction::OperandSyntax::Nary:
    for (unsigned I = 0; I < Arity; ++I)
      if ((I && Comma()) || Typed())
        return true;
    if (Lex.getKind() == tok::comma)
      return error("'" + OpName + "' takes " + pluralize(Arity, "operand"));
    return false;
  case Instruction::OperandSyntax::Binary: {
    // The second operand repeats the first operand's type rather than spelling
    // it again.
    MatcherOperand A;
    if (parseTypedOperand(A))
      return true;
    Ops.push_back(A);
    if (Comma())
      return true;
    MatcherOperand B;
    B.Ty = A.Ty;
    if (parseValue(B.Val) || parseOperandMetaFlags(B))
      return true;
    Ops.push_back(B);
    return false;
  }
  case Instruction::OperandSyntax::Cast: {
    if (Typed())
      return true;
    if (Lex.getKind() != tok::kw_to)
      return error("expected 'to' in conversion");
    next();
    // The destination is a bare type, not an operand of the instruction.
    MatcherOperand Dst;
    Dst.IsInstructionOperand = false;
    if (parseType(Dst.Ty, true))
      return true;
    Ops.push_back(Dst);
    return false;
  }
  case Instruction::OperandSyntax::Custom:
    break;
  }
  llvm_unreachable("custom operand syntax is not a shared archetype");
}

bool MIRParser::parseInstruction(Instruction *&Result) {
  LocTy Loc = Lex.getLoc();
  SmallString<16> ResultNameStorage;
  StringRef ResultName;
  if (Lex.getKind() == tok::LocalVar || Lex.getKind() == tok::LocalVarID) {
    if (Lex.getKind() == tok::LocalVar)
      ResultNameStorage.append(Lex.getStrVal().begin(), Lex.getStrVal().end());
    else
      Twine(Lex.getUIntVal()).toVector(ResultNameStorage);
    ResultName = ResultNameStorage;
    if (Instructions.count(ResultName))
      return error("duplicate instruction result '%" + ResultName + "'");
    next();
    if (expect(tok::equal, "expected '=' after instruction result"))
      return true;
  }
  if (!isOpcode(Lex.getKind())) {
    // Anything that is not a built-in matcher must name a composite one, and
    // matcher names are plain identifiers.
    if (Lex.getKind() == tok::Identifier) {
      StringRef OpName = Context.saveString(Lex.getStrVal());
      if (CompositeMatcher *CM = Context.getCompositeMatcher(OpName))
        return parseCompositeInstruction(Result, CM, OpName, ResultName, Loc);
    }
    return error("expected instruction matcher");
  }
  Instruction::InstructionID ID = instructionID(Lex.getKind());
  StringRef Op = Instruction::getOpcodeName(ID);
  next();
  MetaVariable *Capture = nullptr;
  if (parseInstructionCapture(Capture))
    return true;
  SmallVector<MetaFlag *, 4> MFlags;
  if (parseInstructionMetaFlags(MFlags, Instruction::isCommutative(ID), Op))
    return true;
  SmallVector<InstructionFlag, 8> Flags;
  if (parseSemanticFlags(
          [ID](InstructionFlag::FlagID F) {
            return (Instruction::getSupportedFlags(ID) &
                    Instruction::mask(F)) != 0;
          },
          Op, Flags))
    return true;
  SmallVector<MatcherOperand, 8> Ops;
  auto Typed = [&](MetaType E = MetaType::Value) -> bool {
    MatcherOperand O;
    if (parseTypedOperand(O, E))
      return true;
    Ops.push_back(O);
    return false;
  };
  auto TypeOnly = [&]() -> bool {
    MatcherOperand O;
    O.IsInstructionOperand = false;
    if (parseType(O.Ty, true))
      return true;
    Ops.push_back(O);
    return false;
  };
  auto Comma = [&]() {
    return expect(tok::comma, "expected ',' between operands");
  };

  switch (Instruction::getOperandSyntax(ID)) {
  case Instruction::OperandSyntax::Nary:
  case Instruction::OperandSyntax::Binary:
  case Instruction::OperandSyntax::Cast:
    if (parseArchetypeOperands(Instruction::getOperandSyntax(ID),
                               Instruction::getOperandArity(ID), Op, Ops))
      return true;
    break;
  case Instruction::OperandSyntax::Custom:
    switch (ID) {
    case Instruction::I_extractelement:
      if (Typed() || Comma() || Typed(MetaType::Nat))
        return true;
      break;
    case Instruction::I_extractvalue:
    case Instruction::I_insertvalue:
      if (Typed())
        return true;
      if (ID == Instruction::I_insertvalue && (Comma() || Typed()))
        return true;
      while (consume(tok::comma)) {
        MatcherOperand O;
        if (Lex.getKind() == tok::dotdotdot) {
          if (parseArrayCapture(O, false))
            return true;
          Ops.push_back(O);
          break;
        }
        if (parseValue(O.Val, MetaType::Nat))
          return true;
        Ops.push_back(O);
      }
      break;
    case Instruction::I_alloca:
      if (TypeOnly())
        return true;
      while (consume(tok::comma)) {
        if (Lex.getKind() == tok::kw_align ||
            Lex.getKind() == tok::kw_addrspace) {
          bool AS = Lex.getKind() == tok::kw_addrspace;
          next();
          if (AS && expect(tok::lparen, "expected '(' after addrspace"))
            return true;
          MatcherOperand O;
          O.IsInstructionOperand = false;
          O.Key = AS ? MatcherOperand::AddressSpace : MatcherOperand::Alignment;
          if (parseValue(O.Val, MetaType::Nat))
            return true;
          Ops.push_back(O);
          if (AS && expect(tok::rparen, "expected ')' after addrspace"))
            return true;
        } else if (Typed(MetaType::Nat))
          return true;
      }
      break;
    case Instruction::I_load:
      if (TypeOnly() || Comma() || Typed())
        return true;
      if (consume(tok::comma)) {
        if (Lex.getKind() != tok::kw_align)
          return error("expected 'align'");
        next();
        MatcherOperand O;
        O.IsInstructionOperand = false;
        O.Key = MatcherOperand::Alignment;
        if (parseValue(O.Val, MetaType::Nat))
          return true;
        Ops.push_back(O);
      }
      break;
    case Instruction::I_store:
      if (Typed() || Comma() || Typed())
        return true;
      if (consume(tok::comma)) {
        if (Lex.getKind() != tok::kw_align)
          return error("expected 'align'");
        next();
        MatcherOperand O;
        O.IsInstructionOperand = false;
        O.Key = MatcherOperand::Alignment;
        if (parseValue(O.Val, MetaType::Nat))
          return true;
        Ops.push_back(O);
      }
      break;
    case Instruction::I_getelementptr:
      if (Lex.getKind() == tok::kw_inrange) {
        next();
        if (expect(tok::lparen, "expected '(' after inrange"))
          return true;
        MatcherOperand L, U;
        L.IsInstructionOperand = false;
        U.IsInstructionOperand = false;
        L.Key = MatcherOperand::InRangeLower;
        U.Key = MatcherOperand::InRangeUpper;
        if (parseValue(L.Val, MetaType::Nat) || Comma() ||
            parseValue(U.Val, MetaType::Nat) ||
            expect(tok::rparen, "expected ')' after inrange"))
          return true;
        Ops.push_back(L);
        Ops.push_back(U);
      }
      if (TypeOnly() || Comma() || Typed())
        return true;
      while (consume(tok::comma)) {
        MatcherOperand O;
        if (Lex.getKind() == tok::dotdotdot) {
          if (parseArrayCapture(O, true))
            return true;
          Ops.push_back(O);
          break;
        }
        if (parseTypedOperand(O))
          return true;
        Ops.push_back(O);
      }
      break;
    case Instruction::I_ret: {
      MatcherOperand O;
      if (parseType(O.Ty, true))
        return true;
      if (O.Ty->getTypeID() == Type::VoidTyID)
        O.IsInstructionOperand = false;
      else if (parseValue(O.Val))
        return true;
      Ops.push_back(O);
      break;
    }
    case Instruction::I_br: {
      MatcherOperand First;
      if (parseType(First.Ty))
        return true;
      bool IsLabel = First.Ty->getTypeID() == Type::LabelTyID;
      bool IsBool = isa<IntegerType>(First.Ty) &&
                    cast<IntegerType>(First.Ty)->getNumBits() == 1;
      if (parseValue(First.Val, IsLabel  ? MetaType::BasicBlock
                                : IsBool ? MetaType::Bool
                                         : MetaType::Value))
        return true;
      Ops.push_back(First);
      if (!IsLabel) {
        if (Comma() || Typed(MetaType::BasicBlock) || Comma() ||
            Typed(MetaType::BasicBlock))
          return true;
      }
      break;
    }
    case Instruction::I_icmp:
    case Instruction::I_fcmp: {
      MatcherOperand Pred;
      Pred.IsInstructionOperand = false;
      Pred.Key = MatcherOperand::Predicate;
      if (Lex.getKind() == tok::MetaVar) {
        MetaVariable *M =
            getMeta(Lex.getStrVal(), MetaType::CmpPredicate, Lex.getLoc());
        if (!M)
          return true;
        Pred.Val = M;
        next();
      } else if (std::optional<KeywordConstant::KeywordID> Predicate =
                     predicateKeywordID(Lex.getKind())) {
        Pred.Val = KeywordConstant::create(
            Context, *Predicate, SourceRange{Lex.getLoc(), Lex.getLoc()});
        next();
      } else
        return error("expected comparison predicate");
      Ops.push_back(Pred);
      MatcherOperand A;
      if (parseTypedOperand(A))
        return true;
      Ops.push_back(A);
      if (Comma())
        return true;
      MatcherOperand B;
      B.Ty = A.Ty;
      if (parseValue(B.Val))
        return true;
      if (parseOperandMetaFlags(B))
        return true;
      Ops.push_back(B);
      break;
    }
    case Instruction::I_phi: {
      Type *Ty = nullptr;
      if (parseType(Ty))
        return true;
      do {
        if (expect(tok::lsquare, "expected '[' in phi"))
          return true;
        MatcherOperand V;
        V.Ty = Ty;
        if (parseValue(V.Val) || Comma())
          return true;
        Ops.push_back(V);
        MatcherOperand BB;
        if (parseValue(BB.Val, MetaType::BasicBlock) ||
            expect(tok::rsquare, "expected ']' in phi"))
          return true;
        Ops.push_back(BB);
      } while (consume(tok::comma));
      break;
    }
    case Instruction::I_call:
      if (TypeOnly())
        return true;
      {
        MatcherOperand Callee;
        if (parseValue(Callee.Val, MetaType::Function))
          return true;
        Ops.push_back(Callee);
      }
      if (expect(tok::lparen, "expected '(' in call"))
        return true;
      if (Lex.getKind() != tok::rparen) {
        do {
          MatcherOperand A;
          if (Lex.getKind() == tok::dotdotdot) {
            if (parseArrayCapture(A, true))
              return true;
            Ops.push_back(A);
            break;
          }
          if (parseTypedOperand(A))
            return true;
          Ops.push_back(A);
        } while (consume(tok::comma));
      }
      if (expect(tok::rparen, "expected ')' after call arguments"))
        return true;
      break;
    default:
      return error("instruction parser is not implemented for '" + Op + "'");
    }
    break;
  }

  for (MetaFlag *F : MFlags) {
    if (F->getMetaFlagID() != MetaFlag::MF_o)
      continue;
    uint64_t Index = 0;
    if (!F->getArguments().empty()) {
      if (F->getArguments().size() != 1 ||
          F->getArguments()[0].K != MetaFlag::Argument::Integer ||
          F->getArguments()[0].IntegerValue < 0)
        return Lex.ParseError(F->getSourceRange().Begin,
                              "metaflag ':o' expects one non-negative operand "
                              "index");
      Index = F->getArguments()[0].IntegerValue;
    }
    uint64_t OperandCount = 0;
    bool HasArray = false;
    for (const MatcherOperand &Operand : Ops) {
      if (!Operand.IsInstructionOperand)
        continue;
      HasArray |= Operand.IsArray;
      if (!Operand.IsArray)
        ++OperandCount;
    }
    if (!HasArray && Index >= OperandCount)
      return Lex.ParseError(F->getSourceRange().Begin,
                            "metaflag ':o' operand index is out of range");
  }
  for (MetaFlag *F : MFlags) {
    if (F->getMetaFlagID() == MetaFlag::MF_c && ID == Instruction::I_call) {
      // Operands are the return type, the callee and the arguments.
      unsigned ArgumentCount = Ops.size() >= 2 ? Ops.size() - 2 : 0;
      bool HasArray =
          any_of(Ops, [](const MatcherOperand &O) { return O.IsArray; });
      if (ArgumentCount != 2 || HasArray)
        return Lex.ParseError(F->getSourceRange().Begin,
                              "metaflag ':c' requires a call with exactly two "
                              "arguments");
    }
  }
  bool SeenKeyedOperand[MatcherOperand::NumKeyedOperandKinds] = {};
  for (const MatcherOperand &Operand : Ops) {
    if (Operand.Key == MatcherOperand::NotKeyed)
      continue;
    if (SeenKeyedOperand[Operand.Key])
      return Lex.ParseError(Operand.Val->getSourceRange().Begin,
                            "duplicate keyed operand");
    SeenKeyedOperand[Operand.Key] = true;
  }
  Result = Instruction::create(Context, ID, ResultName, Flags, MFlags, Ops,
                               Capture, SourceRange{Loc, Lex.getLoc()},
                               CurrentBlock, Settings);
  if (!ResultName.empty()) {
    if (MetaVariables.count(ResultName)) {
      MetaVariable *SameName = MetaVariables[ResultName];
      bool IsThisCapture =
          SameName == Capture || any_of(Flags, [&](const InstructionFlag &F) {
            return F.Capture == SameName;
          });
      if (!IsThisCapture)
        Lex.Warning(Loc, "local variable '%" + ResultName +
                             "' shares a name with meta variable '?" +
                             ResultName + "'");
    }
    Instructions[ResultName] = Result;
  }
  return false;
}

/// Parses the parameter list of a 'match' declaration. Its shape follows the
/// declared archetype, and each position is parsed with the same routines used
/// for pattern operands: a type position therefore accepts any type, whether it
/// leaves the type open ('?ty', 'i?bits') or fixes it ('i8', 'ptr').
bool MIRParser::parseMatchParameters(Instruction::OperandSyntax Syntax,
                                     SmallVectorImpl<ParameterDef> &Result) {
  auto typeParameter = [&]() -> bool {
    ParameterDef P;
    LocTy Loc = Lex.getLoc();
    P.Range = SourceRange{Loc, Loc};
    P.IsType = true;
    if (parseType(P.Ty))
      return true;
    // A name is bound only where the declaration leaves the type open; a
    // concrete type is recorded in P.Ty and matched against the caller's.
    if (auto *MetaTy = dyn_cast<MetaIRType>(P.Ty))
      P.Name = Context.saveString(MetaTy->getVariable()->getName());
    else if (auto *MetaInt = dyn_cast<MetaIntegerType>(P.Ty))
      if (MetaVariable *BitWidth = MetaInt->getBitWidthVariable())
        P.Name = Context.saveString(BitWidth->getName());
    Result.push_back(std::move(P));
    return false;
  };
  auto operandParameter = [&]() -> bool {
    if (Lex.getKind() != tok::MetaVar)
      return error("expected operand meta variable in parameter list");
    ParameterDef P;
    LocTy Loc = Lex.getLoc();
    P.Range = SourceRange{Loc, Loc};
    P.Name = Context.saveString(Lex.getStrVal());
    Result.push_back(std::move(P));
    next();
    return false;
  };
  auto comma = [&]() -> bool {
    return expect(tok::comma, "expected ',' between operand parameters");
  };

  switch (Syntax) {
  case Instruction::OperandSyntax::Nary:
    // Any number of individually typed operands; the count becomes the
    // matcher's arity.
    if (Lex.getKind() == tok::rparen)
      return error("'Nary' matcher needs at least one operand parameter");
    do {
      if (typeParameter() || operandParameter())
        return true;
    } while (consume(tok::comma));
    return false;
  case Instruction::OperandSyntax::Binary:
    return typeParameter() || operandParameter() || comma() ||
           operandParameter();
  case Instruction::OperandSyntax::Cast:
    return typeParameter() || operandParameter() ||
           expect(tok::kw_to, "expected 'to' before the result type") ||
           typeParameter();
  case Instruction::OperandSyntax::Custom:
    break;
  }
  return error("unsupported archetype in match declaration");
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
  LocTy NameLoc = Lex.getLoc();
  if (Context.getConstraintDef(Name))
    return Lex.ParseError(NameLoc, "redefinition of constraint '" + Name + "'");
  next();
  if (expect(tok::lparen, "expected '(' after constraint name"))
    return true;
  SmallVector<std::string, 4> Params;
  SmallVector<SourceRange, 4> ParamRanges;
  StringSet<> SeenParams;
  if (Lex.getKind() != tok::rparen) {
    do {
      // Parameters are meta variables, spelled '?name' as everywhere else.
      if (Lex.getKind() != tok::MetaVar)
        return error("expected '?' parameter meta variable");
      if (!SeenParams.insert(Lex.getStrVal()).second)
        return error("duplicate parameter '?" + Lex.getStrVal() +
                     "' in constraint declaration");
      LocTy ParamLoc = Lex.getLoc();
      Params.push_back(Lex.getStrVal());
      ParamRanges.push_back(SourceRange{ParamLoc, ParamLoc});
      next();
    } while (consume(tok::comma));
  }
  if (expect(tok::rparen, "expected ')' after parameters"))
    return true;
  skipNewlines();
  if (expect(tok::lbrace, "expected '{' before constraint body"))
    return true;
  skipNewlines();

  StringMap<MetaVariable *> OldMetaVariables = std::move(MetaVariables);
  MetaVariables.clear();
  SmallVector<MetaVariable *, 4> ParamVars;
  for (unsigned I = 0; I != Params.size(); ++I) {
    MetaVariable *M = MetaVariable::create(Context, Params[I],
                                           MetaType::Unknown, ParamRanges[I]);
    MetaVariables[Params[I]] = M;
    ParamVars.push_back(M);
  }

  Constraint *Body = nullptr;
  InDefinitionBody = true;
  bool Failed = parseConstraint(Body);
  InDefinitionBody = false;
  if (Failed)
    return true;
  skipNewlines();
  if (expect(tok::rbrace, "expected '}' after constraint body"))
    return true;

  MetaVariables = std::move(OldMetaVariables);

  SmallVector<StringRef, 4> ParamNames(Params.begin(), Params.end());
  auto *Def = ConstraintDef::create(Context, Name, ParamNames, ParamVars, Body);
  [[maybe_unused]] bool Registered = Context.registerConstraintDef(Def);
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
  // spelled like a keyword -- ':poison' and ':or' are built-in metaflags.
  if (Lex.getKind() != tok::MetaFlag)
    return error("expected ':' followed by a metaflag name");
  std::string Name = Lex.getStrVal();
  LocTy NameLoc = Lex.getLoc();
  if (MetaFlag::getMetaFlagID(Name) != MetaFlag::UnknownMetaFlag)
    return error("':" + Name +
                 "' is a built-in metaflag and cannot be redefined");
  if (Context.getMetaFlagDef(Name))
    return Lex.ParseError(NameLoc, "redefinition of metaflag ':" + Name + "'");
  next();
  if (expect(tok::lparen, "expected '(' after metaflag name"))
    return true;
  // The first parameter is the subject the flag is written on; any further ones
  // are its arguments, so ':f(1, 2)' is declared with three parameters.
  SmallVector<std::string, 2> Params;
  SmallVector<SourceRange, 2> ParamRanges;
  StringSet<> SeenParams;
  do {
    if (Lex.getKind() != tok::MetaVar)
      return error("expected '?' parameter meta variable");
    if (!SeenParams.insert(Lex.getStrVal()).second)
      return error("duplicate parameter '?" + Lex.getStrVal() +
                   "' in metaflag declaration");
    LocTy ParamLoc = Lex.getLoc();
    Params.push_back(Lex.getStrVal());
    ParamRanges.push_back(SourceRange{ParamLoc, ParamLoc});
    next();
  } while (consume(tok::comma));
  if (expect(tok::rparen, "expected ')' after parameters"))
    return true;
  skipNewlines();
  if (expect(tok::lbrace, "expected '{' before metaflag body"))
    return true;
  skipNewlines();

  StringMap<MetaVariable *> OldMetaVariables = std::move(MetaVariables);
  MetaVariables.clear();
  SmallVector<MetaVariable *, 2> ParamVars;
  for (unsigned I = 0; I != Params.size(); ++I) {
    MetaVariable *M = MetaVariable::create(Context, Params[I],
                                           MetaType::Unknown, ParamRanges[I]);
    MetaVariables[Params[I]] = M;
    ParamVars.push_back(M);
  }

  Constraint *Body = nullptr;
  InDefinitionBody = true;
  bool Failed = parseConstraint(Body);
  InDefinitionBody = false;
  if (Failed || requireBooleanConstraint(*Body))
    return true;
  skipNewlines();
  if (expect(tok::rbrace, "expected '}' after metaflag body"))
    return true;

  MetaVariables = std::move(OldMetaVariables);

  SmallVector<StringRef, 2> ParamNames(Params.begin(), Params.end());
  auto *Def = MetaFlagDef::create(Context, Name,
                                  static_cast<MetaFlag::Placement>(Placement),
                                  ParamNames, ParamVars, Body);
  [[maybe_unused]] bool Registered = Context.registerMetaFlagDef(Def);
  assert(Registered && "redefinition was checked above");
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
  bool IsCommutative = false;
  // 'match:c' declares a commutative matcher.
  if (Lex.getKind() == tok::MetaFlag) {
    if (Lex.getStrVal() != "c")
      return error("expected ':c' in match declaration");
    IsCommutative = true;
    next();
  }
  // A custom matcher's name must be an identifier, so that it can never
  // collide with a keyword or with a built-in matcher.
  if (Lex.getKind() != tok::Identifier)
    return error("expected matcher name in match declaration, which must be "
                 "an identifier and not a keyword");
  std::string MatcherName = Lex.getStrVal();
  if (Context.getCompositeMatcher(MatcherName))
    return error("redefinition of matcher '" + MatcherName + "'");
  next();

  if (expect(tok::lsquare, "expected '[' before supported flags"))
    return true;
  SmallVector<InstructionFlag::FlagID, 4> SupportedFlags;
  if (Lex.getKind() != tok::rsquare) {
    do {
      if (!isSemanticFlag(Lex.getKind()))
        return error("expected semantic flag name");
      SupportedFlags.push_back(semanticFlagID(Lex.getKind()));
      next();
    } while (consume(tok::comma));
  }
  if (expect(tok::rsquare, "expected ']' after supported flags"))
    return true;

  // 'Unary' is spelling sugar for a Nary matcher with exactly one operand.
  LocTy ArchetypeLoc = Lex.getLoc();
  Instruction::OperandSyntax Syntax;
  bool IsUnary = false;
  if (consume(tok::kw_Unary)) {
    Syntax = Instruction::OperandSyntax::Nary;
    IsUnary = true;
  } else if (consume(tok::kw_Nary))
    Syntax = Instruction::OperandSyntax::Nary;
  else if (consume(tok::kw_Binary))
    Syntax = Instruction::OperandSyntax::Binary;
  else if (consume(tok::kw_Cast))
    Syntax = Instruction::OperandSyntax::Cast;
  else
    return error("expected archetype 'Unary', 'Nary', 'Binary' or 'Cast'");

  if (IsCommutative && Syntax != Instruction::OperandSyntax::Binary)
    return error(
        "only 'Binary' matchers can be declared commutative with ':c'");

  if (expect(tok::lparen, "expected '(' before parameter list"))
    return true;
  // The parameter list forms its own scope: parseType interns the meta
  // variables it sees into the current scope and pattern, while each branch
  // below binds its own copies. Parse against scratch state so the enclosing
  // pattern does not acquire meta variables it never instantiates.
  SmallVector<ParameterDef, 4> Parameters;
  StringMap<MetaVariable *> OuterMetaVariables = std::move(MetaVariables);
  Pattern *OuterPattern = CurrentPattern;
  MetaVariables.clear();
  CurrentPattern = Pattern::create(Context);
  bool ParametersFailed = parseMatchParameters(Syntax, Parameters);
  MetaVariables = std::move(OuterMetaVariables);
  CurrentPattern = OuterPattern;
  if (ParametersFailed)
    return true;
  if (expect(tok::rparen, "expected ')' after parameter list"))
    return true;
  unsigned Arity =
      count_if(Parameters, [](const ParameterDef &P) { return !P.IsType; });
  if (IsUnary && Arity != 1)
    return Lex.ParseError(
        ArchetypeLoc, "'Unary' matcher takes exactly one operand parameter");

  // Operand parameters are distinct values. A type parameter may repeat (so
  // several operands can share a type), but one name cannot denote both a
  // type and an operand.
  StringSet<> TypeNames, OperandNames;
  for (const ParameterDef &P : Parameters)
    if (P.IsType && !P.Name.empty())
      TypeNames.insert(P.Name);
  for (const ParameterDef &P : Parameters) {
    if (P.IsType || P.Name.empty())
      continue;
    if (!OperandNames.insert(P.Name).second || TypeNames.contains(P.Name))
      return Lex.ParseError(P.Range.Begin, "duplicate parameter '?" + P.Name +
                                               "' in match declaration");
  }

  skipNewlines();

  SmallVector<CompositeMatcher::Branch, 2> Branches;
  // Storage the branches refer to until CompositeMatcher::create copies it.
  std::deque<SmallVector<std::pair<InstructionFlag::FlagID, bool>, 2>>
      FlagStorage;
  std::deque<SmallVector<MetaVariable *, 4>> ParameterVarStorage;
  do {
    skipNewlines();

    auto &BranchFlags = FlagStorage.emplace_back();
    if (Lex.getKind() == tok::lsquare) {
      next();
      if (Lex.getKind() != tok::rsquare) {
        do {
          if (!isSemanticFlag(Lex.getKind()))
            return error("expected semantic flag name");
          InstructionFlag::FlagID FlagID = semanticFlagID(Lex.getKind());
          if (!llvm::is_contained(SupportedFlags, FlagID))
            return error("flag '" + InstructionFlag::getName(FlagID) +
                         "' is not declared in matcher's supported flags");
          next();
          bool Val = true;
          if (consume(tok::equal)) {
            if (Lex.getKind() == tok::kw_true) {
              Val = true;
              next();
            } else if (Lex.getKind() == tok::kw_false) {
              Val = false;
              next();
            } else {
              return error("expected 'true' or 'false' after '='");
            }
          }
          BranchFlags.push_back({FlagID, Val});
        } while (consume(tok::comma));
      }
      if (expect(tok::rsquare, "expected ']' after branch flags"))
        return true;
      skipNewlines();
    }

    if (expect(tok::lbrace, "expected '{' to start match branch"))
      return true;
    skipNewlines();

    Pattern *OldPattern = CurrentPattern;
    MetaVariable *OldBlock = CurrentBlock;
    StringMap<Instruction *> OldInstructions = std::move(Instructions);
    StringMap<MetaVariable *> OldMetaVariables = std::move(MetaVariables);

    // A branch is a closed scope: a matcher is expanded at each of its uses, so
    // the only names its body may refer to are its parameters. Leaving the
    // enclosing pattern's locals and meta variables visible would let a body
    // capture them and silently tie the matcher to one pattern. The body is
    // parsed into a scratch pattern exactly like a top-level pattern body.
    CurrentPattern = Pattern::create(Context);
    CurrentBlock = nullptr;
    Instructions.clear();
    MetaVariables.clear();
    auto &ParameterVars = ParameterVarStorage.emplace_back();
    for (const ParameterDef &P : Parameters) {
      if (P.Name.empty()) {
        ParameterVars.push_back(nullptr);
        continue;
      }
      // A type parameter may be repeated to give operands the same type.
      MetaVariable *&M = MetaVariables[P.Name];
      if (!M)
        M = MetaVariable::create(Context, P.Name, MetaType::Unknown, P.Range);
      ParameterVars.push_back(M);
    }

    // Settings written in a body override the use site; anything the body
    // leaves alone is inherited when the branch is inlined. Starting from a
    // default here is what makes that distinction: it keeps the declaration
    // from capturing whatever happened to be active around it.
    PatternSettings OldSettings = Settings;
    Settings = PatternSettings();

    while (Lex.getKind() != tok::rbrace && Lex.getKind() != tok::Eof)
      if (parseBodyLine(tok::rbrace))
        return true;
    ArrayRef<Instruction *> BranchInstructions =
        CurrentPattern->getInstructions();
    ArrayRef<Constraint *> BranchConstraints = CurrentPattern->getConstraints();

    LocTy BranchEnd = Lex.getLoc();
    if (expect(tok::rbrace, "expected '}' to end match branch"))
      return true;

    if (BranchInstructions.empty())
      return Lex.ParseError(
          BranchEnd, "match branch must contain at least one instruction");

    // The branch's result is '%ret', or else its last instruction.
    Instruction *Root = nullptr;
    for (Instruction *I : BranchInstructions) {
      if (I->getResultName() != "ret")
        continue;
      if (Root)
        return Lex.ParseError(BranchEnd,
                              "multiple '%ret' instructions in match branch");
      Root = I;
    }
    if (!Root)
      Root = BranchInstructions.back();

    CompositeMatcher::Branch StoredBranch;
    // CompositeMatcher::create copies the arrays into the context.
    StoredBranch.Instructions = BranchInstructions;
    StoredBranch.Constraints = BranchConstraints;
    StoredBranch.FixedFlags = BranchFlags;
    StoredBranch.ParameterVars = ParameterVars;
    StoredBranch.LocalVariables = CurrentPattern->getMetaVariables();
    StoredBranch.Root = Root;
    Branches.push_back(StoredBranch);

    CurrentPattern = OldPattern;
    CurrentBlock = OldBlock;
    Instructions = std::move(OldInstructions);
    MetaVariables = std::move(OldMetaVariables);
    Settings = OldSettings;

    // Another branch is introduced by 'or' followed by its '[flags]' or '{'.
    // Any other 'or' is an instruction of the enclosing pattern.
  } while (consumeBranchSeparator());

  auto *CM = CompositeMatcher::create(Context, MatcherName, IsCommutative,
                                      SupportedFlags, Syntax, Arity, Parameters,
                                      Branches);
  [[maybe_unused]] bool Registered = Context.registerCompositeMatcher(CM);
  assert(Registered && "redefinition was checked above");
  return false;
}

bool MIRParser::parseCompositeInstruction(Instruction *&Result,
                                          CompositeMatcher *CM,
                                          StringRef OpName,
                                          StringRef ResultName, LocTy Loc) {
  next();
  MetaVariable *Capture = nullptr;
  if (parseInstructionCapture(Capture))
    return true;
  SmallVector<MetaFlag *, 4> MFlags;
  if (parseInstructionMetaFlags(MFlags, CM->isCommutative(), OpName))
    return true;
  SmallVector<InstructionFlag, 8> Flags;
  if (parseSemanticFlags(
          [CM](InstructionFlag::FlagID F) { return CM->hasSupportedFlag(F); },
          OpName, Flags))
    return true;

  // A composite matcher declares one of the shared archetypes, so its operands
  // are spelled exactly like a built-in matcher's.
  SmallVector<MatcherOperand, 8> Ops;
  if (CM->getSyntax() == Instruction::OperandSyntax::Custom)
    return error("custom syntax not supported for composite matchers");
  if (parseArchetypeOperands(CM->getSyntax(), CM->getArity(), OpName, Ops))
    return true;

  SourceRange Range{Loc, Lex.getLoc()};
  Result =
      Instruction::createComposite(Context, ResultName, CM, Flags, MFlags, Ops,
                                   Capture, Range, CurrentBlock, Settings);
  if (!ResultName.empty())
    Instructions[ResultName] = Result;
  return false;
}

} // namespace metaphir
} // namespace llvm
