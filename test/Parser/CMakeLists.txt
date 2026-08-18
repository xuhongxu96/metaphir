set(METAPHIR_TEST_CASES
  MIRLexer-CmpPredicate.ll
  MIRLexer-Constraint.ll
  MIRLexer-ConstantInt.ll
  MIRLexer-Function.ll
  MIRLexer-i1.ll
  MIRLexer-Instruction.ll
  MIRLexer-IntrinsicID.ll
  MIRLexer-Keyword.ll
  MIRLexer-MetaFlag.ll
  MIRLexer-OperandArray.ll
  MIRLexer-Type.ll
  MIRLexer-Value.ll
  MIRLexer.ll
  MIRParser.ll
  MIRParser-BasicBlocks.ll
  MIRParser-BasicBlockConflict.ll
  MIRParser-ConstraintErrors.ll
  MIRParser-Constraints.ll
  MIRParser-Instructions.ll
  MIRParser-Extensible.ll
  MIRParser-InvalidCommutative.ll
  MIRParser-InvalidFlag.ll
  MIRParser-InvalidMetaFlag.ll
  MIRParser-TypesConstants.ll
  MIRParser-Undefined.ll
)

foreach(test_case IN LISTS METAPHIR_TEST_CASES)
  get_filename_component(test_name ${test_case} NAME_WE)
  add_test(
    NAME MetaphIR.Parser.${test_name}
    COMMAND
      ${LLVM_TOOLS_BINARY_DIR}/llvm-lit -sv
      --skip-test-time-recording
      -D "metaphir_lex=$<TARGET_FILE:metaphir-lex>"
      -D "metaphir_parse=$<TARGET_FILE:metaphir-parse>"
      "--filter=:: Parser/${test_case}$"
      ${METAPHIR_TEST_DIR}
  )
  add_test(
    NAME MetaphIR.Parser.${test_name}Debug
    COMMAND ${LLVM_TOOLS_BINARY_DIR}/llvm-lit -sv
      --skip-test-time-recording
      -D "metaphir_lex=$<TARGET_FILE:metaphir-lex>"
      -D "metaphir_parse=$<TARGET_FILE:metaphir-parse>"
      "--filter=:: Parser/${test_case}$"
      ${METAPHIR_TEST_DIR}
  )
endforeach()
