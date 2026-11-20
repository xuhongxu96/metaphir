# The pass tests, a directory per stage, as metaphir/Transforms: Lowering,
# ToPlan and ToIndex. The lit tests there are found by lit; these are the
# gtests.
add_metaphir_test(metaphir-transforms-test Lowering/DesugarMetaFlagsTest.cpp
                  Lowering/ExpandMatchersTest.cpp
                  Lowering/LowerAlternativesTest.cpp
                  Lowering/CheckBindingsTest.cpp)
# TransformTest.h, the fixture the stages' gtests share.
target_include_directories(metaphir-transforms-test
                           PRIVATE ${CMAKE_CURRENT_SOURCE_DIR})
target_link_libraries(metaphir-transforms-test PRIVATE metaphir-compile)
target_link_libraries(metaphir-transforms-test PRIVATE MLIRParser)
