add_library(
  metaphir-matching
  ConstraintCoercion.cpp
  ConstraintCoercion.h
  Coercions.def
  ConstraintError.cpp
  ConstraintError.h
  ConstraintInterpreter.cpp
  ConstraintInterpreter.h
  ConstraintOps.cpp
  ConstraintOps.h
  ConstraintValue.cpp
  ConstraintValue.h
  Instantiation.cpp
  Instantiation.h
  MatchersDetail.cpp
  MatchersDetail.h
  TypeMatcher.cpp
  TypeMatcher.h
  SubtreeMatcher.cpp
  SubtreeMatcher.h
  InstructionMatcher.cpp
  InstructionMatcher.Matchers.cpp
  InstructionMatcher.h
  PatternMatcher.cpp
  PatternMatcher.h
  Target.cpp
  Target.h
  ValueTrackContext.cpp
  ValueTrackContext.h)

target_link_libraries(metaphir-matching PUBLIC metaphir-ir LLVMAnalysis
                                                  LLVMCore LLVMSupport)
