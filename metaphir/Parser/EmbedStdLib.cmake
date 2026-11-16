# EmbedStdLib.cmake - Generate StdLibSource.inc from stdlib.mpir.
#
# Usage:
#   cmake -DINPUT=<stdlib.mpir> -DOUTPUT=<StdLibSource.inc> -P EmbedStdLib.cmake
#
# The file is emitted as one raw string literal, forming
# `static constexpr char StdLibSource[]`.

file(READ "${INPUT}" CONTENT)
# Normalize line endings so a CRLF checkout embeds the same text.
string(REPLACE "\r\n" "\n" CONTENT "${CONTENT}")
string(REPLACE "\r" "\n" CONTENT "${CONTENT}")
# The literal ends at the first `)mpir"`; refuse input that contains it.
string(FIND "${CONTENT}" ")mpir\"" DELIMITER_AT)
if(NOT DELIMITER_AT EQUAL -1)
  message(FATAL_ERROR "${INPUT} contains the raw string delimiter )mpir\"")
endif()
file(WRITE "${OUTPUT}"
  "// Auto-generated from stdlib.mpir by EmbedStdLib.cmake -- do not edit.\n"
  "static constexpr char StdLibSource[] = R\"mpir(${CONTENT})mpir\";\n"
)
