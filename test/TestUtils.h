//===- TestUtils.h - Shared helpers for MetaphIR unit tests -----*- C++ -*-===//
//
// Parsing helpers for LLVM IR and MetaphIR pattern sources, and a gtest
// fixture with constraint-expression builders.
//
//===----------------------------------------------------------------------===//

#ifndef METAPHIR_TEST_TESTUTILS_H
#define METAPHIR_TEST_TESTUTILS_H

#include "metaphir/IR/Constraint.h"
#include "metaphir/IR/MIRContext.h"
#include "metaphir/IR/Pattern.h"
#include "metaphir/IR/PatternLowering.h"
#include "metaphir/Parser/MIRParser.h"
#include "llvm/AsmParser/Parser.h"
#include "llvm/IR/LLVMContext.h"
#include "llvm/IR/Module.h"
#include "llvm/Support/MemoryBuffer.h"
#include "llvm/Support/SourceMgr.h"
#include "gtest/gtest.h"

#include <initializer_list>
#include <memory>

namespace llvm {
namespace metaphir {
namespace test {

/// Parses textual LLVM IR, returning null (and printing the diagnostic) on
/// failure.
inline std::unique_ptr<Module> parseLLVMModule(StringRef IR,
                                               LLVMContext &Context) {
  SMDiagnostic Diag;
  std::unique_ptr<Module> M = parseAssemblyString(IR, Diag, Context);
  if (!M)
    Diag.print("test", errs());
  return M;
}

/// Parses a MetaphIR source into a pattern. The buffer is added to \p SM,
/// which must outlive the pattern because its source ranges point into it.
/// Returns null on failure; the diagnostic is stored in \p Diag when given.
inline Pattern *parsePattern(StringRef Source, SourceMgr &SM,
                             MIRContext &Context,
                             SMDiagnostic *Diag = nullptr) {
  unsigned ID =
      SM.AddNewSourceBuffer(MemoryBuffer::getMemBuffer(Source), SMLoc());
  SMDiagnostic LocalDiag;
  SMDiagnostic &Error = Diag ? *Diag : LocalDiag;
  MIRParser Parser(SM.getMemoryBuffer(ID)->getBuffer(), SM, Error, Context);
  Pattern *Result = nullptr;
  if (Parser.parse(Result))
    return nullptr;
  return Result;
}

/// Lowers \p P and returns its single leaf variant, or null when lowering
/// fails or produces a number of variants other than one.
inline Pattern *lowerToSingleVariant(Pattern *P, MIRContext &Context) {
  if (!P)
    return nullptr;
  Expected<PatternVariants> Lowered = PatternLowering(Context).lower(P);
  if (!Lowered) {
    consumeError(Lowered.takeError());
    return nullptr;
  }
  if (Lowered->size() != 1)
    return nullptr;
  return (*Lowered)[0];
}

/// Parses a MetaphIR source and lowers it to its single leaf variant.
inline Pattern *parseAndLower(StringRef Source, SourceMgr &SM,
                              MIRContext &Context) {
  return lowerToSingleVariant(parsePattern(Source, SM, Context), Context);
}

/// Fixture with builders for constraint expressions.
class ConstraintTest : public testing::Test {
protected:
  MIRContext Context;
  SourceRange Range;

  IntegerConstraint *integer(int64_t Value) {
    return IntegerConstraint::create(Context, Value, Range);
  }

  BooleanConstraint *boolean(bool Value) {
    return BooleanConstraint::create(Context, Value, Range);
  }

  /// Builds a builtin operator when \p Name is one, and a call to a
  /// user-defined constraint otherwise.
  OperatorConstraint *operation(Constraint::ConstraintID Kind, StringRef Name,
                                std::initializer_list<Constraint *> Arguments) {
    Constraint::OperatorID ID = Constraint::getOperatorID(Name, Kind);
    std::optional<Constraint::OperatorSchema> Schema =
        Constraint::getOperatorSchema(ID);
    Constraint::ResultType Result =
        Schema ? Schema->Result : Constraint::BooleanResult;
    if (ID != Constraint::UnknownOperator)
      return OperatorConstraint::createBuiltin(Context, Kind, Result, ID,
                                               Arguments, Range);
    return OperatorConstraint::createUserDefined(Context, Kind, Result, Name,
                                                 Arguments, Range);
  }

  OperatorConstraint *unary(StringRef Name, Constraint *Operand) {
    return operation(Constraint::Unary, Name, {Operand});
  }

  OperatorConstraint *binary(StringRef Name, Constraint *Left,
                             Constraint *Right) {
    return operation(Constraint::Binary, Name, {Left, Right});
  }

  OperatorConstraint *call(StringRef Name, Constraint *Operand) {
    return operation(Constraint::Call, Name, {Operand});
  }

  OperatorConstraint *call(StringRef Name, Constraint *Left,
                           Constraint *Right) {
    return operation(Constraint::Call, Name, {Left, Right});
  }

  ArrayConstraint *array(Constraint::ResultType Type,
                         std::initializer_list<Constraint *> Elements) {
    return ArrayConstraint::create(Context, Type, Elements, Range);
  }

  ArrayAccessConstraint *access(Constraint *Array, Constraint *Index,
                                Constraint::ResultType Type) {
    return ArrayAccessConstraint::create(Context, Type, Array, Index, Range);
  }
};

} // namespace test
} // namespace metaphir
} // namespace llvm

#endif // METAPHIR_TEST_TESTUTILS_H
