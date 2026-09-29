add_metaphir_test(metaphir-parser-test LibraryTest.cpp SourceRangeTest.cpp)
target_link_libraries(metaphir-parser-test PRIVATE metaphir-parser)
