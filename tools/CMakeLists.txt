add_executable(metaphir-lex metaphir-lex.cpp)
target_link_libraries(metaphir-lex PRIVATE metaphir-parser)
target_compile_features(metaphir-lex PRIVATE cxx_std_17)
