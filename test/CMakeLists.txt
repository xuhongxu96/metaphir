set(LLVM_TOOLS_BINARY_DIR ${PROJECT_SOURCE_DIR}/llvm-project/build/bin)
set(METAPHIR_TEST_DIR ${CMAKE_CURRENT_BINARY_DIR})
file(MAKE_DIRECTORY ${METAPHIR_TEST_DIR})
configure_file(lit.site.cfg.py.in ${METAPHIR_TEST_DIR}/lit.site.cfg.py @ONLY)

add_subdirectory(Parser)
add_subdirectory(IR)
