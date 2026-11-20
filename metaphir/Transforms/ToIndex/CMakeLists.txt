# ToIndex: lowered mpir → mpir_index, and the passes over mpir_index.
set(LLVM_TARGET_DEFINITIONS Passes.td)
mlir_tablegen(Passes.h.inc -gen-pass-decls -name ToIndex)
mlir_tablegen(Passes.md -gen-pass-doc)
add_public_tablegen_target(MetaphIRToIndexPassIncGen)

target_sources(metaphir-transforms PRIVATE
  Passes.h
  Retrieval.cpp
  Structuralize.cpp
  ToIndex.cpp)
