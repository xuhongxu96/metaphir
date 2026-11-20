//===- ToPlan/Passes.td - Plan passes ----------------------*- tablegen -*-===//
//
// ToPlan: lowered mpir → an mpir_plan.matcher added after each mpir.pattern,
// which stays.
// A pass lists as dependentDialects the dialects whose ops it creates that its
// input may not have loaded.
//
//===----------------------------------------------------------------------===//

include "mlir/Pass/PassBase.td"

def ToPlanPass : Pass<"mpir-to-plan", "mlir::ModuleOp"> {
  let summary = "Compile lowered patterns into match plans";
  let description = [{
    - Reads: lowered `mpir`.
    - Writes: an `mpir_plan.matcher` after each `mpir.pattern`, the plan that
      matches it; its constraints are `mpir_expr`.
  }];
  let dependentDialects = ["mpir_expr::ExprDialect", "mpir_plan::PlanDialect"];
}
