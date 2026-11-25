# The mpir_plan dialect: match plans.
set(LLVM_TARGET_DEFINITIONS PlanEnums.td)
mlir_tablegen(PlanEnums.h.inc -gen-enum-decls)
mlir_tablegen(PlanEnums.cpp.inc -gen-enum-defs)

set(LLVM_TARGET_DEFINITIONS PlanOps.td)
mlir_tablegen(PlanOps.h.inc -gen-op-decls)
mlir_tablegen(PlanOps.cpp.inc -gen-op-defs)
mlir_tablegen(PlanOpsDialect.h.inc -gen-dialect-decls -dialect=mpir_plan)
mlir_tablegen(PlanOpsDialect.cpp.inc -gen-dialect-defs -dialect=mpir_plan)
mlir_tablegen(PlanOpsTypes.h.inc -gen-typedef-decls -typedefs-dialect=mpir_plan)
mlir_tablegen(PlanOpsTypes.cpp.inc -gen-typedef-defs -typedefs-dialect=mpir_plan)
add_public_tablegen_target(MetaphIRPlanOpsIncGen)

add_library(metaphir-dialect-plan PlanDialect.cpp PlanDialect.h)
add_dependencies(metaphir-dialect-plan MetaphIRPlanOpsIncGen
                 MetaphIRPatternOpsIncGen MetaphIRExprOpsIncGen)
target_link_libraries(metaphir-dialect-plan PUBLIC metaphir-dialect-pattern
                                                   metaphir-dialect-expr)
# The generated op definitions call the builders they deprecate.
target_compile_options(metaphir-dialect-plan
                       PRIVATE -Wno-error=deprecated-declarations
                               -Wno-deprecated-declarations)
