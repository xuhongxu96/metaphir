#include "metaphir/IR/MIRContext.h"
#include "metaphir/IR/Pattern.h"
#include "metaphir/Parser/MIRParser.h"
#include "llvm/Support/MemoryBuffer.h"
#include "llvm/Support/SourceMgr.h"
#include "llvm/Support/raw_ostream.h"

using namespace llvm;
using namespace llvm::metaphir;

int main(int Argc, char **Argv) {
  if (Argc != 2) {
    errs() << "usage: metaphir-parse <input>\n";
    return 1;
  }
  auto Buffer = MemoryBuffer::getFile(Argv[1]);
  if (!Buffer) {
    errs() << Argv[1] << ": " << Buffer.getError().message() << '\n';
    return 1;
  }
  SourceMgr SM;
  SM.AddNewSourceBuffer(std::move(*Buffer), SMLoc());
  SMDiagnostic Error;
  MIRContext Context;
  MIRParser Parser(SM.getMemoryBuffer(SM.getMainFileID())->getBuffer(), SM,
                   Error, Context);
  Pattern *P = nullptr;
  if (Parser.parse(P)) {
    Error.print(Argv[0], errs());
    return 1;
  }
  outs() << *P;
  return 0;
}
