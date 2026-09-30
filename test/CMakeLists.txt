# Directory holding llvm-lit, FileCheck and not. These are build-tree utilities
# that `cmake --install` does not copy, so they are taken from the LLVM build
# directory rather than from LLVM_TOOLS_BINARY_DIR (the install prefix).
set(METAPHIR_LLVM_UTILS_DIR
    ${PROJECT_SOURCE_DIR}/llvm-project/build/bin
    CACHE PATH "Directory containing llvm-lit, FileCheck and not")
foreach(util llvm-lit FileCheck not)
  if(NOT EXISTS ${METAPHIR_LLVM_UTILS_DIR}/${util})
    message(WARNING "${util} not found in ${METAPHIR_LLVM_UTILS_DIR}; "
                    "lit tests will fail. Set METAPHIR_LLVM_UTILS_DIR.")
  endif()
endforeach()

set(METAPHIR_TEST_DIR ${CMAKE_CURRENT_BINARY_DIR})
configure_file(lit.site.cfg.py.in ${METAPHIR_TEST_DIR}/lit.site.cfg.py @ONLY)

add_subdirectory(Parser)
add_subdirectory(IR)
add_subdirectory(Matching)
add_subdirectory(Index)
add_subdirectory(Web)

# A single lit invocation discovers and runs every .ll test under test/.
add_test(
  NAME MetaphIR.lit
  COMMAND
    ${METAPHIR_LLVM_UTILS_DIR}/llvm-lit -sv --skip-test-time-recording
    -D "metaphir_lex=$<TARGET_FILE:metaphir-lex>"
    -D "metaphir_parse=$<TARGET_FILE:metaphir-parse>"
    -D "metaphir_match=$<TARGET_FILE:metaphir-match>"
    -D "metaphir_index=$<TARGET_FILE:metaphir-index>"
    ${METAPHIR_TEST_DIR})
set_tests_properties(MetaphIR.lit PROPERTIES ENVIRONMENT
                     "${METAPHIR_TEST_ENVIRONMENT}")

# Unit tests for the evaluation harness scripts.
find_package(Python3 COMPONENTS Interpreter)
if(Python3_FOUND)
  # metaphir-match's faster modes must not change what it prints.
  add_test(
    NAME MetaphIR.differential
    COMMAND
      ${Python3_EXECUTABLE} ${CMAKE_CURRENT_SOURCE_DIR}/scripts/differential.py
      --match $<TARGET_FILE:metaphir-match> --index
      $<TARGET_FILE:metaphir-index> --split-file
      ${METAPHIR_LLVM_UTILS_DIR}/split-file --llvm-as
      ${METAPHIR_LLVM_UTILS_DIR}/llvm-as ${CMAKE_CURRENT_SOURCE_DIR}/Matching)

  # The WebAssembly builds (scripts/build_wasm.sh), when there are some, must
  # find what the native tools find.
  find_program(NODE_EXECUTABLE node)
  if(NODE_EXECUTABLE AND EXISTS ${PROJECT_SOURCE_DIR}/web/public/wasm/metaphir.js)
    file(GLOB METAPHIR_WEB_TESTS ${PROJECT_SOURCE_DIR}/web/test/*.test.ts)
    add_test(NAME MetaphIR.web COMMAND ${NODE_EXECUTABLE} --test
                                       ${METAPHIR_WEB_TESTS})
    set_tests_properties(
      MetaphIR.web
      PROPERTIES ENVIRONMENT "METAPHIR_BUILD=${PROJECT_BINARY_DIR};LLVM_BIN=${METAPHIR_LLVM_UTILS_DIR}")
  endif()

  add_test(
    NAME MetaphIR.eval-scripts
    COMMAND ${Python3_EXECUTABLE} -m unittest discover -s
            ${PROJECT_SOURCE_DIR}/eval/scripts -p "test_*.py")
endif()
