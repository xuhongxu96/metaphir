//===- ToIndex/Passes.td - Index passes --------------------*- tablegen -*-===//
//
// ToIndex: lowered mpir → an mpir_index.query added after each mpir.pattern,
// which stays; the others read and rewrite mpir_index, in this order.
// A pass lists as dependentDialects the dialects whose ops it creates that its
// input may not have loaded.
//
//===----------------------------------------------------------------------===//

include "mlir/Pass/PassBase.td"

def ToIndexPass : Pass<"mpir-to-index", "mlir::ModuleOp"> {
  let summary = "Compile lowered patterns into index queries";
  let description = [{
    - Reads: lowered `mpir`.
    - Writes: an `mpir_index.query` after each `mpir.pattern`: a variant per
      choice of matcher branches, with the features a function needs for it.
  }];
  let dependentDialects = ["mpir_index::IndexDialect"];
}

def IndexStructuralizePass
    : Pass<"mpir-index-structuralize", "mlir::ModuleOp"> {
  let summary = "Require what constraints say of instructions as features";
  let description = [{
    - Reads and writes: `mpir_index`. What a variant's constraints say of the
      kind of an instruction, or of the intrinsic a call calls, becomes
      features it requires, which the corpus index has posting lists of.
  }];
}

def IndexRetrievalPass : Pass<"mpir-index-retrieval", "mlir::ModuleOp"> {
  let summary = "Add the posting-list lookup of index queries";
  let description = [{
    - Reads and writes: `mpir_index`. Each query gets an `mpir_index.retrieve`:
      the union over its variants of the intersection of their lists.
  }];
}

def IndexFactorPass : Pass<"mpir-index-factor", "mlir::ModuleOp"> {
  let summary = "Factor the posting lists every variant reads";
  let description = [{
    - Reads and writes: `mpir_index`. A list every variant of an
      `mpir_index.retrieve` reads is factored out of its union.
  }];
}
