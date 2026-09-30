add_metaphir_test(metaphir-web-test WebQueryTest.cpp)

target_link_libraries(metaphir-web-test PRIVATE metaphir-web-publish
                                                LLVMAsmParser)
