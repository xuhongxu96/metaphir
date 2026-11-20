# Lowering: surface mpir → lowered mpir, a pass a file.
set(LLVM_TARGET_DEFINITIONS Passes.td)
mlir_tablegen(Passes.h.inc -gen-pass-decls -name Lowering)
mlir_tablegen(Passes.md -gen-pass-doc)
add_public_tablegen_target(MetaphIRLoweringPassIncGen)

target_sources(metaphir-transforms PRIVATE
  CheckBindings.cpp
  DesugarMetaFlags.cpp
  ExpandMatchers.cpp
  LowerAlternatives.cpp
  Lowering.cpp
  Lowering.h
  Passes.h)
