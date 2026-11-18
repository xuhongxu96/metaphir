# Passes over the mpir dialects.
add_library(metaphir-transforms
  Retrieval.cpp
  Retrieval.h
  Structuralize.cpp
  Structuralize.h
  ToIndex.cpp
  ToIndex.h
  ToPlan.cpp
  ToPlan.h)
add_subdirectory(Lowering)
add_dependencies(metaphir-transforms MetaphIRPatternOpsIncGen
                 MetaphIRExprOpsIncGen MetaphIRPlanOpsIncGen
                 MetaphIRIndexOpsIncGen)
target_link_libraries(metaphir-transforms PUBLIC metaphir-surface-printer
                                                 metaphir-dialect-plan
                                                 metaphir-dialect-index
                                                 metaphir-matching
                                                 MLIRPass MLIRTransformUtils)
