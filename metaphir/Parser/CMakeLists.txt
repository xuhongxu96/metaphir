add_library(metaphir-parser
  MIRToken.cpp
  MIRToken.h

  MIRLexer.cpp
  MIRLexer.h
)

target_link_libraries(metaphir-parser
  PUBLIC
    LLVMSupport
    metaphir-ir
)
