#include "metaphir/IR/Constants.h"
#include "llvm/Support/ErrorHandling.h"

namespace llvm {
namespace metaphir {

StringRef KeywordConstant::getKeywordName(KeywordID ID) {
  switch (ID) {
#define MIR_KEYWORD_CONSTANT(ID, Spelling)                                     \
  case K_##ID:                                                                 \
    return #Spelling;
#include "metaphir/IR/KeywordConstants.def"
  }
  llvm_unreachable("invalid keyword constant ID");
}

} // namespace metaphir
} // namespace llvm
