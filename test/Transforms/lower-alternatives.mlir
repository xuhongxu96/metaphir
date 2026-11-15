// RUN: %metaphir-opt --split-input-file --mpir-lower-alternatives %s | FileCheck %s
// mpir-lower-alternatives turns the choices written on instruction matchers
// into mpir.alt: ':c' into the instruction with its operands in either order,
// ':o' into its operand or the instruction.

// ':c': both orders of the two operands.
mpir.pattern {
// CHECK-LABEL:   mpir.pattern {
  %0 = mpir.type.int 32 : <Type> loc("lower-alternatives.mlir":9:1)
// CHECK:           %[[TYPE_0:.*]] = mpir.type.int 32 : <Type>
  %x = mpir.var "x" : <Operand> loc("lower-alternatives.mlir":11:1)
// CHECK:           %[[VAR_0:.*]] = mpir.var "x" : <Operand>
  %1 = mpir.int 1 : ui1 : <Value> loc("lower-alternatives.mlir":13:1)
// CHECK:           %[[INT_0:.*]] = mpir.int 1 : ui1 : <Value>
// CHECK:           %[[ALT_0:.*]] = mpir.alt {
  %i_a = mpir.inst <add> (%0, %x, %0, %1) <result_name = "a", flags = [], flag_modes = [], operand_kinds = [0, 0], metaflags = [#mpir.metaflag<"c", [], loc("lower-alternatives.mlir":16:1)>]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
// CHECK:             %[[INST_0:.*]] = mpir.inst <add> (%[[TYPE_0]], %[[VAR_0]], %[[TYPE_0]], %[[INT_0]]) <result_name = "a", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
// CHECK:             mpir.yield %[[INST_0]] : <Instruction>
// CHECK:           }, {
// CHECK:             %[[INST_1:.*]] = mpir.inst <add> (%[[TYPE_0]], %[[INT_0]], %[[TYPE_0]], %[[VAR_0]]) <result_name = "a", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Value>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:             mpir.yield %[[INST_1]] : <Instruction>
// CHECK:           } attributes {commuted, result_name = "a"} : <Instruction>
} loc("lower-alternatives.mlir":23:1)
// CHECK:         }

// -----

// ':c' on a comparison: the swapped order matches the swapped predicate.
mpir.pattern {
// CHECK-LABEL:   mpir.pattern {
  %0 = mpir.keyword ult : <Value> loc("lower-alternatives.mlir":31:1)
// CHECK:           %[[KEYWORD_0:.*]] = mpir.keyword ult : <Value>
  %1 = mpir.type.int 32 : <Type> loc("lower-alternatives.mlir":33:1)
// CHECK:           %[[TYPE_0:.*]] = mpir.type.int 32 : <Type>
  %x = mpir.var "x" : <Operand> loc("lower-alternatives.mlir":35:1)
// CHECK:           %[[VAR_0:.*]] = mpir.var "x" : <Operand>
  %y = mpir.var "y" : <Operand> loc("lower-alternatives.mlir":37:1)
// CHECK:           %[[VAR_1:.*]] = mpir.var "y" : <Operand>
// CHECK:           %[[ALT_0:.*]] = mpir.alt {
  %i_c = mpir.inst <icmp> (%0, %1, %x, %1, %y) <result_name = "c", flags = [], flag_modes = [], operand_kinds = [5, 0, 0], metaflags = [#mpir.metaflag<"c", [], loc("lower-alternatives.mlir":40:1)>]> : (!mpir.sort<Value>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:             %[[INST_0:.*]] = mpir.inst <icmp> (%[[KEYWORD_0]], %[[TYPE_0]], %[[VAR_0]], %[[TYPE_0]], %[[VAR_1]]) <result_name = "c", flags = [], flag_modes = [], operand_kinds = [5, 0, 0]> : (!mpir.sort<Value>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:             mpir.yield %[[INST_0]] : <Instruction>
// CHECK:           }, {
// CHECK:             %[[INST_1:.*]] = mpir.inst <icmp> (%[[KEYWORD_0]], %[[TYPE_0]], %[[VAR_1]], %[[TYPE_0]], %[[VAR_0]]) <result_name = "c", flags = [], flag_modes = [], operand_kinds = [5, 0, 0], swapped_predicate> : (!mpir.sort<Value>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:             mpir.yield %[[INST_1]] : <Instruction>
// CHECK:           } attributes {commuted, result_name = "c"} : <Instruction>
  %p = mpir.var "p" : <CmpPredicate> loc("lower-alternatives.mlir":47:1)
// CHECK:           %[[VAR_2:.*]] = mpir.var "p" : <CmpPredicate>
  %2 = mpir.type.prim float : <Type> loc("lower-alternatives.mlir":49:1)
// CHECK:           %[[TYPE_1:.*]] = mpir.type.prim float : <Type>
  %f = mpir.var "f" : <Operand> loc("lower-alternatives.mlir":51:1)
// CHECK:           %[[VAR_3:.*]] = mpir.var "f" : <Operand>
  %3 = mpir.float 1.000000e+00 : f64 -> <Value> loc("lower-alternatives.mlir":53:1)
// CHECK:           %[[FLOAT_0:.*]] = mpir.float 1.000000e+00 : f64 -> <Value>
// CHECK:           %[[ALT_1:.*]] = mpir.alt {
  %i_d = mpir.inst <fcmp> (%p, %2, %f, %2, %3) <result_name = "d", flags = [], flag_modes = [], operand_kinds = [5, 0, 0], metaflags = [#mpir.metaflag<"c", [], loc("lower-alternatives.mlir":56:1)>]> : (!mpir.sort<CmpPredicate>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
// CHECK:             %[[INST_2:.*]] = mpir.inst <fcmp> (%[[VAR_2]], %[[TYPE_1]], %[[VAR_3]], %[[TYPE_1]], %[[FLOAT_0]]) <result_name = "d", flags = [], flag_modes = [], operand_kinds = [5, 0, 0]> : (!mpir.sort<CmpPredicate>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
// CHECK:             mpir.yield %[[INST_2]] : <Instruction>
// CHECK:           }, {
// CHECK:             %[[INST_3:.*]] = mpir.inst <fcmp> (%[[VAR_2]], %[[TYPE_1]], %[[FLOAT_0]], %[[TYPE_1]], %[[VAR_3]]) <result_name = "d", flags = [], flag_modes = [], operand_kinds = [5, 0, 0], swapped_predicate> : (!mpir.sort<CmpPredicate>, !mpir.sort<Type>, !mpir.sort<Value>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:             mpir.yield %[[INST_3]] : <Instruction>
// CHECK:           } attributes {commuted, result_name = "d"} : <Instruction>
} loc("lower-alternatives.mlir":63:1)
// CHECK:         }

// -----

// ':c' on a call of two arguments swaps them, not the callee.
mpir.pattern {
// CHECK-LABEL:   mpir.pattern {
  %0 = mpir.type.int 32 : <Type> loc("lower-alternatives.mlir":71:1)
// CHECK:           %[[TYPE_0:.*]] = mpir.type.int 32 : <Type>
  %1 = mpir.global "llvm.umax.i32" : <Value> loc("lower-alternatives.mlir":73:1)
// CHECK:           %[[GLOBAL_0:.*]] = mpir.global "llvm.umax.i32" : <Value>
  %2 = mpir.type.int 32 : <Type> loc("lower-alternatives.mlir":75:1)
// CHECK:           %[[TYPE_1:.*]] = mpir.type.int 32 : <Type>
  %x = mpir.var "x" : <Operand> loc("lower-alternatives.mlir":77:1)
// CHECK:           %[[VAR_0:.*]] = mpir.var "x" : <Operand>
  %3 = mpir.type.int 32 : <Type> loc("lower-alternatives.mlir":79:1)
// CHECK:           %[[TYPE_2:.*]] = mpir.type.int 32 : <Type>
  %4 = mpir.int 7 : ui3 : <Value> loc("lower-alternatives.mlir":81:1)
// CHECK:           %[[INT_0:.*]] = mpir.int 7 : ui3 : <Value>
// CHECK:           %[[ALT_0:.*]] = mpir.alt {
  %i_m = mpir.inst <call> (%0, %1, %2, %x, %3, %4) <result_name = "m", flags = [], flag_modes = [], operand_kinds = [2, 1, 0, 0], metaflags = [#mpir.metaflag<"c", [], loc("lower-alternatives.mlir":84:1)>]> : (!mpir.sort<Type>, !mpir.sort<Value>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
// CHECK:             %[[INST_0:.*]] = mpir.inst <call> (%[[TYPE_0]], %[[GLOBAL_0]], %[[TYPE_1]], %[[VAR_0]], %[[TYPE_2]], %[[INT_0]]) <result_name = "m", flags = [], flag_modes = [], operand_kinds = [2, 1, 0, 0]> : (!mpir.sort<Type>, !mpir.sort<Value>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
// CHECK:             mpir.yield %[[INST_0]] : <Instruction>
// CHECK:           }, {
// CHECK:             %[[INST_1:.*]] = mpir.inst <call> (%[[TYPE_0]], %[[GLOBAL_0]], %[[TYPE_2]], %[[INT_0]], %[[TYPE_1]], %[[VAR_0]]) <result_name = "m", flags = [], flag_modes = [], operand_kinds = [2, 1, 0, 0]> : (!mpir.sort<Type>, !mpir.sort<Value>, !mpir.sort<Type>, !mpir.sort<Value>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:             mpir.yield %[[INST_1]] : <Instruction>
// CHECK:           } attributes {commuted, result_name = "m"} : <Instruction>
} loc("lower-alternatives.mlir":91:1)
// CHECK:         }

// -----

// ':o': the first operand, or the instruction. The alternative is named
// after the instruction; its uses read the alternative.
mpir.pattern {
// CHECK-LABEL:   mpir.pattern {
  %0 = mpir.type.int 32 : <Type> loc("lower-alternatives.mlir":100:1)
// CHECK:           %[[TYPE_0:.*]] = mpir.type.int 32 : <Type>
  %x = mpir.var "x" : <Operand> loc("lower-alternatives.mlir":102:1)
// CHECK:           %[[VAR_0:.*]] = mpir.var "x" : <Operand>
  %1 = mpir.int 0 : ui1 : <Value> loc("lower-alternatives.mlir":104:1)
// CHECK:           %[[INT_0:.*]] = mpir.int 0 : ui1 : <Value>
// CHECK:           %[[ALT_0:.*]] = mpir.alt {
  %i_a = mpir.inst <add> (%0, %x, %0, %1) <result_name = "a", flags = [], flag_modes = [], operand_kinds = [0, 0], metaflags = [#mpir.metaflag<"o", [], loc("lower-alternatives.mlir":107:1)>]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
// CHECK:             mpir.yield %[[VAR_0]] : <Operand>
// CHECK:           }, {
// CHECK:             %[[INST_0:.*]] = mpir.inst <add> (%[[TYPE_0]], %[[VAR_0]], %[[TYPE_0]], %[[INT_0]]) <result_name = "a", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
// CHECK:             mpir.yield %[[INST_0]] : <Instruction>
// CHECK:           } attributes {or_self_of = "add", or_self_region = 0 : i32, result_name = "a"} : <Instruction>
  %2 = mpir.type.int 32 : <Type> loc("lower-alternatives.mlir":113:1)
// CHECK:           %[[TYPE_1:.*]] = mpir.type.int 32 : <Type>
  %i_b = mpir.inst <mul> (%2, %i_a, %2, %i_a) <result_name = "b", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Instruction>) -> !mpir.sort<Instruction> loc("lower-alternatives.mlir":115:1)
// CHECK:           %[[INST_1:.*]] = mpir.inst <mul> (%[[TYPE_1]], %[[ALT_0]], %[[TYPE_1]], %[[ALT_0]]) <result_name = "b", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Instruction>) -> !mpir.sort<Instruction>
} loc("lower-alternatives.mlir":117:1)
// CHECK:         }

// -----

// ':o(N)' picks the operand among the value operands, whatever else the
// instruction has; a capture is bound to the operand too.
mpir.pattern {
// CHECK-LABEL:   mpir.pattern {
  %sel = mpir.var "sel" : <Instruction> loc("lower-alternatives.mlir":126:1)
// CHECK:           %[[VAR_0:.*]] = mpir.var "sel" : <Instruction>
  %0 = mpir.type.int 1 : <Type> loc("lower-alternatives.mlir":128:1)
// CHECK:           %[[TYPE_0:.*]] = mpir.type.int 1 : <Type>
  %c = mpir.var "c" : <Boolean> loc("lower-alternatives.mlir":130:1)
// CHECK:           %[[VAR_1:.*]] = mpir.var "c" : <Boolean>
  %1 = mpir.type.int 32 : <Type> loc("lower-alternatives.mlir":132:1)
// CHECK:           %[[TYPE_1:.*]] = mpir.type.int 32 : <Type>
  %t = mpir.var "t" : <Operand> loc("lower-alternatives.mlir":134:1)
// CHECK:           %[[VAR_2:.*]] = mpir.var "t" : <Operand>
  %2 = mpir.type.int 32 : <Type> loc("lower-alternatives.mlir":136:1)
// CHECK:           %[[TYPE_2:.*]] = mpir.type.int 32 : <Type>
  %f = mpir.var "f" : <Operand> loc("lower-alternatives.mlir":138:1)
// CHECK:           %[[VAR_3:.*]] = mpir.var "f" : <Operand>
// CHECK:           %[[ALT_0:.*]] = mpir.alt {
  %i_s = mpir.inst <select> capture %sel (%0, %c, %1, %t, %2, %f) <result_name = "s", flags = [], flag_modes = [], operand_kinds = [0, 0, 0], metaflags = [#mpir.metaflag<"o", [2], loc("lower-alternatives.mlir":141:1)>]> : (!mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Boolean>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:             mpir.bind %[[VAR_0]], %[[VAR_3]] : <Instruction>, <Operand>
// CHECK:             mpir.yield %[[VAR_3]] : <Operand>
// CHECK:           }, {
// CHECK:             %[[INST_0:.*]] = mpir.inst <select> capture %[[VAR_0]] (%[[TYPE_0]], %[[VAR_1]], %[[TYPE_1]], %[[VAR_2]], %[[TYPE_2]], %[[VAR_3]]) <result_name = "s", flags = [], flag_modes = [], operand_kinds = [0, 0, 0]> : (!mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Boolean>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:             mpir.yield %[[INST_0]] : <Instruction>
// CHECK:           } attributes {or_self_of = "select", or_self_region = 0 : i32, result_name = "s"} : <Instruction>
  %ext = mpir.var "ext" : <Instruction> loc("lower-alternatives.mlir":148:1)
// CHECK:           %[[VAR_4:.*]] = mpir.var "ext" : <Instruction>
  %3 = mpir.type.int 8 : <Type> loc("lower-alternatives.mlir":150:1)
// CHECK:           %[[TYPE_3:.*]] = mpir.type.int 8 : <Type>
  %x = mpir.var "x" : <Operand> loc("lower-alternatives.mlir":152:1)
// CHECK:           %[[VAR_5:.*]] = mpir.var "x" : <Operand>
  %4 = mpir.type.int 32 : <Type> loc("lower-alternatives.mlir":154:1)
// CHECK:           %[[TYPE_4:.*]] = mpir.type.int 32 : <Type>
// CHECK:           %[[ALT_1:.*]] = mpir.alt {
  %i_z = mpir.inst <zext> capture %ext (%3, %x, %4) <result_name = "z", flags = [8], flag_modes = [0], operand_kinds = [0, 2], metaflags = [#mpir.metaflag<"o", [], loc("lower-alternatives.mlir":157:1)>]> : (!mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>) -> !mpir.sort<Instruction>
// CHECK:             mpir.bind %[[VAR_4]], %[[VAR_5]] : <Instruction>, <Operand>
// CHECK:             mpir.yield %[[VAR_5]] : <Operand>
// CHECK:           }, {
// CHECK:             %[[INST_1:.*]] = mpir.inst <zext> capture %[[VAR_4]] (%[[TYPE_3]], %[[VAR_5]], %[[TYPE_4]]) <result_name = "z", flags = [8], flag_modes = [0], operand_kinds = [0, 2]> : (!mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>) -> !mpir.sort<Instruction>
// CHECK:             mpir.yield %[[INST_1]] : <Instruction>
// CHECK:           } attributes {or_self_of = "zext", or_self_region = 0 : i32, result_name = "z"} : <Instruction>
} loc("lower-alternatives.mlir":164:1)
// CHECK:         }

// -----

// ':c' and ':o' together: the operand, or the instruction in either order.
mpir.pattern {
// CHECK-LABEL:   mpir.pattern {
  %0 = mpir.type.int 32 : <Type> loc("lower-alternatives.mlir":172:1)
// CHECK:           %[[TYPE_0:.*]] = mpir.type.int 32 : <Type>
  %1 = mpir.int 1 : ui1 : <Value> loc("lower-alternatives.mlir":174:1)
// CHECK:           %[[INT_0:.*]] = mpir.int 1 : ui1 : <Value>
  %x = mpir.var "x" : <Operand> loc("lower-alternatives.mlir":176:1)
// CHECK:           %[[VAR_0:.*]] = mpir.var "x" : <Operand>
// CHECK:           %[[ALT_0:.*]] = mpir.alt {
  %i_a = mpir.inst <add> (%0, %1, %0, %x) <result_name = "a", flags = [], flag_modes = [], operand_kinds = [0, 0], metaflags = [#mpir.metaflag<"c", [], loc("lower-alternatives.mlir":179:1)>, #mpir.metaflag<"o", [1], loc("lower-alternatives.mlir":179:1)>]> : (!mpir.sort<Type>, !mpir.sort<Value>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:             mpir.yield %[[VAR_0]] : <Operand>
// CHECK:           }, {
// CHECK:             %[[ALT_1:.*]] = mpir.alt {
// CHECK:               %[[INST_0:.*]] = mpir.inst <add> (%[[TYPE_0]], %[[INT_0]], %[[TYPE_0]], %[[VAR_0]]) <result_name = "a", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Value>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:               mpir.yield %[[INST_0]] : <Instruction>
// CHECK:             }, {
// CHECK:               %[[INST_1:.*]] = mpir.inst <add> (%[[TYPE_0]], %[[VAR_0]], %[[TYPE_0]], %[[INT_0]]) <result_name = "a", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
// CHECK:               mpir.yield %[[INST_1]] : <Instruction>
// CHECK:             } attributes {commuted, result_name = "a"} : <Instruction>
// CHECK:             mpir.yield %[[ALT_1]] : <Instruction>
// CHECK:           } attributes {or_self_of = "add", or_self_region = 0 : i32, result_name = "a"} : <Instruction>
} loc("lower-alternatives.mlir":191:1)
// CHECK:         }

// -----

// An instruction without a result name, with flags, a block and a setting:
// all are kept on each copy.
mpir.pattern {
// CHECK-LABEL:   mpir.pattern {
  %bb = mpir.var "bb" : <BasicBlock> loc("lower-alternatives.mlir":200:1)
// CHECK:           %[[VAR_0:.*]] = mpir.var "bb" : <BasicBlock>
  %u = mpir.var "u" : <Boolean> loc("lower-alternatives.mlir":202:1)
// CHECK:           %[[VAR_1:.*]] = mpir.var "u" : <Boolean>
  %0 = mpir.type.int 32 : <Type> loc("lower-alternatives.mlir":204:1)
// CHECK:           %[[TYPE_0:.*]] = mpir.type.int 32 : <Type>
  %x = mpir.var "x" : <Operand> loc("lower-alternatives.mlir":206:1)
// CHECK:           %[[VAR_2:.*]] = mpir.var "x" : <Operand>
  %1 = mpir.int 1 : ui1 : <Value> loc("lower-alternatives.mlir":208:1)
// CHECK:           %[[INT_0:.*]] = mpir.int 1 : ui1 : <Value>
// CHECK:           %[[ALT_0:.*]] = mpir.alt {
  %2 = mpir.inst <add> block %bb flags(%u) (%0, %x, %0, %1) <flags = [0, 1], flag_modes = [0, 2], operand_kinds = [0, 0], metaflags = [#mpir.metaflag<"c", [], loc("lower-alternatives.mlir":211:1)>], treat_int_as_vec = true> : (!mpir.sort<BasicBlock>, !mpir.sort<Boolean>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
// CHECK:             %[[INST_0:.*]] = mpir.inst <add> block %[[VAR_0]] flags(%[[VAR_1]]) (%[[TYPE_0]], %[[VAR_2]], %[[TYPE_0]], %[[INT_0]]) <flags = [0, 1], flag_modes = [0, 2], operand_kinds = [0, 0], treat_int_as_vec = true> : (!mpir.sort<BasicBlock>, !mpir.sort<Boolean>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
// CHECK:             mpir.yield %[[INST_0]] : <Instruction>
// CHECK:           }, {
// CHECK:             %[[INST_1:.*]] = mpir.inst <add> block %[[VAR_0]] flags(%[[VAR_1]]) (%[[TYPE_0]], %[[INT_0]], %[[TYPE_0]], %[[VAR_2]]) <flags = [0, 1], flag_modes = [0, 2], operand_kinds = [0, 0], treat_int_as_vec = true> : (!mpir.sort<BasicBlock>, !mpir.sort<Boolean>, !mpir.sort<Type>, !mpir.sort<Value>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:             mpir.yield %[[INST_1]] : <Instruction>
// CHECK:           } attributes {commuted} : <Instruction>
} loc("lower-alternatives.mlir":218:1)
// CHECK:         }

// -----

// Instructions inside the alternatives of an expanded matcher.
mpir.pattern {
// CHECK-LABEL:   mpir.pattern {
  %0 = mpir.type.int 32 : <Type> loc("lower-alternatives.mlir":226:1)
// CHECK:           %[[TYPE_0:.*]] = mpir.type.int 32 : <Type>
  %x = mpir.var "x" : <Operand> loc("lower-alternatives.mlir":228:1)
// CHECK:           %[[VAR_0:.*]] = mpir.var "x" : <Operand>
  %y = mpir.var "y" : <Operand> loc("lower-alternatives.mlir":230:1)
// CHECK:           %[[VAR_1:.*]] = mpir.var "y" : <Operand>
// CHECK:           %[[ALT_0:.*]] = mpir.alt {
  %1 = mpir.alt {
    %2 = mpir.int 3 : ui2 : <Value> loc("lower-alternatives.mlir":234:1)
// CHECK:             %[[INT_0:.*]] = mpir.int 3 : ui2 : <Value>
// CHECK:             %[[ALT_1:.*]] = mpir.alt {
    %i_r_m = mpir.inst <mul> (%0, %x, %0, %2) <result_name = "r$m", flags = [], flag_modes = [], operand_kinds = [0, 0], metaflags = [#mpir.metaflag<"c", [], loc("lower-alternatives.mlir":237:1)>]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
// CHECK:               %[[INST_0:.*]] = mpir.inst <mul> (%[[TYPE_0]], %[[VAR_0]], %[[TYPE_0]], %[[INT_0]]) <result_name = "r$m", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
// CHECK:               mpir.yield %[[INST_0]] : <Instruction>
// CHECK:             }, {
// CHECK:               %[[INST_1:.*]] = mpir.inst <mul> (%[[TYPE_0]], %[[INT_0]], %[[TYPE_0]], %[[VAR_0]]) <result_name = "r$m", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Value>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:               mpir.yield %[[INST_1]] : <Instruction>
// CHECK:             } attributes {commuted, result_name = "r$m"} : <Instruction>
// CHECK:             %[[ALT_2:.*]] = mpir.alt {
    %i_r = mpir.inst <add> (%0, %y, %0, %i_r_m) <result_name = "r", flags = [], flag_modes = [], operand_kinds = [0, 0], metaflags = [#mpir.metaflag<"o", [1], loc("lower-alternatives.mlir":245:1)>]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Instruction>) -> !mpir.sort<Instruction>
// CHECK:               mpir.yield %[[ALT_1]] : <Instruction>
// CHECK:             }, {
// CHECK:               %[[INST_2:.*]] = mpir.inst <add> (%[[TYPE_0]], %[[VAR_1]], %[[TYPE_0]], %[[ALT_1]]) <result_name = "r", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Instruction>) -> !mpir.sort<Instruction>
// CHECK:               mpir.yield %[[INST_2]] : <Instruction>
// CHECK:             } attributes {or_self_of = "add", or_self_region = 0 : i32, result_name = "r"} : <Instruction>
    mpir.yield %i_r : <Instruction> loc("lower-alternatives.mlir":251:1)
// CHECK:             mpir.yield %[[ALT_2]] : <Instruction>
  }, {
// CHECK:           }, {
    %i_r = mpir.inst <shl> (%0, %x, %0, %y) <result_name = "r", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction> loc("lower-alternatives.mlir":255:1)
// CHECK:             %[[INST_3:.*]] = mpir.inst <shl> (%[[TYPE_0]], %[[VAR_0]], %[[TYPE_0]], %[[VAR_1]]) <result_name = "r", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
    mpir.yield %i_r : <Instruction> loc("lower-alternatives.mlir":257:1)
// CHECK:             mpir.yield %[[INST_3]] : <Instruction>
  } attributes {result_name = "r"} : <Instruction> loc("lower-alternatives.mlir":259:1)
// CHECK:           } attributes {result_name = "r"} : <Instruction>
} loc("lower-alternatives.mlir":261:1)
// CHECK:         }

// -----

// Instructions without choices are left as they are, whatever they had.
mpir.pattern {
// CHECK-LABEL:   mpir.pattern {
  %0 = mpir.type.int 32 : <Type> loc("lower-alternatives.mlir":269:1)
// CHECK:           %[[TYPE_0:.*]] = mpir.type.int 32 : <Type>
  %x = mpir.var "x" : <Operand> loc("lower-alternatives.mlir":271:1)
// CHECK:           %[[VAR_0:.*]] = mpir.var "x" : <Operand>
  %y = mpir.var "y" : <Operand> loc("lower-alternatives.mlir":273:1)
// CHECK:           %[[VAR_1:.*]] = mpir.var "y" : <Operand>
  %i_a = mpir.inst <add> (%0, %x, %0, %y) <result_name = "a", flags = [0], flag_modes = [0], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction> loc("lower-alternatives.mlir":275:1)
// CHECK:           %[[INST_0:.*]] = mpir.inst <add> (%[[TYPE_0]], %[[VAR_0]], %[[TYPE_0]], %[[VAR_1]]) <result_name = "a", flags = [0], flag_modes = [0], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
  %1 = mpir.type.int 32 : <Type> loc("lower-alternatives.mlir":277:1)
// CHECK:           %[[TYPE_1:.*]] = mpir.type.int 32 : <Type>
  %i_b = mpir.inst <sub> (%1, %i_a, %1, %y) <result_name = "b", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction> loc("lower-alternatives.mlir":279:1)
// CHECK:           %[[INST_1:.*]] = mpir.inst <sub> (%[[TYPE_1]], %[[INST_0]], %[[TYPE_1]], %[[VAR_1]]) <result_name = "b", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
  %2 = mpir_expr.read %i_a : (!mpir.sort<Instruction>) -> !mpir.sort<Value> loc("lower-alternatives.mlir":281:1)
// CHECK:           %[[READ_0:.*]] = mpir_expr.read %[[INST_0]] : (!mpir.sort<Instruction>) -> !mpir.sort<Value>
  %3 = mpir_expr.call call "hasOneUse"(%2) anchor %i_a : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("lower-alternatives.mlir":283:1)
// CHECK:           %[[CALL_0:.*]] = mpir_expr.call call "hasOneUse"(%[[READ_0]]) anchor %[[INST_0]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
  mpir.require %3 {from_metaflag} : <Boolean> loc("lower-alternatives.mlir":285:1)
// CHECK:           mpir.require %[[CALL_0]] {from_metaflag} : <Boolean>
  %4 = mpir_expr.read %x : (!mpir.sort<Operand>) -> !mpir.sort<Value> loc("lower-alternatives.mlir":287:1)
// CHECK:           %[[READ_1:.*]] = mpir_expr.read %[[VAR_0]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
  %5 = mpir_expr.call call "isZero"(%4) anchor %i_a : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("lower-alternatives.mlir":289:1)
// CHECK:           %[[CALL_1:.*]] = mpir_expr.call call "isZero"(%[[READ_1]]) anchor %[[INST_0]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
  mpir.require %5 {from_metaflag} : <Boolean> loc("lower-alternatives.mlir":291:1)
// CHECK:           mpir.require %[[CALL_1]] {from_metaflag} : <Boolean>
} loc("lower-alternatives.mlir":293:1)
// CHECK:         }
