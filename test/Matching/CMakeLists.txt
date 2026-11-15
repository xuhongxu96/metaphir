add_metaphir_test(metaphir-matching-test FeaturesTest.cpp OpcodePredicatesTest.cpp TypeCodeTest.cpp
                  BindingTest.cpp UseOracleTest.cpp)

target_link_libraries(metaphir-matching-test
                      PRIVATE metaphir-matching metaphir-compile LLVMAsmParser LLVMBitWriter LLVMBitReader)
