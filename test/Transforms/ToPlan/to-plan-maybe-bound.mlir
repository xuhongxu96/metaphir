// NOTE: CHECK lines are written by hand; update_test_check.py skips this file.
// RUN: %metaphir-opt --mpir-to-plan %s | FileCheck %s
// %q is bound in the alternative that uses it and not in the other, so it is
// matched after the roots only where it is not bound yet. Under
// 'check_bound is false' it is unbound: it is matched in full there, not
// asked again whether it is bound.

// CHECK:      mpir_plan.check_bound 3 is false
// CHECK-NEXT: %[[EACH:.*]] = mpir_plan.foreach_instruction
// CHECK-NEXT: mpir_plan.check_opcode %[[EACH]], <lshr>
// CHECK-NOT:  mpir_plan.check_bound 3

mpir.pattern {
  %0 = mpir.type.int 32 : <Type>
  %x = mpir.var "x" : <Operand>
  %1 = mpir.int 1 : ui1 : <Value>
  %i_p = mpir.inst <shl> (%0, %x, %0, %1) <result_name = "p", flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
  %2 = mpir.type.int 32 : <Type>
  %z = mpir.var "z" : <Operand>
  %3 = mpir.int 1 : ui1 : <Value>
  %i_q = mpir.inst <lshr> (%2, %z, %2, %3) <result_name = "q", flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
  %4 = mpir.type.int 32 : <Type>
  %5 = mpir.alt {
    %i_r = mpir.inst <add> (%4, %i_p, %4, %i_q) <result_name = "r", flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Instruction>) -> !mpir.sort<Instruction>
    mpir.yield %i_r : <Instruction>
  }, {
    %i_r = mpir.inst <sub> (%4, %i_p, %4, %i_p) <result_name = "r", flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Instruction>) -> !mpir.sort<Instruction>
    mpir.yield %i_r : <Instruction>
  } <result_name = "r"> : <Instruction>
}
