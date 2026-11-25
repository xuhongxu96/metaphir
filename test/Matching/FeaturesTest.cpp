#include "metaphir/Matching/Features.h"
#include "gtest/gtest.h"

using namespace llvm;
using namespace llvm::metaphir;

namespace {

// Each measure keeps the number that satisfies the most queries: the most
// known trailing zeros, and the fewest bits for the others.
TEST(MeasureOrderTest, DeclaresAnOrderForEveryMeasure) {
  EXPECT_EQ(getMeasureOrder(Measure::TrailingZeros), MeasureOrder::Most);
  EXPECT_EQ(getMeasureOrder(Measure::ActiveBits), MeasureOrder::Least);
  EXPECT_EQ(getMeasureOrder(Measure::RangeSignedBits), MeasureOrder::Least);
  EXPECT_EQ(getMeasureOrder(Measure::RangeUnsignedBits), MeasureOrder::Least);
  EXPECT_EQ(mergeMeasure(Measure::TrailingZeros, 3, 5), 5u);
  EXPECT_EQ(mergeMeasure(Measure::RangeUnsignedBits, 3, 5), 3u);
}

TEST(MeasureOrderTest, MergingFeaturesKeepsEachMeasuresOrder) {
  auto ID = instruction::I_add;
  FunctionFeatures A, B;
  A.Measures = {
      FunctionFeatures::getMeasureKey(ID, 0, Measure::TrailingZeros, 3),
      FunctionFeatures::getMeasureKey(ID, 0, Measure::RangeUnsignedBits, 9)};
  B.Measures = {
      FunctionFeatures::getMeasureKey(ID, 0, Measure::TrailingZeros, 7),
      FunctionFeatures::getMeasureKey(ID, 0, Measure::RangeUnsignedBits, 4)};
  llvm::sort(A.Measures);
  llvm::sort(B.Measures);
  A.merge(B);
  EXPECT_EQ(A.getMeasure(ID, 0, Measure::TrailingZeros), 7u);
  EXPECT_EQ(A.getMeasure(ID, 0, Measure::RangeUnsignedBits), 4u);
}

} // namespace
