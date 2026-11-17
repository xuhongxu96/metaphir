metaphir_tablegen(ConstraintCoercions.inc -gen-coercions)
metaphir_tablegen(LLVMValueClasses.inc -gen-value-classes)
metaphir_tablegen(OpcodeMatchers.inc -gen-opcode-matchers)
metaphir_tablegen(Operators/CmpPredicateOps.inc -gen-cmp-predicate-operators)
metaphir_tablegen(Operators/ConstantClassOps.inc -gen-constant-classes)
metaphir_tablegen(Operators/Facts.inc -gen-facts)
add_custom_target(MetaphIRMatchingTableGen DEPENDS
  "${CMAKE_CURRENT_BINARY_DIR}/ConstraintCoercions.inc"
  "${CMAKE_CURRENT_BINARY_DIR}/LLVMValueClasses.inc"
  "${CMAKE_CURRENT_BINARY_DIR}/OpcodeMatchers.inc"
  "${CMAKE_CURRENT_BINARY_DIR}/Operators/CmpPredicateOps.inc"
  "${CMAKE_CURRENT_BINARY_DIR}/Operators/ConstantClassOps.inc"
  "${CMAKE_CURRENT_BINARY_DIR}/Operators/Facts.inc")

add_library(
  metaphir-matching
  Binding.cpp
  Binding.h
  ConstraintCoercion.cpp
  ConstraintCoercion.h
  ConstraintError.cpp
  ConstraintError.h
  LLVMValueClasses.h
  Operators/Arithmetic.cpp
  Operators/AbstractCall.cpp
  Operators/AbstractCall.h
  Operators/Arithmetic.h
  Operators/CmpPredicates.cpp
  Operators/CmpPredicates.h
  Operators/CmpPredicateSupport.h
  Operators/Facts.cpp
  Operators/Facts.h
  Operators/OperatorCall.h
  Operators/ValuePredicates.cpp
  Operators/ValuePredicates.h
  Operators/ValuePredicateSupport.h
  Operators/ValueTracking.cpp
  Operators/ValueTracking.h
  ConstraintValue.cpp
  ConstraintValue.h
  ConstantInteger.cpp
  ConstantInteger.h
  FeatureRequirement.cpp
  FeatureRequirement.h
  Features.cpp
  Features.h
  IntegerSemantics.cpp
  IntegerSemantics.h
  UseOracle.cpp
  UseOracle.h
  OpcodePredicates.cpp
  OpcodePredicates.h
  Target.cpp
  Target.h
  TypeCode.cpp
  TypeCode.h
  ValueTrackContext.cpp
  ValueTrackContext.h)

add_dependencies(metaphir-matching MetaphIRMatchingTableGen)
target_link_libraries(metaphir-matching PUBLIC metaphir-ir metaphir-surface-printer LLVMAnalysis
                                                  LLVMCore LLVMSupport)
