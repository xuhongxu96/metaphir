# The mpir_expr dialect: constraint expressions.
set(LLVM_TARGET_DEFINITIONS ExprOps.td)
mlir_tablegen(ExprOps.h.inc -gen-op-decls)
mlir_tablegen(ExprOps.cpp.inc -gen-op-defs)
mlir_tablegen(ExprOpsDialect.h.inc -gen-dialect-decls -dialect=mpir_expr)
mlir_tablegen(ExprOpsDialect.cpp.inc -gen-dialect-defs -dialect=mpir_expr)
add_public_tablegen_target(MetaphIRExprOpsIncGen)

add_library(metaphir-dialect-expr ExprDialect.cpp ExprDialect.h)
add_dependencies(metaphir-dialect-expr MetaphIRExprOpsIncGen
                 MetaphIRPatternOpsIncGen)
target_link_libraries(metaphir-dialect-expr PUBLIC metaphir-dialect-pattern)
# The generated op definitions call the builders they deprecate.
target_compile_options(metaphir-dialect-expr
                       PRIVATE -Wno-error=deprecated-declarations
                               -Wno-deprecated-declarations)
