# ToPlan: lowered mpir → mpir_plan.
set(LLVM_TARGET_DEFINITIONS Passes.td)
mlir_tablegen(Passes.h.inc -gen-pass-decls -name ToPlan)
mlir_tablegen(Passes.md -gen-pass-doc)
add_public_tablegen_target(MetaphIRToPlanPassIncGen)

target_sources(metaphir-transforms PRIVATE Passes.h ToPlan.cpp)
