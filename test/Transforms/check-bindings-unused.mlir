// RUN: %metaphir-opt --mpir-check-bindings %s | FileCheck %s
// mpir-check-bindings is about what ':o' leaves unbound: a variable nothing
// binds at all is not its concern, nor is an instruction only a constraint
// reads a root of its own.

mpir.pattern {
  %i32 = mpir.type.int 32 : !mpir.sort<Type>
  %x = mpir.var "x" : !mpir.sort<Operand>
  %unused = mpir.var "unused" : !mpir.sort<Operand>
  %a = mpir.inst <add>(%i32, %x, %i32, %x) <result_name = "a", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
  %alt = mpir.alt {
    mpir.yield %x : !mpir.sort<Operand>
  }, {
    mpir.yield %a : !mpir.sort<Instruction>
  } attributes {or_self_of = "add", or_self_region = 0 : i32, result_name = "a"} : !mpir.sort<Instruction>
  %b = mpir.inst <mul>(%i32, %alt, %i32, %x) <result_name = "b", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
  %r = mpir_expr.read %b : (!mpir.sort<Instruction>) -> !mpir.sort<Value>
  %one = mpir_expr.call call "hasOneUse"(%r) anchor %b : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
  mpir.require %one : !mpir.sort<Boolean>
}
// CHECK-LABEL:   mpir.pattern {
// CHECK:           %[[TYPE_0:.*]] = mpir.type.int 32 : <Type>
// CHECK:           %[[VAR_0:.*]] = mpir.var "x" : <Operand>
// CHECK:           %[[VAR_1:.*]] = mpir.var "unused" : <Operand>
// CHECK:           %[[INST_0:.*]] = mpir.inst <add> (%[[TYPE_0]], %[[VAR_0]], %[[TYPE_0]], %[[VAR_0]]) <result_name = "a", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:           %[[ALT_0:.*]] = mpir.alt {
// CHECK:             mpir.yield %[[VAR_0]] : <Operand>
// CHECK:           }, {
// CHECK:             mpir.yield %[[INST_0]] : <Instruction>
// CHECK:           } attributes {or_self_of = "add", or_self_region = 0 : i32, result_name = "a"} : <Instruction>
// CHECK:           %[[INST_1:.*]] = mpir.inst <mul> (%[[TYPE_0]], %[[ALT_0]], %[[TYPE_0]], %[[VAR_0]]) <result_name = "b", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:           %[[READ_0:.*]] = mpir_expr.read %[[INST_1]] : (!mpir.sort<Instruction>) -> !mpir.sort<Value>
// CHECK:           %[[CALL_0:.*]] = mpir_expr.call call "hasOneUse"(%[[READ_0]]) anchor %[[INST_1]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:           mpir.require %[[CALL_0]] : <Boolean>
// CHECK:         }
