# The mpir_index dialect: index queries.
set(LLVM_TARGET_DEFINITIONS IndexOps.td)
mlir_tablegen(IndexOps.h.inc -gen-op-decls)
mlir_tablegen(IndexOps.cpp.inc -gen-op-defs)
mlir_tablegen(IndexOpsDialect.h.inc -gen-dialect-decls -dialect=mpir_index)
mlir_tablegen(IndexOpsDialect.cpp.inc -gen-dialect-defs -dialect=mpir_index)
mlir_tablegen(IndexOpsTypes.h.inc -gen-typedef-decls -typedefs-dialect=mpir_index)
mlir_tablegen(IndexOpsTypes.cpp.inc -gen-typedef-defs -typedefs-dialect=mpir_index)
add_public_tablegen_target(MetaphIRIndexOpsIncGen)

add_library(metaphir-dialect-index IndexDialect.cpp IndexDialect.h)
add_dependencies(metaphir-dialect-index MetaphIRIndexOpsIncGen
                 MetaphIRPatternOpsIncGen)
target_link_libraries(metaphir-dialect-index PUBLIC metaphir-dialect-pattern)
# The generated op definitions call the builders they deprecate.
target_compile_options(metaphir-dialect-index
                       PRIVATE -Wno-error=deprecated-declarations
                               -Wno-deprecated-declarations)
