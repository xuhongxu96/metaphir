// RUN: %metaphir-opt --split-input-file --verify-diagnostics %s
// What the mpir_plan dialect rejects: a let whose condition is not that its
// slot's binding is its value.

mpir_plan.matcher <slot_names = ["x", "y"], slot_kinds = [variable, variable], slot_sorts = [Boolean, Boolean], slot_locs = [loc(unknown), loc(unknown)]> {
  %v = mpir_plan.slot 1 : <Boolean>
  %c = mpir_plan.slot 1 : <Boolean>
  // expected-error @+1 {{condition must be that slot 0's binding is the value}}
  mpir_plan.let 0, %v, %c : <Boolean>, <Boolean>
  mpir_plan.emit
}

// -----

mpir_plan.matcher <slot_names = ["x", "y"], slot_kinds = [variable, variable], slot_sorts = [Boolean, Boolean], slot_locs = [loc(unknown), loc(unknown)]> {
  %v = mpir_plan.slot 1 : <Boolean>
  %s = mpir_plan.slot 1 : <Boolean>
  %r = mpir_expr.read %s : (!mpir.sort<Boolean>) -> !mpir.sort<Boolean>
  %c = mpir_expr.call binary "=="(%r, %v) : (!mpir.sort<Boolean>, !mpir.sort<Boolean>) -> !mpir.sort<Boolean>
  // expected-error @+1 {{condition must be that slot 0's binding is the value}}
  mpir_plan.let 0, %v, %c : <Boolean>, <Boolean>
  mpir_plan.emit
}

// -----

mpir_plan.matcher <slot_names = ["x", "y"], slot_kinds = [variable, variable], slot_sorts = [Boolean, Boolean], slot_locs = [loc(unknown), loc(unknown)]> {
  %v = mpir_plan.slot 1 : <Boolean>
  %w = mpir_plan.slot 1 : <Boolean>
  %s = mpir_plan.slot 0 : <Boolean>
  %r = mpir_expr.read %s : (!mpir.sort<Boolean>) -> !mpir.sort<Boolean>
  %c = mpir_expr.call binary "=="(%r, %w) : (!mpir.sort<Boolean>, !mpir.sort<Boolean>) -> !mpir.sort<Boolean>
  // expected-error @+1 {{condition must be that slot 0's binding is the value}}
  mpir_plan.let 0, %v, %c : <Boolean>, <Boolean>
  mpir_plan.emit
}

// -----

mpir_plan.matcher <slot_names = ["x", "y"], slot_kinds = [variable, variable], slot_sorts = [Boolean, Boolean], slot_locs = [loc(unknown), loc(unknown)]> {
  %v = mpir_plan.slot 1 : <Boolean>
  %s = mpir_plan.slot 0 : <Boolean>
  %r = mpir_expr.read %s : (!mpir.sort<Boolean>) -> !mpir.sort<Boolean>
  %c = mpir_expr.call binary "!="(%r, %v) : (!mpir.sort<Boolean>, !mpir.sort<Boolean>) -> !mpir.sort<Boolean>
  // expected-error @+1 {{condition must be that slot 0's binding is the value}}
  mpir_plan.let 0, %v, %c : <Boolean>, <Boolean>
  mpir_plan.emit
}
