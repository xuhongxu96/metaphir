add_metaphir_test(
  metaphir-matching-test
  ConstraintCoercionTest.cpp
  ConstraintInterpreterTest.cpp
  FeaturesTest.cpp
  PatternMatcherTest.cpp
  SubtreeMatcherTest.cpp
  InstructionMatcherTest.cpp
  TypeMatcherTest.cpp
  MetaFlagTest.cpp
  End2EndTest.cpp)

target_link_libraries(metaphir-matching-test
                      PRIVATE metaphir-matching metaphir-parser LLVMAsmParser)
