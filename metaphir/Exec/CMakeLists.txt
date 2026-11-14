# Running match plans on LLVM IR.
add_library(metaphir-exec ExprEvaluator.cpp ExprEvaluator.h PlanMatcher.cpp
                          PlanMatcher.h)
add_dependencies(metaphir-exec MetaphIRPatternOpsIncGen MetaphIRExprOpsIncGen
                 MetaphIRPlanOpsIncGen)
target_link_libraries(metaphir-exec PUBLIC metaphir-matching
                                           metaphir-surface-printer
                                           metaphir-dialect-plan)
