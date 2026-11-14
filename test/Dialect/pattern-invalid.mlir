// RUN: not %metaphir-opt --split-input-file %s 2>&1 | FileCheck %s

mpir.pattern {
  %x = mpir.var "x" : !mpir.sort<Value>
  // CHECK: operand kinds need 2 operand values, but it has 1
  %a = "mpir.inst"(%x) {opcode = #mpir.opcode<freeze>, flags = array<i32>,
      flag_modes = array<i32>, operand_kinds = array<i32: 0>,
      operandSegmentSizes = array<i32: 0, 0, 0, 1>}
      : (!mpir.sort<Value>) -> !mpir.sort<Instruction>
}

// -----

mpir.pattern {
  %ty = "mpir.type.int"() {width = 32 : i32} : () -> !mpir.sort<Type>
  %x = mpir.var "x" : !mpir.sort<Value>
  // CHECK: 'sub' is not commutative
  %a = "mpir.inst"(%ty, %x, %ty, %x) {opcode = #mpir.opcode<sub>, metaflags = [#mpir.metaflag<"c", [], loc(unknown)>],
      flags = array<i32>, flag_modes = array<i32>, operand_kinds = array<i32: 0, 0>,
      operandSegmentSizes = array<i32: 0, 0, 0, 4>}
      : (!mpir.sort<Type>, !mpir.sort<Value>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
}

// -----

// CHECK: unknown sort 'Bogus'
"mpir.require"(%c) : (!mpir.sort<Bogus>) -> ()
