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

  Constraint.cpp
  Constraint.h

  Constraints.h

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
