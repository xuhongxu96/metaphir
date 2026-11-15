add_metaphir_test(metaphir-exec-test ExprEvaluatorTest.cpp)
target_link_libraries(metaphir-exec-test PRIVATE metaphir-exec LLVMAsmParser)
