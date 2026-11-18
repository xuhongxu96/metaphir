# The passes that lower the surface form of a pattern, a file each.
target_sources(metaphir-transforms PRIVATE
  CheckBindings.cpp
  CheckBindings.h
  DesugarMetaFlags.cpp
  DesugarMetaFlags.h
  ExpandMatchers.cpp
  ExpandMatchers.h
  LowerAlternatives.cpp
  LowerAlternatives.h
  Lowering.cpp
  Lowering.h)
