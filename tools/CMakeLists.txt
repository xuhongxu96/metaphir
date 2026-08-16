add_executable(metaphir-lex metaphir-lex.cpp)
target_link_libraries(metaphir-lex PRIVATE metaphir-parser)

add_executable(metaphir-parse metaphir-parse.cpp)
target_link_libraries(metaphir-parse PRIVATE metaphir-parser)
