// RUN: %metaphir-opt --mpir-check-bindings %s | FileCheck %s
// mpir-check-bindings is about what ':o' leaves unbound: a variable nothing
// binds at all is not its concern, nor is an instruction only a constraint
// reads a root of its own.

mpir.pattern {
// CHECK-LABEL:   mpir.pattern {
  %i32 = mpir.type.int 32 : !mpir.sort<Type> loc("check-bindings-unused.mlir":8:1)
// CHECK:           %[[TYPE_0:.*]] = mpir.type.int 32 : <Type>
  %x = mpir.var "x" : !mpir.sort<Operand> loc("check-bindings-unused.mlir":10:1)
// CHECK:           %[[VAR_0:.*]] = mpir.var "x" : <Operand>
  %unused = mpir.var "unused" : !mpir.sort<Operand> loc("check-bindings-unused.mlir":12:1)
// CHECK:           %[[VAR_1:.*]] = mpir.var "unused" : <Operand>
  %a = mpir.inst <add>(%i32, %x, %i32, %x) <result_name = "a", flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction> loc("check-bindings-unused.mlir":14:1)
// CHECK:           %[[INST_0:.*]] = mpir.inst <add> (%[[TYPE_0]], %[[VAR_0]], %[[TYPE_0]], %[[VAR_0]]) <flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value], result_name = "a"> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:           %[[ALT_0:.*]] = mpir.alt {
  %alt = mpir.alt {
    mpir.yield %x : !mpir.sort<Operand> loc("check-bindings-unused.mlir":18:1)
// CHECK:             mpir.yield %[[VAR_0]] : <Operand>
  }, {
// CHECK:           }, {
    mpir.yield %a : !mpir.sort<Instruction> loc("check-bindings-unused.mlir":22:1)
// CHECK:             mpir.yield %[[INST_0]] : <Instruction>
  } <result_name = "a"> : !mpir.sort<Instruction> loc("check-bindings-unused.mlir":24:1)
// CHECK:           } <result_name = "a"> : <Instruction>
  %b = mpir.inst <mul>(%i32, %alt, %i32, %x) <result_name = "b", flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction> loc("check-bindings-unused.mlir":26:1)
// CHECK:           %[[INST_1:.*]] = mpir.inst <mul> (%[[TYPE_0]], %[[ALT_0]], %[[TYPE_0]], %[[VAR_0]]) <flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value], result_name = "b"> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
  %r = mpir_expr.read %b : (!mpir.sort<Instruction>) -> !mpir.sort<Value> loc("check-bindings-unused.mlir":28:1)
// CHECK:           %[[READ_0:.*]] = mpir_expr.read %[[INST_1]] : (!mpir.sort<Instruction>) -> !mpir.sort<Value>
  %one = mpir_expr.call call "hasOneUse"(%r) anchor %b : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("check-bindings-unused.mlir":30:1)
// CHECK:           %[[CALL_0:.*]] = mpir_expr.call call "hasOneUse"(%[[READ_0]]) anchor %[[INST_1]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
  mpir.require %one : !mpir.sort<Boolean> loc("check-bindings-unused.mlir":32:1)
// CHECK:           mpir.require %[[CALL_0]] : <Boolean>
} loc("check-bindings-unused.mlir":34:1)
// CHECK:         }
