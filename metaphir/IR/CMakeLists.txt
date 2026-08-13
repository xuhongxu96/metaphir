add_library(metaphir-ir
  MIRContext.cpp
  MIRContext.h

  MIRContextImpl.h

  Type.cpp
  Type.h

  DerivedTypes.cpp
  DerivedTypes.h
)

target_link_libraries(metaphir-ir
  PUBLIC
    LLVMSupport
)