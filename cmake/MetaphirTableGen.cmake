# metaphir_tablegen(): runs metaphir-tblgen on the language's tables.

# The tables every backend reads, and the root `include`s in them are
# relative to. This file is in <root>/cmake, whichever project includes it.
get_filename_component(METAPHIR_SOURCE_ROOT "${CMAKE_CURRENT_LIST_DIR}/.."
                       ABSOLUTE)
set(METAPHIR_LANGUAGE_TD "${METAPHIR_SOURCE_ROOT}/metaphir/Language.td")

# Generates `output` (in the current binary directory) from the language's
# tables with one metaphir-tblgen backend, e.g.
#   metaphir_tablegen(Types.inc -gen-primitive-types)
# METAPHIR_TABLEGEN names a metaphir-tblgen built for this machine when
# cross-compiling; otherwise the one this project builds is used.
set(METAPHIR_TABLEGEN "" CACHE FILEPATH
    "metaphir-tblgen to run, instead of the one built in this tree")
function(metaphir_tablegen output backend)
  if(METAPHIR_TABLEGEN)
    set(exe "${METAPHIR_TABLEGEN}")
    set(exe_dep "${METAPHIR_TABLEGEN}")
  else()
    set(exe "$<TARGET_FILE:metaphir-tblgen>")
    set(exe_dep metaphir-tblgen)
  endif()
  file(GLOB_RECURSE tds "${METAPHIR_SOURCE_ROOT}/metaphir/*.td")
  add_custom_command(
    OUTPUT "${CMAKE_CURRENT_BINARY_DIR}/${output}"
    COMMAND ${exe} ${backend} -I "${METAPHIR_SOURCE_ROOT}"
            "${METAPHIR_LANGUAGE_TD}"
            -o "${CMAKE_CURRENT_BINARY_DIR}/${output}"
    DEPENDS ${exe_dep} ${tds}
    COMMENT "Generating ${output}")
  set_source_files_properties("${CMAKE_CURRENT_BINARY_DIR}/${output}"
                              PROPERTIES GENERATED TRUE)
endfunction()
