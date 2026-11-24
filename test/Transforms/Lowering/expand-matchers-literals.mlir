// NOTE: CHECK lines are written by hand; update_test_check.py skips this file.
// RUN: %metaphir-opt --mpir-expand-matchers %s | FileCheck %s
// A parameter a use binds to a constant is read, in the branch's constraints,
// as that number: a literal, not a read of the constant.

// CHECK-LABEL: mpir.pattern {
// CHECK-NOT:   mpir_expr.read
// CHECK:       %[[BITS:.*]] = mpir_expr.int 32 : ui64 : <Integer>
// CHECK-NOT:   mpir_expr.read
// CHECK:       mpir_expr.call binary "=="(%[[BITS]],
mpir.matcher @low <supported_flags = [], syntax = nary, arity = 1, param_names = ["bits", "a"], param_is_type = [true, false]> {
  %bits = mpir.var "bits" : <Nat>
  %0 = mpir.type.meta_int %bits : (!mpir.sort<Nat>) -> !mpir.sort<Type>
  mpir.signature %0 : !mpir.sort<Type>
  mpir.branch <param_args = [0, 1], fixed_flags = [], fixed_flag_values = []> {
  ^bb0(%arg0: !mpir.sort<Nat>, %arg1: !mpir.sort<Operand>):
    %1 = mpir.type.meta_int %arg0 : (!mpir.sort<Nat>) -> !mpir.sort<Type>
    %2 = mpir.type.int 8 : <Type>
    %i_ret = mpir.inst <trunc> (%1, %arg1, %2) <result_name = "ret", flags = [], flag_modes = [], operand_kinds = [typed_value, type_only]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>) -> !mpir.sort<Instruction>
    %3 = mpir_expr.read %arg0 : (!mpir.sort<Nat>) -> !mpir.sort<Integer>
    %4 = mpir_expr.int 32 : ui64 : <Integer>
    %5 = mpir_expr.call binary "=="(%3, %4) anchor %i_ret : (!mpir.sort<Integer>, !mpir.sort<Integer>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
    mpir.require %5 : <Boolean>
    mpir.yield %i_ret : <Instruction>
  }
}
mpir.pattern {
  %0 = mpir.type.int 32 : <Type>
  %x = mpir.var "x" : <Operand>
  %u_r = mpir.use @low (%0, %x) <result_name = "r", flags = [], flag_modes = [], operand_kinds = [typed_value]> : (!mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
}
