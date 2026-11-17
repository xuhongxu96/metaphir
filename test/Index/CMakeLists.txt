add_metaphir_test(metaphir-index-test CorpusIndexTest.cpp FeatureSchemaTest.cpp FunctionPackTest.cpp)

target_link_libraries(metaphir-index-test PRIVATE metaphir-index-lib
                                                  LLVMAsmParser)
