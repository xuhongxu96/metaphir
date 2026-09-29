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

add_library(metaphir-parser
  MIRKeywords.def
  MIRTokenKinds.def

  MIRToken.cpp
  MIRToken.h

  MIRConstraintLexer.cpp
  MIRConstraintLexer.h

  MIRLexer.cpp
  MIRLexer.h

  MIRParser.cpp
  MIRParser.ParseConstraint.cpp
  MIRParser.h

  "${METAPHIR_STDLIB_OUTPUT}"
)

target_include_directories(metaphir-parser
  PRIVATE "${CMAKE_CURRENT_BINARY_DIR}"
)

target_link_libraries(metaphir-parser
  PUBLIC
    LLVMSupport
    metaphir-ir
)
