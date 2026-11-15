# Passes over the mpir dialects.
add_library(metaphir-transforms Lowering.cpp Lowering.h ToPlan.cpp ToPlan.h
                               ToIndex.cpp ToIndex.h Structuralize.cpp
                               Structuralize.h Retrieval.cpp Retrieval.h)
add_dependencies(metaphir-transforms MetaphIRPatternOpsIncGen
                 MetaphIRExprOpsIncGen MetaphIRPlanOpsIncGen
                 MetaphIRIndexOpsIncGen)
target_link_libraries(metaphir-transforms PUBLIC metaphir-surface-printer
                                                 metaphir-dialect-plan
                                                 metaphir-dialect-index
                                                 metaphir-matching
                                                 MLIRPass MLIRTransformUtils)
