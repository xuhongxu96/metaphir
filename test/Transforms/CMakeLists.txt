add_metaphir_test(metaphir-transforms-test DesugarMetaFlagsTest.cpp
                  ExpandMatchersTest.cpp LowerAlternativesTest.cpp
                  CheckBindingsTest.cpp)
target_link_libraries(metaphir-transforms-test PRIVATE metaphir-compile)
target_link_libraries(metaphir-transforms-test PRIVATE MLIRParser)
