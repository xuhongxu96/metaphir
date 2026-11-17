// RUN: %metaphir-opt --split-input-file --mpir-check-bindings %s | FileCheck %s
// mpir-check-bindings accepts the patterns in which every named meta variable
// is bound whichever way ':o' is matched, and changes nothing.

// A variable the instruction binds is also bound elsewhere.
mpir.pattern {
// CHECK-LABEL:   mpir.pattern {
  %0 = mpir.type.int 32 : <Type> loc("check-bindings.mlir":8:1)
// CHECK:           %[[TYPE_0:.*]] = mpir.type.int 32 : <Type>
  %x = mpir.var "x" : <Operand> loc("check-bindings.mlir":10:1)
// CHECK:           %[[VAR_0:.*]] = mpir.var "x" : <Operand>
  %y = mpir.var "y" : <Operand> loc("check-bindings.mlir":12:1)
// CHECK:           %[[VAR_1:.*]] = mpir.var "y" : <Operand>
// CHECK:           %[[ALT_0:.*]] = mpir.alt {
  %1 = mpir.alt {
    mpir.yield %x : <Operand> loc("check-bindings.mlir":16:1)
// CHECK:             mpir.yield %[[VAR_0]] : <Operand>
  }, {
// CHECK:           }, {
    %i_a = mpir.inst <add> (%0, %x, %0, %y) <result_name = "a", flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction> loc("check-bindings.mlir":20:1)
// CHECK:             %[[INST_0:.*]] = mpir.inst <add> (%[[TYPE_0]], %[[VAR_0]], %[[TYPE_0]], %[[VAR_1]]) <flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value], result_name = "a"> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
    mpir.yield %i_a : <Instruction> loc("check-bindings.mlir":22:1)
// CHECK:             mpir.yield %[[INST_0]] : <Instruction>
  } attributes {or_self_of = "add", or_self_region = 0 : i32, result_name = "a"} : <Instruction> loc("check-bindings.mlir":24:1)
// CHECK:           } attributes {or_self_of = "add", or_self_region = 0 : i32, result_name = "a"} : <Instruction>
  %2 = mpir.type.int 32 : <Type> loc("check-bindings.mlir":26:1)
// CHECK:           %[[TYPE_1:.*]] = mpir.type.int 32 : <Type>
  %i_b = mpir.inst <mul> (%2, %1, %2, %y) <result_name = "b", flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction> loc("check-bindings.mlir":28:1)
// CHECK:           %[[INST_1:.*]] = mpir.inst <mul> (%[[TYPE_1]], %[[ALT_0]], %[[TYPE_1]], %[[VAR_1]]) <flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value], result_name = "b"> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
} loc("check-bindings.mlir":30:1)
// CHECK:         }

// -----

// A variable whose name starts with '_' need not be bound.
mpir.pattern {
// CHECK-LABEL:   mpir.pattern {
  %0 = mpir.type.int 32 : <Type> loc("check-bindings.mlir":38:1)
// CHECK:           %[[TYPE_0:.*]] = mpir.type.int 32 : <Type>
  %x = mpir.var "x" : <Operand> loc("check-bindings.mlir":40:1)
// CHECK:           %[[VAR_0:.*]] = mpir.var "x" : <Operand>
  %_k = mpir.var "_k" : <Operand> loc("check-bindings.mlir":42:1)
// CHECK:           %[[VAR_1:.*]] = mpir.var "_k" : <Operand>
// CHECK:           %[[ALT_0:.*]] = mpir.alt {
  %1 = mpir.alt {
    mpir.yield %x : <Operand> loc("check-bindings.mlir":46:1)
// CHECK:             mpir.yield %[[VAR_0]] : <Operand>
  }, {
// CHECK:           }, {
    %i_a = mpir.inst <add> (%0, %x, %0, %_k) <result_name = "a", flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction> loc("check-bindings.mlir":50:1)
// CHECK:             %[[INST_0:.*]] = mpir.inst <add> (%[[TYPE_0]], %[[VAR_0]], %[[TYPE_0]], %[[VAR_1]]) <flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value], result_name = "a"> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
    mpir.yield %i_a : <Instruction> loc("check-bindings.mlir":52:1)
// CHECK:             mpir.yield %[[INST_0]] : <Instruction>
  } attributes {or_self_of = "add", or_self_region = 0 : i32, result_name = "a"} : <Instruction> loc("check-bindings.mlir":54:1)
// CHECK:           } attributes {or_self_of = "add", or_self_region = 0 : i32, result_name = "a"} : <Instruction>
  %2 = mpir.type.int 32 : <Type> loc("check-bindings.mlir":56:1)
// CHECK:           %[[TYPE_1:.*]] = mpir.type.int 32 : <Type>
  %3 = mpir.int 3 : ui2 : <Value> loc("check-bindings.mlir":58:1)
// CHECK:           %[[INT_0:.*]] = mpir.int 3 : ui2 : <Value>
  %i_b = mpir.inst <mul> (%2, %1, %2, %3) <result_name = "b", flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction> loc("check-bindings.mlir":60:1)
// CHECK:           %[[INST_1:.*]] = mpir.inst <mul> (%[[TYPE_1]], %[[ALT_0]], %[[TYPE_1]], %[[INT_0]]) <flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value], result_name = "b"> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
} loc("check-bindings.mlir":62:1)
// CHECK:         }

// -----

// Everything ':o' could leave out is bound by the operand: types, flag
// captures, blocks, aggregates and nested alternatives.
mpir.pattern {
// CHECK-LABEL:   mpir.pattern {
  %bb = mpir.var "bb" : <BasicBlock> loc("check-bindings.mlir":71:1)
// CHECK:           %[[VAR_0:.*]] = mpir.var "bb" : <BasicBlock>
  %w = mpir.var "w" : <Boolean> loc("check-bindings.mlir":73:1)
// CHECK:           %[[VAR_1:.*]] = mpir.var "w" : <Boolean>
  %n = mpir.var "n" : <Nat> loc("check-bindings.mlir":75:1)
// CHECK:           %[[VAR_2:.*]] = mpir.var "n" : <Nat>
  %0 = mpir.type.meta_int %n : (!mpir.sort<Nat>) -> !mpir.sort<Type> loc("check-bindings.mlir":77:1)
// CHECK:           %[[TYPE_0:.*]] = mpir.type.meta_int %[[VAR_2]] : (!mpir.sort<Nat>) -> !mpir.sort<Type>
  %x = mpir.var "x" : <Operand> loc("check-bindings.mlir":79:1)
// CHECK:           %[[VAR_3:.*]] = mpir.var "x" : <Operand>
  %y = mpir.var "y" : <Operand> loc("check-bindings.mlir":81:1)
// CHECK:           %[[VAR_4:.*]] = mpir.var "y" : <Operand>
// CHECK:           %[[ALT_0:.*]] = mpir.alt {
  %1 = mpir.alt {
    %i_i = mpir.inst <add> block %bb flags(%w) (%0, %x, %0, %y) <result_name = "i", flags = [nsw], flag_modes = [captured], operand_kinds = [typed_value, typed_value]> : (!mpir.sort<BasicBlock>, !mpir.sort<Boolean>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction> loc("check-bindings.mlir":85:1)
// CHECK:             %[[INST_0:.*]] = mpir.inst <add> block %[[VAR_0]] flags(%[[VAR_1]]) (%[[TYPE_0]], %[[VAR_3]], %[[TYPE_0]], %[[VAR_4]]) <flags = [nsw], flag_modes = [captured], operand_kinds = [typed_value, typed_value], result_name = "i"> : (!mpir.sort<BasicBlock>, !mpir.sort<Boolean>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
    mpir.yield %i_i : <Instruction> loc("check-bindings.mlir":87:1)
// CHECK:             mpir.yield %[[INST_0]] : <Instruction>
  }, {
// CHECK:           }, {
    %i_i = mpir.inst <add> block %bb flags(%w) (%0, %y, %0, %x) <result_name = "i", flags = [nsw], flag_modes = [captured], operand_kinds = [typed_value, typed_value]> : (!mpir.sort<BasicBlock>, !mpir.sort<Boolean>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction> loc("check-bindings.mlir":91:1)
// CHECK:             %[[INST_1:.*]] = mpir.inst <add> block %[[VAR_0]] flags(%[[VAR_1]]) (%[[TYPE_0]], %[[VAR_4]], %[[TYPE_0]], %[[VAR_3]]) <flags = [nsw], flag_modes = [captured], operand_kinds = [typed_value, typed_value], result_name = "i"> : (!mpir.sort<BasicBlock>, !mpir.sort<Boolean>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
    mpir.yield %i_i : <Instruction> loc("check-bindings.mlir":93:1)
// CHECK:             mpir.yield %[[INST_1]] : <Instruction>
  } attributes {commuted, result_name = "i"} : <Instruction> loc("check-bindings.mlir":95:1)
// CHECK:           } attributes {commuted, result_name = "i"} : <Instruction>
  %self = mpir.var "self" : <Instruction> loc("check-bindings.mlir":97:1)
// CHECK:           %[[VAR_5:.*]] = mpir.var "self" : <Instruction>
  %2 = mpir.type.int 1 : <Type> loc("check-bindings.mlir":99:1)
// CHECK:           %[[TYPE_1:.*]] = mpir.type.int 1 : <Type>
  %c = mpir.var "c" : <Boolean> loc("check-bindings.mlir":101:1)
// CHECK:           %[[VAR_6:.*]] = mpir.var "c" : <Boolean>
  %3 = mpir.type.meta_int %n : (!mpir.sort<Nat>) -> !mpir.sort<Type> loc("check-bindings.mlir":103:1)
// CHECK:           %[[TYPE_2:.*]] = mpir.type.meta_int %[[VAR_2]] : (!mpir.sort<Nat>) -> !mpir.sort<Type>
  %4 = mpir.type.seq vector 2 x %3 : (!mpir.sort<Type>) -> !mpir.sort<Type> loc("check-bindings.mlir":105:1)
// CHECK:           %[[TYPE_3:.*]] = mpir.type.seq vector 2 x %[[TYPE_2]] : (!mpir.sort<Type>) -> !mpir.sort<Type>
  %5 = mpir.type.meta_int %n : (!mpir.sort<Nat>) -> !mpir.sort<Type> loc("check-bindings.mlir":107:1)
// CHECK:           %[[TYPE_4:.*]] = mpir.type.meta_int %[[VAR_2]] : (!mpir.sort<Nat>) -> !mpir.sort<Type>
  %6 = mpir.type.meta_int %n : (!mpir.sort<Nat>) -> !mpir.sort<Type> loc("check-bindings.mlir":109:1)
// CHECK:           %[[TYPE_5:.*]] = mpir.type.meta_int %[[VAR_2]] : (!mpir.sort<Nat>) -> !mpir.sort<Type>
  %7 = mpir.aggregate vector(%5, %1, %6, %y) : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Value> loc("check-bindings.mlir":111:1)
// CHECK:           %[[AGGREGATE_0:.*]] = mpir.aggregate vector(%[[TYPE_4]], %[[ALT_0]], %[[TYPE_5]], %[[VAR_4]]) : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Value>
  %8 = mpir.type.meta_int %n : (!mpir.sort<Nat>) -> !mpir.sort<Type> loc("check-bindings.mlir":113:1)
// CHECK:           %[[TYPE_6:.*]] = mpir.type.meta_int %[[VAR_2]] : (!mpir.sort<Nat>) -> !mpir.sort<Type>
  %9 = mpir.type.seq vector 2 x %8 : (!mpir.sort<Type>) -> !mpir.sort<Type> loc("check-bindings.mlir":115:1)
// CHECK:           %[[TYPE_7:.*]] = mpir.type.seq vector 2 x %[[TYPE_6]] : (!mpir.sort<Type>) -> !mpir.sort<Type>
  %v = mpir.var "v" : <Operand> loc("check-bindings.mlir":117:1)
// CHECK:           %[[VAR_7:.*]] = mpir.var "v" : <Operand>
// CHECK:           %[[ALT_1:.*]] = mpir.alt {
  %10 = mpir.alt {
    mpir.bind %self, %7 : <Instruction>, <Value> loc("check-bindings.mlir":121:1)
// CHECK:             mpir.bind %[[VAR_5]], %[[AGGREGATE_0]] : <Instruction>, <Value>
    mpir.yield %7 : <Value> loc("check-bindings.mlir":123:1)
// CHECK:             mpir.yield %[[AGGREGATE_0]] : <Value>
  }, {
// CHECK:           }, {
    %i_a = mpir.inst <select> capture %self block %bb (%2, %c, %4, %7, %9, %v) <result_name = "a", flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value, typed_value]> : (!mpir.sort<Instruction>, !mpir.sort<BasicBlock>, !mpir.sort<Type>, !mpir.sort<Boolean>, !mpir.sort<Type>, !mpir.sort<Value>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction> loc("check-bindings.mlir":127:1)
// CHECK:             %[[INST_2:.*]] = mpir.inst <select> capture %[[VAR_5]] block %[[VAR_0]] (%[[TYPE_1]], %[[VAR_6]], %[[TYPE_3]], %[[AGGREGATE_0]], %[[TYPE_7]], %[[VAR_7]]) <flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value, typed_value], result_name = "a"> : (!mpir.sort<Instruction>, !mpir.sort<BasicBlock>, !mpir.sort<Type>, !mpir.sort<Boolean>, !mpir.sort<Type>, !mpir.sort<Value>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
    mpir.yield %i_a : <Instruction> loc("check-bindings.mlir":129:1)
// CHECK:             mpir.yield %[[INST_2]] : <Instruction>
  } attributes {or_self_of = "select", or_self_region = 0 : i32, result_name = "a"} : <Instruction> loc("check-bindings.mlir":131:1)
// CHECK:           } attributes {or_self_of = "select", or_self_region = 0 : i32, result_name = "a"} : <Instruction>
  %11 = mpir.type.int 1 : <Type> loc("check-bindings.mlir":133:1)
// CHECK:           %[[TYPE_8:.*]] = mpir.type.int 1 : <Type>
  %12 = mpir.global "use" : <Value> loc("check-bindings.mlir":135:1)
// CHECK:           %[[GLOBAL_0:.*]] = mpir.global "use" : <Value>
  %13 = mpir.type.int 1 : <Type> loc("check-bindings.mlir":137:1)
// CHECK:           %[[TYPE_9:.*]] = mpir.type.int 1 : <Type>
  %14 = mpir.type.meta_int %n : (!mpir.sort<Nat>) -> !mpir.sort<Type> loc("check-bindings.mlir":139:1)
// CHECK:           %[[TYPE_10:.*]] = mpir.type.meta_int %[[VAR_2]] : (!mpir.sort<Nat>) -> !mpir.sort<Type>
  %15 = mpir.type.meta_int %n : (!mpir.sort<Nat>) -> !mpir.sort<Type> loc("check-bindings.mlir":141:1)
// CHECK:           %[[TYPE_11:.*]] = mpir.type.meta_int %[[VAR_2]] : (!mpir.sort<Nat>) -> !mpir.sort<Type>
  %16 = mpir.type.seq vector 2 x %15 : (!mpir.sort<Type>) -> !mpir.sort<Type> loc("check-bindings.mlir":143:1)
// CHECK:           %[[TYPE_12:.*]] = mpir.type.seq vector 2 x %[[TYPE_11]] : (!mpir.sort<Type>) -> !mpir.sort<Type>
  %17 = mpir.type.meta_int %n : (!mpir.sort<Nat>) -> !mpir.sort<Type> loc("check-bindings.mlir":145:1)
// CHECK:           %[[TYPE_13:.*]] = mpir.type.meta_int %[[VAR_2]] : (!mpir.sort<Nat>) -> !mpir.sort<Type>
  %18 = mpir.type.seq vector 2 x %17 : (!mpir.sort<Type>) -> !mpir.sort<Type> loc("check-bindings.mlir":147:1)
// CHECK:           %[[TYPE_14:.*]] = mpir.type.seq vector 2 x %[[TYPE_13]] : (!mpir.sort<Type>) -> !mpir.sort<Type>
  %i_u = mpir.inst <call> block %bb (%11, %12, %13, %c, %14, %1, %16, %v, %18, %10) <result_name = "u", flags = [], flag_modes = [], operand_kinds = [type_only, value, typed_value, typed_value, typed_value, typed_value]> : (!mpir.sort<BasicBlock>, !mpir.sort<Type>, !mpir.sort<Value>, !mpir.sort<Type>, !mpir.sort<Boolean>, !mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Instruction>) -> !mpir.sort<Instruction> loc("check-bindings.mlir":149:1)
// CHECK:           %[[INST_3:.*]] = mpir.inst <call> block %[[VAR_0]] (%[[TYPE_8]], %[[GLOBAL_0]], %[[TYPE_9]], %[[VAR_6]], %[[TYPE_10]], %[[ALT_0]], %[[TYPE_12]], %[[VAR_7]], %[[TYPE_14]], %[[ALT_1]]) <flags = [], flag_modes = [], operand_kinds = [type_only, value, typed_value, typed_value, typed_value, typed_value], result_name = "u"> : (!mpir.sort<BasicBlock>, !mpir.sort<Type>, !mpir.sort<Value>, !mpir.sort<Type>, !mpir.sort<Boolean>, !mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Instruction>) -> !mpir.sort<Instruction>
  %19 = mpir_expr.read %w : (!mpir.sort<Boolean>) -> !mpir.sort<Boolean> loc("check-bindings.mlir":151:1)
// CHECK:           %[[READ_0:.*]] = mpir_expr.read %[[VAR_1]] : (!mpir.sort<Boolean>) -> !mpir.sort<Boolean>
  mpir.require %19 : <Boolean> loc("check-bindings.mlir":153:1)
// CHECK:           mpir.require %[[READ_0]] : <Boolean>
} loc("check-bindings.mlir":155:1)
// CHECK:         }

// -----

// ':o' on a use of a matcher.
mpir.pattern {
// CHECK-LABEL:   mpir.pattern {
  %0 = mpir.type.int 32 : <Type> loc("check-bindings.mlir":163:1)
// CHECK:           %[[TYPE_0:.*]] = mpir.type.int 32 : <Type>
  %x = mpir.var "x" : <Operand> loc("check-bindings.mlir":165:1)
// CHECK:           %[[VAR_0:.*]] = mpir.var "x" : <Operand>
// CHECK:           %[[ALT_0:.*]] = mpir.alt {
  %1 = mpir.alt {
    %i_d = mpir.inst <add> (%0, %x, %0, %x) <result_name = "d", flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction> loc("check-bindings.mlir":169:1)
// CHECK:             %[[INST_0:.*]] = mpir.inst <add> (%[[TYPE_0]], %[[VAR_0]], %[[TYPE_0]], %[[VAR_0]]) <flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value], result_name = "d"> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
    mpir.yield %i_d : <Instruction> loc("check-bindings.mlir":171:1)
// CHECK:             mpir.yield %[[INST_0]] : <Instruction>
  }, {
// CHECK:           }, {
    mpir.yield %x : <Operand> loc("check-bindings.mlir":175:1)
// CHECK:             mpir.yield %[[VAR_0]] : <Operand>
  } attributes {or_self_of = "twice", or_self_region = 1 : i32, result_name = "d"} : <Instruction> loc("check-bindings.mlir":177:1)
// CHECK:           } attributes {or_self_of = "twice", or_self_region = 1 : i32, result_name = "d"} : <Instruction>
  %2 = mpir.type.int 32 : <Type> loc("check-bindings.mlir":179:1)
// CHECK:           %[[TYPE_1:.*]] = mpir.type.int 32 : <Type>
  %i_e = mpir.inst <mul> (%2, %1, %2, %x) <result_name = "e", flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction> loc("check-bindings.mlir":181:1)
// CHECK:           %[[INST_1:.*]] = mpir.inst <mul> (%[[TYPE_1]], %[[ALT_0]], %[[TYPE_1]], %[[VAR_0]]) <flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value], result_name = "e"> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
} loc("check-bindings.mlir":183:1)
// CHECK:         }

// -----

// Without ':o', nothing to check.
mpir.pattern {
// CHECK-LABEL:   mpir.pattern {
  %0 = mpir.type.int 32 : <Type> loc("check-bindings.mlir":191:1)
// CHECK:           %[[TYPE_0:.*]] = mpir.type.int 32 : <Type>
  %x = mpir.var "x" : <Operand> loc("check-bindings.mlir":193:1)
// CHECK:           %[[VAR_0:.*]] = mpir.var "x" : <Operand>
  %1 = mpir.int 1 : ui1 : <Value> loc("check-bindings.mlir":195:1)
// CHECK:           %[[INT_0:.*]] = mpir.int 1 : ui1 : <Value>
// CHECK:           %[[ALT_0:.*]] = mpir.alt {
  %2 = mpir.alt {
    %i_a = mpir.inst <add> (%0, %x, %0, %1) <result_name = "a", flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction> loc("check-bindings.mlir":199:1)
// CHECK:             %[[INST_0:.*]] = mpir.inst <add> (%[[TYPE_0]], %[[VAR_0]], %[[TYPE_0]], %[[INT_0]]) <flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value], result_name = "a"> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
    mpir.yield %i_a : <Instruction> loc("check-bindings.mlir":201:1)
// CHECK:             mpir.yield %[[INST_0]] : <Instruction>
  }, {
// CHECK:           }, {
    %i_a = mpir.inst <add> (%0, %1, %0, %x) <result_name = "a", flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value]> : (!mpir.sort<Type>, !mpir.sort<Value>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction> loc("check-bindings.mlir":205:1)
// CHECK:             %[[INST_1:.*]] = mpir.inst <add> (%[[TYPE_0]], %[[INT_0]], %[[TYPE_0]], %[[VAR_0]]) <flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value], result_name = "a"> : (!mpir.sort<Type>, !mpir.sort<Value>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
    mpir.yield %i_a : <Instruction> loc("check-bindings.mlir":207:1)
// CHECK:             mpir.yield %[[INST_1]] : <Instruction>
  } attributes {commuted, result_name = "a"} : <Instruction> loc("check-bindings.mlir":209:1)
// CHECK:           } attributes {commuted, result_name = "a"} : <Instruction>
} loc("check-bindings.mlir":211:1)
// CHECK:         }
