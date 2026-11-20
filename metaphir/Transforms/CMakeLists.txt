# Passes over the mpir dialects, a directory per stage, each declaring its
# passes in its Passes.td:
#   Lowering/  surface mpir → lowered mpir
#   ToPlan/    lowered mpir → mpir_plan
#   ToIndex/   lowered mpir → mpir_index, and passes over mpir_index
add_library(metaphir-transforms)
add_subdirectory(Lowering)
add_subdirectory(ToPlan)
add_subdirectory(ToIndex)
add_dependencies(metaphir-transforms MetaphIRPatternOpsIncGen
                 MetaphIRExprOpsIncGen MetaphIRPlanOpsIncGen
                 MetaphIRIndexOpsIncGen MetaphIRLoweringPassIncGen
                 MetaphIRToPlanPassIncGen MetaphIRToIndexPassIncGen)
target_link_libraries(metaphir-transforms PUBLIC metaphir-surface-printer
                                                 metaphir-dialect-plan
                                                 metaphir-dialect-index
                                                 metaphir-matching
                                                 MLIRPass MLIRTransformUtils)
