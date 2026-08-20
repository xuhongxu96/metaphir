set(METAPHIR_EVAL_PLUGINS
  pr216436
  pr215122
  pr215130
  pr214541
  pr214517
  pr214381
  pr214376
  pr213709
  pr213313
  pr212132
  pr210499
  pr209322
  pr207564
  pr207462
  pr205383
  pr204928
  pr204927
  pr216470
  pr216046
  pr204089
)

foreach(pr IN LISTS METAPHIR_EVAL_PLUGINS)
  add_library(${pr} MODULE ${pr}.cpp)
  target_include_directories(${pr} PRIVATE ${LLVM_INCLUDE_DIRS})
  set_target_properties(${pr} PROPERTIES PREFIX "")
endforeach()
