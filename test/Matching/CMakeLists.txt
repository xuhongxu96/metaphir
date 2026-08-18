add_metaphir_test(metaphir-matching-test
  ConstraintInterpreterTest.cpp
  NaiveMatcherTest.cpp
)

target_link_libraries(metaphir-matching-test
  PRIVATE
    metaphir-matching
    LLVMAsmParser
)

set(METAPHIR_MATCHING_TEST_CASES
  MIRMatcher-Aggregate.ll
  MIRMatcher-Arrays.ll
  MIRMatcher-BasicBlockMembership.ll
  MIRMatcher-CrossBasicBlock.ll
  MIRMatcher-Constraints.ll
  MIRMatcher-ConstraintBindings.ll
  MIRMatcher-Graph.ll
  MIRMatcher-FloatingConstants.ll
  MIRMatcher-Intrinsic.ll
  MIRMatcher-MetaFlags-Constants.ll
  MIRMatcher-MetaFlags-OrSelf.ll
  MIRMatcher-MetaFlags-Uses.ll
  MIRMatcher-MetaVariables.ll
  MIRMatcher-KeyedOperands.ll
  MIRMatcher-SemanticFlags.ll
)

foreach(test_case IN LISTS METAPHIR_MATCHING_TEST_CASES)
  get_filename_component(test_name ${test_case} NAME_WE)
  add_test(
    NAME MetaphIR.Matching.${test_name}
    COMMAND
      ${LLVM_TOOLS_BINARY_DIR}/llvm-lit -sv
      --skip-test-time-recording
      -D "metaphir_lex=$<TARGET_FILE:metaphir-lex>"
      -D "metaphir_parse=$<TARGET_FILE:metaphir-parse>"
      -D "metaphir_match=$<TARGET_FILE:metaphir-match>"
      "--filter=:: Matching/${test_case}$"
      ${METAPHIR_TEST_DIR}
  )
endforeach()
