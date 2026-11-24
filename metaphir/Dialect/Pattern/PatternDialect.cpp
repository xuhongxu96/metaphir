#include "metaphir/Dialect/Pattern/PatternDialect.h"
#include "metaphir/IR/Constants.h"
#include "metaphir/IR/Type.h"
#include "mlir/IR/Builders.h"
#include "mlir/IR/DialectImplementation.h"
#include "llvm/ADT/SmallString.h"
#include "llvm/ADT/StringExtras.h"
#include "llvm/ADT/StringSwitch.h"
#include "llvm/ADT/TypeSwitch.h"

using namespace mlir;
using namespace llvm::metaphir;
using namespace llvm::metaphir::mpir;

#include "metaphir/Dialect/Pattern/PatternOpsDialect.cpp.inc"

#define GET_TYPEDEF_CLASSES
#include "metaphir/Dialect/Pattern/PatternOpsTypes.cpp.inc"

#include "metaphir/Dialect/Pattern/PatternAttrInterfaces.cpp.inc"

#define GET_ATTRDEF_CLASSES
#include "metaphir/Dialect/Pattern/PatternOpsAttrDefs.cpp.inc"

#include "metaphir/Dialect/Pattern/PatternEnums.cpp.inc"

#include "metaphir/Dialect/Pattern/PatternOpInterfaces.cpp.inc"

#define GET_OP_CLASSES
#include "metaphir/Dialect/Pattern/PatternOps.cpp.inc"

void PatternDialect::initialize() {
  addTypes<
#define GET_TYPEDEF_LIST
#include "metaphir/Dialect/Pattern/PatternOpsTypes.cpp.inc"
      >();
  addAttributes<
#define GET_ATTRDEF_LIST
#include "metaphir/Dialect/Pattern/PatternOpsAttrDefs.cpp.inc"
      >();
  addOperations<
#define GET_OP_LIST
#include "metaphir/Dialect/Pattern/PatternOps.cpp.inc"
      >();
}

//===----------------------------------------------------------------------===//
// Types and attributes
//===----------------------------------------------------------------------===//

// !mpir.sort<Value>
mlir::Type SortType::parse(AsmParser &Parser) {
  StringRef Name;
  SMLoc Loc = Parser.getCurrentLocation();
  if (Parser.parseLess() || Parser.parseKeyword(&Name) || Parser.parseGreater())
    return {};
  std::optional<Sort> S = getSortFromKeyword(Name);
  if (!S) {
    Parser.emitError(Loc, "unknown sort '") << Name << "'";
    return {};
  }
  return SortType::get(Parser.getContext(), *S);
}

void SortType::print(AsmPrinter &Printer) const {
  Printer << "<" << getSortKeyword(getSort()) << ">";
}

// #mpir.opcode<add>
Attribute OpcodeAttr::parse(AsmParser &Parser, mlir::Type) {
  std::string Name;
  SMLoc Loc = Parser.getCurrentLocation();
  if (Parser.parseLess() || Parser.parseKeywordOrString(&Name) ||
      Parser.parseGreater())
    return {};
  for (unsigned ID = 0; ID != instruction::NumInstructionIDs; ++ID)
    if (instruction::getOpcodeName(instruction::InstructionID(ID)) == Name)
      return OpcodeAttr::get(Parser.getContext(),
                             instruction::InstructionID(ID));
  Parser.emitError(Loc, "unknown instruction matcher '") << Name << "'";
  return {};
}

void OpcodeAttr::print(AsmPrinter &Printer) const {
  Printer << "<" << instruction::getOpcodeName(getValue()) << ">";
}

//===----------------------------------------------------------------------===//
// Type patterns
//===----------------------------------------------------------------------===//

/// Parses '[' type-pattern (',' type-pattern)* ']'.
static ParseResult parseTypePatterns(AsmParser &Parser,
                                     SmallVectorImpl<TypePatternAttr> &List) {
  return Parser.parseCommaSeparatedList(AsmParser::Delimiter::Square, [&] {
    TypePatternAttr Each;
    if (Parser.parseAttribute(Each))
      return failure();
    List.push_back(Each);
    return success();
  });
}

static void printTypePatterns(AsmPrinter &Printer,
                              ArrayRef<TypePatternAttr> List) {
  Printer << '[';
  llvm::interleaveComma(List, Printer);
  Printer << ']';
}

LogicalResult
PrimTypePatternAttr::verify(function_ref<InFlightDiagnostic()> EmitError,
                            primitive_type::TypeID Kind) {
  if (!isEnumerator(Kind))
    return EmitError() << "invalid primitive type " << unsigned(Kind);
  return success();
}

// #mpir.tp_ptr, #mpir.tp_ptr<element = #mpir.tp_int<32>, addrspace = 1>
Attribute PtrTypePatternAttr::parse(AsmParser &Parser, mlir::Type) {
  std::optional<unsigned> AddressSpace;
  TypePatternAttr Element;
  if (succeeded(Parser.parseOptionalLess())) {
    if (succeeded(Parser.parseOptionalKeyword("element")))
      if (Parser.parseEqual() || Parser.parseAttribute(Element))
        return {};
    if (!Element || succeeded(Parser.parseOptionalComma())) {
      unsigned Space;
      if (Parser.parseKeyword("addrspace") || Parser.parseEqual() ||
          Parser.parseInteger(Space))
        return {};
      AddressSpace = Space;
    }
    if (Parser.parseGreater())
      return {};
  }
  return PtrTypePatternAttr::get(Parser.getContext(), AddressSpace, Element);
}

void PtrTypePatternAttr::print(AsmPrinter &Printer) const {
  if (!getElement() && !getAddressSpace())
    return;
  Printer << '<';
  if (getElement())
    Printer << "element = " << getElement();
  if (getElement() && getAddressSpace())
    Printer << ", ";
  if (getAddressSpace())
    Printer << "addrspace = " << *getAddressSpace();
  Printer << '>';
}

LogicalResult
SeqTypePatternAttr::verify(function_ref<InFlightDiagnostic()> EmitError,
                           SeqKind Kind, std::optional<uint64_t> Count,
                           std::optional<unsigned> CountSlot,
                           TypePatternAttr Element) {
  if (Count.has_value() == CountSlot.has_value())
    return EmitError() << "expected either a count or a count variable";
  return success();
}

// #mpir.tp_seq<vector, 4, #mpir.tp_int<8>>,
// #mpir.tp_seq<array, count_slot = 2, #mpir.tp_var<3>>
Attribute SeqTypePatternAttr::parse(AsmParser &Parser, mlir::Type) {
  SMLoc Loc = Parser.getCurrentLocation();
  if (Parser.parseLess())
    return {};
  FailureOr<SeqKind> Kind = FieldParser<SeqKind>::parse(Parser);
  if (failed(Kind) || Parser.parseComma())
    return {};
  std::optional<uint64_t> Count;
  std::optional<unsigned> CountSlot;
  if (succeeded(Parser.parseOptionalKeyword("count_slot"))) {
    unsigned Slot;
    if (Parser.parseEqual() || Parser.parseInteger(Slot))
      return {};
    CountSlot = Slot;
  } else {
    uint64_t N;
    if (Parser.parseInteger(N))
      return {};
    Count = N;
  }
  TypePatternAttr Element;
  if (Parser.parseComma() || Parser.parseAttribute(Element) ||
      Parser.parseGreater())
    return {};
  return Parser.getChecked<SeqTypePatternAttr>(Loc, Parser.getContext(), *Kind,
                                               Count, CountSlot, Element);
}

void SeqTypePatternAttr::print(AsmPrinter &Printer) const {
  Printer << '<' << getKind() << ", ";
  if (getCountSlot())
    Printer << "count_slot = " << *getCountSlot();
  else
    Printer << *getCount();
  Printer << ", " << getElement() << '>';
}

// #mpir.tp_struct<[#mpir.tp_int<32>]>, #mpir.tp_struct<packed, []>
Attribute StructTypePatternAttr::parse(AsmParser &Parser, mlir::Type) {
  bool Packed = false;
  SmallVector<TypePatternAttr> Elements;
  if (Parser.parseLess())
    return {};
  if (succeeded(Parser.parseOptionalKeyword("packed"))) {
    Packed = true;
    if (Parser.parseComma())
      return {};
  }
  if (parseTypePatterns(Parser, Elements) || Parser.parseGreater())
    return {};
  return StructTypePatternAttr::get(Parser.getContext(), Packed, Elements);
}

void StructTypePatternAttr::print(AsmPrinter &Printer) const {
  Printer << '<';
  if (getPacked())
    Printer << "packed, ";
  printTypePatterns(Printer, getElements());
  Printer << '>';
}

// #mpir.tp_func<#mpir.tp_int<32>, [#mpir.tp_var<1>], var_arg>
Attribute FuncTypePatternAttr::parse(AsmParser &Parser, mlir::Type) {
  TypePatternAttr Return;
  SmallVector<TypePatternAttr> Params;
  if (Parser.parseLess() || Parser.parseAttribute(Return) ||
      Parser.parseComma() || parseTypePatterns(Parser, Params))
    return {};
  bool VarArg = false;
  if (succeeded(Parser.parseOptionalComma())) {
    if (Parser.parseKeyword("var_arg"))
      return {};
    VarArg = true;
  }
  if (Parser.parseGreater())
    return {};
  return FuncTypePatternAttr::get(Parser.getContext(), Return, Params, VarArg);
}

void FuncTypePatternAttr::print(AsmPrinter &Printer) const {
  Printer << '<' << getReturnType() << ", ";
  printTypePatterns(Printer, getParams());
  if (getVarArg())
    Printer << ", var_arg";
  Printer << '>';
}

//===----------------------------------------------------------------------===//
// Operands of instruction matchers
//===----------------------------------------------------------------------===//

unsigned mpir::getNumOperandValues(OperandKind Kind) {
  switch (Kind) {
  case OperandKind::TypedValue:
  case OperandKind::TypedValueArray:
    return 2;
  default:
    return 1;
  }
}

bool mpir::isArrayOperand(OperandKind Kind) {
  return Kind == OperandKind::ValueArray ||
         Kind == OperandKind::TypedValueArray;
}

bool mpir::isKeyedOperand(OperandKind Kind) {
  return Kind >= OperandKind::Predicate;
}

bool mpir::isValueOperand(OperandKind Kind) {
  switch (Kind) {
  case OperandKind::TypedValue:
  case OperandKind::Value:
  case OperandKind::ValueArray:
  case OperandKind::TypedValueArray:
    return true;
  default:
    return false;
  }
}

SmallVector<MatcherOperandView, 4>
mpir::getMatcherOperands(MatcherOpInterface Op) {
  SmallVector<MatcherOperandView, 4> Result;
  ValueRange Values = Op.getOperandValues();
  unsigned Next = 0;
  for (OperandKind Kind : Op.getOperandKinds()) {
    MatcherOperandView View{Kind, {}, {}};
    switch (Kind) {
    case OperandKind::TypedValue:
    case OperandKind::TypedValueArray:
      View.Type = Values[Next++];
      View.Val = Values[Next++];
      break;
    case OperandKind::TypeOnly:
      View.Type = Values[Next++];
      break;
    default:
      View.Val = Values[Next++];
      break;
    }
    Result.push_back(View);
  }
  return Result;
}

MatcherParts MatcherParts::of(MatcherOpInterface Matcher) {
  MatcherParts P;
  P.ResultName = Matcher.getResultNameAttr();
  P.Flags.assign(Matcher.getFlags().begin(), Matcher.getFlags().end());
  P.Modes.assign(Matcher.getFlagModes().begin(), Matcher.getFlagModes().end());
  P.FlagCaptures.assign(Matcher.getFlagCaptures().begin(),
                        Matcher.getFlagCaptures().end());
  P.Operands = getMatcherOperands(Matcher);
  if (std::optional<ArrayAttr> Flags = Matcher.getMetaflags())
    P.MetaFlags.assign(Flags->begin(), Flags->end());
  if (std::optional<ArrayAttr> Flags = Matcher.getOperandMetaflags())
    P.OperandMetaFlags.assign(Flags->begin(), Flags->end());
  P.TreatIntAsVec = Matcher.getTreatIntAsVec();
  P.Capture = Matcher.getCapture();
  P.ParentBlock = Matcher.getParentBlock();
  return P;
}

namespace {
/// What building an mpir.inst or mpir.use takes of MatcherParts: its operand
/// kinds and values, and its optional attributes.
struct BuildArguments {
  SmallVector<OperandKind, 8> Kinds;
  SmallVector<Value, 8> Values;
  ArrayAttr MetaFlags;
  ArrayAttr OperandMetaFlags;
  BoolAttr TreatIntAsVec;

  BuildArguments(OpBuilder &Builder, const MatcherParts &Parts) {
    for (const MatcherOperandView &Op : Parts.Operands) {
      Kinds.push_back(Op.Kind);
      if (Op.Type)
        Values.push_back(Op.Type);
      if (Op.Val)
        Values.push_back(Op.Val);
    }
    if (!Parts.MetaFlags.empty())
      MetaFlags = Builder.getArrayAttr(Parts.MetaFlags);
    if (any_of(Parts.OperandMetaFlags,
               [](Attribute A) { return !cast<ArrayAttr>(A).empty(); }))
      OperandMetaFlags = Builder.getArrayAttr(Parts.OperandMetaFlags);
    if (Parts.TreatIntAsVec)
      TreatIntAsVec = Builder.getBoolAttr(*Parts.TreatIntAsVec);
  }
};
} // namespace

InstOp MatcherParts::buildInst(OpBuilder &Builder, Location Loc,
                               OpcodeAttr Opcode) const {
  BuildArguments Args(Builder, *this);
  return InstOp::create(
      Builder, Loc, SortType::get(Builder.getContext(), Sort::Instruction),
      Opcode, ResultName, Flags, Modes, Args.Kinds, Args.MetaFlags,
      Args.OperandMetaFlags, Args.TreatIntAsVec, Capture, ParentBlock,
      FlagCaptures, Args.Values);
}

UseOp MatcherParts::buildUse(OpBuilder &Builder, Location Loc,
                             FlatSymbolRefAttr Matcher) const {
  BuildArguments Args(Builder, *this);
  return UseOp::create(
      Builder, Loc, SortType::get(Builder.getContext(), Sort::Instruction),
      Matcher, ResultName, Flags, Modes, Args.Kinds, Args.MetaFlags,
      Args.OperandMetaFlags, Args.TreatIntAsVec, Capture, ParentBlock,
      FlagCaptures, Args.Values);
}

SmallVector<Operation *, 4> mpir::getPatternRoots(Block &Block) {
  SmallVector<Operation *, 4> Roots;
  for (Operation &Op : Block) {
    if (!isa<InstOp, AltOp>(Op))
      continue;
    bool Used = any_of(Op.getResult(0).getUses(), [](OpOperand &Use) {
      Operation *Owner = Use.getOwner();
      if (isa<YieldOp>(Owner))
        return true;
      if (auto Inst = dyn_cast<InstOp>(Owner)) {
        for (const MatcherOperandView &O : getMatcherOperands(Inst))
          if (isValueOperand(O.Kind) && O.Val == Use.get())
            return true;
      }
      return false;
    });
    if (!Used)
      Roots.push_back(&Op);
  }
  return Roots;
}

/// Checks what the matcher uses' attributes say about their operands.
template <typename OpT> static LogicalResult verifyMatcherUse(OpT Op) {
  unsigned Needed = 0;
  for (OperandKind Kind : Op.getOperandKinds())
    Needed += getNumOperandValues(Kind);
  if (Needed != Op.getOperandValues().size())
    return Op.emitOpError("operand kinds need ")
           << Needed << " operand values, but it has "
           << Op.getOperandValues().size();
  if (Op.getFlags().size() != Op.getFlagModes().size())
    return Op.emitOpError("needs one mode per flag");
  unsigned Captured = 0;
  for (FlagMode Mode : Op.getFlagModes())
    Captured += Mode == FlagMode::Captured;
  if (Captured != Op.getFlagCaptures().size())
    return Op.emitOpError("needs one capture per captured flag");
  if (std::optional<ArrayAttr> PerOperand = Op.getOperandMetaflags())
    if (PerOperand->size() != Op.getOperandKinds().size())
      return Op.emitOpError("needs one metaflag list per operand");
  return success();
}

LogicalResult InstOp::verify() {
  if (failed(verifyMatcherUse(*this)))
    return failure();
  instruction::InstructionID ID = getOpcode().getValue();
  for (int32_t Flag : getFlags())
    if (Flag < 0 || Flag >= instruction_flag::NumFlagIDs ||
        !(instruction::getSupportedFlags(ID) &
          instruction::mask(instruction_flag::FlagID(Flag))))
      return emitOpError("flag ") << Flag << " is not valid for '"
                                  << instruction::getOpcodeName(ID) << "'";
  if (isCommutative() && !instruction::isCommutative(ID))
    return emitOpError("'")
           << instruction::getOpcodeName(ID) << "' is not commutative";
  return success();
}

LogicalResult UseOp::verify() { return verifyMatcherUse(*this); }

LogicalResult UseOp::verifySymbolUses(SymbolTableCollection &Symbols) {
  if (!Symbols.lookupNearestSymbolFrom<MatcherOp>(*this, getMatcherAttr()))
    return emitOpError("uses unknown matcher '") << getMatcher() << "'";
  return success();
}

/// ':c' among Flags.
static bool hasCommutativeFlag(std::optional<ArrayAttr> Flags) {
  if (Flags)
    for (Attribute A : *Flags)
      if (cast<MetaFlagAttr>(A).getName() == "c")
        return true;
  return false;
}

/// The index ':o' among Flags names: its argument, or 0.
static std::optional<unsigned> orSelfIndex(std::optional<ArrayAttr> Flags) {
  if (Flags)
    for (Attribute A : *Flags) {
      auto Flag = cast<MetaFlagAttr>(A);
      if (Flag.getName() != "o")
        continue;
      if (Flag.getArgs().empty())
        return 0u;
      return unsigned(cast<IntegerAttr>(Flag.getArgs()[0]).getInt());
    }
  return std::nullopt;
}

bool InstOp::isCommutative() { return hasCommutativeFlag(getMetaflags()); }
std::optional<unsigned> InstOp::getOrSelfIndex() {
  return orSelfIndex(getMetaflags());
}
bool UseOp::isCommutative() { return hasCommutativeFlag(getMetaflags()); }
std::optional<unsigned> UseOp::getOrSelfIndex() {
  return orSelfIndex(getMetaflags());
}

//===----------------------------------------------------------------------===//
// Names and region kinds
//===----------------------------------------------------------------------===//

/// A printable SSA name for a pattern name: letters, digits and '_'.
static SmallString<32> asmName(StringRef Prefix, StringRef Name) {
  SmallString<32> Result = Prefix;
  for (char C : Name)
    Result += llvm::isAlnum(C) ? C : '_';
  return Result;
}

void VarOp::getAsmResultNames(OpAsmSetValueNameFn SetName) {
  SetName(getResult(), asmName("", getVarName()));
}

void InstOp::getAsmResultNames(OpAsmSetValueNameFn SetName) {
  if (std::optional<StringRef> Name = getResultName())
    SetName(getResult(), asmName("i_", *Name));
}

void UseOp::getAsmResultNames(OpAsmSetValueNameFn SetName) {
  if (std::optional<StringRef> Name = getResultName())
    SetName(getResult(), asmName("u_", *Name));
}

// A branch and an alternative are pieces of a pattern: a graph, in which
// instructions may refer to each other in cycles (through phis).
RegionKind BranchOp::getRegionKind(unsigned) { return RegionKind::Graph; }
RegionKind AltOp::getRegionKind(unsigned) { return RegionKind::Graph; }
