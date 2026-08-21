#include "metaphir/Matching/SubtreeMatcher.h"
#include "metaphir/IR/DerivedTypes.h"
#include "metaphir/IR/Instruction.h"
#include "metaphir/IR/MIRContext.h"
#include "metaphir/IR/MetaVariable.h"
#include "metaphir/IR/Values.h"
#include "metaphir/Matching/Instantiation.h"
#include "llvm/AsmParser/Parser.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/DerivedTypes.h"
#include "llvm/IR/LLVMContext.h"
#include "llvm/IR/Module.h"
#include "llvm/Support/SourceMgr.h"
#include "gtest/gtest.h"

using namespace llvm;
using namespace llvm::metaphir;

static std::unique_ptr<Module> parseModule(StringRef IR, LLVMContext &Context) {
  SMDiagnostic Error;
  return parseAssemblyString(IR, Error, Context);
}

TEST(SubtreeMatcherTest, NonValueMetaTypesFailToMatchLLVMValues) {
  MIRContext Context;
  SourceRange Range;
  LLVMContext LLVMContext;
  ConstantInt *Target =
      ConstantInt::get(llvm::Type::getInt32Ty(LLVMContext), 0);

  for (MetaType Type : {MetaType::Type, MetaType::CmpPredicate,
                        MetaType::TypeArray, MetaType::ValueArray}) {
    MetaVariable *Variable =
        MetaVariable::get(Context, "variable", Type, Range);
    Instantiation State;
    EXPECT_TRUE(
        SubtreeMatcher(*Variable, *Target, std::move(State)).match().empty());
  }
}

TEST(SubtreeMatcherTest, RejectsUnknownMetaTypeAsUnexpected) {
  MIRContext Context;
  SourceRange Range;
  LLVMContext LLVMContext;
  MetaVariable *Variable =
      MetaVariable::get(Context, "unknown", MetaType::Unknown, Range);
  ConstantInt *Target =
      ConstantInt::get(llvm::Type::getInt32Ty(LLVMContext), 0);

  EXPECT_DEATH(
      {
        Instantiation State;
        (void)SubtreeMatcher(*Variable, *Target, std::move(State)).match();
      },
      "unexpected meta type 'Unknown'");
}

TEST(SubtreeMatcherTest, InstantiationsRepresentNonValueBindings) {
  MIRContext Context;
  SourceRange Range;
  MetaVariable *Pred =
      MetaVariable::get(Context, "pred", MetaType::CmpPredicate, Range);
  Instantiation::Binding Predicate(CmpInst::ICMP_EQ);
  Instantiation::Binding OtherPredicate(CmpInst::ICMP_NE);
  Instantiation::Binding Integer(APInt(32, 17));
  Instantiation::Binding Flag(true);

  EXPECT_EQ(Predicate, Instantiation::Binding(CmpInst::ICMP_EQ));
  EXPECT_NE(Predicate, OtherPredicate);
  EXPECT_EQ(Integer, Instantiation::Binding(APInt(32, 17)));
  EXPECT_EQ(Flag, Instantiation::Binding(true));

  Instantiation State;
  State.bind(*Pred, Predicate);
  ASSERT_NE(State.lookup(*Pred), nullptr);
  EXPECT_EQ(*State.lookup(*Pred), Predicate);
}

TEST(SubtreeMatcherTest, AggregateConstantsRequireMatchingShape) {
  MIRContext Context;
  SourceRange Range;
  llvm::metaphir::Type *I32 = llvm::metaphir::IntegerType::get(Context, 32);
  llvm::metaphir::Value *Elements[] = {
      IntegerConstant::get(Context, APSInt(APInt(32, 1), false), Range),
      IntegerConstant::get(Context, APSInt(APInt(32, 2), false), Range),
  };
  llvm::metaphir::Type *Types[] = {I32, I32};
  AggregateConstant *Array = AggregateConstant::get(
      Context, Types, Elements, AggregateConstant::Square, Range);

  LLVMContext LLVMContext;
  std::unique_ptr<Module> Module = parseModule(
      R"(
        @array = constant [2 x i32] [i32 1, i32 2]
        @wrong_elements = constant [2 x i32] [i32 1, i32 3]
        @vector = constant <2 x i32> <i32 1, i32 2>
      )",
      LLVMContext);
  ASSERT_NE(Module, nullptr);

  Instantiation ArrayBindings;
  EXPECT_FALSE(
      SubtreeMatcher(*Array,
                     *Module->getGlobalVariable("array")->getInitializer(),
                     std::move(ArrayBindings))
          .match()
          .empty());
  Instantiation WrongElementBindings;
  EXPECT_TRUE(
      SubtreeMatcher(
          *Array,
          *Module->getGlobalVariable("wrong_elements")->getInitializer(),
          std::move(WrongElementBindings))
          .match()
          .empty());
  Instantiation VectorBindings;
  EXPECT_TRUE(
      SubtreeMatcher(*Array,
                     *Module->getGlobalVariable("vector")->getInitializer(),
                     std::move(VectorBindings))
          .match()
          .empty());
}
