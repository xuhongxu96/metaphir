set(METAPHIR_EVAL_PLUGINS
  pr216436
)

foreach(pr IN LISTS METAPHIR_EVAL_PLUGINS)
  add_library(${pr} MODULE ${pr}.cpp)
  target_include_directories(${pr} PRIVATE ${LLVM_INCLUDE_DIRS})
  set_target_properties(${pr} PROPERTIES PREFIX "")
endforeach()
