# EmbedStdLib.cmake - Generate StdLibSource.inc from stdlib.mpir
#
# Usage: cmake -DINPUT=<path-to-stdlib.mpir> -DOUTPUT=<path-to-StdLibSource.inc> -P EmbedStdLib.cmake

file(READ "${INPUT}" CONTENT)
# Escape backslashes, then quotes
string(REPLACE "\\" "\\\\" CONTENT "${CONTENT}")
string(REPLACE "\"" "\\\"" CONTENT "${CONTENT}")
# Convert newlines to \n inside string literal
string(REPLACE "\n" "\\n\"\n\"" CONTENT "${CONTENT}")
file(WRITE "${OUTPUT}"
  "// Auto-generated from stdlib.mpir -- do not edit.\n"
  "static const char *StdLibSource =\n"
  "\"${CONTENT}\";\n"
)
