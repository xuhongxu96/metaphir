add_metaphir_test(metaphir-exec-test ConstraintCoercionTest.cpp ConcreteEvaluatorTest.cpp
                  PlanMatcherTest.cpp CompiledPatternTest.cpp)
target_link_libraries(metaphir-exec-test PRIVATE metaphir-compile LLVMAsmParser)
