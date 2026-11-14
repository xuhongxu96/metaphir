# Running match plans on LLVM IR.
add_library(metaphir-exec ExprEvaluator.cpp ExprEvaluator.h TypePattern.cpp
                          TypePattern.h IndexQuery.cpp IndexQuery.h
                          PlanMatcher.cpp
                          PlanMatcher.h)
add_dependencies(metaphir-exec MetaphIRPatternOpsIncGen MetaphIRExprOpsIncGen
                 MetaphIRPlanOpsIncGen MetaphIRIndexOpsIncGen)
target_link_libraries(metaphir-exec PUBLIC metaphir-matching
                                           metaphir-surface-printer
                                           metaphir-dialect-plan
                                           metaphir-dialect-index)
