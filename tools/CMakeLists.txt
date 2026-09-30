add_executable(metaphir-lex metaphir-lex.cpp)
target_link_libraries(metaphir-lex PRIVATE metaphir-parser)

add_executable(metaphir-parse metaphir-parse.cpp)
target_link_libraries(metaphir-parse PRIVATE metaphir-parser)

add_executable(metaphir-match metaphir-match.cpp)
target_link_libraries(metaphir-match
  PRIVATE
    metaphir-index-lib
    metaphir-web
    metaphir-matching
    metaphir-parser
    LLVMAsmParser
    LLVMIRReader
)

add_executable(metaphir-index metaphir-index.cpp)
target_link_libraries(metaphir-index
  PRIVATE
    metaphir-index-lib
    metaphir-web-publish
    metaphir-matching
    metaphir-parser
    LLVMAsmParser
    LLVMIRReader
)

foreach(tool metaphir-lex metaphir-parse metaphir-match metaphir-index)
  target_compile_definitions(${tool}
    PRIVATE METAPHIR_VERSION="${PROJECT_VERSION}")
endforeach()
