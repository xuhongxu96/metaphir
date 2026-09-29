add_library(
  metaphir-matching
  ConstraintCoercion.cpp
  ConstraintCoercion.h
  ConstraintError.cpp
  ConstraintError.h
  ConstraintInterpreter.cpp
  ConstraintInterpreter.h
  ConstraintOps.cpp
  ConstraintOps.h
  ConstraintValue.cpp
  ConstraintValue.h
  ConstantInteger.cpp
  ConstantInteger.h
  Instantiation.cpp
  IntegerSemantics.cpp
  IntegerSemantics.h
  Instantiation.h
  TypeMatcher.cpp
  TypeMatcher.h
  SubtreeMatcher.cpp
  SubtreeMatcher.h
  InstructionMatcher.cpp
  OpcodePredicates.cpp
  InstructionMatcher.h
  LLVMValueClasses.def
  PatternMatcher.cpp
  PatternMatcher.h
  Target.cpp
  Target.h
  ValueTrackContext.cpp
  ValueTrackContext.h)

target_link_libraries(metaphir-matching PUBLIC metaphir-ir LLVMAnalysis
                                                  LLVMCore LLVMSupport)
