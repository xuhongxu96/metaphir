//===- MIRParser.ParseInstruction.cpp - Instructions, types and values ----===//
//
// Instruction matchers: result names, captures, flags and metaflags, the
// operand grammars of built-in and composite matchers, types and values.
//
//===----------------------------------------------------------------------===//

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

std::optional<InstructionFlag::FlagID> MIRParser::getSemanticFlag(tok::Kind K) {
  switch (K) {
#define MIR_FLAG_TOKEN_KIND(Name)                                              \
  case tok::kw_##Name:                                                         \
    return InstructionFlag::F_##Name;
#include "metaphir/IR/Flags.def"
  default:
    return std::nullopt;
  }
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
  while (true) {
    LocTy Loc = Lex.getLoc();
    bool Negated = consume(tok::exclaim);
    std::optional<InstructionFlag::FlagID> Flag =
        getSemanticFlag(Lex.getKind());
    if (!Flag) {
      if (Negated)
        return error("expected a flag after '!'");
      return false;
    }
    InstructionFlag::FlagID FlagID = *Flag;
    StringRef FlagName = InstructionFlag::getName(FlagID);
    if (!IsSupported(FlagID))
      return Lex.ParseError(Loc, "flag '" + FlagName + "' is not valid for '" +
                                     OwnerName + "'");
    if (any_of(Result,
               [FlagID](const InstructionFlag &F) { return F.ID == FlagID; }))
      return Lex.ParseError(Loc,
                            "flag '" + FlagName + "' is written more than once");
    next();
    MetaVariable *Capture = nullptr;
    if (Lex.getKind() == tok::MetaCaptureVar) {
      if (Negated)
        return error("a negated flag cannot be captured");
      StringRef CaptureName = Lex.getStrVal();
      if (CaptureName == "_")
        return error("flag '" + FlagName +
                     "' cannot be captured by '?_'; omit the flag, which "
                     "matches whether or not it is present");
      Capture = getMeta(CaptureName, MetaType::Bool, Lex.getLoc());
      if (!Capture)
        return true;
      next();
    }
    Result.push_back({FlagID, Capture, Negated});
  }
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
  return parseBaseType(Result, AllowVoid) || parseTypeSuffixes(Result);
}

bool MIRParser::parseBaseType(Type *&Result, bool AllowVoid) {
  LocTy Loc = Lex.getLoc();
  switch (Lex.getKind()) {
  case tok::Type:
    Result = Lex.getTyVal();
    next();
    return false;
  case tok::MetaIntVar: {
    MetaVariable *Width = getMeta(Lex.getStrVal(), MetaType::Nat, Loc);
    if (!Width)
      return true;
    Result =
        MetaIntegerType::get(Context, Width, Lex.getMetaIntPrefix() == 'b');
    next();
    return false;
  }
  case tok::MetaVar: {
    MetaVariable *M = getMeta(Lex.getStrVal(), MetaType::Type, Loc);
    if (!M)
      return true;
    Result = MetaIRType::get(Context, M);
    next();
    return false;
  }
  case tok::kw_ptr:
    return parsePointerType(Result);
  case tok::lsquare:
    next();
    return parseSequenceType(Result, /*IsVector=*/false);
  case tok::lbrace:
    next();
    return parseStructType(Result, /*Packed=*/false);
  case tok::less:
    next();
    if (consume(tok::lbrace))
      return parseStructType(Result, /*Packed=*/true);
    return parseSequenceType(Result, /*IsVector=*/true);
  default:
    break;
  }
  std::optional<Type::TypeID> ID = primitiveTypeID(Lex.getKind());
  if (!ID)
    return error("expected type");
  if (*ID == Type::VoidTyID && !AllowVoid)
    return error("void type is not allowed here");
  Result = Type::get(Context, *ID);
  next();
  return false;
}

bool MIRParser::parsePointerType(Type *&Result) {
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
  return false;
}

bool MIRParser::parseSequenceType(Type *&Result, bool IsVector) {
  StringRef What = IsVector ? "vector" : "array";
  bool Scalable = false;
  if (IsVector && consume(tok::kw_vscale)) {
    Scalable = true;
    if (!consume(tok::kw_x))
      return error("expected 'x' after vscale");
  }
  uint64_t Count = 0;
  MetaVariable *CountVar = nullptr;
  if (Lex.getKind() == tok::APSInt) {
    if (Lex.getAPSIntVal().isNegative() ||
        Lex.getAPSIntVal().getActiveBits() > 64)
      return error("invalid " + What + " size");
    Count = Lex.getAPSIntVal().getZExtValue();
  } else if (Lex.getKind() == tok::MetaVar) {
    CountVar = getMeta(Lex.getStrVal(), MetaType::Nat, Lex.getLoc());
    if (!CountVar)
      return true;
  } else {
    return error("expected " + What + " size (got " + describeToken() + ")");
  }
  next();
  if (!consume(tok::kw_x))
    return error("expected 'x' after " + What + " size");
  Type *Element = nullptr;
  if (parseType(Element) || expect(IsVector ? tok::greater : tok::rsquare,
                                   "expected '" + Twine(IsVector ? '>' : ']') +
                                       "' after " + What + " type"))
    return true;
  Result = IsVector ? static_cast<Type *>(VectorType::get(
                          Context, Scalable, Element, Count, CountVar))
                    : ArrayType::get(Context, Element, Count, CountVar);
  return false;
}

bool MIRParser::parseStructType(Type *&Result, bool Packed) {
  SmallVector<Type *, 8> Elements;
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
  Result = StructType::get(Context, Elements, Packed);
  return false;
}

bool MIRParser::parseTypeSuffixes(Type *&Result) {
  while (true) {
    if (consume(tok::star)) {
      Result = PointerType::get(Context, Result);
      continue;
    }
    if (!consume(tok::lparen))
      return false;
    SmallVector<Type *, 8> Parameters;
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
    Result = FunctionType::get(Context, Result, Parameters, VarArg);
  }
}

bool MIRParser::parseValue(Value *&Result, MetaType Expected) {
  LocTy Loc = Lex.getLoc();
  SourceRange Range{Loc, Loc};
  switch (Lex.getKind()) {
  case tok::MetaVar: {
    MetaVariable *M = getMeta(Lex.getStrVal(), Expected, Loc);
    if (!M)
      return true;
    Result = M;
    next();
    return false;
  }
  case tok::LocalVar:
  case tok::LocalVarID: {
    SmallString<16> NameStorage;
    StringRef Name = Lex.getKind() == tok::LocalVar
                         ? StringRef(Lex.getStrVal())
                         : Twine(Lex.getUIntVal()).toStringRef(NameStorage);
    // A block written as a local ('label %bb') is a block meta variable.
    if (Expected == MetaType::BasicBlock) {
      Result = getMeta(Name, MetaType::BasicBlock, Loc);
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
    // '@llvm.?id': the lexer yields this prefix only when a '?' follows.
    next();
    if (Lex.getKind() != tok::MetaVar)
      return error("expected intrinsic ID meta variable");
    Result = getMeta(Lex.getStrVal(), MetaType::IntrinsicID, Lex.getLoc());
    if (!Result)
      return true;
    next();
    return false;
  }
  case tok::GlobalVar:
  case tok::GlobalID: {
    // The name has to outlive the lexer's buffer, which next() overwrites.
    SmallString<32> Name;
    if (Lex.getKind() == tok::GlobalVar)
      Name = Lex.getStrVal();
    else
      Twine(Lex.getUIntVal()).toVector(Name);
    next();
    Result = GlobalValue::create(Context, Name, Range);
    return false;
  }
  case tok::APSInt:
    Result = IntegerConstant::create(Context, Lex.getAPSIntVal(), Range);
    next();
    return false;
  case tok::APFloat:
    Result = FloatingConstant::create(Context, Lex.getAPFloatVal(), Range);
    next();
    return false;
  case tok::kw_true:
  case tok::kw_false:
    Result = IntegerConstant::create(
        Context,
        APSInt(APInt(1, Lex.getKind() == tok::kw_true), /*isUnsigned=*/true),
        Range);
    next();
    return false;
#define MIR_CONSTANT_KEYWORD(ID, Kind)                                         \
  case tok::kw_##Kind:                                                         \
    Result = KeywordConstant::create(Context, KeywordConstant::K_##ID, Range); \
    next();                                                                    \
    return false;
#include "metaphir/Parser/MIRKeywords.def"
  case tok::lsquare:
  case tok::lbrace:
  case tok::less:
    return parseAggregateConstant(Result);
  default:
    return error("expected value");
  }
}

bool MIRParser::parseAggregateConstant(Value *&Result) {
  LocTy Loc = Lex.getLoc();
  tok::Kind Open = Lex.getKind();
  tok::Kind Close = Open == tok::lsquare  ? tok::rsquare
                    : Open == tok::lbrace ? tok::rbrace
                                          : tok::greater;
  AggregateConstant::Delimiter Delimiter =
      Open == tok::lsquare ? AggregateConstant::Square
      : Open == tok::less  ? AggregateConstant::Angle
                           : AggregateConstant::Brace;
  next();
  SmallVector<Type *, 8> Types;
  SmallVector<Value *, 8> Values;
  if (parseCommaList(Close,
                     [&] {
                       return parseType(Types.emplace_back()) ||
                              parseValue(Values.emplace_back());
                     }) ||
      expect(Close, "expected end of aggregate constant"))
    return true;
  Result = AggregateConstant::create(Context, Types, Values, Delimiter,
                                     SourceRange{Loc, Loc});
  return false;
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

bool MIRParser::parseInstructionResult(SmallVectorImpl<char> &Name) {
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

bool MIRParser::parseInstruction(Instruction *&Result) {
  LocTy Loc = Lex.getLoc();
  SmallString<16> ResultNameStorage;
  if (parseInstructionResult(ResultNameStorage))
    return true;
  StringRef ResultName = ResultNameStorage;

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
  SmallVector<MetaFlag *, 4> MFlags;
  SmallVector<InstructionFlag, 8> Flags;
  if (parseInstructionCapture(Capture) ||
      parseInstructionMetaFlags(MFlags, Instruction::isCommutative(ID), Op) ||
      parseSemanticFlags(
          [ID](InstructionFlag::FlagID F) {
            return (Instruction::getSupportedFlags(ID) &
                    Instruction::mask(F)) != 0;
          },
          Op, Flags))
    return true;

  SmallVector<MatcherOperand, 8> Ops;
  Instruction::OperandSyntax Syntax = Instruction::getOperandSyntax(ID);
  if (Syntax == Instruction::OperandSyntax::Custom
          ? parseCustomOperands(ID, Ops)
          : parseArchetypeOperands(Syntax, Instruction::getOperandArity(ID), Op,
                                   Ops))
    return true;
  if (validateInstruction(ID, MFlags, Ops))
    return true;

  Result = Instruction::create(Context, ID, ResultName, Flags, MFlags, Ops,
                               Capture, SourceRange{Loc, Lex.getPrevTokEnd()},
                               CurrentBlock, Settings);
  if (!ResultName.empty()) {
    auto It = MetaVariables.find(ResultName);
    if (It != MetaVariables.end()) {
      MetaVariable *SameName = It->second;
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

bool MIRParser::parseOperand(SmallVectorImpl<MatcherOperand> &Ops,
                             MetaType Expected) {
  MatcherOperand O;
  if (parseTypedOperand(O, Expected))
    return true;
  Ops.push_back(O);
  return false;
}

bool MIRParser::parseTypeOperand(SmallVectorImpl<MatcherOperand> &Ops) {
  MatcherOperand O;
  O.IsInstructionOperand = false;
  if (parseType(O.Ty, /*AllowVoid=*/true))
    return true;
  Ops.push_back(O);
  return false;
}

bool MIRParser::parseKeyedOperand(SmallVectorImpl<MatcherOperand> &Ops,
                                  MatcherOperand::KeyedOperandKind Key,
                                  MetaType Expected) {
  MatcherOperand O;
  O.IsInstructionOperand = false;
  O.Key = Key;
  if (parseValue(O.Val, Expected))
    return true;
  Ops.push_back(O);
  return false;
}

bool MIRParser::parseOperandComma() {
  return expect(tok::comma, "expected ',' between operands");
}

bool MIRParser::parseAlign(SmallVectorImpl<MatcherOperand> &Ops) {
  if (!consume(tok::comma))
    return false;
  if (!consume(tok::kw_align))
    return error("expected 'align'");
  return parseKeyedOperand(Ops, MatcherOperand::Alignment, MetaType::Nat);
}

bool MIRParser::parseTrailingOperands(SmallVectorImpl<MatcherOperand> &Ops,
                                      TrailingOperandKind Kind) {
  while (consume(tok::comma)) {
    MatcherOperand O;
    // An array capture takes all remaining operands.
    if (Lex.getKind() == tok::dotdotdot) {
      if (parseArrayCapture(O, /*WithTypes=*/Kind != NatIndices))
        return true;
      Ops.push_back(O);
      return false;
    }
    if (Kind == NatIndices ? parseValue(O.Val, MetaType::Nat)
                           : parseTypedOperand(O))
      return true;
    Ops.push_back(O);
  }
  return false;
}

bool MIRParser::parseCustomOperands(Instruction::InstructionID ID,
                                    SmallVectorImpl<MatcherOperand> &Ops) {
  switch (ID) {
  case Instruction::I_extractelement:
    return parseOperand(Ops) || parseOperandComma() ||
           parseOperand(Ops, MetaType::Nat);
  case Instruction::I_extractvalue:
    return parseOperand(Ops) || parseTrailingOperands(Ops, NatIndices);
  case Instruction::I_insertvalue:
    return parseOperand(Ops) || parseOperandComma() || parseOperand(Ops) ||
           parseTrailingOperands(Ops, NatIndices);
  case Instruction::I_alloca:
    return parseAllocaOperands(Ops);
  case Instruction::I_load:
    return parseTypeOperand(Ops) || parseOperandComma() || parseOperand(Ops) ||
           parseAlign(Ops);
  case Instruction::I_store:
    return parseOperand(Ops) || parseOperandComma() || parseOperand(Ops) ||
           parseAlign(Ops);
  case Instruction::I_getelementptr:
    return parseGEPOperands(Ops);
  case Instruction::I_ret: {
    MatcherOperand O;
    if (parseType(O.Ty, /*AllowVoid=*/true))
      return true;
    if (O.Ty->getTypeID() == Type::VoidTyID)
      O.IsInstructionOperand = false;
    else if (parseValue(O.Val))
      return true;
    Ops.push_back(O);
    return false;
  }
  case Instruction::I_br:
    return parseBranchOperands(Ops);
  case Instruction::I_icmp:
  case Instruction::I_fcmp:
    return parseCompareOperands(Ops);
  case Instruction::I_phi:
    return parsePhiOperands(Ops);
  case Instruction::I_call:
    return parseCallOperands(Ops);
  default:
    return error("instruction parser is not implemented for '" +
                 Instruction::getOpcodeName(ID) + "'");
  }
}

bool MIRParser::parseAllocaOperands(SmallVectorImpl<MatcherOperand> &Ops) {
  if (parseTypeOperand(Ops))
    return true;
  while (consume(tok::comma)) {
    if (consume(tok::kw_align)) {
      if (parseKeyedOperand(Ops, MatcherOperand::Alignment, MetaType::Nat))
        return true;
    } else if (consume(tok::kw_addrspace)) {
      if (expect(tok::lparen, "expected '(' after 'addrspace'") ||
          parseKeyedOperand(Ops, MatcherOperand::AddressSpace, MetaType::Nat) ||
          expect(tok::rparen, "expected ')' after 'addrspace'"))
        return true;
    } else if (parseOperand(Ops, MetaType::Nat)) {
      return true;
    }
  }
  return false;
}

bool MIRParser::parseGEPOperands(SmallVectorImpl<MatcherOperand> &Ops) {
  if (consume(tok::kw_inrange)) {
    if (expect(tok::lparen, "expected '(' after 'inrange'") ||
        parseKeyedOperand(Ops, MatcherOperand::InRangeLower, MetaType::Nat) ||
        parseOperandComma() ||
        parseKeyedOperand(Ops, MatcherOperand::InRangeUpper, MetaType::Nat) ||
        expect(tok::rparen, "expected ')' after 'inrange'"))
      return true;
  }
  return parseTypeOperand(Ops) || parseOperandComma() || parseOperand(Ops) ||
         parseTrailingOperands(Ops, TypedOperands);
}

bool MIRParser::parseBranchOperands(SmallVectorImpl<MatcherOperand> &Ops) {
  MatcherOperand First;
  if (parseType(First.Ty))
    return true;
  bool IsLabel = First.Ty->getTypeID() == Type::LabelTyID;
  auto *Integer = dyn_cast<IntegerType>(First.Ty);
  bool IsBool = Integer && Integer->getNumBits() == 1;
  if (parseValue(First.Val, IsLabel  ? MetaType::BasicBlock
                            : IsBool ? MetaType::Bool
                                     : MetaType::Value))
    return true;
  Ops.push_back(First);
  // 'br label %dest', or 'br i1 %cond, label %true, label %false'.
  if (IsLabel)
    return false;
  return parseOperandComma() || parseOperand(Ops, MetaType::BasicBlock) ||
         parseOperandComma() || parseOperand(Ops, MetaType::BasicBlock);
}

bool MIRParser::parseCompareOperands(SmallVectorImpl<MatcherOperand> &Ops) {
  MatcherOperand Pred;
  Pred.IsInstructionOperand = false;
  Pred.Key = MatcherOperand::Predicate;
  if (Lex.getKind() == tok::MetaVar) {
    Pred.Val = getMeta(Lex.getStrVal(), MetaType::CmpPredicate, Lex.getLoc());
    if (!Pred.Val)
      return true;
  } else if (std::optional<KeywordConstant::KeywordID> Predicate =
                 predicateKeywordID(Lex.getKind())) {
    Pred.Val = KeywordConstant::create(Context, *Predicate,
                                       SourceRange{Lex.getLoc(), Lex.getLoc()});
  } else {
    return error("expected comparison predicate");
  }
  next();
  Ops.push_back(Pred);
  // Both compared operands have the first one's type.
  return parseArchetypeOperands(Instruction::OperandSyntax::Binary, 2, "", Ops);
}

bool MIRParser::parsePhiOperands(SmallVectorImpl<MatcherOperand> &Ops) {
  Type *Ty = nullptr;
  if (parseType(Ty))
    return true;
  do {
    MatcherOperand Incoming, Block;
    Incoming.Ty = Ty;
    if (expect(tok::lsquare, "expected '[' in phi") ||
        parseValue(Incoming.Val) || parseOperandComma() ||
        parseValue(Block.Val, MetaType::BasicBlock) ||
        expect(tok::rsquare, "expected ']' in phi"))
      return true;
    Ops.push_back(Incoming);
    Ops.push_back(Block);
  } while (consume(tok::comma));
  return false;
}

bool MIRParser::parseCallOperands(SmallVectorImpl<MatcherOperand> &Ops) {
  MatcherOperand Callee;
  if (parseTypeOperand(Ops) || parseValue(Callee.Val, MetaType::Function))
    return true;
  Ops.push_back(Callee);
  if (expect(tok::lparen, "expected '(' in call"))
    return true;
  if (Lex.getKind() != tok::rparen) {
    // The first argument, then the rest as for a GEP's indices.
    if (Lex.getKind() == tok::dotdotdot) {
      MatcherOperand Array;
      if (parseArrayCapture(Array, /*WithTypes=*/true))
        return true;
      Ops.push_back(Array);
    } else if (parseOperand(Ops) || parseTrailingOperands(Ops, TypedOperands)) {
      return true;
    }
  }
  return expect(tok::rparen, "expected ')' after call arguments");
}

bool MIRParser::validateInstruction(Instruction::InstructionID ID,
                                    ArrayRef<MetaFlag *> MFlags,
                                    ArrayRef<MatcherOperand> Ops) {
  for (const MetaFlag *F : MFlags) {
    LocTy FlagLoc = F->getSourceRange().Begin;
    if (F->getMetaFlagID() == MetaFlag::MF_o) {
      uint64_t Index = 0;
      if (!F->getArguments().empty()) {
        const MetaFlag::Argument &Arg = F->getArguments().front();
        if (F->getArguments().size() != 1 ||
            Arg.K != MetaFlag::Argument::Integer || Arg.IntegerValue < 0)
          return Lex.ParseError(
              FlagLoc, "metaflag ':o' expects one non-negative operand index");
        Index = Arg.IntegerValue;
      }
      uint64_t OperandCount = count_if(Ops, [](const MatcherOperand &O) {
        return O.IsInstructionOperand && !O.IsArray;
      });
      bool HasArray =
          any_of(Ops, [](const MatcherOperand &O) { return O.IsArray; });
      if (!HasArray && Index >= OperandCount)
        return Lex.ParseError(FlagLoc,
                              "metaflag ':o' operand index is out of range");
    }
    if (F->getMetaFlagID() == MetaFlag::MF_c && ID == Instruction::I_call) {
      // Operands are the return type, the callee and the arguments.
      unsigned ArgumentCount = Ops.size() >= 2 ? Ops.size() - 2 : 0;
      bool HasArray =
          any_of(Ops, [](const MatcherOperand &O) { return O.IsArray; });
      if (ArgumentCount != 2 || HasArray)
        return Lex.ParseError(
            FlagLoc,
            "metaflag ':c' requires a call with exactly two arguments");
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

  SourceRange Range{Loc, Lex.getPrevTokEnd()};
  Result =
      Instruction::createComposite(Context, ResultName, CM, Flags, MFlags, Ops,
                                   Capture, Range, CurrentBlock, Settings);
  if (!ResultName.empty())
    Instructions[ResultName] = Result;
  return false;
}

} // namespace metaphir
} // namespace llvm
