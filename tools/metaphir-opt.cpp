// Runs MetaphIR's passes on patterns written as MLIR, as mlir-opt does: what
// the tests of the passes run.
#include "metaphir/Dialect/Pattern/PatternDialect.h"
#include "mlir/IR/DialectRegistry.h"
#include "mlir/Tools/mlir-opt/MlirOptMain.h"
#include "mlir/Transforms/Passes.h"

using namespace llvm;

int main(int argc, char **argv) {
  mlir::registerCanonicalizerPass();
  mlir::registerCSEPass();

  mlir::DialectRegistry Registry;
  Registry.insert<metaphir::mpir::PatternDialect>();
  return mlir::asMainReturnCode(
      mlir::MlirOptMain(argc, argv, "MetaphIR pass driver\n", Registry));
}
