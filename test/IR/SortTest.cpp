#include "metaphir/IR/Sort.h"
#include "metaphir/IR/Constraint.h"
#include "gtest/gtest.h"

using namespace llvm;
using namespace llvm::metaphir;

namespace {

TEST(SortTest, OrdersOperandSorts) {
  EXPECT_TRUE(isSubsort(Sort::Instruction, Sort::Value));
  EXPECT_TRUE(isSubsort(Sort::Function, Sort::Operand));
  EXPECT_TRUE(isSubsort(Sort::Boolean, Sort::Nat));
  EXPECT_TRUE(isSubsort(Sort::Boolean, Sort::Operand));
  EXPECT_TRUE(isSubsort(Sort::Nat, Sort::Integer));
  EXPECT_TRUE(isSubsort(Sort::CmpPredicate, Sort::String));
  // A number is not an IR value, and a block is not a first-class operand.
  EXPECT_FALSE(isSubsort(Sort::Nat, Sort::Value));
  EXPECT_FALSE(isSubsort(Sort::BasicBlock, Sort::Operand));
  // Unknown is the top.
  EXPECT_TRUE(isSubsort(Sort::Type, Sort::Unknown));
  EXPECT_FALSE(isSubsort(Sort::Unknown, Sort::Type));
}

TEST(SortTest, MeetsOccurrences) {
  EXPECT_EQ(meetSorts(Sort::Operand, Sort::Instruction), Sort::Instruction);
  EXPECT_EQ(meetSorts(Sort::Operand, Sort::Nat), Sort::Nat);
  EXPECT_EQ(meetSorts(Sort::Nat, Sort::Boolean), Sort::Boolean);
  EXPECT_EQ(meetSorts(Sort::Unknown, Sort::Type), Sort::Type);
  EXPECT_EQ(meetSorts(Sort::Operand, Sort::Operand), Sort::Operand);
  EXPECT_EQ(meetSorts(Sort::Instruction, Sort::Nat), std::nullopt);
  EXPECT_EQ(meetSorts(Sort::Instruction, Sort::Function), std::nullopt);
  EXPECT_EQ(meetSorts(Sort::Operand, Sort::BasicBlock), std::nullopt);
  EXPECT_EQ(meetSorts(Sort::Type, Sort::CmpPredicate), std::nullopt);
}

TEST(SortTest, ResolvesOperandToValue) {
  EXPECT_EQ(resolveSort(Sort::Operand), Sort::Value);
  EXPECT_EQ(resolveSort(Sort::Nat), Sort::Nat);
}

TEST(SortTest, CoercesBySubsortOrConversion) {
  EXPECT_TRUE(Constraint::canCoerce(Sort::Nat, Sort::Integer));
  EXPECT_TRUE(Constraint::canCoerce(Sort::CmpPredicate, Sort::String));
  EXPECT_TRUE(Constraint::canCoerce(Sort::Value, Sort::Integer));
  EXPECT_TRUE(Constraint::canCoerce(Sort::Boolean, Sort::Integer));
  EXPECT_TRUE(Constraint::canCoerce(Sort::Integer, Sort::Boolean));
  EXPECT_TRUE(Constraint::canCoerce(Sort::Type, Sort::String));
  EXPECT_FALSE(Constraint::canCoerce(Sort::Nat, Sort::Value));
  EXPECT_FALSE(Constraint::canCoerce(Sort::Type, Sort::Integer));
}

} // namespace
