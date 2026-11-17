//===- main.cpp - metaphir-tblgen -----------------------------------------===//
//
// Turns the language's tables (metaphir/**/*.td) into C++. Each table's
// emitter registers its own -gen-* option.
//
//===----------------------------------------------------------------------===//

#include "llvm/TableGen/Main.h"
#include "llvm/Support/CommandLine.h"
#include "llvm/Support/InitLLVM.h"

using namespace llvm;

int main(int argc, char **argv) {
  InitLLVM X(argc, argv);
  cl::ParseCommandLineOptions(argc, argv);
  // Every backend is a registered -gen-* option; there is no default one.
  MultiFileTableGenMainFn MainFn = nullptr;
  return TableGenMain(argv[0], MainFn);
}
