add_library(metaphir-ir
  MIRContext.cpp
  MIRContext.h

  MIRContextImpl.h
  MIRContextImpl.cpp

  Type.cpp
  Type.h

  DerivedTypes.cpp
  DerivedTypes.h

  Pattern.cpp
  Pattern.h
  PatternVariants.h

  Constraint.cpp
  Constraint.h

  Constraints.h
  ConstraintCoercions.def
  ConstraintOperators.def

  CompositeMatcher.cpp
  CompositeMatcher.h

  PatternLowering.cpp
  PatternLowering.h

  Value.h
  Values.h
  Values.cpp

  Instruction.cpp
  Instruction.h

  MetaFlag.cpp
  MetaFlag.h

  MetaVariable.h
  MetaVariable.cpp
)

target_link_libraries(metaphir-ir
  PUBLIC
    LLVMSupport
)
