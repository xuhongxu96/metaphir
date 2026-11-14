#include "metaphir/Dialect/Pattern/PatternDialect.h"
#include "mlir/IR/Builders.h"
#include "mlir/IR/DialectImplementation.h"
#include "llvm/ADT/StringExtras.h"
#include "llvm/ADT/StringSwitch.h"
#include "llvm/ADT/TypeSwitch.h"

using namespace mlir;
using namespace llvm::metaphir;
using namespace llvm::metaphir::mpir;

#include "metaphir/Dialect/Pattern/PatternOpsDialect.cpp.inc"

#define GET_TYPEDEF_CLASSES
#include "metaphir/Dialect/Pattern/PatternOpsTypes.cpp.inc"

#define GET_ATTRDEF_CLASSES
#include "metaphir/Dialect/Pattern/PatternOpsAttrDefs.cpp.inc"

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

static std::optional<Sort> parseSortName(StringRef Name) {
#define MIR_SORT(ID, SortName, Representation)                                 \
  if (Name == #ID)                                                             \
    return Sort::ID;
#include "metaphir/IR/Sorts.def"
  return std::nullopt;
}

static StringRef sortKeyword(Sort S) {
  switch (S) {
#define MIR_SORT(ID, SortName, Representation)                                 \
  case Sort::ID:                                                               \
    return #ID;
#include "metaphir/IR/Sorts.def"
  }
  llvm_unreachable("invalid sort");
}

// !mpir.sort<Value>
mlir::Type SortType::parse(AsmParser &Parser) {
  StringRef Name;
  SMLoc Loc = Parser.getCurrentLocation();
  if (Parser.parseLess() || Parser.parseKeyword(&Name) || Parser.parseGreater())
    return {};
  std::optional<Sort> S = parseSortName(Name);
  if (!S) {
    Parser.emitError(Loc, "unknown sort '") << Name << "'";
    return {};
  }
  return SortType::get(Parser.getContext(), *S);
}

void SortType::print(AsmPrinter &Printer) const {
  Printer << "<" << sortKeyword(getSort()) << ">";
}

// #mpir.opcode<add>
Attribute OpcodeAttr::parse(AsmParser &Parser, mlir::Type) {
  std::string Name;
  SMLoc Loc = Parser.getCurrentLocation();
  if (Parser.parseLess() || Parser.parseKeywordOrString(&Name) ||
      Parser.parseGreater())
    return {};
  for (unsigned ID = 0; ID != Instruction::NumInstructionIDs; ++ID)
    if (Instruction::getOpcodeName(Instruction::InstructionID(ID)) == Name)
      return OpcodeAttr::get(Parser.getContext(),
                             Instruction::InstructionID(ID));
  Parser.emitError(Loc, "unknown instruction matcher '") << Name << "'";
  return {};
}

void OpcodeAttr::print(AsmPrinter &Printer) const {
  Printer << "<" << Instruction::getOpcodeName(getValue()) << ">";
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

StringRef mpir::stringifyOperandKind(OperandKind Kind) {
  switch (Kind) {
  case OperandKind::TypedValue:
    return "typed";
  case OperandKind::Value:
    return "value";
  case OperandKind::TypeOnly:
    return "type";
  case OperandKind::ValueArray:
    return "values";
  case OperandKind::TypedValueArray:
    return "typed_values";
  case OperandKind::Predicate:
    return "predicate";
  case OperandKind::Alignment:
    return "align";
  case OperandKind::AddressSpace:
    return "addrspace";
  case OperandKind::InRangeLower:
    return "inrange_lower";
  case OperandKind::InRangeUpper:
    return "inrange_upper";
  }
  llvm_unreachable("invalid operand kind");
}

template <typename OpT>
static SmallVector<MatcherOperandView, 4> operandsOf(OpT Op) {
  SmallVector<MatcherOperandView, 4> Result;
  ValueRange Values = Op.getOperandValues();
  unsigned Next = 0;
  for (int32_t Raw : Op.getOperandKinds()) {
    auto Kind = OperandKind(Raw);
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

SmallVector<MatcherOperandView, 4> mpir::getMatcherOperands(Operation *Op) {
  if (auto Inst = dyn_cast<InstOp>(Op))
    return operandsOf(Inst);
  return operandsOf(cast<UseOp>(Op));
}

/// Checks what the matcher uses' attributes say about their operands.
template <typename OpT> static LogicalResult verifyMatcherUse(OpT Op) {
  unsigned Needed = 0;
  for (int32_t Raw : Op.getOperandKinds()) {
    if (Raw < 0 || Raw > int32_t(OperandKind::InRangeUpper))
      return Op.emitOpError("has an invalid operand kind ") << Raw;
    Needed += getNumOperandValues(OperandKind(Raw));
  }
  if (Needed != Op.getOperandValues().size())
    return Op.emitOpError("operand kinds need ")
           << Needed << " operand values, but it has "
           << Op.getOperandValues().size();
  if (Op.getFlags().size() != Op.getFlagModes().size())
    return Op.emitOpError("needs one mode per flag");
  unsigned Captured = 0;
  for (int32_t Mode : Op.getFlagModes()) {
    if (Mode < 0 || Mode > int32_t(FlagMode::Captured))
      return Op.emitOpError("has an invalid flag mode ") << Mode;
    Captured += Mode == int32_t(FlagMode::Captured);
  }
  if (Captured != Op.getFlagCaptures().size())
    return Op.emitOpError("needs one capture per captured flag");
  return success();
}

LogicalResult InstOp::verify() {
  if (failed(verifyMatcherUse(*this)))
    return failure();
  Instruction::InstructionID ID = getOpcode().getValue();
  for (int32_t Flag : getFlags())
    if (Flag < 0 || Flag >= InstructionFlag::NumFlagIDs ||
        !(Instruction::getSupportedFlags(ID) &
          Instruction::mask(InstructionFlag::FlagID(Flag))))
      return emitOpError("flag ") << Flag << " is not valid for '"
                                  << Instruction::getOpcodeName(ID) << "'";
  if (getCommutative() && !Instruction::isCommutative(ID))
    return emitOpError("'")
           << Instruction::getOpcodeName(ID) << "' is not commutative";
  return success();
}

LogicalResult UseOp::verify() { return verifyMatcherUse(*this); }

LogicalResult UseOp::verifySymbolUses(SymbolTableCollection &Symbols) {
  if (!Symbols.lookupNearestSymbolFrom<MatcherOp>(*this, getMatcherAttr()))
    return emitOpError("uses unknown matcher '") << getMatcher() << "'";
  return success();
}

LogicalResult FlagOp::verifySymbolUses(SymbolTableCollection &Symbols) {
  if (!Symbols.lookupNearestSymbolFrom<MetaFlagDefOp>(*this, getFlagAttr()))
    return emitOpError("uses unknown metaflag '") << getFlag() << "'";
  return success();
}

//===----------------------------------------------------------------------===//
// Names and region kinds
//===----------------------------------------------------------------------===//

/// A printable SSA name for a pattern name: letters, digits and '_'.
static std::string asmName(StringRef Prefix, StringRef Name) {
  std::string Result = Prefix.str();
  for (char C : Name)
    Result += llvm::isAlnum(C) ? C : '_';
  return Result;
}

void VarOp::getAsmResultNames(OpAsmSetValueNameFn SetName) {
  SetName(getResult(), asmName("", getName()));
}

void InstOp::getAsmResultNames(OpAsmSetValueNameFn SetName) {
  if (std::optional<StringRef> Name = getName())
    SetName(getResult(), asmName("i_", *Name));
}

void UseOp::getAsmResultNames(OpAsmSetValueNameFn SetName) {
  if (std::optional<StringRef> Name = getName())
    SetName(getResult(), asmName("u_", *Name));
}

// A branch and an alternative are pieces of a pattern: a graph, in which
// instructions may refer to each other in cycles (through phis).
RegionKind BranchOp::getRegionKind(unsigned) { return RegionKind::Graph; }
RegionKind AltOp::getRegionKind(unsigned) { return RegionKind::Graph; }
