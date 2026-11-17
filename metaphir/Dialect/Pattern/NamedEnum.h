//===- NamedEnum.h - Enumerations the dialects spell by name ----*- C++ -*-===//
//
// The enumerations that ODS cannot generate, because the tables define them
// (Flags.td, Sorts.td, ...) or because they are masks. A property of one of
// them (Mpir_NamedProp in PatternBase.td) is written as its name and stored as
// the enumerator.
//
//===----------------------------------------------------------------------===//

#ifndef METAPHIR_DIALECT_PATTERN_NAMEDENUM_H
#define METAPHIR_DIALECT_PATTERN_NAMEDENUM_H

#include "metaphir/IR/Constants.h"
#include "metaphir/IR/Instruction.h"
#include "metaphir/IR/MetaFlag.h"
#include "metaphir/IR/Sort.h"
#include "metaphir/IR/Type.h"
#include "mlir/IR/OpImplementation.h"
#include <optional>

namespace llvm {
namespace metaphir {
namespace mpir {

/// What an enumeration is called in diagnostics, and how its enumerators are
/// spelled. Specialized for each enumeration; the names are indexed by the
/// enumerator unless the specialization says otherwise.
template <typename EnumT> struct EnumNames;

template <> struct EnumNames<instruction_flag::FlagID> {
  static constexpr StringLiteral What = "a semantic flag";
  static ArrayRef<StringRef> names() { return instruction_flag::FlagNames; }
};

template <> struct EnumNames<keyword_constant::KeywordID> {
  static constexpr StringLiteral What = "a keyword constant";
  static ArrayRef<StringRef> names() {
    return keyword_constant::getKeywordNames();
  }
};

template <> struct EnumNames<primitive_type::TypeID> {
  static constexpr StringLiteral What = "a primitive type";
  static ArrayRef<StringRef> names() { return primitive_type::getNames(); }
};

template <> struct EnumNames<instruction::OperandSyntax> {
  static constexpr StringLiteral What = "an operand syntax";
  static ArrayRef<StringRef> names() { return instruction::OperandSyntaxNames; }
};

template <> struct EnumNames<aggregate_constant::Delimiter> {
  static constexpr StringLiteral What = "an aggregate kind";
  static ArrayRef<StringRef> names() { return aggregate_constant::getNames(); }
};

/// Whether Value is one of EnumT's enumerators.
template <typename EnumT> bool isEnumerator(EnumT Value) {
  return uint64_t(Value) < EnumNames<EnumT>::names().size();
}

/// Parses the name of an enumerator.
template <typename EnumT>
mlir::FailureOr<EnumT> parseEnumerator(mlir::AsmParser &Parser) {
  SMLoc Loc = Parser.getCurrentLocation();
  StringRef Name;
  if (Parser.parseKeyword(&Name))
    return mlir::failure();
  for (auto [Index, Each] : enumerate(EnumNames<EnumT>::names()))
    if (Each == Name)
      return EnumT(Index);
  return Parser.emitError(Loc) << "expected " << EnumNames<EnumT>::What
                               << ", got: " << Name;
}

/// Prints the name of an enumerator.
template <typename EnumT>
void printEnumerator(mlir::AsmPrinter &Printer, EnumT Value) {
  if (isEnumerator(Value))
    Printer << EnumNames<EnumT>::names()[unsigned(Value)];
  else
    Printer << "<invalid " << uint64_t(Value) << ">";
}

// The sorts are spelled by their keywords.
template <> mlir::FailureOr<Sort> parseEnumerator<Sort>(mlir::AsmParser &Parser);
template <> void printEnumerator<Sort>(mlir::AsmPrinter &Printer, Sort Value);
template <> inline bool isEnumerator(Sort Value) {
  return unsigned(Value) < NumSorts;
}

// The placements of a metaflag are a mask, written 'instruction', 'operand'
// or 'instruction|operand'.
template <>
mlir::FailureOr<metaflag::Placement>
parseEnumerator<metaflag::Placement>(mlir::AsmParser &Parser);
template <>
void printEnumerator<metaflag::Placement>(mlir::AsmPrinter &Printer,
                                          metaflag::Placement Value);
template <> inline bool isEnumerator(metaflag::Placement Value) {
  return Value >= metaflag::InstructionPlacement &&
         Value <= metaflag::AnyPlacement;
}

} // namespace mpir
} // namespace metaphir
} // namespace llvm

#endif // METAPHIR_DIALECT_PATTERN_NAMEDENUM_H
