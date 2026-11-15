# The language's vocabulary: its instruction matchers, flags, metaflags,
# constraint operators, keywords, primitive types, sorts and settings, and
# what each takes. The patterns themselves are the mpir dialect's.
add_library(metaphir-ir
  Constants.cpp
  Constants.h
  KeywordConstants.def

  Constraint.cpp
  Constraint.h
  ConstraintCoercions.def
  ConstraintOperators.def
  CmpPredicateOperators.def
  ConstantClasses.def

  Instruction.cpp
  Instruction.h
  InstructionMatchers.def
  Flags.def

  MetaFlag.cpp
  MetaFlag.h
  MetaFlags.def

  PatternSettings.cpp
  PatternSettings.h
  PatternSettings.def

  Sort.cpp
  Sort.h
  Sorts.def

  Type.h
  Types.def
)

target_link_libraries(metaphir-ir
  PUBLIC
    LLVMSupport
)
