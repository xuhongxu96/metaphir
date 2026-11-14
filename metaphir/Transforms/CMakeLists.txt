# Passes over the mpir dialects.
add_library(metaphir-transforms Lowering.cpp Lowering.h)
add_dependencies(metaphir-transforms MetaphIRPatternOpsIncGen
                 MetaphIRExprOpsIncGen)
target_link_libraries(metaphir-transforms PUBLIC metaphir-surface-printer
                                                 MLIRPass MLIRTransformUtils)
