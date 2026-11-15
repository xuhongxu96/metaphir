# Running match plans on LLVM IR, and index queries on features.
add_library(metaphir-exec ExprEvaluator.cpp ExprEvaluator.h TypePattern.cpp
                          TypePattern.h IndexQuery.cpp IndexQuery.h
                          PlanMatcher.cpp PlanMatcher.h)
add_dependencies(metaphir-exec MetaphIRPatternOpsIncGen MetaphIRExprOpsIncGen
                 MetaphIRPlanOpsIncGen MetaphIRIndexOpsIncGen)
target_link_libraries(metaphir-exec PUBLIC metaphir-matching metaphir-index-core
                                           metaphir-surface-printer
                                           metaphir-dialect-plan
                                           metaphir-dialect-index)

# A pattern compiled through the whole pipeline, from its source.
add_library(metaphir-compile CompiledPattern.cpp CompiledPattern.h)
target_link_libraries(metaphir-compile PUBLIC metaphir-exec
                                              metaphir-pattern-parser
                                              metaphir-transforms)
