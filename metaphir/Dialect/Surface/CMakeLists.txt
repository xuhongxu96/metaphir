# Printing patterns in the pattern language: needs the expression dialect too.
add_library(metaphir-surface-printer SurfacePrinter.cpp SurfacePrinter.h)
add_dependencies(metaphir-surface-printer MetaphIRExprOpsIncGen
                 MetaphIRPatternOpsIncGen)
target_link_libraries(metaphir-surface-printer PUBLIC metaphir-dialect-expr)
