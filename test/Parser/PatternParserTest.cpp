//===- PatternParserTest.cpp - What the parser's mpir records ------------===//
//
// The standard library each pattern is parsed with, and where the parser
// says its values are written: the parameters of definitions, which a
// caller of getSourceRange could otherwise find without a location.
//
//===----------------------------------------------------------------------===//

#include "metaphir/Parser/PatternParser.h"
#include "metaphir/Dialect/Expr/ExprDialect.h"
#include "metaphir/Dialect/Pattern/PatternDialect.h"
#include "metaphir/Dialect/Pattern/SourceLocation.h"
#include "metaphir/IR/Constraint.h"
#include "metaphir/Transforms/Lowering.h"
#include "mlir/IR/MLIRContext.h"
#include "mlir/IR/SymbolTable.h"
#include "llvm/Support/MemoryBuffer.h"
#include "llvm/Support/SourceMgr.h"
#include "llvm/Support/raw_ostream.h"
#include "gtest/gtest.h"

using namespace llvm;
using namespace llvm::metaphir;

namespace {

class PatternParserTest : public testing::Test {
protected:
  mlir::ModuleOp parse(StringRef Source) {
    SMDiagnostic Diag;
    Module = parsePatternBuffer(
        MemoryBuffer::getMemBufferCopy(Source, "pattern"), SM, Context, Diag);
    if (!Module) {
      std::string Message;
      raw_string_ostream OS(Message);
      Diag.print("test", OS);
      ADD_FAILURE() << Message;
      return nullptr;
    }
    return *Module;
  }

  /// One-based line and column of where Loc's range begins.
  std::pair<unsigned, unsigned> lineAndColumn(mlir::Location Loc) {
    SMRange Range = getSourceRange(Loc);
    EXPECT_TRUE(Range.Start.isValid());
    if (!Range.Start.isValid())
      return {0, 0};
    return SM.getLineAndColumn(Range.Start);
  }

  SourceMgr SM;
  mlir::MLIRContext Context;
  mlir::OwningOpRef<mlir::ModuleOp> Module;
};

// Every pattern is parsed after the standard library, whose definitions keep
// locations in its own buffer, after the pattern's.
TEST_F(PatternParserTest, ParsesTheStandardLibraryFirst) {
  mlir::ModuleOp M = parse("%r = add i32 ?x:zero, ?y\n");
  ASSERT_TRUE(M);
  auto Zero = mlir::SymbolTable::lookupSymbolIn(M, "zero");
  ASSERT_TRUE(Zero && isa<mpir::MetaFlagDefOp>(Zero));
  EXPECT_EQ(SM.getMainFileID(), 1u);
  SMRange Range = getSourceRange(Zero->getLoc());
  unsigned Buffer = SM.FindBufferContainingLoc(Range.Start);
  ASSERT_NE(Buffer, 0u);
  EXPECT_EQ(SM.getMemoryBuffer(Buffer)->getBufferIdentifier(), "stdlib");
  // A definition is located at its name.
  EXPECT_TRUE(StringRef(Range.Start.getPointer()).starts_with(":zero(?v)"));
}

TEST_F(PatternParserTest, ConstraintDefinitionParameters) {
  mlir::ModuleOp M = parse(R"(constraint pair(?a, ?b) {
	?a == ?b
}

%r = add i32 ?x, ?y
)");
  ASSERT_TRUE(M);
  auto Def = dyn_cast_or_null<mpir::ConstraintDefOp>(
      mlir::SymbolTable::lookupSymbolIn(M, "pair"));
  ASSERT_TRUE(Def);
  mlir::Block &Body = Def.getBody().front();
  ASSERT_EQ(Body.getNumArguments(), 2u);
  // '?a' and '?b' are on the first line, at their own columns.
  EXPECT_EQ(lineAndColumn(Body.getArgument(0).getLoc()),
            std::make_pair(1u, 17u));
  EXPECT_EQ(lineAndColumn(Body.getArgument(1).getLoc()),
            std::make_pair(1u, 21u));
}

TEST_F(PatternParserTest, MetaFlagDefinitionParameters) {
  mlir::ModuleOp M = parse(R"(metaflag :between(?v, ?lo, ?hi) {
	sle(?lo, ?v) && sle(?v, ?hi)
}

%r = add i32 ?x, ?c:between(1, 2)
)");
  ASSERT_TRUE(M);
  auto Def = dyn_cast_or_null<mpir::MetaFlagDefOp>(
      mlir::SymbolTable::lookupSymbolIn(M, "between"));
  ASSERT_TRUE(Def);
  mlir::Block &Body = Def.getBody().front();
  ASSERT_EQ(Body.getNumArguments(), 3u);
  for (mlir::BlockArgument Parameter : Body.getArguments())
    EXPECT_EQ(lineAndColumn(Parameter.getLoc()).first, 1u);
}

TEST_F(PatternParserTest, MatchParametersBoundPerBranch) {
  mlir::ModuleOp M = parse(R"(match addm [] Binary (?ty ?x, ?y) {
	%ret = add ?ty ?x, ?y
} or {
	%ret = sub ?ty ?x, ?y
}

%r = addm i32 ?a, ?b
)");
  ASSERT_TRUE(M);
  auto Matcher = dyn_cast_or_null<mpir::MatcherOp>(
      mlir::SymbolTable::lookupSymbolIn(M, "addm"));
  ASSERT_TRUE(Matcher);
  unsigned NumBranches = 0;
  for (auto Branch : Matcher.getBody().front().getOps<mpir::BranchOp>()) {
    ++NumBranches;
    mlir::Block &Body = Branch.getBody().front();
    ASSERT_EQ(Body.getNumArguments(), 3u);
    for (mlir::BlockArgument Parameter : Body.getArguments())
      EXPECT_EQ(lineAndColumn(Parameter.getLoc()).first, 1u);
  }
  EXPECT_EQ(NumBranches, 2u);
}

// A metaflag on an instruction lowers to a constraint on the instruction
// itself: the pattern gets no capture for it.
TEST_F(PatternParserTest, InstructionMetaFlagConstrainsTheInstruction) {
  mlir::ModuleOp M = parse(R"(metaflag:i :isaddop(?i) {
	opcode(?i) == "add"
}

%r = add:isaddop i32 ?x, ?y
)");
  ASSERT_TRUE(M);
  std::string Errors;
  raw_string_ostream OS(Errors);
  ASSERT_TRUE(mlir::succeeded(lowerPatternModule(M, SM, OS))) << Errors;

  mpir::InstOp Add;
  M.walk([&](mpir::InstOp I) { Add = I; });
  ASSERT_TRUE(Add);
  EXPECT_FALSE(Add.getCapture());
  mpir::RequireOp Require;
  M.walk([&](mpir::RequireOp R) { Require = R; });
  ASSERT_TRUE(Require);
  auto Equal = Require.getCondition().getDefiningOp<mpir_expr::CallOp>();
  ASSERT_TRUE(Equal);
  EXPECT_EQ(Equal.getOperatorID(), unsigned(constraint::O_Equal));
  auto Opcode = Equal.getArgs()[0].getDefiningOp<mpir_expr::CallOp>();
  ASSERT_TRUE(Opcode);
  EXPECT_EQ(Opcode.getOperatorID(), unsigned(constraint::O_Opcode));
  auto Read = Opcode.getArgs()[0].getDefiningOp<mpir_expr::ReadOp>();
  ASSERT_TRUE(Read);
  EXPECT_EQ(Read.getValue(), Add.getResult());
}

} // namespace
