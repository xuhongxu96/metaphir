#include "metaphir/IR/Constants.h"
#include "llvm/Support/ErrorHandling.h"

namespace llvm {
namespace metaphir {
namespace keyword_constant {

StringRef getKeywordName(KeywordID ID) {
  switch (ID) {
#define MIR_KEYWORD_CONSTANT(ID, Spelling)                                     \
  case K_##ID:                                                                 \
    return #Spelling;
#include "metaphir/IR/KeywordConstants.def"
  }
  llvm_unreachable("invalid keyword constant ID");
}

} // namespace keyword_constant
} // namespace metaphir
} // namespace llvm
