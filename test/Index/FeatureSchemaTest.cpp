//===- FeatureSchemaTest.cpp - The order of the index's feature schema ----===//
//
// The feature schema is stored in every index, in the order the instruction
// matchers, predicates, value classes and measures are defined. This compares
// it with test/Index/Golden/feature-schema.txt, so changing how those tables
// are defined cannot invalidate stored indexes unnoticed.
//
//===----------------------------------------------------------------------===//

#include "metaphir/Index/FeatureCoding.h"
#include "test/GoldenFile.h"
#include "gtest/gtest.h"

using namespace llvm;
using namespace llvm::metaphir;

namespace {

TEST(FeatureSchemaTest, MatchesTheGoldenDump) {
  std::string Dump;
  raw_string_ostream OS(Dump);
  unsigned Index = 0;
  for (const std::string &Feature : getFeatureSchema()) {
    // The LLVM revision changes with the checkout, not the tables.
    if (StringRef(Feature).starts_with("llvm:"))
      continue;
    OS << Index++ << ' ' << Feature << '\n';
  }
  test::expectMatchesGolden("test/Index/Golden/feature-schema.txt", OS.str());
}

} // namespace
