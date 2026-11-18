#include "metaphir/Dialect/Pattern/PatternDialect.h"
#include "metaphir/IR/Constants.h"
#include "metaphir/IR/Type.h"
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

#include "metaphir/Dialect/Pattern/PatternEnums.cpp.inc"

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

template <typename EnumT>
static mlir::ArrayAttr getEnumArrayAttr(mlir::Builder &Builder,
                                        ArrayRef<EnumT> Values) {
  SmallVector<mlir::Attribute, 8> Attrs;
  for (EnumT Value : Values)
    Attrs.push_back(Builder.getI32IntegerAttr(int32_t(Value)));
  return Builder.getArrayAttr(Attrs);
}

void mpir::setMatcherProperties(mlir::Builder &Builder,
                                mlir::OperationState &State,
                                ArrayRef<instruction_flag::FlagID> Flags,
                                ArrayRef<FlagMode> Modes,
                                ArrayRef<OperandKind> Kinds) {
  State.propertiesAttr = Builder.getDictionaryAttr(
      {Builder.getNamedAttr("flags", getEnumArrayAttr(Builder, Flags)),
       Builder.getNamedAttr("flag_modes", getEnumArrayAttr(Builder, Modes)),
       Builder.getNamedAttr("operand_kinds",
                            getEnumArrayAttr(Builder, Kinds))});
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

template <typename OpT>
static SmallVector<MatcherOperandView, 4> operandsOf(OpT Op) {
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

SmallVector<MatcherOperandView, 4> mpir::getMatcherOperands(Operation *Op) {
  if (auto Inst = dyn_cast<InstOp>(Op))
    return operandsOf(Inst);
  return operandsOf(cast<UseOp>(Op));
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
static std::string asmName(StringRef Prefix, StringRef Name) {
  std::string Result = Prefix.str();
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
