#include "metaphir/Dialect/Pattern/NamedEnum.h"

namespace llvm {
namespace metaphir {
namespace mpir {

template <> mlir::FailureOr<Sort> parseEnumerator<Sort>(mlir::AsmParser &Parser) {
  SMLoc Loc = Parser.getCurrentLocation();
  StringRef Name;
  if (Parser.parseKeyword(&Name))
    return mlir::failure();
  if (std::optional<Sort> S = getSortFromKeyword(Name))
    return *S;
  return Parser.emitError(Loc) << "expected a sort, got: " << Name;
}

template <> void printEnumerator<Sort>(mlir::AsmPrinter &Printer, Sort Value) {
  if (isEnumerator(Value))
    Printer << getSortKeyword(Value);
  else
    Printer << "<invalid " << unsigned(Value) << ">";
}

template <>
mlir::FailureOr<metaflag::Placement>
parseEnumerator<metaflag::Placement>(mlir::AsmParser &Parser) {
  unsigned Mask = 0;
  do {
    SMLoc Loc = Parser.getCurrentLocation();
    StringRef Name;
    if (Parser.parseKeyword(&Name))
      return mlir::failure();
    if (Name == "instruction")
      Mask |= metaflag::InstructionPlacement;
    else if (Name == "operand")
      Mask |= metaflag::OperandPlacement;
    else
      return Parser.emitError(Loc)
             << "expected 'instruction' or 'operand', got: " << Name;
  } while (succeeded(Parser.parseOptionalVerticalBar()));
  return metaflag::Placement(Mask);
}

template <>
void printEnumerator<metaflag::Placement>(mlir::AsmPrinter &Printer,
                                          metaflag::Placement Value) {
  if (!isEnumerator(Value)) {
    Printer << "<invalid " << unsigned(Value) << ">";
    return;
  }
  if (Value & metaflag::InstructionPlacement)
    Printer << "instruction";
  if (Value == metaflag::AnyPlacement)
    Printer << "|";
  if (Value & metaflag::OperandPlacement)
    Printer << "operand";
}

} // namespace mpir
} // namespace metaphir
} // namespace llvm
