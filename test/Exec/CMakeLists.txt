add_metaphir_test(metaphir-exec-test ConstraintCoercionTest.cpp ExprEvaluatorTest.cpp
                  PlanMatcherTest.cpp CompiledPatternTest.cpp)
target_link_libraries(metaphir-exec-test PRIVATE metaphir-compile LLVMAsmParser)
