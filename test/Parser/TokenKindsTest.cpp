//===- TokenKindsTest.cpp - The order of the lexer's token kinds ----------===//
//
// Dumps the token kinds in order and compares them with
// test/Parser/Golden/token-kinds.txt, so changing how the keyword tables
// are defined cannot renumber or drop a token unnoticed.
//
//===----------------------------------------------------------------------===//

#include "metaphir/Parser/MIRToken.h"
#include "test/GoldenFile.h"
#include "gtest/gtest.h"

using namespace llvm;
using namespace llvm::metaphir;

namespace {

TEST(TokenKindsTest, MatchesTheGoldenDump) {
  std::string Dump;
  raw_string_ostream OS(Dump);
  // The last token kind is the last pattern setting.
  for (unsigned K = 0; K <= tok::kw_treatIntAsVec; ++K)
    OS << K << ' ' << tok::getTokenKindName(tok::Kind(K)) << '\n';
  test::expectMatchesGolden("test/Parser/Golden/token-kinds.txt", OS.str());
}

} // namespace
