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

  ConstraintCoercions.def
  ConstraintOperators.def

  CompositeMatcher.cpp
  CompositeMatcher.h

  LibraryDefs.h

  PatternSettings.cpp
  PatternSettings.h

  SourceRange.h

  PatternLowering.cpp
  PatternLowering.h

  Value.h
  Constants.h
  Constants.cpp

  Instruction.cpp
  Instruction.h

  MetaFlag.cpp
  MetaFlag.h

  MetaVariable.h
  MetaVariable.cpp

  Sort.cpp
  Sort.h
  Sorts.def
)

target_link_libraries(metaphir-ir
  PUBLIC
    LLVMSupport
)
