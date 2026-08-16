#include "metaphir/Parser/MIRParser.h"
#include "metaphir/IR/DerivedTypes.h"
#include "metaphir/IR/MIRContext.h"
#include "llvm/ADT/SmallString.h"
#include "llvm/Support/raw_ostream.h"
#include <limits>
#include <memory>

namespace llvm {
namespace metaphir {

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

static StringRef tokenName(tok::Kind K) {
  StringRef N = tok::getTokenKindName(K);
  return N.consume_front("kw_") ? N : StringRef();
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

static Instruction::SemanticFlagID semanticFlagID(tok::Kind K) {
  switch (K) {
#define MIR_FLAG(Name)                                                         \
  case tok::kw_##Name:                                                         \
    return Instruction::F_##Name;
#define MIR_FAST_MATH_FLAG(Name)                                               \
  case tok::kw_##Name:                                                         \
    return Instruction::F_##Name;
#include "metaphir/IR/Flags.def"
  default:
    llvm_unreachable("not a semantic flag token");
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
    return error(Message + " (got " + tok::getTokenKindName(Lex.getKind()) +
                 ")");
  return false;
}

void MIRParser::skipNewlines() {
  while (consume(tok::Newline)) {
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
  auto *M = MetaVariable::get(Context, Name, Expected, SourceRange{Loc, Loc});
  MetaVariables[M->getName()] = M;
  CurrentPattern->addMetaVariable(M);
  return M;
}

bool MIRParser::parse(Pattern *&Result) {
  Result = nullptr;
  CurrentPattern = Pattern::get(Context);
  next();
  skipNewlines();
  while (Lex.getKind() != tok::Eof) {
    if (consume(tok::ConstraintMarker)) {
      SawConstraint = true;
      Constraint *C = nullptr;
      if (parseConstraint(C))
        return true;
      if (C->getResultType() == Constraint::IntegerResult)
        return error("constraint must have a boolean result");
      CurrentPattern->addConstraint(C);
      if (Lex.getKind() != tok::Newline && Lex.getKind() != tok::Eof)
        return error("unexpected token after constraint");
      skipNewlines();
      continue;
    }
    if (SawConstraint)
      return error("instruction is not allowed after constraints");
    if (!CurrentPattern->getInstructions().empty() &&
        CurrentPattern->getInstructions().back()->getResultName().empty())
      return error("only the final instruction may omit a result assignment");
    Instruction *I = nullptr;
    if (parseInstruction(I))
      return true;
    CurrentPattern->addInstruction(I);
    if (Lex.getKind() != tok::Newline && Lex.getKind() != tok::Eof)
      return error("unexpected token after instruction");
    skipNewlines();
  }
  if (CurrentPattern->getInstructions().empty())
    return error("expected at least one instruction matcher");
  Result = CurrentPattern;
  return false;
}

bool MIRParser::parseSemanticFlags(Instruction::InstructionID ID,
                                   SmallVectorImpl<MatcherFlag> &Result) {
  while (isSemanticFlag(Lex.getKind())) {
    LocTy Loc = Lex.getLoc();
    StringRef Name = tokenName(Lex.getKind());
    Instruction::SemanticFlagID FlagID = semanticFlagID(Lex.getKind());
    if (!(Instruction::getSupportedFlags(ID) & Instruction::mask(FlagID)))
      return Lex.ParseError(Loc, "flag '" + Name + "' is not valid for '" +
                                     Instruction::getOpcodeName(ID) + "'");
    next();
    MetaVariable *Capture = nullptr;
    if (Lex.getKind() == tok::MetaCaptureVar) {
      Capture = getMeta(Lex.getStrVal(), MetaType::Bool, Lex.getLoc());
      if (!Capture)
        return true;
      next();
    }
    Result.push_back({Name, Capture});
  }
  return false;
}

bool MIRParser::parseMetaFlag(MetaFlag *&Result) {
  if (Lex.getKind() != tok::MetaFlag)
    return error("expected meta flag");
  LocTy Loc = Lex.getLoc();
  std::string NameStorage = Lex.getStrVal();
  StringRef Name = NameStorage;
  next();
  SmallVector<MetaFlag::Argument, 4> Args;
  if (consume(tok::lparen)) {
    if (Lex.getKind() != tok::rparen) {
      do {
        MetaFlag::Argument Arg;
        if (Lex.getKind() == tok::MetaFlag) {
          Arg.K = MetaFlag::Argument::Flag;
          if (parseMetaFlag(Arg.FlagValue))
            return true;
        } else if (Lex.getKind() == tok::APSInt) {
          if (!Lex.getAPSIntVal().isSignedIntN(64))
            return error("meta flag integer argument is too large");
          Arg.K = MetaFlag::Argument::Integer;
          Arg.IntegerValue = Lex.getAPSIntVal().getExtValue();
          next();
        } else {
          return error("expected integer or nested meta flag argument");
        }
        Args.push_back(Arg);
      } while (consume(tok::comma));
    }
    if (expect(tok::rparen, "expected ')' after meta flag arguments"))
      return true;
  }
  if (std::optional<MetaFlag::Schema> Schema = MetaFlag::getSchema(Name)) {
    if (Args.size() < Schema->MinArguments ||
        Args.size() > Schema->MaxArguments)
      return Lex.ParseError(
          Loc, "invalid number of arguments for meta flag ':" + Name + "'");
    for (const MetaFlag::Argument &Arg : Args) {
      if (Schema->Arguments == MetaFlag::IntegerArgument &&
          Arg.K != MetaFlag::Argument::Integer)
        return Lex.ParseError(Loc, "meta flag ':" + Name +
                                       "' expects integer arguments");
      if (Schema->Arguments == MetaFlag::FlagArgument &&
          Arg.K != MetaFlag::Argument::Flag)
        return Lex.ParseError(Loc, "meta flag ':" + Name +
                                       "' expects nested meta flags");
    }
  }
  Result = MetaFlag::get(Context, Name, Args, SourceRange{Loc, Loc});
  return false;
}

bool MIRParser::parseMetaFlags(SmallVectorImpl<MetaFlag *> &Result,
                               MetaFlag::Placement Placement) {
  while (Lex.getKind() == tok::MetaFlag) {
    MetaFlag *F = nullptr;
    if (parseMetaFlag(F))
      return true;
    if (std::optional<MetaFlag::Schema> Schema =
            MetaFlag::getSchema(F->getName())) {
      if (!(Schema->AllowedPlacement & Placement))
        return Lex.ParseError(F->getSourceRange().Begin,
                              "meta flag ':" + F->getName() +
                                  "' is not valid in this position");
    }
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
    Result = PointerType::get(Context);
    next();
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
        return error("expected vector size (got " +
                     tok::getTokenKindName(Lex.getKind()) + ")");
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
  struct ValueBuildInfo {
    Value::ValueID Kind;
    StringRef Spelling = {};
    MetaVariable *Meta = nullptr;
    Instruction *Definition = nullptr;
    APSInt Integer = APSInt(1, true);
    APFloat Floating = APFloat(0.0);
    ArrayRef<Value *> Elements = {};
    ArrayRef<Type *> ElementTypes = {};
    AggregateConstant::Delimiter Delimiter = AggregateConstant::Brace;
  };
  auto Make = [&](const ValueBuildInfo &Info) {
    SourceRange R{Loc, Loc};
    switch (Info.Kind) {
    case Value::MetaVal:
      return static_cast<Value *>(MetaValue::get(Context, Info.Meta, R));
    case Value::LocalInstructionVal:
      return static_cast<Value *>(LocalInstructionValue::get(
          Context, Info.Spelling, Info.Definition, R));
    case Value::BasicBlockVal:
      return static_cast<Value *>(
          BasicBlockValue::get(Context, Info.Spelling, Info.Meta, R));
    case Value::GlobalVal:
      return static_cast<Value *>(GlobalValue::get(Context, Info.Spelling, R));
    case Value::IntrinsicVal:
      return static_cast<Value *>(IntrinsicValue::get(Context, Info.Meta, R));
    case Value::IntegerConstantVal:
      return static_cast<Value *>(
          IntegerConstant::get(Context, Info.Integer, R));
    case Value::FloatingConstantVal:
      return static_cast<Value *>(
          FloatingConstant::get(Context, Info.Floating, R));
    case Value::KeywordConstantVal:
      return static_cast<Value *>(
          KeywordConstant::get(Context, Info.Spelling, R));
    case Value::AggregateConstantVal:
      return static_cast<Value *>(AggregateConstant::get(
          Context, Info.ElementTypes, Info.Elements, Info.Delimiter, R));
    }
    llvm_unreachable("invalid value kind");
  };
  if (Lex.getKind() == tok::plus || Lex.getKind() == tok::minus) {
    bool Negative = Lex.getKind() == tok::minus;
    next();
    if (Lex.getKind() == tok::APSInt) {
      APSInt Number = Lex.getAPSIntVal();
      if (Negative)
        Number = -Number;
      Result = Make({Value::IntegerConstantVal, {}, nullptr, nullptr, Number});
      next();
      return false;
    }
    if (Lex.getKind() == tok::APFloat) {
      APFloat Number = Lex.getAPFloatVal();
      if (Negative)
        Number.changeSign();
      Result = Make({Value::FloatingConstantVal,
                     {},
                     nullptr,
                     nullptr,
                     APSInt(1, true),
                     Number});
      next();
      return false;
    }
    return error("expected numeric literal after sign");
  }
  if (Lex.getKind() == tok::MetaVar) {
    auto *M = getMeta(Lex.getStrVal(), Expected, Loc);
    if (!M)
      return true;
    Result = Make({Value::MetaVal, {}, M});
    next();
    return false;
  }
  if (Lex.getKind() == tok::LocalVar || Lex.getKind() == tok::LocalVarID) {
    std::string NameStorage;
    StringRef Name = Lex.getStrVal();
    if (Lex.getKind() == tok::LocalVarID) {
      NameStorage = Twine(Lex.getUIntVal()).str();
      Name = NameStorage;
    }
    if (Expected == MetaType::BasicBlock) {
      auto *M = getMeta(Name, MetaType::BasicBlock, Loc);
      if (!M)
        return true;
      Result = Make({Value::BasicBlockVal, Name, M});
      next();
      return false;
    }
    auto It = Instructions.find(Name);
    if (It == Instructions.end())
      return error("undefined or forward local reference '%" + Name + "'");
    Result = Make({Value::LocalInstructionVal, Name, nullptr, It->second});
    next();
    return false;
  }
  if (Lex.getKind() == tok::IntrinsicPrefix) {
    next();
    if (Lex.getKind() != tok::MetaVar)
      return error("expected intrinsic ID meta variable");
    auto *M = getMeta(Lex.getStrVal(), MetaType::IntrinsicID, Lex.getLoc());
    if (!M)
      return true;
    next();
    Result = Make({Value::IntrinsicVal, {}, M});
    return false;
  }
  if (Lex.getKind() == tok::GlobalVar || Lex.getKind() == tok::GlobalID) {
    std::string NameStorage;
    if (Lex.getKind() == tok::GlobalVar)
      NameStorage = Lex.getStrVal();
    else
      NameStorage = Twine(Lex.getUIntVal()).str();
    StringRef Name = NameStorage;
    next();
    Result = Make({Value::GlobalVal, Name});
    return false;
  }
  if (Lex.getKind() == tok::APSInt) {
    APSInt V = Lex.getAPSIntVal();
    Result = Make({Value::IntegerConstantVal, {}, nullptr, nullptr, V});
    next();
    return false;
  }
  if (Lex.getKind() == tok::APFloat) {
    APFloat V = Lex.getAPFloatVal();
    Result = Make(
        {Value::FloatingConstantVal, {}, nullptr, nullptr, APSInt(1, true), V});
    next();
    return false;
  }
  if (Lex.getKind() == tok::kw_true || Lex.getKind() == tok::kw_false) {
    bool V = Lex.getKind() == tok::kw_true;
    APSInt I(APInt(1, V), false);
    Result = Make(
        {Value::IntegerConstantVal, V ? "true" : "false", nullptr, nullptr, I});
    next();
    return false;
  }
#define MIR_CONSTANT_KEYWORD(Kind)                                             \
  if (Lex.getKind() == tok::kw_##Kind) {                                       \
    Result = Make({Value::KeywordConstantVal, #Kind});                         \
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
    Result = Make({Value::AggregateConstantVal,
                   {},
                   nullptr,
                   nullptr,
                   APSInt(1, true),
                   APFloat(0.0),
                   Values,
                   Types,
                   Open == tok::lsquare ? AggregateConstant::Square
                   : Open == tok::less  ? AggregateConstant::Angle
                                        : AggregateConstant::Brace});
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
  SmallVector<MetaFlag *, 4> Flags;
  if (parseMetaFlags(Flags, MetaFlag::OperandPlacement))
    return true;
  if (!Flags.empty()) {
    Result.Val->setMetaFlags(Context, Flags);
  }
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
  if (!isOpcode(Lex.getKind()))
    return error("expected instruction matcher");
  Instruction::InstructionID ID = instructionID(Lex.getKind());
  StringRef Op = tokenName(Lex.getKind());
  next();
  MetaVariable *Capture = nullptr;
  if (Lex.getKind() == tok::MetaCaptureVar) {
    Capture = getMeta(Lex.getStrVal(), MetaType::Instruction, Lex.getLoc());
    if (!Capture)
      return true;
    next();
  }
  SmallVector<MetaFlag *, 4> MFlags;
  if (parseMetaFlags(MFlags, MetaFlag::InstructionPlacement))
    return true;
  for (MetaFlag *F : MFlags)
    if (F->getMetaFlagID() == MetaFlag::MF_c && !Instruction::isCommutative(ID))
      return Lex.ParseError(F->getSourceRange().Begin,
                            "commutative matching is not valid for '" + Op +
                                "'");
  SmallVector<MatcherFlag, 8> Flags;
  if (parseSemanticFlags(ID, Flags))
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

  if (ID == Instruction::I_fneg || ID == Instruction::I_freeze) {
    if (Typed())
      return true;
  } else if (ID == Instruction::I_add || ID == Instruction::I_fadd ||
             ID == Instruction::I_sub || ID == Instruction::I_fsub ||
             ID == Instruction::I_mul || ID == Instruction::I_fmul ||
             ID == Instruction::I_udiv || ID == Instruction::I_sdiv ||
             ID == Instruction::I_fdiv || ID == Instruction::I_urem ||
             ID == Instruction::I_srem || ID == Instruction::I_frem ||
             ID == Instruction::I_shl || ID == Instruction::I_lshr ||
             ID == Instruction::I_ashr || ID == Instruction::I_and ||
             ID == Instruction::I_or || ID == Instruction::I_xor) {
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
    SmallVector<MetaFlag *, 4> Fs;
    if (parseMetaFlags(Fs, MetaFlag::OperandPlacement))
      return true;
    if (!Fs.empty()) {
      B.Val->setMetaFlags(Context, Fs);
    }
    Ops.push_back(B);
  } else if (ID == Instruction::I_extractelement) {
    if (Typed() || Comma() || Typed(MetaType::Nat))
      return true;
  } else if (ID == Instruction::I_insertelement ||
             ID == Instruction::I_shufflevector ||
             ID == Instruction::I_select) {
    if (Typed() || Comma() || Typed() || Comma() || Typed())
      return true;
  } else if (ID == Instruction::I_extractvalue ||
             ID == Instruction::I_insertvalue) {
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
  } else if (ID == Instruction::I_alloca) {
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
  } else if (ID == Instruction::I_load) {
    if (TypeOnly() || Comma() || Typed())
      return true;
    if (consume(tok::comma)) {
      if (Lex.getKind() != tok::kw_align)
        return error("expected align");
      next();
      MatcherOperand O;
      O.IsInstructionOperand = false;
      O.Key = MatcherOperand::Alignment;
      if (parseValue(O.Val, MetaType::Nat))
        return true;
      Ops.push_back(O);
    }
  } else if (ID == Instruction::I_store) {
    if (Typed() || Comma() || Typed())
      return true;
    if (consume(tok::comma)) {
      if (Lex.getKind() != tok::kw_align)
        return error("expected align");
      next();
      MatcherOperand O;
      O.IsInstructionOperand = false;
      O.Key = MatcherOperand::Alignment;
      if (parseValue(O.Val, MetaType::Nat))
        return true;
      Ops.push_back(O);
    }
  } else if (ID == Instruction::I_getelementptr) {
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
  } else if (ID == Instruction::I_trunc || ID == Instruction::I_zext ||
             ID == Instruction::I_sext || ID == Instruction::I_fptrunc ||
             ID == Instruction::I_fpext || ID == Instruction::I_fptoui ||
             ID == Instruction::I_fptosi || ID == Instruction::I_uitofp ||
             ID == Instruction::I_sitofp || ID == Instruction::I_ptrtoint ||
             ID == Instruction::I_ptrtoaddr || ID == Instruction::I_inttoptr ||
             ID == Instruction::I_bitcast) {
    if (Typed())
      return true;
    if (Lex.getKind() != tok::kw_to)
      return error("expected 'to' in conversion");
    next();
    if (TypeOnly())
      return true;
  } else if (ID == Instruction::I_ret) {
    MatcherOperand O;
    if (parseType(O.Ty, true))
      return true;
    if (O.Ty->getTypeID() != Type::VoidTyID && parseValue(O.Val))
      return true;
    Ops.push_back(O);
  } else if (ID == Instruction::I_br) {
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
  } else if (ID == Instruction::I_icmp || ID == Instruction::I_fcmp) {
    MatcherOperand Pred;
    Pred.IsInstructionOperand = false;
    Pred.Key = MatcherOperand::Predicate;
    if (Lex.getKind() == tok::MetaVar) {
      MetaVariable *M =
          getMeta(Lex.getStrVal(), MetaType::CmpPredicate, Lex.getLoc());
      if (!M)
        return true;
      Pred.Val =
          MetaValue::get(Context, M, SourceRange{Lex.getLoc(), Lex.getLoc()});
      next();
    } else if (Lex.getKind() == tok::Identifier) {
      Pred.Val = KeywordConstant::get(Context, Lex.getStrVal(),
                                      SourceRange{Lex.getLoc(), Lex.getLoc()});
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
    Ops.push_back(B);
  } else if (ID == Instruction::I_phi) {
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
  } else if (ID == Instruction::I_call) {
    if (TypeOnly())
      return true;
    MatcherOperand Callee;
    if (parseValue(Callee.Val, MetaType::Function))
      return true;
    Ops.push_back(Callee);
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
  } else {
    return error("instruction parser is not implemented for '" + Op + "'");
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
                              ":o expects one non-negative operand index");
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
                            ":o operand index is out of range");
  }
  for (MetaFlag *F : MFlags) {
    if (F->getMetaFlagID() == MetaFlag::MF_c && ID == Instruction::I_call) {
      unsigned ArgumentCount = Ops.size() >= 2 ? Ops.size() - 2 : 0;
      if (ArgumentCount != 2)
        return Lex.ParseError(F->getSourceRange().Begin,
                              ":c requires a call with exactly two arguments");
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
  Result = Instruction::get(Context, ID, ResultName, Flags, MFlags, Ops,
                            Capture, SourceRange{Loc, Lex.getLoc()});
  if (!ResultName.empty())
    Instructions[ResultName] = Result;
  return false;
}

} // namespace metaphir
} // namespace llvm
