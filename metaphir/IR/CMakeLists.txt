# The language's vocabulary: its instruction matchers, flags, metaflags,
# constraint operators, keywords, primitive types, sorts and settings, and
# what each takes. The patterns themselves are the mpir dialect's.
metaphir_tablegen(Constants.inc -gen-keyword-constants)
metaphir_tablegen(Constraint.inc -gen-constraint-operators)
metaphir_tablegen(Instruction.inc -gen-instructions)
metaphir_tablegen(MetaFlag.inc -gen-metaflags)
metaphir_tablegen(PatternSettings.inc -gen-pattern-settings)
metaphir_tablegen(Sort.inc -gen-sorts)
metaphir_tablegen(Types.inc -gen-primitive-types)
add_custom_target(MetaphIRIRTableGen DEPENDS
  "${CMAKE_CURRENT_BINARY_DIR}/Constants.inc"
  "${CMAKE_CURRENT_BINARY_DIR}/Constraint.inc"
  "${CMAKE_CURRENT_BINARY_DIR}/Instruction.inc"
  "${CMAKE_CURRENT_BINARY_DIR}/MetaFlag.inc"
  "${CMAKE_CURRENT_BINARY_DIR}/PatternSettings.inc"
  "${CMAKE_CURRENT_BINARY_DIR}/Sort.inc"
  "${CMAKE_CURRENT_BINARY_DIR}/Types.inc")

add_library(metaphir-ir
  Constants.h
  Constraint.h
  Instruction.h
  MetaFlag.h
  PatternSettings.h
  Sort.cpp
  Sort.h
  Type.h
)
add_dependencies(metaphir-ir MetaphIRIRTableGen)

target_link_libraries(metaphir-ir
  PUBLIC
    LLVMSupport
)
