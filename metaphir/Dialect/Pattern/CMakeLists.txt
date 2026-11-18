# The mpir dialect: patterns as written, and as lowered.
set(LLVM_TARGET_DEFINITIONS PatternOps.td)
mlir_tablegen(PatternEnums.h.inc -gen-enum-decls)
mlir_tablegen(PatternEnums.cpp.inc -gen-enum-defs)
mlir_tablegen(PatternOpInterfaces.h.inc -gen-op-interface-decls)
mlir_tablegen(PatternOpInterfaces.cpp.inc -gen-op-interface-defs)
mlir_tablegen(PatternOps.h.inc -gen-op-decls)
mlir_tablegen(PatternOps.cpp.inc -gen-op-defs)
mlir_tablegen(PatternOpsDialect.h.inc -gen-dialect-decls -dialect=mpir)
mlir_tablegen(PatternOpsDialect.cpp.inc -gen-dialect-defs -dialect=mpir)
mlir_tablegen(PatternOpsTypes.h.inc -gen-typedef-decls -typedefs-dialect=mpir)
mlir_tablegen(PatternOpsTypes.cpp.inc -gen-typedef-defs -typedefs-dialect=mpir)
mlir_tablegen(PatternOpsAttrDefs.h.inc -gen-attrdef-decls -attrdefs-dialect=mpir)
mlir_tablegen(PatternOpsAttrDefs.cpp.inc -gen-attrdef-defs -attrdefs-dialect=mpir)
add_public_tablegen_target(MetaphIRPatternOpsIncGen)

add_library(metaphir-dialect-pattern NamedEnum.cpp NamedEnum.h PatternDialect.cpp
                                     PatternDialect.h
                                     SourceLocation.cpp SourceLocation.h)

add_dependencies(metaphir-dialect-pattern MetaphIRPatternOpsIncGen)
target_link_libraries(metaphir-dialect-pattern PUBLIC metaphir-ir MLIRIR
                                                      MLIRSupport
                                                      MLIRSideEffectInterfaces)
# The generated op definitions call the builders they deprecate.
target_compile_options(metaphir-dialect-pattern
                       PRIVATE -Wno-error=deprecated-declarations
                               -Wno-deprecated-declarations)
