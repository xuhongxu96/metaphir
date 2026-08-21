add_metaphir_test(
  metaphir-matching-test
  ConstraintInterpreterTest.cpp
  PatternMatcherTest.cpp
  SubtreeMatcherTest.cpp
  InstructionMatcherTest.cpp
  TypeMatcherTest.cpp
  MetaFlagMatcherTest.cpp
  End2EndTest.cpp)

target_link_libraries(metaphir-matching-test
                      PRIVATE metaphir-matching metaphir-parser LLVMAsmParser)

set(METAPHIR_MATCHING_TEST_CASES
    MIRMatcher-Aggregate.ll
    MIRMatcher-FloatingConstants.ll
    MIRMatcher-MetaVariables.ll
    MIRMatcher-Arrays.ll
    MIRMatcher-Graph.ll
    MIRMatcher-NamedInstOperand.ll
    MIRMatcher-BasicBlockMembership.ll
    MIRMatcher-CrossBlock.ll
    MIRMatcher-VectorTypes.ll
    MIRMatcher-Inputs.ll
    MIRMatcher-NewInstructionMatchers.ll
    MIRMatcher-BitCount.ll
    MIRMatcher-Intrinsic.ll
    MIRMatcher-PHICyclic.ll
    MIRMatcher-ConstantIntMeta.ll
    MIRMatcher-KeyedOperands.ll
    MIRMatcher-PHI.ll
    MIRMatcher-ConstraintBindings.ll
    MIRMatcher-LiteralIntrinsic.ll
    MIRMatcher-PowerOfTwoMeta.ll
    MIRMatcher-ConstraintBitWidth.ll
    MIRMatcher-ConstantSplatMeta.ll
    MIRMatcher-TreatIntAsVec.ll
    MIRMatcher-MetaFlags-Constants.ll
    MIRMatcher-SemanticFlags.ll
    MIRMatcher-Constraints.ll
    MIRMatcher-MetaFlags-OrSelf.ll
    MIRMatcher-CrossBasicBlock.ll
    MIRMatcher-MetaFlags-Uses.ll)

foreach(test_case IN LISTS METAPHIR_MATCHING_TEST_CASES)
  get_filename_component(test_name ${test_case} NAME_WE)
  add_test(
    NAME MetaphIR.Matching.${test_name}
    COMMAND
      ${LLVM_TOOLS_BINARY_DIR}/llvm-lit -sv --skip-test-time-recording -D
      "metaphir_lex=$<TARGET_FILE:metaphir-lex>" -D
      "metaphir_parse=$<TARGET_FILE:metaphir-parse>" -D
      "metaphir_match=$<TARGET_FILE:metaphir-match>"
      "--filter=:: Matching/${test_case}$" ${METAPHIR_TEST_DIR})
endforeach()
