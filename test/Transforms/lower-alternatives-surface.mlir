// RUN: %metaphir-opt --mpir-lower-alternatives %s | FileCheck %s
// mpir-lower-alternatives on a module whose metaflags are not desugared:
// an instruction with other metaflags only is left as it is, and one with
// a choice among them loses them all.

mpir.pattern {
  %i32 = mpir.type.int 32 : !mpir.sort<Type>
  %x = mpir.var "x" : !mpir.sort<Operand>
  %a = mpir.inst <add>(%i32, %x, %i32, %x) <result_name = "a", flags = [], flag_modes = [], operand_kinds = [0, 0], metaflags = [#mpir.metaflag<"s", [], loc(unknown)>]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
  %b = mpir.inst <mul>(%i32, %a, %i32, %x) <result_name = "b", flags = [], flag_modes = [], operand_kinds = [0, 0], metaflags = [#mpir.metaflag<"s", [], loc(unknown)>, #mpir.metaflag<"c", [], loc(unknown)>], operand_metaflags = [[#mpir.metaflag<"zero", [], loc(unknown)>], []]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
}
// CHECK-LABEL:   mpir.pattern {
// CHECK:           %[[TYPE_0:.*]] = mpir.type.int 32 : <Type>
// CHECK:           %[[VAR_0:.*]] = mpir.var "x" : <Operand>
// CHECK:           %[[INST_0:.*]] = mpir.inst <add> (%[[TYPE_0]], %[[VAR_0]], %[[TYPE_0]], %[[VAR_0]]) <result_name = "a", flags = [], flag_modes = [], operand_kinds = [0, 0], metaflags = [#mpir.metaflag<"s", [], {{.*}}>]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:           %[[ALT_0:.*]] = mpir.alt {
// CHECK:             %[[INST_1:.*]] = mpir.inst <mul> (%[[TYPE_0]], %[[INST_0]], %[[TYPE_0]], %[[VAR_0]]) <result_name = "b", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:             mpir.yield %[[INST_1]] : <Instruction>
// CHECK:           }, {
// CHECK:             %[[INST_2:.*]] = mpir.inst <mul> (%[[TYPE_0]], %[[VAR_0]], %[[TYPE_0]], %[[INST_0]]) <result_name = "b", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Instruction>) -> !mpir.sort<Instruction>
// CHECK:             mpir.yield %[[INST_2]] : <Instruction>
// CHECK:           } attributes {commuted, result_name = "b"} : <Instruction>
// CHECK:         }
