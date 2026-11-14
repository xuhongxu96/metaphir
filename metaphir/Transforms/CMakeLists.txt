# Passes over the mpir dialects.
add_library(metaphir-transforms Lowering.cpp Lowering.h ToPlan.cpp ToPlan.h)
add_dependencies(metaphir-transforms MetaphIRPatternOpsIncGen
                 MetaphIRExprOpsIncGen MetaphIRPlanOpsIncGen)
target_link_libraries(metaphir-transforms PUBLIC metaphir-surface-printer
                                                 metaphir-dialect-plan
                                                 MLIRPass MLIRTransformUtils)
