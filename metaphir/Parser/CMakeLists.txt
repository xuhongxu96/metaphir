set(METAPHIR_STDLIB_INPUT "${CMAKE_CURRENT_SOURCE_DIR}/../StdLib/stdlib.mpir")
set(METAPHIR_STDLIB_OUTPUT "${CMAKE_CURRENT_BINARY_DIR}/StdLibSource.inc")

add_custom_command(
  OUTPUT "${METAPHIR_STDLIB_OUTPUT}"
  COMMAND ${CMAKE_COMMAND}
    "-DINPUT=${METAPHIR_STDLIB_INPUT}"
    "-DOUTPUT=${METAPHIR_STDLIB_OUTPUT}"
    -P "${CMAKE_CURRENT_SOURCE_DIR}/EmbedStdLib.cmake"
  DEPENDS "${METAPHIR_STDLIB_INPUT}" "${CMAKE_CURRENT_SOURCE_DIR}/EmbedStdLib.cmake"
  COMMENT "Embedding stdlib.mpir into StdLibSource.inc"
)

metaphir_tablegen(MIRToken.inc -gen-tokens)
metaphir_tablegen(KeywordTokens.inc -gen-keyword-tokens)
add_custom_target(MetaphIRParserTableGen DEPENDS
  "${CMAKE_CURRENT_BINARY_DIR}/MIRToken.inc"
  "${CMAKE_CURRENT_BINARY_DIR}/KeywordTokens.inc")

add_library(metaphir-lexer
  KeywordRange.h
  KeywordTokens.h
  MIRLexer.cpp
  MIRLexer.h
  MIRToken.h
)

add_dependencies(metaphir-lexer MetaphIRParserTableGen)
target_link_libraries(metaphir-lexer
  PUBLIC
    LLVMSupport
    metaphir-ir
)

# The parser that emits the mpir dialect.
add_library(metaphir-parser PatternParser.cpp PatternParser.h
                            "${METAPHIR_STDLIB_OUTPUT}")
target_include_directories(metaphir-parser PRIVATE "${CMAKE_CURRENT_BINARY_DIR}")
target_link_libraries(metaphir-parser PUBLIC metaphir-lexer
                                             metaphir-dialect-expr)
