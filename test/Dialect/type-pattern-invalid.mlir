// RUN: %metaphir-opt --split-input-file --verify-diagnostics %s
// What type patterns reject, and the ops that take them.

mpir_plan.matcher <slot_names = [], slot_kinds = [], slot_sorts = [], slot_locs = []> {
  %i = mpir_plan.foreach_instruction
  %t = mpir_plan.get_type %i
  // expected-error @+1 {{expected a type pattern}}
  mpir_plan.check_type %t, #mpir.tp_seq<vector, 4, 8 : i32>
}

// -----

mpir_plan.matcher <slot_names = [], slot_kinds = [], slot_sorts = [], slot_locs = []> {
  %i = mpir_plan.foreach_instruction
  %t = mpir_plan.get_type %i
  // expected-error @+1 {{unknown sequence kind 'list'}}
  mpir_plan.check_type %t, #mpir.tp_seq<list, 4, #mpir.tp_int<8>>
}

// -----

mpir_plan.matcher <slot_names = [], slot_kinds = [], slot_sorts = [], slot_locs = []> {
  %i = mpir_plan.foreach_instruction
  %t = mpir_plan.get_type %i
  // expected-error @+2 {{expected a primitive type, got: i32}}
  // expected-error @+1 {{failed to parse Mpir_PrimTypePattern parameter 'kind'}}
  mpir_plan.check_type %t, #mpir.tp_prim<i32>
}

// -----

mpir_plan.matcher <slot_names = [], slot_kinds = [], slot_sorts = [], slot_locs = []> {
  %i = mpir_plan.foreach_instruction
  %t = mpir_plan.get_type %i
  // expected-error @+1 {{invalid kind of attribute specified}}
  mpir_plan.check_type %t, [1, 32, 0]
}

// -----

mpir_index.query {
  mpir_index.variant {
    // expected-error @+1 {{type patterns or unit}}
    mpir_index.typing <add> <present = 0, absent = 0, operand_types = [[]], value_operand = [true]>
  }
}
