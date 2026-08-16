add_library(metaphir-parser
  MIRKeywords.def

  MIRToken.cpp
  MIRToken.h

  MIRConstraintLexer.cpp
  MIRConstraintLexer.h

  MIRLexer.cpp
  MIRLexer.h

  MIRParser.cpp
  MIRParser.ParseConstraint.cpp
  MIRParser.h
)

target_link_libraries(metaphir-parser
  PUBLIC
    LLVMSupport
    metaphir-ir
)
