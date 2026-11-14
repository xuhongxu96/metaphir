// RUN: %metaphir-opt %s | %metaphir-opt | FileCheck %s

// '(X u/ 2) + (X u% 2)' with ':c', and a metaflag on ?x, as the parser
// writes it.
// CHECK-LABEL: mpir.pattern
mpir.pattern {
  %n = mpir.var "n" : !mpir.sort<Nat>
  %x = mpir.var "x" : !mpir.sort<Value>
  %ty = "mpir.type.meta_int"(%n) : (!mpir.sort<Nat>) -> !mpir.sort<Type>
  %two = "mpir.int"() {value = 2 : i64} : () -> !mpir.sort<Value>
  // CHECK: %i_div = "mpir.inst"
  %div = "mpir.inst"(%ty, %x, %ty, %two) {opcode = #mpir.opcode<udiv>, result_name = "div",
      flags = array<i32>, flag_modes = array<i32>, operand_kinds = array<i32: 0, 0>,
      operandSegmentSizes = array<i32: 0, 0, 0, 4>}
      : (!mpir.sort<Type>, !mpir.sort<Value>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
  %rem = "mpir.inst"(%ty, %x, %ty, %two) {opcode = #mpir.opcode<urem>, result_name = "rem",
      flags = array<i32>, flag_modes = array<i32>, operand_kinds = array<i32: 0, 0>,
      operandSegmentSizes = array<i32: 0, 0, 0, 4>}
      : (!mpir.sort<Type>, !mpir.sort<Value>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
  // CHECK: #mpir.metaflag<"c", []
  %sum = "mpir.inst"(%ty, %div, %ty, %rem) {opcode = #mpir.opcode<add>, result_name = "sum",
      metaflags = [#mpir.metaflag<"c", [], loc(unknown)>], flags = array<i32>, flag_modes = array<i32>,
      operand_kinds = array<i32: 0, 0>, operandSegmentSizes = array<i32: 0, 0, 0, 4>}
      : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Instruction>) -> !mpir.sort<Instruction>
}
