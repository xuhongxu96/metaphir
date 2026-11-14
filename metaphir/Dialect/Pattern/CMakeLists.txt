# The mpir dialect: patterns as written, and as lowered.
set(LLVM_TARGET_DEFINITIONS PatternOps.td)
mlir_tablegen(PatternOps.h.inc -gen-op-decls)
mlir_tablegen(PatternOps.cpp.inc -gen-op-defs)
mlir_tablegen(PatternOpsDialect.h.inc -gen-dialect-decls -dialect=mpir)
mlir_tablegen(PatternOpsDialect.cpp.inc -gen-dialect-defs -dialect=mpir)
mlir_tablegen(PatternOpsTypes.h.inc -gen-typedef-decls -typedefs-dialect=mpir)
mlir_tablegen(PatternOpsTypes.cpp.inc -gen-typedef-defs -typedefs-dialect=mpir)
mlir_tablegen(PatternOpsAttrDefs.h.inc -gen-attrdef-decls -attrdefs-dialect=mpir)
mlir_tablegen(PatternOpsAttrDefs.cpp.inc -gen-attrdef-defs -attrdefs-dialect=mpir)
add_public_tablegen_target(MetaphIRPatternOpsIncGen)

add_library(metaphir-dialect-pattern PatternDialect.cpp PatternDialect.h
                                     SourceLocation.cpp SourceLocation.h)

# Printing the surface form needs the expression dialect too.
add_library(metaphir-surface-printer SurfacePrinter.cpp SurfacePrinter.h)
add_dependencies(metaphir-surface-printer MetaphIRExprOpsIncGen)
target_link_libraries(metaphir-surface-printer PUBLIC metaphir-dialect-expr)
add_dependencies(metaphir-dialect-pattern MetaphIRPatternOpsIncGen)
target_link_libraries(metaphir-dialect-pattern PUBLIC metaphir-ir MLIRIR
                                                      MLIRSupport
                                                      MLIRSideEffectInterfaces)
# The generated op definitions call the builders they deprecate.
target_compile_options(metaphir-dialect-pattern
                       PRIVATE -Wno-error=deprecated-declarations
                               -Wno-deprecated-declarations)
