# Checks docs/passes.md against the passes' Passes.td, or with
# METAPHIR_UPDATE_GOLDEN set rewrites it. Run as
#   cmake -DSTAGES="<name>=<generated Passes.md>;..." -DDOC=<docs/passes.md>
#         -P PassDocs.cmake
# Each stage's mlir-tblgen -gen-pass-doc output becomes a section.

set(Text "# Passes\n\n")
string(APPEND Text
  "<!-- Generated from metaphir/Transforms/*/Passes.td: do not edit. Update "
  "with METAPHIR_UPDATE_GOLDEN=1 ctest -R MetaphIR.pass-docs. -->\n\n"
  "The passes over the mpir dialects run in three stages, a directory of "
  "`metaphir/Transforms` each, and declared in its `Passes.td`:\n\n"
  "```\n"
  "metaphir-parse ──► mpir (surface)\n"
  "  Lowering   mpir-desugar-metaflags → mpir-expand-matchers\n"
  "             → mpir-lower-alternatives → mpir-check-bindings\n"
  "mpir (lowered)\n"
  "  ToPlan     mpir-to-plan                  adds an mpir_plan.matcher\n"
  "  ToIndex    mpir-to-index                 adds an mpir_index.query\n"
  "             → mpir-index-structuralize → mpir-index-retrieval\n"
  "             → mpir-index-factor\n"
  "```\n\n"
  "`mpir-to-plan` and `mpir-to-index` add their op after each "
  "`mpir.pattern`, which stays.\n")

foreach(Stage IN LISTS STAGES)
  string(REGEX MATCH "^([^=]+)=(.*)$" _ "${Stage}")
  set(Name "${CMAKE_MATCH_1}")
  file(READ "${CMAKE_MATCH_2}" Generated)
  string(REGEX REPLACE "<!--[^\n]*-->\n*" "" Generated "${Generated}")
  string(APPEND Text "\n## ${Name} (`metaphir/Transforms/${Name}`)\n\n"
                     "${Generated}")
endforeach()
string(REGEX REPLACE "\n+$" "\n" Text "${Text}")

if(DEFINED ENV{METAPHIR_UPDATE_GOLDEN})
  file(WRITE "${DOC}" "${Text}")
  message(STATUS "wrote ${DOC}")
  return()
endif()
if(EXISTS "${DOC}")
  file(READ "${DOC}" Current)
endif()
if(NOT Current STREQUAL Text)
  message(FATAL_ERROR "${DOC} differs from the passes' Passes.td; rerun with "
                      "METAPHIR_UPDATE_GOLDEN=1 if the change is intended")
endif()
