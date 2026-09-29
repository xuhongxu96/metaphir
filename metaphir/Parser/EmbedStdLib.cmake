# EmbedStdLib.cmake - Generate StdLibSource.inc from stdlib.mpir.
#
# Usage:
#   cmake -DINPUT=<stdlib.mpir> -DOUTPUT=<StdLibSource.inc> -P EmbedStdLib.cmake
#
# The file is emitted as a sequence of adjacent narrow string literals, one per
# source line, forming `static constexpr char StdLibSource[]`.

file(READ "${INPUT}" CONTENT)
# Normalize line endings so a CRLF checkout embeds the same text.
string(REPLACE "\r\n" "\n" CONTENT "${CONTENT}")
string(REPLACE "\r" "\n" CONTENT "${CONTENT}")
# Escape backslashes first, then quotes and tabs.
string(REPLACE "\\" "\\\\" CONTENT "${CONTENT}")
string(REPLACE "\"" "\\\"" CONTENT "${CONTENT}")
string(REPLACE "\t" "\\t" CONTENT "${CONTENT}")
# End each literal at a newline so the generated file stays readable.
string(REPLACE "\n" "\\n\"\n    \"" CONTENT "${CONTENT}")
file(WRITE "${OUTPUT}"
  "// Auto-generated from stdlib.mpir by EmbedStdLib.cmake -- do not edit.\n"
  "static constexpr char StdLibSource[] =\n"
  "    \"${CONTENT}\";\n"
)
