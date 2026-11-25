# Running match plans on LLVM IR, and index queries on features.
metaphir_tablegen(ConstraintDispatch.inc -gen-constraint-dispatch)
metaphir_tablegen(KeywordConstantMatch.inc -gen-keyword-constant-matcher)
metaphir_tablegen(PrimitiveTypeMatch.inc -gen-primitive-type-matcher)
add_custom_target(MetaphIRExecTableGen DEPENDS
  "${CMAKE_CURRENT_BINARY_DIR}/ConstraintDispatch.inc"
  "${CMAKE_CURRENT_BINARY_DIR}/KeywordConstantMatch.inc"
  "${CMAKE_CURRENT_BINARY_DIR}/PrimitiveTypeMatch.inc")

add_library(metaphir-exec ConcreteEvaluator.cpp ConcreteEvaluator.h ExprEvaluator.h
                          KeywordConstantMatch.h
                          PrimitiveTypeMatch.h TypePattern.cpp
                          TypePattern.h IndexQuery.cpp IndexQuery.h
                          PlanMatcher.cpp PlanMatcher.h
                          PlanMatcher.Match.cpp PlanMatcher.Program.cpp
                          PlanStep.h)
add_dependencies(metaphir-exec MetaphIRExecTableGen MetaphIRPatternOpsIncGen MetaphIRExprOpsIncGen
                 MetaphIRPlanOpsIncGen MetaphIRIndexOpsIncGen)
target_link_libraries(metaphir-exec PUBLIC metaphir-matching metaphir-index-core
                                           metaphir-surface-printer
                                           metaphir-dialect-plan
                                           metaphir-dialect-index)

# A pattern compiled through the whole pipeline, from its source.
add_library(metaphir-compile CompiledPattern.cpp CompiledPattern.h)
target_link_libraries(metaphir-compile PUBLIC metaphir-exec
                                              metaphir-parser
                                              metaphir-transforms)
