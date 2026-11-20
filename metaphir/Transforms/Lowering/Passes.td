//===- Lowering/Passes.td - Lowering passes ----------------*- tablegen -*-===//
//
// Lowering: the surface mpir a parse emits (metaflags, mpir.use, ':c' and ':o')
// → lowered mpir, in which every choice a match makes is an mpir.alt. They
// run in this order (buildLoweringPipeline, "mpir-lower").
// A pass lists as dependentDialects the dialects whose ops it creates that its
// input may not have loaded.
//
//===----------------------------------------------------------------------===//

include "mlir/Pass/PassBase.td"

def DesugarMetaFlagsPass : Pass<"mpir-desugar-metaflags", "mlir::ModuleOp"> {
  let summary = "Turn metaflags into constraints";
  let description = [{
    - Reads: surface `mpir`, with metaflags.
    - Writes: `mpir` without metaflags; each becomes an `mpir.require` of an
      `mpir_expr` constraint.
  }];
  let dependentDialects = ["mpir_expr::ExprDialect"];
}

def ExpandMatchersPass : Pass<"mpir-expand-matchers", "mlir::ModuleOp"> {
  let summary = "Inline the uses of 'match' matchers";
  let description = [{
    - Reads: `mpir` with `mpir.use`s of `mpir.matcher`s.
    - Writes: `mpir` without `mpir.use`; each becomes an `mpir.alt` with an
      alternative per branch (and per operand order, with `:c`), and one that
      matches the operand, with `:o`.
  }];
}

def LowerAlternativesPass : Pass<"mpir-lower-alternatives", "mlir::ModuleOp"> {
  let summary = "Turn ':c' and ':o' on instruction matchers into mpir.alt";
  let description = [{
    - Reads: `mpir` with `:c` and `:o` on `mpir.inst`s.
    - Writes: lowered `mpir`, in which every choice a match makes is an
      `mpir.alt`. A commuted compare's predicate is swapped by a keyword, or by
      an `mpir.let` of an `mpir_expr` call.
  }];
  let dependentDialects = ["mpir_expr::ExprDialect"];
}

def CheckBindingsPass : Pass<"mpir-check-bindings", "mlir::ModuleOp"> {
  let summary = "Check that every alternative binds the named meta variables";
  let description = [{
    - Reads: lowered `mpir`.
    - Writes: nothing; fails on a named meta variable some `mpir.alt`
      alternatives leave unbound.
  }];
}
