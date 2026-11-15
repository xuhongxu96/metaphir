add_executable(metaphir-lex metaphir-lex.cpp)
target_link_libraries(metaphir-lex PRIVATE metaphir-lexer)

add_executable(metaphir-parse metaphir-parse.cpp)
target_link_libraries(metaphir-parse PRIVATE metaphir-parser
                                             metaphir-surface-printer)

add_executable(metaphir-match metaphir-match.cpp)
target_link_libraries(metaphir-match
  PRIVATE
    metaphir-compile
    metaphir-index-lib
    metaphir-web
    metaphir-matching
    LLVMAsmParser
    LLVMIRReader
)

add_executable(metaphir-index metaphir-index.cpp)
target_link_libraries(metaphir-index
  PRIVATE
    metaphir-compile
    metaphir-index-lib
    metaphir-web-publish
    metaphir-matching
    LLVMAsmParser
    LLVMIRReader
)

add_executable(metaphir-opt metaphir-opt.cpp)
target_link_libraries(metaphir-opt
  PRIVATE
    metaphir-transforms
    MLIROptLib
    MLIRTransforms
)

foreach(tool metaphir-lex metaphir-parse metaphir-match metaphir-index)
  target_compile_definitions(${tool}
    PRIVATE METAPHIR_VERSION="${PROJECT_VERSION}")
endforeach()
