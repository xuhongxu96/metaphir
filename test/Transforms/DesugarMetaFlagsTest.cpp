//===- DesugarMetaFlagsTest.cpp - mpir-desugar-metaflags ------------------===//
//
// A defined metaflag becomes the constraint of its definition, read on the
// flag's subject; ':c' and ':o' are structural flags, not constraints, and stay
// for the next pass.
//
//===----------------------------------------------------------------------===//

#include "metaphir/Transforms/Lowering/DesugarMetaFlags.h"
#include "TransformTest.h"
#include "metaphir/Dialect/Expr/ExprDialect.h"

using namespace llvm;
using namespace llvm::metaphir;

namespace {

class DesugarMetaFlagsTest : public test::TransformTest {};

TEST_F(DesugarMetaFlagsTest, DefinedMetaFlagBecomesARequirement) {
  ASSERT_TRUE(parse("%r = add i32 ?x:zero, ?y\n"));
  EXPECT_EQ(count<mpir::RequireOp>(), 0u);
  ASSERT_TRUE(mlir::succeeded(run(createDesugarMetaFlagsPass()))) << Errors;
  EXPECT_EQ(count<mpir::RequireOp>(), 1u);
  mpir::InstOp Add = first<mpir::InstOp>();
  ASSERT_TRUE(Add);
  // The flag is gone from the operand.
  if (std::optional<mlir::ArrayAttr> Flags = Add.getOperandMetaflags())
    for (mlir::Attribute Operand : *Flags)
      EXPECT_TRUE(cast<mlir::ArrayAttr>(Operand).empty());
}

TEST_F(DesugarMetaFlagsTest, InstructionMetaFlagBecomesARequirement) {
  ASSERT_TRUE(parse("%r = add:s i32 ?x, ?y\n"));
  ASSERT_TRUE(mlir::succeeded(run(createDesugarMetaFlagsPass()))) << Errors;
  EXPECT_EQ(count<mpir::RequireOp>(), 1u);
  EXPECT_FALSE(first<mpir::InstOp>().getMetaflags());
}

TEST_F(DesugarMetaFlagsTest, EachFlagIsOneRequirement) {
  ASSERT_TRUE(parse("%r = add i32 ?x:zero, ?y:zero\n"));
  ASSERT_TRUE(mlir::succeeded(run(createDesugarMetaFlagsPass()))) << Errors;
  EXPECT_EQ(count<mpir::RequireOp>(), 2u);
}

TEST_F(DesugarMetaFlagsTest, CommutativeFlagStays) {
  ASSERT_TRUE(parse("%r = add:c i32 ?x, ?y\n"));
  ASSERT_TRUE(mlir::succeeded(run(createDesugarMetaFlagsPass()))) << Errors;
  EXPECT_EQ(count<mpir::RequireOp>(), 0u);
  EXPECT_TRUE(first<mpir::InstOp>().getMetaflags());
}

TEST_F(DesugarMetaFlagsTest, OrSelfFlagStays) {
  ASSERT_TRUE(parse("%r = add:o i32 ?x, ?_y\n"));
  ASSERT_TRUE(mlir::succeeded(run(createDesugarMetaFlagsPass()))) << Errors;
  EXPECT_EQ(count<mpir::RequireOp>(), 0u);
  EXPECT_TRUE(first<mpir::InstOp>().getMetaflags());
}

TEST_F(DesugarMetaFlagsTest, StructuralFlagsStayBesideConstraintFlags) {
  ASSERT_TRUE(parse("%r = add:c:o:s i32 ?x:zero, ?_y\n"));
  ASSERT_TRUE(mlir::succeeded(run(createDesugarMetaFlagsPass()))) << Errors;
  // ':s' and ':zero' become constraints; ':c' and ':o' are left.
  EXPECT_EQ(count<mpir::RequireOp>(), 2u);
  std::optional<mlir::ArrayAttr> Flags = first<mpir::InstOp>().getMetaflags();
  ASSERT_TRUE(Flags);
  EXPECT_EQ(Flags->size(), 2u);
}

// A captured instruction is the subject of its flags as an uncaptured one is:
// the constraint reads the instruction, not its capture.
TEST_F(DesugarMetaFlagsTest, CapturedInstructionIsItsOwnSubject) {
  ASSERT_TRUE(parse("%r = add:?anch:s i32 ?x, ?y\n"));
  ASSERT_TRUE(mlir::succeeded(run(createDesugarMetaFlagsPass()))) << Errors;
  mpir::InstOp Add = first<mpir::InstOp>();
  ASSERT_TRUE(Add && Add.getCapture());
  mpir_expr::ReadOp Read = first<mpir_expr::ReadOp>();
  ASSERT_TRUE(Read);
  EXPECT_EQ(Read->getOperand(0), Add.getResult());
}

TEST_F(DesugarMetaFlagsTest, NoFlagsLeavesThePatternAlone) {
  ASSERT_TRUE(parse("%r = add i32 ?x, ?y\n"));
  ASSERT_TRUE(mlir::succeeded(run(createDesugarMetaFlagsPass()))) << Errors;
  EXPECT_EQ(count<mpir::RequireOp>(), 0u);
  EXPECT_EQ(count<mpir::InstOp>(), 1u);
}

TEST_F(DesugarMetaFlagsTest, RejectsAFlagOnAnOperandWithoutValue) {
  // A type-only operand has no value to be the flag's subject.
  ASSERT_TRUE(parseMLIR(R"(
mpir.metaflag_def @zero <param_names = ["v"], placement = operand> {
^bb0(%arg0: !mpir.sort<Unknown>):
  %0 = mpir_expr.read %arg0 : (!mpir.sort<Unknown>) -> !mpir.sort<Unknown>
  %1 = mpir_expr.call call "isZero"(%0) : (!mpir.sort<Unknown>) -> !mpir.sort<Boolean>
  mpir.yield %1 : <Boolean>
}
mpir.pattern {
  %i8 = mpir.type.int 8 : !mpir.sort<Type>
  %i32 = mpir.type.int 32 : !mpir.sort<Type>
  %x = mpir.var "x" : !mpir.sort<Operand>
  %a = mpir.inst <zext>(%i8, %x, %i32) <flags = [], flag_modes = [], operand_kinds = [typed_value, type_only], operand_metaflags = [[], [#mpir.metaflag<"zero", [], loc("no-subject":1:1)>]]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>) -> !mpir.sort<Instruction>
}
)"));
  EXPECT_TRUE(mlir::failed(run(createDesugarMetaFlagsPass())));
  EXPECT_NE(Errors.find("metaflag ':zero' has no value to use as its subject"),
            std::string::npos)
      << Errors;
}

} // namespace
