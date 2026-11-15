// Runs MetaphIR's passes on patterns written as MLIR, as mlir-opt does: what
// the tests of the passes run.
#include "metaphir/Dialect/Expr/ExprDialect.h"
#include "metaphir/Dialect/Index/IndexDialect.h"
#include "metaphir/Dialect/Pattern/PatternDialect.h"
#include "metaphir/Dialect/Plan/PlanDialect.h"
#include "metaphir/Transforms/Lowering.h"
#include "metaphir/Transforms/Retrieval.h"
#include "metaphir/Transforms/Structuralize.h"
#include "metaphir/Transforms/ToIndex.h"
#include "metaphir/Transforms/ToPlan.h"
#include "mlir/IR/DialectRegistry.h"
#include "mlir/Tools/mlir-opt/MlirOptMain.h"
#include "mlir/Transforms/Passes.h"

using namespace llvm;

int main(int argc, char **argv) {
  mlir::registerCanonicalizerPass();
  mlir::registerCSEPass();
  metaphir::registerLoweringPasses();
  metaphir::registerToPlanPass();
  metaphir::registerToIndexPass();
  metaphir::registerIndexStructuralizePass();
  metaphir::registerIndexRetrievalPasses();

  mlir::DialectRegistry Registry;
  Registry
      .insert<metaphir::mpir::PatternDialect, metaphir::mpir_expr::ExprDialect,
              metaphir::mpir_plan::PlanDialect>();
  return mlir::asMainReturnCode(
      mlir::MlirOptMain(argc, argv, "MetaphIR pass driver\n", Registry));
}
