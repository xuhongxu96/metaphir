// RUN: %metaphir-opt --split-input-file --mpir-expand-matchers %s | FileCheck %s
// mpir-expand-matchers replaces each use of a 'match' matcher by an mpir.alt
// with a region per branch the use can match: the branch's body, with its
// parameters bound to the use's operands, its instructions named after the
// use, and its root standing for the use.

// One branch: its root takes the use's name.
mpir.matcher @twice <supported_flags = [], syntax = nary, arity = 1, param_names = ["ty", "a"], param_is_type = [true, false]> {
// CHECK-LABEL:   mpir.matcher @twice <supported_flags = [], syntax = nary, arity = 1, param_names = ["ty", "a"], param_is_type = [true, false]> {
  %ty = mpir.var "ty" : <Type> loc("expand-matchers.mlir":10:1)
// CHECK:           %[[VAR_0:.*]] = mpir.var "ty" : <Type>
  mpir.signature %ty : !mpir.sort<Type> loc("expand-matchers.mlir":12:1)
// CHECK:           mpir.signature %[[VAR_0]] : !mpir.sort<Type>
  mpir.branch <param_args = [0, 1], fixed_flags = [], fixed_flag_values = []> {
// CHECK:           mpir.branch <fixed_flags = [], param_args = [0, 1], fixed_flag_values = []> {
// CHECK:           ^bb0(%[[VAL_0:.*]]: !mpir.sort<Type>, %[[VAL_1:.*]]: !mpir.sort<Operand>):
  ^bb0(%arg0: !mpir.sort<Type>, %arg1: !mpir.sort<Operand>):
    %i_ret = mpir.inst <add> (%arg0, %arg1, %arg0, %arg1) <result_name = "ret", flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction> loc("expand-matchers.mlir":18:1)
// CHECK:             %[[INST_0:.*]] = mpir.inst <add> (%[[VAL_0]], %[[VAL_1]], %[[VAL_0]], %[[VAL_1]]) <flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value], result_name = "ret"> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
    mpir.yield %i_ret : <Instruction> loc("expand-matchers.mlir":20:1)
// CHECK:             mpir.yield %[[INST_0]] : <Instruction>
  } loc("expand-matchers.mlir":22:1)
// CHECK:           }
} loc("expand-matchers.mlir":24:1)
// CHECK:         }
mpir.pattern {
// CHECK-LABEL:   mpir.pattern {
  %0 = mpir.type.int 32 : <Type> loc("expand-matchers.mlir":28:1)
// CHECK:           %[[TYPE_0:.*]] = mpir.type.int 32 : <Type>
  %x = mpir.var "x" : <Operand> loc("expand-matchers.mlir":30:1)
// CHECK:           %[[VAR_0:.*]] = mpir.var "x" : <Operand>
  %u_d = mpir.use @twice (%0, %x) <result_name = "d", flags = [], flag_modes = [], operand_kinds = [typed_value]> : (!mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction> loc("expand-matchers.mlir":32:1)
// CHECK:           %[[ALT_0:.*]] = mpir.alt {
// CHECK:             %[[INST_0:.*]] = mpir.inst <add> (%[[TYPE_0]], %[[VAR_0]], %[[TYPE_0]], %[[VAR_0]]) <flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value], result_name = "d"> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:             mpir.yield %[[INST_0]] : <Instruction>
// CHECK:           } <result_name = "d"> : <Instruction>
} loc("expand-matchers.mlir":37:1)
// CHECK:         }

// -----

// A region per branch, in order.
mpir.matcher @addOrSub <supported_flags = [], syntax = binary, arity = 2, param_names = ["ty", "a", "b"], param_is_type = [true, false, false]> {
// CHECK-LABEL:   mpir.matcher @addOrSub <supported_flags = [], syntax = binary, arity = 2, param_names = ["ty", "a", "b"], param_is_type = [true, false, false]> {
  %ty = mpir.var "ty" : <Type> loc("expand-matchers.mlir":45:1)
// CHECK:           %[[VAR_0:.*]] = mpir.var "ty" : <Type>
  mpir.signature %ty : !mpir.sort<Type> loc("expand-matchers.mlir":47:1)
// CHECK:           mpir.signature %[[VAR_0]] : !mpir.sort<Type>
  mpir.branch <param_args = [0, 1, 2], fixed_flags = [], fixed_flag_values = []> {
// CHECK:           mpir.branch <fixed_flags = [], param_args = [0, 1, 2], fixed_flag_values = []> {
// CHECK:           ^bb0(%[[VAL_0:.*]]: !mpir.sort<Type>, %[[VAL_1:.*]]: !mpir.sort<Operand>, %[[VAL_2:.*]]: !mpir.sort<Operand>):
  ^bb0(%arg0: !mpir.sort<Type>, %arg1: !mpir.sort<Operand>, %arg2: !mpir.sort<Operand>):
    %i_ret = mpir.inst <add> (%arg0, %arg1, %arg0, %arg2) <result_name = "ret", flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction> loc("expand-matchers.mlir":53:1)
// CHECK:             %[[INST_0:.*]] = mpir.inst <add> (%[[VAL_0]], %[[VAL_1]], %[[VAL_0]], %[[VAL_2]]) <flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value], result_name = "ret"> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
    mpir.yield %i_ret : <Instruction> loc("expand-matchers.mlir":55:1)
// CHECK:             mpir.yield %[[INST_0]] : <Instruction>
  } loc("expand-matchers.mlir":57:1)
// CHECK:           }
  mpir.branch <param_args = [0, 1, 2], fixed_flags = [], fixed_flag_values = []> {
// CHECK:           mpir.branch <fixed_flags = [], param_args = [0, 1, 2], fixed_flag_values = []> {
// CHECK:           ^bb0(%[[VAL_3:.*]]: !mpir.sort<Type>, %[[VAL_4:.*]]: !mpir.sort<Operand>, %[[VAL_5:.*]]: !mpir.sort<Operand>):
  ^bb0(%arg0: !mpir.sort<Type>, %arg1: !mpir.sort<Operand>, %arg2: !mpir.sort<Operand>):
    %i_ret = mpir.inst <sub> (%arg0, %arg1, %arg0, %arg2) <result_name = "ret", flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction> loc("expand-matchers.mlir":63:1)
// CHECK:             %[[INST_1:.*]] = mpir.inst <sub> (%[[VAL_3]], %[[VAL_4]], %[[VAL_3]], %[[VAL_5]]) <flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value], result_name = "ret"> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
    mpir.yield %i_ret : <Instruction> loc("expand-matchers.mlir":65:1)
// CHECK:             mpir.yield %[[INST_1]] : <Instruction>
  } loc("expand-matchers.mlir":67:1)
// CHECK:           }
} loc("expand-matchers.mlir":69:1)
// CHECK:         }
mpir.pattern {
// CHECK-LABEL:   mpir.pattern {
  %0 = mpir.type.int 32 : <Type> loc("expand-matchers.mlir":73:1)
// CHECK:           %[[TYPE_0:.*]] = mpir.type.int 32 : <Type>
  %x = mpir.var "x" : <Operand> loc("expand-matchers.mlir":75:1)
// CHECK:           %[[VAR_0:.*]] = mpir.var "x" : <Operand>
  %y = mpir.var "y" : <Operand> loc("expand-matchers.mlir":77:1)
// CHECK:           %[[VAR_1:.*]] = mpir.var "y" : <Operand>
// CHECK:           %[[ALT_0:.*]] = mpir.alt {
  %u_r = mpir.use @addOrSub (%0, %x, %0, %y) <result_name = "r", flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction> loc("expand-matchers.mlir":80:1)
// CHECK:             %[[INST_0:.*]] = mpir.inst <add> (%[[TYPE_0]], %[[VAR_0]], %[[TYPE_0]], %[[VAR_1]]) <flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value], result_name = "r"> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:             mpir.yield %[[INST_0]] : <Instruction>
// CHECK:           }, {
// CHECK:             %[[INST_1:.*]] = mpir.inst <sub> (%[[TYPE_0]], %[[VAR_0]], %[[TYPE_0]], %[[VAR_1]]) <flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value], result_name = "r"> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:             mpir.yield %[[INST_1]] : <Instruction>
// CHECK:           } <result_name = "r"> : <Instruction>
} loc("expand-matchers.mlir":87:1)
// CHECK:         }

// -----

// ':c' on the use: each branch with the operands in both orders.
mpir.matcher @addOrSub <commutative, supported_flags = [], syntax = binary, arity = 2, param_names = ["ty", "a", "b"], param_is_type = [true, false, false]> {
// CHECK-LABEL:   mpir.matcher @addOrSub <supported_flags = [], syntax = binary, commutative, arity = 2, param_names = ["ty", "a", "b"], param_is_type = [true, false, false]> {
  %ty = mpir.var "ty" : <Type> loc("expand-matchers.mlir":95:1)
// CHECK:           %[[VAR_0:.*]] = mpir.var "ty" : <Type>
  mpir.signature %ty : !mpir.sort<Type> loc("expand-matchers.mlir":97:1)
// CHECK:           mpir.signature %[[VAR_0]] : !mpir.sort<Type>
  mpir.branch <param_args = [0, 1, 2], fixed_flags = [], fixed_flag_values = []> {
// CHECK:           mpir.branch <fixed_flags = [], param_args = [0, 1, 2], fixed_flag_values = []> {
// CHECK:           ^bb0(%[[VAL_0:.*]]: !mpir.sort<Type>, %[[VAL_1:.*]]: !mpir.sort<Operand>, %[[VAL_2:.*]]: !mpir.sort<Operand>):
  ^bb0(%arg0: !mpir.sort<Type>, %arg1: !mpir.sort<Operand>, %arg2: !mpir.sort<Operand>):
    %i_ret = mpir.inst <add> (%arg0, %arg1, %arg0, %arg2) <result_name = "ret", flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction> loc("expand-matchers.mlir":103:1)
// CHECK:             %[[INST_0:.*]] = mpir.inst <add> (%[[VAL_0]], %[[VAL_1]], %[[VAL_0]], %[[VAL_2]]) <flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value], result_name = "ret"> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
    mpir.yield %i_ret : <Instruction> loc("expand-matchers.mlir":105:1)
// CHECK:             mpir.yield %[[INST_0]] : <Instruction>
  } loc("expand-matchers.mlir":107:1)
// CHECK:           }
  mpir.branch <param_args = [0, 1, 2], fixed_flags = [], fixed_flag_values = []> {
// CHECK:           mpir.branch <fixed_flags = [], param_args = [0, 1, 2], fixed_flag_values = []> {
// CHECK:           ^bb0(%[[VAL_3:.*]]: !mpir.sort<Type>, %[[VAL_4:.*]]: !mpir.sort<Operand>, %[[VAL_5:.*]]: !mpir.sort<Operand>):
  ^bb0(%arg0: !mpir.sort<Type>, %arg1: !mpir.sort<Operand>, %arg2: !mpir.sort<Operand>):
    %i_ret = mpir.inst <sub> (%arg0, %arg1, %arg0, %arg2) <result_name = "ret", flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction> loc("expand-matchers.mlir":113:1)
// CHECK:             %[[INST_1:.*]] = mpir.inst <sub> (%[[VAL_3]], %[[VAL_4]], %[[VAL_3]], %[[VAL_5]]) <flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value], result_name = "ret"> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
    mpir.yield %i_ret : <Instruction> loc("expand-matchers.mlir":115:1)
// CHECK:             mpir.yield %[[INST_1]] : <Instruction>
  } loc("expand-matchers.mlir":117:1)
// CHECK:           }
} loc("expand-matchers.mlir":119:1)
// CHECK:         }
mpir.pattern {
// CHECK-LABEL:   mpir.pattern {
  %0 = mpir.type.int 32 : <Type> loc("expand-matchers.mlir":123:1)
// CHECK:           %[[TYPE_0:.*]] = mpir.type.int 32 : <Type>
  %x = mpir.var "x" : <Operand> loc("expand-matchers.mlir":125:1)
// CHECK:           %[[VAR_0:.*]] = mpir.var "x" : <Operand>
  %1 = mpir.int 1 : ui1 : <Value> loc("expand-matchers.mlir":127:1)
// CHECK:           %[[INT_0:.*]] = mpir.int 1 : ui1 : <Value>
// CHECK:           %[[ALT_0:.*]] = mpir.alt {
  %u_r = mpir.use @addOrSub (%0, %x, %0, %1) <result_name = "r", flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value], metaflags = [#mpir.metaflag<"c", [], loc("expand-matchers.mlir":130:1)>]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
// CHECK:             %[[INST_0:.*]] = mpir.inst <add> (%[[TYPE_0]], %[[VAR_0]], %[[TYPE_0]], %[[INT_0]]) <flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value], result_name = "r"> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
// CHECK:             mpir.yield %[[INST_0]] : <Instruction>
// CHECK:           }, {
// CHECK:             %[[INST_1:.*]] = mpir.inst <add> (%[[TYPE_0]], %[[INT_0]], %[[TYPE_0]], %[[VAR_0]]) <flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value], result_name = "r"> : (!mpir.sort<Type>, !mpir.sort<Value>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:             mpir.yield %[[INST_1]] : <Instruction>
// CHECK:           }, {
// CHECK:             %[[INST_2:.*]] = mpir.inst <sub> (%[[TYPE_0]], %[[VAR_0]], %[[TYPE_0]], %[[INT_0]]) <flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value], result_name = "r"> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
// CHECK:             mpir.yield %[[INST_2]] : <Instruction>
// CHECK:           }, {
// CHECK:             %[[INST_3:.*]] = mpir.inst <sub> (%[[TYPE_0]], %[[INT_0]], %[[TYPE_0]], %[[VAR_0]]) <flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value], result_name = "r"> : (!mpir.sort<Type>, !mpir.sort<Value>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:             mpir.yield %[[INST_3]] : <Instruction>
// CHECK:           } <result_name = "r"> : <Instruction>
} loc("expand-matchers.mlir":143:1)
// CHECK:         }

// -----

// A flag the use omits is a fresh variable on the root; a branch that fixes
// flags leaves them out of its root.
mpir.matcher @addish <supported_flags = [nsw, nuw], syntax = binary, arity = 2, param_names = ["ty", "a", "b"], param_is_type = [true, false, false]> {
// CHECK-LABEL:   mpir.matcher @addish <supported_flags = [nsw, nuw], syntax = binary, arity = 2, param_names = ["ty", "a", "b"], param_is_type = [true, false, false]> {
  %ty = mpir.var "ty" : <Type> loc("expand-matchers.mlir":152:1)
// CHECK:           %[[VAR_0:.*]] = mpir.var "ty" : <Type>
  mpir.signature %ty : !mpir.sort<Type> loc("expand-matchers.mlir":154:1)
// CHECK:           mpir.signature %[[VAR_0]] : !mpir.sort<Type>
  mpir.branch <param_args = [0, 1, 2], fixed_flags = [], fixed_flag_values = []> {
// CHECK:           mpir.branch <fixed_flags = [], param_args = [0, 1, 2], fixed_flag_values = []> {
// CHECK:           ^bb0(%[[VAL_0:.*]]: !mpir.sort<Type>, %[[VAL_1:.*]]: !mpir.sort<Operand>, %[[VAL_2:.*]]: !mpir.sort<Operand>):
  ^bb0(%arg0: !mpir.sort<Type>, %arg1: !mpir.sort<Operand>, %arg2: !mpir.sort<Operand>):
    %nsw = mpir.var "nsw" : <Boolean> loc("expand-matchers.mlir":160:1)
// CHECK:             %[[VAR_1:.*]] = mpir.var "nsw" : <Boolean>
    %nuw = mpir.var "nuw" : <Boolean> loc("expand-matchers.mlir":162:1)
// CHECK:             %[[VAR_2:.*]] = mpir.var "nuw" : <Boolean>
    %i_ret = mpir.inst <add> flags(%nsw, %nuw) (%arg0, %arg1, %arg0, %arg2) <result_name = "ret", flags = [nsw, nuw], flag_modes = [captured, captured], operand_kinds = [typed_value, typed_value]> : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction> loc("expand-matchers.mlir":164:1)
// CHECK:             %[[INST_0:.*]] = mpir.inst <add> flags(%[[VAR_1]], %[[VAR_2]]) (%[[VAL_0]], %[[VAL_1]], %[[VAL_0]], %[[VAL_2]]) <flags = [nsw, nuw], flag_modes = [captured, captured], operand_kinds = [typed_value, typed_value], result_name = "ret"> : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
    mpir.yield %i_ret : <Instruction> loc("expand-matchers.mlir":166:1)
// CHECK:             mpir.yield %[[INST_0]] : <Instruction>
  } loc("expand-matchers.mlir":168:1)
// CHECK:           }
  mpir.branch <param_args = [0, 1, 2], fixed_flags = [nsw, nuw], fixed_flag_values = [true, false]> {
// CHECK:           mpir.branch <fixed_flags = [nsw, nuw], param_args = [0, 1, 2], fixed_flag_values = [true, false]> {
// CHECK:           ^bb0(%[[VAL_3:.*]]: !mpir.sort<Type>, %[[VAL_4:.*]]: !mpir.sort<Operand>, %[[VAL_5:.*]]: !mpir.sort<Operand>):
  ^bb0(%arg0: !mpir.sort<Type>, %arg1: !mpir.sort<Operand>, %arg2: !mpir.sort<Operand>):
    %i_ret = mpir.inst <or> (%arg0, %arg1, %arg0, %arg2) <result_name = "ret", flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction> loc("expand-matchers.mlir":174:1)
// CHECK:             %[[INST_1:.*]] = mpir.inst <or> (%[[VAL_3]], %[[VAL_4]], %[[VAL_3]], %[[VAL_5]]) <flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value], result_name = "ret"> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
    mpir.yield %i_ret : <Instruction> loc("expand-matchers.mlir":176:1)
// CHECK:             mpir.yield %[[INST_1]] : <Instruction>
  } loc("expand-matchers.mlir":178:1)
// CHECK:           }
} loc("expand-matchers.mlir":180:1)
// CHECK:         }
mpir.pattern {
// CHECK-LABEL:   mpir.pattern {
  %0 = mpir.type.int 32 : <Type> loc("expand-matchers.mlir":184:1)
// CHECK:           %[[TYPE_0:.*]] = mpir.type.int 32 : <Type>
  %x = mpir.var "x" : <Operand> loc("expand-matchers.mlir":186:1)
// CHECK:           %[[VAR_0:.*]] = mpir.var "x" : <Operand>
  %y = mpir.var "y" : <Operand> loc("expand-matchers.mlir":188:1)
// CHECK:           %[[VAR_1:.*]] = mpir.var "y" : <Operand>
  %u_r = mpir.use @addish (%0, %x, %0, %y) <result_name = "r", flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction> loc("expand-matchers.mlir":190:1)
// CHECK:           %[[VAR_2:.*]] = mpir.var "_flag$r$nsw" : <Boolean>
// CHECK:           %[[VAR_3:.*]] = mpir.var "_flag$r$nuw" : <Boolean>
// CHECK:           %[[ALT_0:.*]] = mpir.alt {
// CHECK:             %[[INST_0:.*]] = mpir.inst <add> flags(%[[VAR_2]], %[[VAR_3]]) (%[[TYPE_0]], %[[VAR_0]], %[[TYPE_0]], %[[VAR_1]]) <flags = [nsw, nuw], flag_modes = [captured, captured], operand_kinds = [typed_value, typed_value], result_name = "r"> : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:             mpir.yield %[[INST_0]] : <Instruction>
// CHECK:           }, {
// CHECK:             %[[INST_1:.*]] = mpir.inst <or> (%[[TYPE_0]], %[[VAR_0]], %[[TYPE_0]], %[[VAR_1]]) <flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value], result_name = "r"> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:             mpir.yield %[[INST_1]] : <Instruction>
// CHECK:           } <result_name = "r"> : <Instruction>
} loc("expand-matchers.mlir":200:1)
// CHECK:         }

// -----

// A flag the use requires or forbids: the root requires or forbids it, and
// a branch that fixes it otherwise is left out.
mpir.matcher @addish <supported_flags = [nsw, nuw], syntax = binary, arity = 2, param_names = ["ty", "a", "b"], param_is_type = [true, false, false]> {
// CHECK-LABEL:   mpir.matcher @addish <supported_flags = [nsw, nuw], syntax = binary, arity = 2, param_names = ["ty", "a", "b"], param_is_type = [true, false, false]> {
  %ty = mpir.var "ty" : <Type> loc("expand-matchers.mlir":209:1)
// CHECK:           %[[VAR_0:.*]] = mpir.var "ty" : <Type>
  mpir.signature %ty : !mpir.sort<Type> loc("expand-matchers.mlir":211:1)
// CHECK:           mpir.signature %[[VAR_0]] : !mpir.sort<Type>
  mpir.branch <param_args = [0, 1, 2], fixed_flags = [], fixed_flag_values = []> {
// CHECK:           mpir.branch <fixed_flags = [], param_args = [0, 1, 2], fixed_flag_values = []> {
// CHECK:           ^bb0(%[[VAL_0:.*]]: !mpir.sort<Type>, %[[VAL_1:.*]]: !mpir.sort<Operand>, %[[VAL_2:.*]]: !mpir.sort<Operand>):
  ^bb0(%arg0: !mpir.sort<Type>, %arg1: !mpir.sort<Operand>, %arg2: !mpir.sort<Operand>):
    %nsw = mpir.var "nsw" : <Boolean> loc("expand-matchers.mlir":217:1)
// CHECK:             %[[VAR_1:.*]] = mpir.var "nsw" : <Boolean>
    %nuw = mpir.var "nuw" : <Boolean> loc("expand-matchers.mlir":219:1)
// CHECK:             %[[VAR_2:.*]] = mpir.var "nuw" : <Boolean>
    %i_ret = mpir.inst <add> flags(%nsw, %nuw) (%arg0, %arg1, %arg0, %arg2) <result_name = "ret", flags = [nsw, nuw], flag_modes = [captured, captured], operand_kinds = [typed_value, typed_value]> : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction> loc("expand-matchers.mlir":221:1)
// CHECK:             %[[INST_0:.*]] = mpir.inst <add> flags(%[[VAR_1]], %[[VAR_2]]) (%[[VAL_0]], %[[VAL_1]], %[[VAL_0]], %[[VAL_2]]) <flags = [nsw, nuw], flag_modes = [captured, captured], operand_kinds = [typed_value, typed_value], result_name = "ret"> : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
    mpir.yield %i_ret : <Instruction> loc("expand-matchers.mlir":223:1)
// CHECK:             mpir.yield %[[INST_0]] : <Instruction>
  } loc("expand-matchers.mlir":225:1)
// CHECK:           }
  mpir.branch <param_args = [0, 1, 2], fixed_flags = [nsw, nuw], fixed_flag_values = [true, false]> {
// CHECK:           mpir.branch <fixed_flags = [nsw, nuw], param_args = [0, 1, 2], fixed_flag_values = [true, false]> {
// CHECK:           ^bb0(%[[VAL_3:.*]]: !mpir.sort<Type>, %[[VAL_4:.*]]: !mpir.sort<Operand>, %[[VAL_5:.*]]: !mpir.sort<Operand>):
  ^bb0(%arg0: !mpir.sort<Type>, %arg1: !mpir.sort<Operand>, %arg2: !mpir.sort<Operand>):
    %i_ret = mpir.inst <or> (%arg0, %arg1, %arg0, %arg2) <result_name = "ret", flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction> loc("expand-matchers.mlir":231:1)
// CHECK:             %[[INST_1:.*]] = mpir.inst <or> (%[[VAL_3]], %[[VAL_4]], %[[VAL_3]], %[[VAL_5]]) <flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value], result_name = "ret"> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
    mpir.yield %i_ret : <Instruction> loc("expand-matchers.mlir":233:1)
// CHECK:             mpir.yield %[[INST_1]] : <Instruction>
  } loc("expand-matchers.mlir":235:1)
// CHECK:           }
} loc("expand-matchers.mlir":237:1)
// CHECK:         }
mpir.pattern {
// CHECK-LABEL:   mpir.pattern {
  %0 = mpir.type.int 32 : <Type> loc("expand-matchers.mlir":241:1)
// CHECK:           %[[TYPE_0:.*]] = mpir.type.int 32 : <Type>
  %x = mpir.var "x" : <Operand> loc("expand-matchers.mlir":243:1)
// CHECK:           %[[VAR_0:.*]] = mpir.var "x" : <Operand>
  %y = mpir.var "y" : <Operand> loc("expand-matchers.mlir":245:1)
// CHECK:           %[[VAR_1:.*]] = mpir.var "y" : <Operand>
  %u_r = mpir.use @addish (%0, %x, %0, %y) <result_name = "r", flags = [nsw, nuw], flag_modes = [required, negated], operand_kinds = [typed_value, typed_value]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction> loc("expand-matchers.mlir":247:1)
// CHECK:           %[[INT_0:.*]] = mpir.int 1 : ui1 : <Value>
// CHECK:           %[[INT_1:.*]] = mpir.int 0 : ui1 : <Value>
// CHECK:           %[[ALT_0:.*]] = mpir.alt {
// CHECK:             %[[INST_0:.*]] = mpir.inst <add> (%[[TYPE_0]], %[[VAR_0]], %[[TYPE_0]], %[[VAR_1]]) <flags = [nsw, nuw], flag_modes = [required, negated], operand_kinds = [typed_value, typed_value], result_name = "r"> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:             mpir.yield %[[INST_0]] : <Instruction>
// CHECK:           }, {
// CHECK:             %[[INST_1:.*]] = mpir.inst <or> (%[[TYPE_0]], %[[VAR_0]], %[[TYPE_0]], %[[VAR_1]]) <flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value], result_name = "r"> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:             mpir.yield %[[INST_1]] : <Instruction>
// CHECK:           } <result_name = "r"> : <Instruction>
  %1 = mpir.type.int 32 : <Type> loc("expand-matchers.mlir":257:1)
// CHECK:           %[[TYPE_1:.*]] = mpir.type.int 32 : <Type>
  %u_s = mpir.use @addish (%1, %u_r, %1, %y) <result_name = "s", flags = [nsw], flag_modes = [negated], operand_kinds = [typed_value, typed_value]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction> loc("expand-matchers.mlir":259:1)
// CHECK:           %[[INT_2:.*]] = mpir.int 0 : ui1 : <Value>
// CHECK:           %[[VAR_2:.*]] = mpir.var "_flag$s$nuw" : <Boolean>
// CHECK:           %[[ALT_1:.*]] = mpir.alt {
// CHECK:             %[[INST_2:.*]] = mpir.inst <add> flags(%[[VAR_2]]) (%[[TYPE_1]], %[[ALT_0]], %[[TYPE_1]], %[[VAR_1]]) <flags = [nsw, nuw], flag_modes = [negated, captured], operand_kinds = [typed_value, typed_value], result_name = "s"> : (!mpir.sort<Boolean>, !mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:             mpir.yield %[[INST_2]] : <Instruction>
// CHECK:           } <result_name = "s"> : <Instruction>
} loc("expand-matchers.mlir":266:1)
// CHECK:         }

// -----

// A flag the use captures: the root captures it, and a branch that fixes it
// binds the capture.
mpir.matcher @addish <supported_flags = [nsw, nuw], syntax = binary, arity = 2, param_names = ["ty", "a", "b"], param_is_type = [true, false, false]> {
// CHECK-LABEL:   mpir.matcher @addish <supported_flags = [nsw, nuw], syntax = binary, arity = 2, param_names = ["ty", "a", "b"], param_is_type = [true, false, false]> {
  %ty = mpir.var "ty" : <Type> loc("expand-matchers.mlir":275:1)
// CHECK:           %[[VAR_0:.*]] = mpir.var "ty" : <Type>
  mpir.signature %ty : !mpir.sort<Type> loc("expand-matchers.mlir":277:1)
// CHECK:           mpir.signature %[[VAR_0]] : !mpir.sort<Type>
  mpir.branch <param_args = [0, 1, 2], fixed_flags = [], fixed_flag_values = []> {
// CHECK:           mpir.branch <fixed_flags = [], param_args = [0, 1, 2], fixed_flag_values = []> {
// CHECK:           ^bb0(%[[VAL_0:.*]]: !mpir.sort<Type>, %[[VAL_1:.*]]: !mpir.sort<Operand>, %[[VAL_2:.*]]: !mpir.sort<Operand>):
  ^bb0(%arg0: !mpir.sort<Type>, %arg1: !mpir.sort<Operand>, %arg2: !mpir.sort<Operand>):
    %nsw = mpir.var "nsw" : <Boolean> loc("expand-matchers.mlir":283:1)
// CHECK:             %[[VAR_1:.*]] = mpir.var "nsw" : <Boolean>
    %nuw = mpir.var "nuw" : <Boolean> loc("expand-matchers.mlir":285:1)
// CHECK:             %[[VAR_2:.*]] = mpir.var "nuw" : <Boolean>
    %i_ret = mpir.inst <add> flags(%nsw, %nuw) (%arg0, %arg1, %arg0, %arg2) <result_name = "ret", flags = [nsw, nuw], flag_modes = [captured, captured], operand_kinds = [typed_value, typed_value]> : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction> loc("expand-matchers.mlir":287:1)
// CHECK:             %[[INST_0:.*]] = mpir.inst <add> flags(%[[VAR_1]], %[[VAR_2]]) (%[[VAL_0]], %[[VAL_1]], %[[VAL_0]], %[[VAL_2]]) <flags = [nsw, nuw], flag_modes = [captured, captured], operand_kinds = [typed_value, typed_value], result_name = "ret"> : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
    mpir.yield %i_ret : <Instruction> loc("expand-matchers.mlir":289:1)
// CHECK:             mpir.yield %[[INST_0]] : <Instruction>
  } loc("expand-matchers.mlir":291:1)
// CHECK:           }
  mpir.branch <param_args = [0, 1, 2], fixed_flags = [nsw, nuw], fixed_flag_values = [true, false]> {
// CHECK:           mpir.branch <fixed_flags = [nsw, nuw], param_args = [0, 1, 2], fixed_flag_values = [true, false]> {
// CHECK:           ^bb0(%[[VAL_3:.*]]: !mpir.sort<Type>, %[[VAL_4:.*]]: !mpir.sort<Operand>, %[[VAL_5:.*]]: !mpir.sort<Operand>):
  ^bb0(%arg0: !mpir.sort<Type>, %arg1: !mpir.sort<Operand>, %arg2: !mpir.sort<Operand>):
    %i_ret = mpir.inst <or> (%arg0, %arg1, %arg0, %arg2) <result_name = "ret", flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction> loc("expand-matchers.mlir":297:1)
// CHECK:             %[[INST_1:.*]] = mpir.inst <or> (%[[VAL_3]], %[[VAL_4]], %[[VAL_3]], %[[VAL_5]]) <flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value], result_name = "ret"> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
    mpir.yield %i_ret : <Instruction> loc("expand-matchers.mlir":299:1)
// CHECK:             mpir.yield %[[INST_1]] : <Instruction>
  } loc("expand-matchers.mlir":301:1)
// CHECK:           }
} loc("expand-matchers.mlir":303:1)
// CHECK:         }
mpir.pattern {
// CHECK-LABEL:   mpir.pattern {
  %wrap = mpir.var "wrap" : <Boolean> loc("expand-matchers.mlir":307:1)
// CHECK:           %[[VAR_0:.*]] = mpir.var "wrap" : <Boolean>
  %uwrap = mpir.var "uwrap" : <Boolean> loc("expand-matchers.mlir":309:1)
// CHECK:           %[[VAR_1:.*]] = mpir.var "uwrap" : <Boolean>
  %0 = mpir.type.int 32 : <Type> loc("expand-matchers.mlir":311:1)
// CHECK:           %[[TYPE_0:.*]] = mpir.type.int 32 : <Type>
  %x = mpir.var "x" : <Operand> loc("expand-matchers.mlir":313:1)
// CHECK:           %[[VAR_2:.*]] = mpir.var "x" : <Operand>
  %y = mpir.var "y" : <Operand> loc("expand-matchers.mlir":315:1)
// CHECK:           %[[VAR_3:.*]] = mpir.var "y" : <Operand>
// CHECK:           %[[ALT_0:.*]] = mpir.alt {
  %u_r = mpir.use @addish flags(%wrap, %uwrap) (%0, %x, %0, %y) <result_name = "r", flags = [nsw, nuw], flag_modes = [captured, captured], operand_kinds = [typed_value, typed_value]> : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction> loc("expand-matchers.mlir":318:1)
// CHECK:             %[[INST_0:.*]] = mpir.inst <add> flags(%[[VAR_0]], %[[VAR_1]]) (%[[TYPE_0]], %[[VAR_2]], %[[TYPE_0]], %[[VAR_3]]) <flags = [nsw, nuw], flag_modes = [captured, captured], operand_kinds = [typed_value, typed_value], result_name = "r"> : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:             mpir.yield %[[INST_0]] : <Instruction>
// CHECK:           }, {
// CHECK:             %[[INST_1:.*]] = mpir.inst <or> (%[[TYPE_0]], %[[VAR_2]], %[[TYPE_0]], %[[VAR_3]]) <flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value], result_name = "r"> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:             %[[INT_0:.*]] = mpir.int 1 : ui1 : <Value>
// CHECK:             mpir.bind %[[VAR_0]], %[[INT_0]] : <Boolean>, <Value>
// CHECK:             %[[INT_1:.*]] = mpir.int 0 : ui1 : <Value>
// CHECK:             mpir.bind %[[VAR_1]], %[[INT_1]] : <Boolean>, <Value>
// CHECK:             mpir.yield %[[INST_1]] : <Instruction>
// CHECK:           } <result_name = "r"> : <Instruction>
} loc("expand-matchers.mlir":329:1)
// CHECK:         }

// -----

// A parameter of a fixed type: a branch fits only a use of that type.
mpir.matcher @pick <supported_flags = [], syntax = nary, arity = 3, param_names = ["", "c", "ty", "t", "ty", "f"], param_is_type = [true, false, true, false, true, false]> {
// CHECK-LABEL:   mpir.matcher @pick <supported_flags = [], syntax = nary, arity = 3, param_names = ["", "c", "ty", "t", "ty", "f"], param_is_type = [true, false, true, false, true, false]> {
  %0 = mpir.type.int 1 : <Type> loc("expand-matchers.mlir":337:1)
// CHECK:           %[[TYPE_0:.*]] = mpir.type.int 1 : <Type>
  %ty = mpir.var "ty" : <Type> loc("expand-matchers.mlir":339:1)
// CHECK:           %[[VAR_0:.*]] = mpir.var "ty" : <Type>
  mpir.signature %0, %ty, %ty : !mpir.sort<Type>, !mpir.sort<Type>, !mpir.sort<Type> loc("expand-matchers.mlir":341:1)
// CHECK:           mpir.signature %[[TYPE_0]], %[[VAR_0]], %[[VAR_0]] : !mpir.sort<Type>, !mpir.sort<Type>, !mpir.sort<Type>
  mpir.branch <param_args = [-1, 0, 1, 2, 1, 3], fixed_flags = [], fixed_flag_values = []> {
// CHECK:           mpir.branch <fixed_flags = [], param_args = [-1, 0, 1, 2, 1, 3], fixed_flag_values = []> {
// CHECK:           ^bb0(%[[VAL_0:.*]]: !mpir.sort<Boolean>, %[[VAL_1:.*]]: !mpir.sort<Type>, %[[VAL_2:.*]]: !mpir.sort<Operand>, %[[VAL_3:.*]]: !mpir.sort<Operand>):
  ^bb0(%arg0: !mpir.sort<Boolean>, %arg1: !mpir.sort<Type>, %arg2: !mpir.sort<Operand>, %arg3: !mpir.sort<Operand>):
    %1 = mpir.type.int 1 : <Type> loc("expand-matchers.mlir":347:1)
// CHECK:             %[[TYPE_1:.*]] = mpir.type.int 1 : <Type>
    %i_ret = mpir.inst <select> (%1, %arg0, %arg1, %arg2, %arg1, %arg3) <result_name = "ret", flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value, typed_value]> : (!mpir.sort<Type>, !mpir.sort<Boolean>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction> loc("expand-matchers.mlir":349:1)
// CHECK:             %[[INST_0:.*]] = mpir.inst <select> (%[[TYPE_1]], %[[VAL_0]], %[[VAL_1]], %[[VAL_2]], %[[VAL_1]], %[[VAL_3]]) <flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value, typed_value], result_name = "ret"> : (!mpir.sort<Type>, !mpir.sort<Boolean>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
    mpir.yield %i_ret : <Instruction> loc("expand-matchers.mlir":351:1)
// CHECK:             mpir.yield %[[INST_0]] : <Instruction>
  } loc("expand-matchers.mlir":353:1)
// CHECK:           }
} loc("expand-matchers.mlir":355:1)
// CHECK:         }
mpir.pattern {
// CHECK-LABEL:   mpir.pattern {
  %0 = mpir.type.int 1 : <Type> loc("expand-matchers.mlir":359:1)
// CHECK:           %[[TYPE_0:.*]] = mpir.type.int 1 : <Type>
  %cond = mpir.var "cond" : <Boolean> loc("expand-matchers.mlir":361:1)
// CHECK:           %[[VAR_0:.*]] = mpir.var "cond" : <Boolean>
  %1 = mpir.type.int 32 : <Type> loc("expand-matchers.mlir":363:1)
// CHECK:           %[[TYPE_1:.*]] = mpir.type.int 32 : <Type>
  %a = mpir.var "a" : <Operand> loc("expand-matchers.mlir":365:1)
// CHECK:           %[[VAR_1:.*]] = mpir.var "a" : <Operand>
  %2 = mpir.type.int 32 : <Type> loc("expand-matchers.mlir":367:1)
// CHECK:           %[[TYPE_2:.*]] = mpir.type.int 32 : <Type>
  %b = mpir.var "b" : <Operand> loc("expand-matchers.mlir":369:1)
// CHECK:           %[[VAR_2:.*]] = mpir.var "b" : <Operand>
  %u_r = mpir.use @pick (%0, %cond, %1, %a, %2, %b) <result_name = "r", flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value, typed_value]> : (!mpir.sort<Type>, !mpir.sort<Boolean>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction> loc("expand-matchers.mlir":371:1)
// CHECK:           %[[ALT_0:.*]] = mpir.alt {
// CHECK:             %[[TYPE_3:.*]] = mpir.type.int 1 : <Type>
// CHECK:             %[[INST_0:.*]] = mpir.inst <select> (%[[TYPE_3]], %[[VAR_0]], %[[TYPE_1]], %[[VAR_1]], %[[TYPE_1]], %[[VAR_2]]) <flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value, typed_value], result_name = "r"> : (!mpir.sort<Type>, !mpir.sort<Boolean>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:             mpir.yield %[[INST_0]] : <Instruction>
// CHECK:           } <result_name = "r"> : <Instruction>
} loc("expand-matchers.mlir":377:1)
// CHECK:         }

// -----

// A type parameter used for two operands must be one type: a use with two
// types has no branch to match (the alt is empty).
mpir.matcher @pick <supported_flags = [], syntax = nary, arity = 3, param_names = ["", "c", "ty", "t", "ty", "f"], param_is_type = [true, false, true, false, true, false]> {
// CHECK-LABEL:   mpir.matcher @pick <supported_flags = [], syntax = nary, arity = 3, param_names = ["", "c", "ty", "t", "ty", "f"], param_is_type = [true, false, true, false, true, false]> {
  %0 = mpir.type.int 1 : <Type> loc("expand-matchers.mlir":386:1)
// CHECK:           %[[TYPE_0:.*]] = mpir.type.int 1 : <Type>
  %ty = mpir.var "ty" : <Type> loc("expand-matchers.mlir":388:1)
// CHECK:           %[[VAR_0:.*]] = mpir.var "ty" : <Type>
  mpir.signature %0, %ty, %ty : !mpir.sort<Type>, !mpir.sort<Type>, !mpir.sort<Type> loc("expand-matchers.mlir":390:1)
// CHECK:           mpir.signature %[[TYPE_0]], %[[VAR_0]], %[[VAR_0]] : !mpir.sort<Type>, !mpir.sort<Type>, !mpir.sort<Type>
  mpir.branch <param_args = [-1, 0, 1, 2, 1, 3], fixed_flags = [], fixed_flag_values = []> {
// CHECK:           mpir.branch <fixed_flags = [], param_args = [-1, 0, 1, 2, 1, 3], fixed_flag_values = []> {
// CHECK:           ^bb0(%[[VAL_0:.*]]: !mpir.sort<Boolean>, %[[VAL_1:.*]]: !mpir.sort<Type>, %[[VAL_2:.*]]: !mpir.sort<Operand>, %[[VAL_3:.*]]: !mpir.sort<Operand>):
  ^bb0(%arg0: !mpir.sort<Boolean>, %arg1: !mpir.sort<Type>, %arg2: !mpir.sort<Operand>, %arg3: !mpir.sort<Operand>):
    %1 = mpir.type.int 1 : <Type> loc("expand-matchers.mlir":396:1)
// CHECK:             %[[TYPE_1:.*]] = mpir.type.int 1 : <Type>
    %i_ret = mpir.inst <select> (%1, %arg0, %arg1, %arg2, %arg1, %arg3) <result_name = "ret", flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value, typed_value]> : (!mpir.sort<Type>, !mpir.sort<Boolean>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction> loc("expand-matchers.mlir":398:1)
// CHECK:             %[[INST_0:.*]] = mpir.inst <select> (%[[TYPE_1]], %[[VAL_0]], %[[VAL_1]], %[[VAL_2]], %[[VAL_1]], %[[VAL_3]]) <flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value, typed_value], result_name = "ret"> : (!mpir.sort<Type>, !mpir.sort<Boolean>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
    mpir.yield %i_ret : <Instruction> loc("expand-matchers.mlir":400:1)
// CHECK:             mpir.yield %[[INST_0]] : <Instruction>
  } loc("expand-matchers.mlir":402:1)
// CHECK:           }
} loc("expand-matchers.mlir":404:1)
// CHECK:         }
mpir.pattern {
// CHECK-LABEL:   mpir.pattern {
  %0 = mpir.type.int 1 : <Type> loc("expand-matchers.mlir":408:1)
// CHECK:           %[[TYPE_0:.*]] = mpir.type.int 1 : <Type>
  %cond = mpir.var "cond" : <Boolean> loc("expand-matchers.mlir":410:1)
// CHECK:           %[[VAR_0:.*]] = mpir.var "cond" : <Boolean>
  %1 = mpir.type.int 32 : <Type> loc("expand-matchers.mlir":412:1)
// CHECK:           %[[TYPE_1:.*]] = mpir.type.int 32 : <Type>
  %a = mpir.var "a" : <Operand> loc("expand-matchers.mlir":414:1)
// CHECK:           %[[VAR_1:.*]] = mpir.var "a" : <Operand>
  %2 = mpir.type.int 64 : <Type> loc("expand-matchers.mlir":416:1)
// CHECK:           %[[TYPE_2:.*]] = mpir.type.int 64 : <Type>
  %b = mpir.var "b" : <Operand> loc("expand-matchers.mlir":418:1)
// CHECK:           %[[VAR_2:.*]] = mpir.var "b" : <Operand>
  %u_r = mpir.use @pick (%0, %cond, %1, %a, %2, %b) <result_name = "r", flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value, typed_value]> : (!mpir.sort<Type>, !mpir.sort<Boolean>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction> loc("expand-matchers.mlir":420:1)
// CHECK:           %[[ALT_0:.*]] = mpir.alt  <result_name = "r"> : <Instruction>
} loc("expand-matchers.mlir":422:1)
// CHECK:         }

// -----

// ...unless one is only known once matched.
mpir.matcher @pick <supported_flags = [], syntax = nary, arity = 3, param_names = ["", "c", "ty", "t", "ty", "f"], param_is_type = [true, false, true, false, true, false]> {
// CHECK-LABEL:   mpir.matcher @pick <supported_flags = [], syntax = nary, arity = 3, param_names = ["", "c", "ty", "t", "ty", "f"], param_is_type = [true, false, true, false, true, false]> {
  %0 = mpir.type.int 1 : <Type> loc("expand-matchers.mlir":430:1)
// CHECK:           %[[TYPE_0:.*]] = mpir.type.int 1 : <Type>
  %ty = mpir.var "ty" : <Type> loc("expand-matchers.mlir":432:1)
// CHECK:           %[[VAR_0:.*]] = mpir.var "ty" : <Type>
  mpir.signature %0, %ty, %ty : !mpir.sort<Type>, !mpir.sort<Type>, !mpir.sort<Type> loc("expand-matchers.mlir":434:1)
// CHECK:           mpir.signature %[[TYPE_0]], %[[VAR_0]], %[[VAR_0]] : !mpir.sort<Type>, !mpir.sort<Type>, !mpir.sort<Type>
  mpir.branch <param_args = [-1, 0, 1, 2, 1, 3], fixed_flags = [], fixed_flag_values = []> {
// CHECK:           mpir.branch <fixed_flags = [], param_args = [-1, 0, 1, 2, 1, 3], fixed_flag_values = []> {
// CHECK:           ^bb0(%[[VAL_0:.*]]: !mpir.sort<Boolean>, %[[VAL_1:.*]]: !mpir.sort<Type>, %[[VAL_2:.*]]: !mpir.sort<Operand>, %[[VAL_3:.*]]: !mpir.sort<Operand>):
  ^bb0(%arg0: !mpir.sort<Boolean>, %arg1: !mpir.sort<Type>, %arg2: !mpir.sort<Operand>, %arg3: !mpir.sort<Operand>):
    %1 = mpir.type.int 1 : <Type> loc("expand-matchers.mlir":440:1)
// CHECK:             %[[TYPE_1:.*]] = mpir.type.int 1 : <Type>
    %i_ret = mpir.inst <select> (%1, %arg0, %arg1, %arg2, %arg1, %arg3) <result_name = "ret", flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value, typed_value]> : (!mpir.sort<Type>, !mpir.sort<Boolean>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction> loc("expand-matchers.mlir":442:1)
// CHECK:             %[[INST_0:.*]] = mpir.inst <select> (%[[TYPE_1]], %[[VAL_0]], %[[VAL_1]], %[[VAL_2]], %[[VAL_1]], %[[VAL_3]]) <flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value, typed_value], result_name = "ret"> : (!mpir.sort<Type>, !mpir.sort<Boolean>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
    mpir.yield %i_ret : <Instruction> loc("expand-matchers.mlir":444:1)
// CHECK:             mpir.yield %[[INST_0]] : <Instruction>
  } loc("expand-matchers.mlir":446:1)
// CHECK:           }
} loc("expand-matchers.mlir":448:1)
// CHECK:         }
mpir.pattern {
// CHECK-LABEL:   mpir.pattern {
  %0 = mpir.type.int 1 : <Type> loc("expand-matchers.mlir":452:1)
// CHECK:           %[[TYPE_0:.*]] = mpir.type.int 1 : <Type>
  %cond = mpir.var "cond" : <Boolean> loc("expand-matchers.mlir":454:1)
// CHECK:           %[[VAR_0:.*]] = mpir.var "cond" : <Boolean>
  %1 = mpir.type.int 32 : <Type> loc("expand-matchers.mlir":456:1)
// CHECK:           %[[TYPE_1:.*]] = mpir.type.int 32 : <Type>
  %a = mpir.var "a" : <Operand> loc("expand-matchers.mlir":458:1)
// CHECK:           %[[VAR_1:.*]] = mpir.var "a" : <Operand>
  %other = mpir.var "other" : <Type> loc("expand-matchers.mlir":460:1)
// CHECK:           %[[VAR_2:.*]] = mpir.var "other" : <Type>
  %b = mpir.var "b" : <Operand> loc("expand-matchers.mlir":462:1)
// CHECK:           %[[VAR_3:.*]] = mpir.var "b" : <Operand>
  %u_r = mpir.use @pick (%0, %cond, %1, %a, %other, %b) <result_name = "r", flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value, typed_value]> : (!mpir.sort<Type>, !mpir.sort<Boolean>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction> loc("expand-matchers.mlir":464:1)
// CHECK:           %[[ALT_0:.*]] = mpir.alt {
// CHECK:             %[[TYPE_2:.*]] = mpir.type.int 1 : <Type>
// CHECK:             %[[INST_0:.*]] = mpir.inst <select> (%[[TYPE_2]], %[[VAR_0]], %[[TYPE_1]], %[[VAR_1]], %[[TYPE_1]], %[[VAR_3]]) <flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value, typed_value], result_name = "r"> : (!mpir.sort<Type>, !mpir.sort<Boolean>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:             mpir.yield %[[INST_0]] : <Instruction>
// CHECK:           } <result_name = "r"> : <Instruction>
  %2 = mpir.type.int 1 : <Type> loc("expand-matchers.mlir":470:1)
// CHECK:           %[[TYPE_3:.*]] = mpir.type.int 1 : <Type>
  %n = mpir.var "n" : <Nat> loc("expand-matchers.mlir":472:1)
// CHECK:           %[[VAR_4:.*]] = mpir.var "n" : <Nat>
  %3 = mpir.type.meta_int %n : (!mpir.sort<Nat>) -> !mpir.sort<Type> loc("expand-matchers.mlir":474:1)
// CHECK:           %[[TYPE_4:.*]] = mpir.type.meta_int %[[VAR_4]] : (!mpir.sort<Nat>) -> !mpir.sort<Type>
  %4 = mpir.type.meta_int %n : (!mpir.sort<Nat>) -> !mpir.sort<Type> loc("expand-matchers.mlir":476:1)
// CHECK:           %[[TYPE_5:.*]] = mpir.type.meta_int %[[VAR_4]] : (!mpir.sort<Nat>) -> !mpir.sort<Type>
  %u_s = mpir.use @pick (%2, %cond, %3, %u_r, %4, %b) <result_name = "s", flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value, typed_value]> : (!mpir.sort<Type>, !mpir.sort<Boolean>, !mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction> loc("expand-matchers.mlir":478:1)
// CHECK:           %[[ALT_1:.*]] = mpir.alt {
// CHECK:             %[[TYPE_6:.*]] = mpir.type.int 1 : <Type>
// CHECK:             %[[INST_1:.*]] = mpir.inst <select> (%[[TYPE_6]], %[[VAR_0]], %[[TYPE_4]], %[[ALT_0]], %[[TYPE_4]], %[[VAR_3]]) <flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value, typed_value], result_name = "s"> : (!mpir.sort<Type>, !mpir.sort<Boolean>, !mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:             mpir.yield %[[INST_1]] : <Instruction>
// CHECK:           } <result_name = "s"> : <Instruction>
} loc("expand-matchers.mlir":484:1)
// CHECK:         }

// -----

// An 'i?bits' parameter stands for the use's type, and its width for a
// value the branch's constraints read: a literal, or the use's variable.
mpir.matcher @low <supported_flags = [], syntax = nary, arity = 1, param_names = ["bits", "a"], param_is_type = [true, false]> {
// CHECK-LABEL:   mpir.matcher @low <supported_flags = [], syntax = nary, arity = 1, param_names = ["bits", "a"], param_is_type = [true, false]> {
  %bits = mpir.var "bits" : <Nat> loc("expand-matchers.mlir":493:1)
// CHECK:           %[[VAR_0:.*]] = mpir.var "bits" : <Nat>
  %0 = mpir.type.meta_int %bits : (!mpir.sort<Nat>) -> !mpir.sort<Type> loc("expand-matchers.mlir":495:1)
// CHECK:           %[[TYPE_0:.*]] = mpir.type.meta_int %[[VAR_0]] : (!mpir.sort<Nat>) -> !mpir.sort<Type>
  mpir.signature %0 : !mpir.sort<Type> loc("expand-matchers.mlir":497:1)
// CHECK:           mpir.signature %[[TYPE_0]] : !mpir.sort<Type>
  mpir.branch <param_args = [0, 1], fixed_flags = [], fixed_flag_values = []> {
// CHECK:           mpir.branch <fixed_flags = [], param_args = [0, 1], fixed_flag_values = []> {
// CHECK:           ^bb0(%[[VAL_0:.*]]: !mpir.sort<Nat>, %[[VAL_1:.*]]: !mpir.sort<Operand>):
  ^bb0(%arg0: !mpir.sort<Nat>, %arg1: !mpir.sort<Operand>):
    %1 = mpir.type.meta_int %arg0 : (!mpir.sort<Nat>) -> !mpir.sort<Type> loc("expand-matchers.mlir":503:1)
// CHECK:             %[[TYPE_1:.*]] = mpir.type.meta_int %[[VAL_0]] : (!mpir.sort<Nat>) -> !mpir.sort<Type>
    %2 = mpir.type.int 8 : <Type> loc("expand-matchers.mlir":505:1)
// CHECK:             %[[TYPE_2:.*]] = mpir.type.int 8 : <Type>
    %i_ret = mpir.inst <trunc> (%1, %arg1, %2) <result_name = "ret", flags = [], flag_modes = [], operand_kinds = [typed_value, type_only]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>) -> !mpir.sort<Instruction> loc("expand-matchers.mlir":507:1)
// CHECK:             %[[INST_0:.*]] = mpir.inst <trunc> (%[[TYPE_1]], %[[VAL_1]], %[[TYPE_2]]) <flags = [], flag_modes = [], operand_kinds = [typed_value, type_only], result_name = "ret"> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>) -> !mpir.sort<Instruction>
    %3 = mpir_expr.read %arg0 : (!mpir.sort<Nat>) -> !mpir.sort<Integer> loc("expand-matchers.mlir":509:1)
// CHECK:             %[[READ_0:.*]] = mpir_expr.read %[[VAL_0]] : (!mpir.sort<Nat>) -> !mpir.sort<Integer>
    %4 = mpir_expr.int 32 : ui64 : <Integer> loc("expand-matchers.mlir":511:1)
// CHECK:             %[[INT_0:.*]] = mpir_expr.int 32 : ui64 : <Integer>
    %5 = mpir_expr.call binary "=="(%3, %4) anchor %i_ret : (!mpir.sort<Integer>, !mpir.sort<Integer>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("expand-matchers.mlir":513:1)
// CHECK:             %[[CALL_0:.*]] = mpir_expr.call binary "=="(%[[READ_0]], %[[INT_0]]) anchor %[[INST_0]] : (!mpir.sort<Integer>, !mpir.sort<Integer>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
    mpir.require %5 : <Boolean> loc("expand-matchers.mlir":515:1)
// CHECK:             mpir.require %[[CALL_0]] : <Boolean>
    mpir.yield %i_ret : <Instruction> loc("expand-matchers.mlir":517:1)
// CHECK:             mpir.yield %[[INST_0]] : <Instruction>
  } loc("expand-matchers.mlir":519:1)
// CHECK:           }
} loc("expand-matchers.mlir":521:1)
// CHECK:         }
mpir.pattern {
// CHECK-LABEL:   mpir.pattern {
  %0 = mpir.type.int 32 : <Type> loc("expand-matchers.mlir":525:1)
// CHECK:           %[[TYPE_0:.*]] = mpir.type.int 32 : <Type>
  %x = mpir.var "x" : <Operand> loc("expand-matchers.mlir":527:1)
// CHECK:           %[[VAR_0:.*]] = mpir.var "x" : <Operand>
  %u_r = mpir.use @low (%0, %x) <result_name = "r", flags = [], flag_modes = [], operand_kinds = [typed_value]> : (!mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction> loc("expand-matchers.mlir":529:1)
// CHECK:           %[[ALT_0:.*]] = mpir.alt {
// CHECK:             %[[TYPE_1:.*]] = mpir.type.int 8 : <Type>
// CHECK:             %[[INST_0:.*]] = mpir.inst <trunc> (%[[TYPE_0]], %[[VAR_0]], %[[TYPE_1]]) <flags = [], flag_modes = [], operand_kinds = [typed_value, type_only], result_name = "r"> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>) -> !mpir.sort<Instruction>
// CHECK:             %[[INT_0:.*]] = mpir_expr.int 32 : ui64 : <Integer>
// CHECK:             %[[INT_1:.*]] = mpir_expr.int 32 : ui64 : <Integer>
// CHECK:             %[[CALL_0:.*]] = mpir_expr.call binary "=="(%[[INT_0]], %[[INT_1]]) anchor %[[INST_0]] : (!mpir.sort<Integer>, !mpir.sort<Integer>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:             mpir.require %[[CALL_0]] : <Boolean>
// CHECK:             mpir.yield %[[INST_0]] : <Instruction>
// CHECK:           } <result_name = "r"> : <Instruction>
  %w = mpir.var "w" : <Nat> loc("expand-matchers.mlir":539:1)
// CHECK:           %[[VAR_1:.*]] = mpir.var "w" : <Nat>
  %1 = mpir.type.meta_int %w : (!mpir.sort<Nat>) -> !mpir.sort<Type> loc("expand-matchers.mlir":541:1)
// CHECK:           %[[TYPE_2:.*]] = mpir.type.meta_int %[[VAR_1]] : (!mpir.sort<Nat>) -> !mpir.sort<Type>
  %y = mpir.var "y" : <Operand> loc("expand-matchers.mlir":543:1)
// CHECK:           %[[VAR_2:.*]] = mpir.var "y" : <Operand>
  %u_s = mpir.use @low (%1, %y) <result_name = "s", flags = [], flag_modes = [], operand_kinds = [typed_value]> : (!mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction> loc("expand-matchers.mlir":545:1)
// CHECK:           %[[ALT_1:.*]] = mpir.alt {
// CHECK:             %[[TYPE_3:.*]] = mpir.type.int 8 : <Type>
// CHECK:             %[[INST_1:.*]] = mpir.inst <trunc> (%[[TYPE_2]], %[[VAR_2]], %[[TYPE_3]]) <flags = [], flag_modes = [], operand_kinds = [typed_value, type_only], result_name = "s"> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>) -> !mpir.sort<Instruction>
// CHECK:             %[[READ_0:.*]] = mpir_expr.read %[[VAR_1]] : (!mpir.sort<Nat>) -> !mpir.sort<Integer>
// CHECK:             %[[INT_2:.*]] = mpir_expr.int 32 : ui64 : <Integer>
// CHECK:             %[[CALL_1:.*]] = mpir_expr.call binary "=="(%[[READ_0]], %[[INT_2]]) anchor %[[INST_1]] : (!mpir.sort<Integer>, !mpir.sort<Integer>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:             mpir.require %[[CALL_1]] : <Boolean>
// CHECK:             mpir.yield %[[INST_1]] : <Instruction>
// CHECK:           } <result_name = "s"> : <Instruction>
} loc("expand-matchers.mlir":555:1)
// CHECK:         }

// -----

// A cast: the source and the destination type.
mpir.matcher @widen <supported_flags = [nneg], syntax = cast, arity = 1, param_names = ["from", "a", "to"], param_is_type = [true, false, true]> {
// CHECK-LABEL:   mpir.matcher @widen <supported_flags = [nneg], syntax = cast, arity = 1, param_names = ["from", "a", "to"], param_is_type = [true, false, true]> {
  %from = mpir.var "from" : <Type> loc("expand-matchers.mlir":563:1)
// CHECK:           %[[VAR_0:.*]] = mpir.var "from" : <Type>
  %to = mpir.var "to" : <Type> loc("expand-matchers.mlir":565:1)
// CHECK:           %[[VAR_1:.*]] = mpir.var "to" : <Type>
  mpir.signature %from, %to : !mpir.sort<Type>, !mpir.sort<Type> loc("expand-matchers.mlir":567:1)
// CHECK:           mpir.signature %[[VAR_0]], %[[VAR_1]] : !mpir.sort<Type>, !mpir.sort<Type>
  mpir.branch <param_args = [0, 1, 2], fixed_flags = [], fixed_flag_values = []> {
// CHECK:           mpir.branch <fixed_flags = [], param_args = [0, 1, 2], fixed_flag_values = []> {
// CHECK:           ^bb0(%[[VAL_0:.*]]: !mpir.sort<Type>, %[[VAL_1:.*]]: !mpir.sort<Operand>, %[[VAL_2:.*]]: !mpir.sort<Type>):
  ^bb0(%arg0: !mpir.sort<Type>, %arg1: !mpir.sort<Operand>, %arg2: !mpir.sort<Type>):
    %i_ret = mpir.inst <zext> (%arg0, %arg1, %arg2) <result_name = "ret", flags = [], flag_modes = [], operand_kinds = [typed_value, type_only]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>) -> !mpir.sort<Instruction> loc("expand-matchers.mlir":573:1)
// CHECK:             %[[INST_0:.*]] = mpir.inst <zext> (%[[VAL_0]], %[[VAL_1]], %[[VAL_2]]) <flags = [], flag_modes = [], operand_kinds = [typed_value, type_only], result_name = "ret"> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>) -> !mpir.sort<Instruction>
    mpir.yield %i_ret : <Instruction> loc("expand-matchers.mlir":575:1)
// CHECK:             mpir.yield %[[INST_0]] : <Instruction>
  } loc("expand-matchers.mlir":577:1)
// CHECK:           }
  mpir.branch <param_args = [0, 1, 2], fixed_flags = [nneg], fixed_flag_values = [false]> {
// CHECK:           mpir.branch <fixed_flags = [nneg], param_args = [0, 1, 2], fixed_flag_values = [false]> {
// CHECK:           ^bb0(%[[VAL_3:.*]]: !mpir.sort<Type>, %[[VAL_4:.*]]: !mpir.sort<Operand>, %[[VAL_5:.*]]: !mpir.sort<Type>):
  ^bb0(%arg0: !mpir.sort<Type>, %arg1: !mpir.sort<Operand>, %arg2: !mpir.sort<Type>):
    %i_ret = mpir.inst <sext> (%arg0, %arg1, %arg2) <result_name = "ret", flags = [], flag_modes = [], operand_kinds = [typed_value, type_only]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>) -> !mpir.sort<Instruction> loc("expand-matchers.mlir":583:1)
// CHECK:             %[[INST_1:.*]] = mpir.inst <sext> (%[[VAL_3]], %[[VAL_4]], %[[VAL_5]]) <flags = [], flag_modes = [], operand_kinds = [typed_value, type_only], result_name = "ret"> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>) -> !mpir.sort<Instruction>
    mpir.yield %i_ret : <Instruction> loc("expand-matchers.mlir":585:1)
// CHECK:             mpir.yield %[[INST_1]] : <Instruction>
  } loc("expand-matchers.mlir":587:1)
// CHECK:           }
} loc("expand-matchers.mlir":589:1)
// CHECK:         }
mpir.pattern {
// CHECK-LABEL:   mpir.pattern {
  %0 = mpir.type.int 8 : <Type> loc("expand-matchers.mlir":593:1)
// CHECK:           %[[TYPE_0:.*]] = mpir.type.int 8 : <Type>
  %x = mpir.var "x" : <Operand> loc("expand-matchers.mlir":595:1)
// CHECK:           %[[VAR_0:.*]] = mpir.var "x" : <Operand>
  %1 = mpir.type.int 32 : <Type> loc("expand-matchers.mlir":597:1)
// CHECK:           %[[TYPE_1:.*]] = mpir.type.int 32 : <Type>
  %u_r = mpir.use @widen (%0, %x, %1) <result_name = "r", flags = [], flag_modes = [], operand_kinds = [typed_value, type_only]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>) -> !mpir.sort<Instruction> loc("expand-matchers.mlir":599:1)
// CHECK:           %[[VAR_1:.*]] = mpir.var "_flag$r$nneg" : <Boolean>
// CHECK:           %[[ALT_0:.*]] = mpir.alt {
// CHECK:             %[[INST_0:.*]] = mpir.inst <zext> (%[[TYPE_0]], %[[VAR_0]], %[[TYPE_1]]) <flags = [], flag_modes = [], operand_kinds = [typed_value, type_only], result_name = "r"> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>) -> !mpir.sort<Instruction>
// CHECK:             mpir.yield %[[INST_0]] : <Instruction>
// CHECK:           }, {
// CHECK:             %[[INST_1:.*]] = mpir.inst <sext> (%[[TYPE_0]], %[[VAR_0]], %[[TYPE_1]]) <flags = [], flag_modes = [], operand_kinds = [typed_value, type_only], result_name = "r"> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>) -> !mpir.sort<Instruction>
// CHECK:             mpir.yield %[[INST_1]] : <Instruction>
// CHECK:           } <result_name = "r"> : <Instruction>
  %2 = mpir.type.int 32 : <Type> loc("expand-matchers.mlir":608:1)
// CHECK:           %[[TYPE_2:.*]] = mpir.type.int 32 : <Type>
  %wide = mpir.var "wide" : <Type> loc("expand-matchers.mlir":610:1)
// CHECK:           %[[VAR_2:.*]] = mpir.var "wide" : <Type>
  %u_s = mpir.use @widen (%2, %u_r, %wide) <result_name = "s", flags = [nneg], flag_modes = [required], operand_kinds = [typed_value, type_only]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>) -> !mpir.sort<Instruction> loc("expand-matchers.mlir":612:1)
// CHECK:           %[[ALT_1:.*]] = mpir.alt {
// CHECK:             %[[INST_2:.*]] = mpir.inst <zext> (%[[TYPE_2]], %[[ALT_0]], %[[VAR_2]]) <flags = [], flag_modes = [], operand_kinds = [typed_value, type_only], result_name = "s"> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>) -> !mpir.sort<Instruction>
// CHECK:             mpir.yield %[[INST_2]] : <Instruction>
// CHECK:           } <result_name = "s"> : <Instruction>
} loc("expand-matchers.mlir":617:1)
// CHECK:         }

// -----

// A branch's own variables and instructions are copies named after the
// use, one set per use.
mpir.matcher @mulAdd <supported_flags = [], syntax = binary, arity = 2, param_names = ["ty", "a", "b"], param_is_type = [true, false, false]> {
// CHECK-LABEL:   mpir.matcher @mulAdd <supported_flags = [], syntax = binary, arity = 2, param_names = ["ty", "a", "b"], param_is_type = [true, false, false]> {
  %ty = mpir.var "ty" : <Type> loc("expand-matchers.mlir":626:1)
// CHECK:           %[[VAR_0:.*]] = mpir.var "ty" : <Type>
  mpir.signature %ty : !mpir.sort<Type> loc("expand-matchers.mlir":628:1)
// CHECK:           mpir.signature %[[VAR_0]] : !mpir.sort<Type>
  mpir.branch <param_args = [0, 1, 2], fixed_flags = [], fixed_flag_values = []> {
// CHECK:           mpir.branch <fixed_flags = [], param_args = [0, 1, 2], fixed_flag_values = []> {
// CHECK:           ^bb0(%[[VAL_0:.*]]: !mpir.sort<Type>, %[[VAL_1:.*]]: !mpir.sort<Operand>, %[[VAL_2:.*]]: !mpir.sort<Operand>):
  ^bb0(%arg0: !mpir.sort<Type>, %arg1: !mpir.sort<Operand>, %arg2: !mpir.sort<Operand>):
    %k = mpir.var "k" : <Operand> loc("expand-matchers.mlir":634:1)
// CHECK:             %[[VAR_1:.*]] = mpir.var "k" : <Operand>
    %i_m = mpir.inst <mul> (%arg0, %arg1, %arg0, %k) <result_name = "m", flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction> loc("expand-matchers.mlir":636:1)
// CHECK:             %[[INST_0:.*]] = mpir.inst <mul> (%[[VAL_0]], %[[VAL_1]], %[[VAL_0]], %[[VAR_1]]) <flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value], result_name = "m"> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
    %i_ret = mpir.inst <add> (%arg0, %i_m, %arg0, %arg2) <result_name = "ret", flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction> loc("expand-matchers.mlir":638:1)
// CHECK:             %[[INST_1:.*]] = mpir.inst <add> (%[[VAL_0]], %[[INST_0]], %[[VAL_0]], %[[VAL_2]]) <flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value], result_name = "ret"> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
    %0 = mpir_expr.read %k : (!mpir.sort<Operand>) -> !mpir.sort<Value> loc("expand-matchers.mlir":640:1)
// CHECK:             %[[READ_0:.*]] = mpir_expr.read %[[VAR_1]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
    %1 = mpir_expr.int 3 : ui64 : <Integer> loc("expand-matchers.mlir":642:1)
// CHECK:             %[[INT_0:.*]] = mpir_expr.int 3 : ui64 : <Integer>
    %2 = mpir_expr.call binary "=="(%0, %1) anchor %i_ret : (!mpir.sort<Value>, !mpir.sort<Integer>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("expand-matchers.mlir":644:1)
// CHECK:             %[[CALL_0:.*]] = mpir_expr.call binary "=="(%[[READ_0]], %[[INT_0]]) anchor %[[INST_1]] : (!mpir.sort<Value>, !mpir.sort<Integer>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
    mpir.require %2 : <Boolean> loc("expand-matchers.mlir":646:1)
// CHECK:             mpir.require %[[CALL_0]] : <Boolean>
    mpir.yield %i_ret : <Instruction> loc("expand-matchers.mlir":648:1)
// CHECK:             mpir.yield %[[INST_1]] : <Instruction>
  } loc("expand-matchers.mlir":650:1)
// CHECK:           }
} loc("expand-matchers.mlir":652:1)
// CHECK:         }
mpir.pattern {
// CHECK-LABEL:   mpir.pattern {
  %0 = mpir.type.int 32 : <Type> loc("expand-matchers.mlir":656:1)
// CHECK:           %[[TYPE_0:.*]] = mpir.type.int 32 : <Type>
  %x = mpir.var "x" : <Operand> loc("expand-matchers.mlir":658:1)
// CHECK:           %[[VAR_0:.*]] = mpir.var "x" : <Operand>
  %y = mpir.var "y" : <Operand> loc("expand-matchers.mlir":660:1)
// CHECK:           %[[VAR_1:.*]] = mpir.var "y" : <Operand>
  %u_r = mpir.use @mulAdd (%0, %x, %0, %y) <result_name = "r", flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction> loc("expand-matchers.mlir":662:1)
// CHECK:           %[[ALT_0:.*]] = mpir.alt {
// CHECK:             %[[VAR_2:.*]] = mpir.var "r$k" : <Operand>
// CHECK:             %[[INST_0:.*]] = mpir.inst <mul> (%[[TYPE_0]], %[[VAR_0]], %[[TYPE_0]], %[[VAR_2]]) <flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value], result_name = "r$m"> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:             %[[INST_1:.*]] = mpir.inst <add> (%[[TYPE_0]], %[[INST_0]], %[[TYPE_0]], %[[VAR_1]]) <flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value], result_name = "r"> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:             %[[READ_0:.*]] = mpir_expr.read %[[VAR_2]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
// CHECK:             %[[INT_0:.*]] = mpir_expr.int 3 : ui64 : <Integer>
// CHECK:             %[[CALL_0:.*]] = mpir_expr.call binary "=="(%[[READ_0]], %[[INT_0]]) anchor %[[INST_1]] : (!mpir.sort<Value>, !mpir.sort<Integer>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:             mpir.require %[[CALL_0]] : <Boolean>
// CHECK:             mpir.yield %[[INST_1]] : <Instruction>
// CHECK:           } <result_name = "r"> : <Instruction>
  %1 = mpir.type.int 32 : <Type> loc("expand-matchers.mlir":673:1)
// CHECK:           %[[TYPE_1:.*]] = mpir.type.int 32 : <Type>
  %u_s = mpir.use @mulAdd (%1, %u_r, %1, %y) <result_name = "s", flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction> loc("expand-matchers.mlir":675:1)
// CHECK:           %[[ALT_1:.*]] = mpir.alt {
// CHECK:             %[[VAR_3:.*]] = mpir.var "s$k" : <Operand>
// CHECK:             %[[INST_2:.*]] = mpir.inst <mul> (%[[TYPE_1]], %[[ALT_0]], %[[TYPE_1]], %[[VAR_3]]) <flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value], result_name = "s$m"> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:             %[[INST_3:.*]] = mpir.inst <add> (%[[TYPE_1]], %[[INST_2]], %[[TYPE_1]], %[[VAR_1]]) <flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value], result_name = "s"> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:             %[[READ_1:.*]] = mpir_expr.read %[[VAR_3]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
// CHECK:             %[[INT_1:.*]] = mpir_expr.int 3 : ui64 : <Integer>
// CHECK:             %[[CALL_1:.*]] = mpir_expr.call binary "=="(%[[READ_1]], %[[INT_1]]) anchor %[[INST_3]] : (!mpir.sort<Value>, !mpir.sort<Integer>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:             mpir.require %[[CALL_1]] : <Boolean>
// CHECK:             mpir.yield %[[INST_3]] : <Instruction>
// CHECK:           } <result_name = "s"> : <Instruction>
} loc("expand-matchers.mlir":686:1)
// CHECK:         }

// -----

// A matcher that uses another: expanded until none is left.
mpir.matcher @addOrSub <supported_flags = [], syntax = binary, arity = 2, param_names = ["ty", "a", "b"], param_is_type = [true, false, false]> {
// CHECK-LABEL:   mpir.matcher @addOrSub <supported_flags = [], syntax = binary, arity = 2, param_names = ["ty", "a", "b"], param_is_type = [true, false, false]> {
  %ty = mpir.var "ty" : <Type> loc("expand-matchers.mlir":694:1)
// CHECK:           %[[VAR_0:.*]] = mpir.var "ty" : <Type>
  mpir.signature %ty : !mpir.sort<Type> loc("expand-matchers.mlir":696:1)
// CHECK:           mpir.signature %[[VAR_0]] : !mpir.sort<Type>
  mpir.branch <param_args = [0, 1, 2], fixed_flags = [], fixed_flag_values = []> {
// CHECK:           mpir.branch <fixed_flags = [], param_args = [0, 1, 2], fixed_flag_values = []> {
// CHECK:           ^bb0(%[[VAL_0:.*]]: !mpir.sort<Type>, %[[VAL_1:.*]]: !mpir.sort<Operand>, %[[VAL_2:.*]]: !mpir.sort<Operand>):
  ^bb0(%arg0: !mpir.sort<Type>, %arg1: !mpir.sort<Operand>, %arg2: !mpir.sort<Operand>):
    %i_ret = mpir.inst <add> (%arg0, %arg1, %arg0, %arg2) <result_name = "ret", flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction> loc("expand-matchers.mlir":702:1)
// CHECK:             %[[INST_0:.*]] = mpir.inst <add> (%[[VAL_0]], %[[VAL_1]], %[[VAL_0]], %[[VAL_2]]) <flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value], result_name = "ret"> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
    mpir.yield %i_ret : <Instruction> loc("expand-matchers.mlir":704:1)
// CHECK:             mpir.yield %[[INST_0]] : <Instruction>
  } loc("expand-matchers.mlir":706:1)
// CHECK:           }
  mpir.branch <param_args = [0, 1, 2], fixed_flags = [], fixed_flag_values = []> {
// CHECK:           mpir.branch <fixed_flags = [], param_args = [0, 1, 2], fixed_flag_values = []> {
// CHECK:           ^bb0(%[[VAL_3:.*]]: !mpir.sort<Type>, %[[VAL_4:.*]]: !mpir.sort<Operand>, %[[VAL_5:.*]]: !mpir.sort<Operand>):
  ^bb0(%arg0: !mpir.sort<Type>, %arg1: !mpir.sort<Operand>, %arg2: !mpir.sort<Operand>):
    %i_ret = mpir.inst <sub> (%arg0, %arg1, %arg0, %arg2) <result_name = "ret", flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction> loc("expand-matchers.mlir":712:1)
// CHECK:             %[[INST_1:.*]] = mpir.inst <sub> (%[[VAL_3]], %[[VAL_4]], %[[VAL_3]], %[[VAL_5]]) <flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value], result_name = "ret"> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
    mpir.yield %i_ret : <Instruction> loc("expand-matchers.mlir":714:1)
// CHECK:             mpir.yield %[[INST_1]] : <Instruction>
  } loc("expand-matchers.mlir":716:1)
// CHECK:           }
} loc("expand-matchers.mlir":718:1)
// CHECK:         }
mpir.matcher @outer <supported_flags = [], syntax = binary, arity = 2, param_names = ["ty", "a", "b"], param_is_type = [true, false, false]> {
// CHECK-LABEL:   mpir.matcher @outer <supported_flags = [], syntax = binary, arity = 2, param_names = ["ty", "a", "b"], param_is_type = [true, false, false]> {
  %ty = mpir.var "ty" : <Type> loc("expand-matchers.mlir":722:1)
// CHECK:           %[[VAR_0:.*]] = mpir.var "ty" : <Type>
  mpir.signature %ty : !mpir.sort<Type> loc("expand-matchers.mlir":724:1)
// CHECK:           mpir.signature %[[VAR_0]] : !mpir.sort<Type>
  mpir.branch <param_args = [0, 1, 2], fixed_flags = [], fixed_flag_values = []> {
// CHECK:           mpir.branch <fixed_flags = [], param_args = [0, 1, 2], fixed_flag_values = []> {
// CHECK:           ^bb0(%[[VAL_0:.*]]: !mpir.sort<Type>, %[[VAL_1:.*]]: !mpir.sort<Operand>, %[[VAL_2:.*]]: !mpir.sort<Operand>):
  ^bb0(%arg0: !mpir.sort<Type>, %arg1: !mpir.sort<Operand>, %arg2: !mpir.sort<Operand>):
    %u_inner = mpir.use @addOrSub (%arg0, %arg1, %arg0, %arg2) <result_name = "inner", flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction> loc("expand-matchers.mlir":730:1)
// CHECK:             %[[USE_0:.*]] = mpir.use @addOrSub (%[[VAL_0]], %[[VAL_1]], %[[VAL_0]], %[[VAL_2]]) <flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value], result_name = "inner"> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
    %i_ret = mpir.inst <mul> (%arg0, %u_inner, %arg0, %arg2) <result_name = "ret", flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction> loc("expand-matchers.mlir":732:1)
// CHECK:             %[[INST_0:.*]] = mpir.inst <mul> (%[[VAL_0]], %[[USE_0]], %[[VAL_0]], %[[VAL_2]]) <flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value], result_name = "ret"> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
    mpir.yield %i_ret : <Instruction> loc("expand-matchers.mlir":734:1)
// CHECK:             mpir.yield %[[INST_0]] : <Instruction>
  } loc("expand-matchers.mlir":736:1)
// CHECK:           }
} loc("expand-matchers.mlir":738:1)
// CHECK:         }
mpir.pattern {
// CHECK-LABEL:   mpir.pattern {
  %0 = mpir.type.int 32 : <Type> loc("expand-matchers.mlir":742:1)
// CHECK:           %[[TYPE_0:.*]] = mpir.type.int 32 : <Type>
  %x = mpir.var "x" : <Operand> loc("expand-matchers.mlir":744:1)
// CHECK:           %[[VAR_0:.*]] = mpir.var "x" : <Operand>
  %y = mpir.var "y" : <Operand> loc("expand-matchers.mlir":746:1)
// CHECK:           %[[VAR_1:.*]] = mpir.var "y" : <Operand>
  %u_r = mpir.use @outer (%0, %x, %0, %y) <result_name = "r", flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction> loc("expand-matchers.mlir":748:1)
// CHECK:           %[[ALT_0:.*]] = mpir.alt {
// CHECK:             %[[ALT_1:.*]] = mpir.alt {
// CHECK:               %[[INST_0:.*]] = mpir.inst <add> (%[[TYPE_0]], %[[VAR_0]], %[[TYPE_0]], %[[VAR_1]]) <flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value], result_name = "r$inner"> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:               mpir.yield %[[INST_0]] : <Instruction>
// CHECK:             }, {
// CHECK:               %[[INST_1:.*]] = mpir.inst <sub> (%[[TYPE_0]], %[[VAR_0]], %[[TYPE_0]], %[[VAR_1]]) <flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value], result_name = "r$inner"> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:               mpir.yield %[[INST_1]] : <Instruction>
// CHECK:             } <result_name = "r$inner"> : <Instruction>
// CHECK:             %[[INST_2:.*]] = mpir.inst <mul> (%[[TYPE_0]], %[[ALT_1]], %[[TYPE_0]], %[[VAR_1]]) <flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value], result_name = "r"> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:             mpir.yield %[[INST_2]] : <Instruction>
// CHECK:           } <result_name = "r"> : <Instruction>
} loc("expand-matchers.mlir":760:1)
// CHECK:         }

// -----

// A use that is not named gets a number.
mpir.matcher @addOrSub <supported_flags = [], syntax = binary, arity = 2, param_names = ["ty", "a", "b"], param_is_type = [true, false, false]> {
// CHECK-LABEL:   mpir.matcher @addOrSub <supported_flags = [], syntax = binary, arity = 2, param_names = ["ty", "a", "b"], param_is_type = [true, false, false]> {
  %ty = mpir.var "ty" : <Type> loc("expand-matchers.mlir":768:1)
// CHECK:           %[[VAR_0:.*]] = mpir.var "ty" : <Type>
  mpir.signature %ty : !mpir.sort<Type> loc("expand-matchers.mlir":770:1)
// CHECK:           mpir.signature %[[VAR_0]] : !mpir.sort<Type>
  mpir.branch <param_args = [0, 1, 2], fixed_flags = [], fixed_flag_values = []> {
// CHECK:           mpir.branch <fixed_flags = [], param_args = [0, 1, 2], fixed_flag_values = []> {
// CHECK:           ^bb0(%[[VAL_0:.*]]: !mpir.sort<Type>, %[[VAL_1:.*]]: !mpir.sort<Operand>, %[[VAL_2:.*]]: !mpir.sort<Operand>):
  ^bb0(%arg0: !mpir.sort<Type>, %arg1: !mpir.sort<Operand>, %arg2: !mpir.sort<Operand>):
    %i_ret = mpir.inst <add> (%arg0, %arg1, %arg0, %arg2) <result_name = "ret", flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction> loc("expand-matchers.mlir":776:1)
// CHECK:             %[[INST_0:.*]] = mpir.inst <add> (%[[VAL_0]], %[[VAL_1]], %[[VAL_0]], %[[VAL_2]]) <flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value], result_name = "ret"> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
    mpir.yield %i_ret : <Instruction> loc("expand-matchers.mlir":778:1)
// CHECK:             mpir.yield %[[INST_0]] : <Instruction>
  } loc("expand-matchers.mlir":780:1)
// CHECK:           }
  mpir.branch <param_args = [0, 1, 2], fixed_flags = [], fixed_flag_values = []> {
// CHECK:           mpir.branch <fixed_flags = [], param_args = [0, 1, 2], fixed_flag_values = []> {
// CHECK:           ^bb0(%[[VAL_3:.*]]: !mpir.sort<Type>, %[[VAL_4:.*]]: !mpir.sort<Operand>, %[[VAL_5:.*]]: !mpir.sort<Operand>):
  ^bb0(%arg0: !mpir.sort<Type>, %arg1: !mpir.sort<Operand>, %arg2: !mpir.sort<Operand>):
    %i_ret = mpir.inst <sub> (%arg0, %arg1, %arg0, %arg2) <result_name = "ret", flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction> loc("expand-matchers.mlir":786:1)
// CHECK:             %[[INST_1:.*]] = mpir.inst <sub> (%[[VAL_3]], %[[VAL_4]], %[[VAL_3]], %[[VAL_5]]) <flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value], result_name = "ret"> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
    mpir.yield %i_ret : <Instruction> loc("expand-matchers.mlir":788:1)
// CHECK:             mpir.yield %[[INST_1]] : <Instruction>
  } loc("expand-matchers.mlir":790:1)
// CHECK:           }
} loc("expand-matchers.mlir":792:1)
// CHECK:         }
mpir.pattern {
// CHECK-LABEL:   mpir.pattern {
  %0 = mpir.type.int 32 : <Type> loc("expand-matchers.mlir":796:1)
// CHECK:           %[[TYPE_0:.*]] = mpir.type.int 32 : <Type>
  %x = mpir.var "x" : <Operand> loc("expand-matchers.mlir":798:1)
// CHECK:           %[[VAR_0:.*]] = mpir.var "x" : <Operand>
  %y = mpir.var "y" : <Operand> loc("expand-matchers.mlir":800:1)
// CHECK:           %[[VAR_1:.*]] = mpir.var "y" : <Operand>
  %i_a = mpir.inst <mul> (%0, %x, %0, %y) <result_name = "a", flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction> loc("expand-matchers.mlir":802:1)
// CHECK:           %[[INST_0:.*]] = mpir.inst <mul> (%[[TYPE_0]], %[[VAR_0]], %[[TYPE_0]], %[[VAR_1]]) <flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value], result_name = "a"> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
  %1 = mpir.type.int 32 : <Type> loc("expand-matchers.mlir":804:1)
// CHECK:           %[[TYPE_1:.*]] = mpir.type.int 32 : <Type>
// CHECK:           %[[ALT_0:.*]] = mpir.alt {
  %2 = mpir.use @addOrSub (%1, %i_a, %1, %y) <flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction> loc("expand-matchers.mlir":807:1)
// CHECK:             %[[INST_1:.*]] = mpir.inst <add> (%[[TYPE_1]], %[[INST_0]], %[[TYPE_1]], %[[VAR_1]]) <flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:             mpir.yield %[[INST_1]] : <Instruction>
// CHECK:           }, {
// CHECK:             %[[INST_2:.*]] = mpir.inst <sub> (%[[TYPE_1]], %[[INST_0]], %[[TYPE_1]], %[[VAR_1]]) <flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:             mpir.yield %[[INST_2]] : <Instruction>
// CHECK:           } : <Instruction>
} loc("expand-matchers.mlir":814:1)
// CHECK:         }

// -----

// The use's capture names the root, and the root's own capture is the
// use's.
mpir.matcher @capt <supported_flags = [], syntax = binary, arity = 2, param_names = ["ty", "a", "b"], param_is_type = [true, false, false]> {
// CHECK-LABEL:   mpir.matcher @capt <supported_flags = [], syntax = binary, arity = 2, param_names = ["ty", "a", "b"], param_is_type = [true, false, false]> {
  %ty = mpir.var "ty" : <Type> loc("expand-matchers.mlir":823:1)
// CHECK:           %[[VAR_0:.*]] = mpir.var "ty" : <Type>
  mpir.signature %ty : !mpir.sort<Type> loc("expand-matchers.mlir":825:1)
// CHECK:           mpir.signature %[[VAR_0]] : !mpir.sort<Type>
  mpir.branch <param_args = [0, 1, 2], fixed_flags = [], fixed_flag_values = []> {
// CHECK:           mpir.branch <fixed_flags = [], param_args = [0, 1, 2], fixed_flag_values = []> {
// CHECK:           ^bb0(%[[VAL_0:.*]]: !mpir.sort<Type>, %[[VAL_1:.*]]: !mpir.sort<Operand>, %[[VAL_2:.*]]: !mpir.sort<Operand>):
  ^bb0(%arg0: !mpir.sort<Type>, %arg1: !mpir.sort<Operand>, %arg2: !mpir.sort<Operand>):
    %self = mpir.var "self" : <Instruction> loc("expand-matchers.mlir":831:1)
// CHECK:             %[[VAR_1:.*]] = mpir.var "self" : <Instruction>
    %i_ret = mpir.inst <add> capture %self (%arg0, %arg1, %arg0, %arg2) <result_name = "ret", flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value]> : (!mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction> loc("expand-matchers.mlir":833:1)
// CHECK:             %[[INST_0:.*]] = mpir.inst <add> capture %[[VAR_1]] (%[[VAL_0]], %[[VAL_1]], %[[VAL_0]], %[[VAL_2]]) <flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value], result_name = "ret"> : (!mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
    %0 = mpir_expr.read %self : (!mpir.sort<Instruction>) -> !mpir.sort<Value> loc("expand-matchers.mlir":835:1)
// CHECK:             %[[READ_0:.*]] = mpir_expr.read %[[VAR_1]] : (!mpir.sort<Instruction>) -> !mpir.sort<Value>
    %1 = mpir_expr.call call "hasOneUse"(%0) anchor %i_ret : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("expand-matchers.mlir":837:1)
// CHECK:             %[[CALL_0:.*]] = mpir_expr.call call "hasOneUse"(%[[READ_0]]) anchor %[[INST_0]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
    mpir.require %1 : <Boolean> loc("expand-matchers.mlir":839:1)
// CHECK:             mpir.require %[[CALL_0]] : <Boolean>
    mpir.yield %i_ret : <Instruction> loc("expand-matchers.mlir":841:1)
// CHECK:             mpir.yield %[[INST_0]] : <Instruction>
  } loc("expand-matchers.mlir":843:1)
// CHECK:           }
} loc("expand-matchers.mlir":845:1)
// CHECK:         }
mpir.pattern {
// CHECK-LABEL:   mpir.pattern {
  %mine = mpir.var "mine" : <Instruction> loc("expand-matchers.mlir":849:1)
// CHECK:           %[[VAR_0:.*]] = mpir.var "mine" : <Instruction>
  %0 = mpir.type.int 32 : <Type> loc("expand-matchers.mlir":851:1)
// CHECK:           %[[TYPE_0:.*]] = mpir.type.int 32 : <Type>
  %x = mpir.var "x" : <Operand> loc("expand-matchers.mlir":853:1)
// CHECK:           %[[VAR_1:.*]] = mpir.var "x" : <Operand>
  %y = mpir.var "y" : <Operand> loc("expand-matchers.mlir":855:1)
// CHECK:           %[[VAR_2:.*]] = mpir.var "y" : <Operand>
  %u_r = mpir.use @capt capture %mine (%0, %x, %0, %y) <result_name = "r", flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value]> : (!mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction> loc("expand-matchers.mlir":857:1)
// CHECK:           %[[ALT_0:.*]] = mpir.alt {
// CHECK:             %[[INST_0:.*]] = mpir.inst <add> capture %[[VAR_0]] (%[[TYPE_0]], %[[VAR_1]], %[[TYPE_0]], %[[VAR_2]]) <flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value], result_name = "r"> : (!mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:             %[[READ_0:.*]] = mpir_expr.read %[[VAR_0]] : (!mpir.sort<Instruction>) -> !mpir.sort<Value>
// CHECK:             %[[CALL_0:.*]] = mpir_expr.call call "hasOneUse"(%[[READ_0]]) anchor %[[INST_0]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:             mpir.require %[[CALL_0]] : <Boolean>
// CHECK:             mpir.yield %[[INST_0]] : <Instruction>
// CHECK:           } <result_name = "r"> : <Instruction>
  %1 = mpir.type.int 32 : <Type> loc("expand-matchers.mlir":865:1)
// CHECK:           %[[TYPE_1:.*]] = mpir.type.int 32 : <Type>
  %u_s = mpir.use @capt (%1, %u_r, %1, %y) <result_name = "s", flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction> loc("expand-matchers.mlir":867:1)
// CHECK:           %[[ALT_1:.*]] = mpir.alt {
// CHECK:             %[[VAR_3:.*]] = mpir.var "s$self" : <Instruction>
// CHECK:             %[[INST_1:.*]] = mpir.inst <add> capture %[[VAR_3]] (%[[TYPE_1]], %[[ALT_0]], %[[TYPE_1]], %[[VAR_2]]) <flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value], result_name = "s"> : (!mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:             %[[READ_1:.*]] = mpir_expr.read %[[VAR_3]] : (!mpir.sort<Instruction>) -> !mpir.sort<Value>
// CHECK:             %[[CALL_1:.*]] = mpir_expr.call call "hasOneUse"(%[[READ_1]]) anchor %[[INST_1]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:             mpir.require %[[CALL_1]] : <Boolean>
// CHECK:             mpir.yield %[[INST_1]] : <Instruction>
// CHECK:           } <result_name = "s"> : <Instruction>
} loc("expand-matchers.mlir":876:1)
// CHECK:         }

// -----

// ':o' on a use: its operand may stand for the use, bound to the capture.
mpir.matcher @addOrSub <supported_flags = [], syntax = binary, arity = 2, param_names = ["ty", "a", "b"], param_is_type = [true, false, false]> {
// CHECK-LABEL:   mpir.matcher @addOrSub <supported_flags = [], syntax = binary, arity = 2, param_names = ["ty", "a", "b"], param_is_type = [true, false, false]> {
  %ty = mpir.var "ty" : <Type> loc("expand-matchers.mlir":884:1)
// CHECK:           %[[VAR_0:.*]] = mpir.var "ty" : <Type>
  mpir.signature %ty : !mpir.sort<Type> loc("expand-matchers.mlir":886:1)
// CHECK:           mpir.signature %[[VAR_0]] : !mpir.sort<Type>
  mpir.branch <param_args = [0, 1, 2], fixed_flags = [], fixed_flag_values = []> {
// CHECK:           mpir.branch <fixed_flags = [], param_args = [0, 1, 2], fixed_flag_values = []> {
// CHECK:           ^bb0(%[[VAL_0:.*]]: !mpir.sort<Type>, %[[VAL_1:.*]]: !mpir.sort<Operand>, %[[VAL_2:.*]]: !mpir.sort<Operand>):
  ^bb0(%arg0: !mpir.sort<Type>, %arg1: !mpir.sort<Operand>, %arg2: !mpir.sort<Operand>):
    %i_ret = mpir.inst <add> (%arg0, %arg1, %arg0, %arg2) <result_name = "ret", flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction> loc("expand-matchers.mlir":892:1)
// CHECK:             %[[INST_0:.*]] = mpir.inst <add> (%[[VAL_0]], %[[VAL_1]], %[[VAL_0]], %[[VAL_2]]) <flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value], result_name = "ret"> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
    mpir.yield %i_ret : <Instruction> loc("expand-matchers.mlir":894:1)
// CHECK:             mpir.yield %[[INST_0]] : <Instruction>
  } loc("expand-matchers.mlir":896:1)
// CHECK:           }
  mpir.branch <param_args = [0, 1, 2], fixed_flags = [], fixed_flag_values = []> {
// CHECK:           mpir.branch <fixed_flags = [], param_args = [0, 1, 2], fixed_flag_values = []> {
// CHECK:           ^bb0(%[[VAL_3:.*]]: !mpir.sort<Type>, %[[VAL_4:.*]]: !mpir.sort<Operand>, %[[VAL_5:.*]]: !mpir.sort<Operand>):
  ^bb0(%arg0: !mpir.sort<Type>, %arg1: !mpir.sort<Operand>, %arg2: !mpir.sort<Operand>):
    %i_ret = mpir.inst <sub> (%arg0, %arg1, %arg0, %arg2) <result_name = "ret", flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction> loc("expand-matchers.mlir":902:1)
// CHECK:             %[[INST_1:.*]] = mpir.inst <sub> (%[[VAL_3]], %[[VAL_4]], %[[VAL_3]], %[[VAL_5]]) <flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value], result_name = "ret"> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
    mpir.yield %i_ret : <Instruction> loc("expand-matchers.mlir":904:1)
// CHECK:             mpir.yield %[[INST_1]] : <Instruction>
  } loc("expand-matchers.mlir":906:1)
// CHECK:           }
} loc("expand-matchers.mlir":908:1)
// CHECK:         }
mpir.pattern {
// CHECK-LABEL:   mpir.pattern {
  %c = mpir.var "c" : <Instruction> loc("expand-matchers.mlir":912:1)
// CHECK:           %[[VAR_0:.*]] = mpir.var "c" : <Instruction>
  %0 = mpir.type.int 32 : <Type> loc("expand-matchers.mlir":914:1)
// CHECK:           %[[TYPE_0:.*]] = mpir.type.int 32 : <Type>
  %1 = mpir.int 0 : ui1 : <Value> loc("expand-matchers.mlir":916:1)
// CHECK:           %[[INT_0:.*]] = mpir.int 0 : ui1 : <Value>
  %y = mpir.var "y" : <Operand> loc("expand-matchers.mlir":918:1)
// CHECK:           %[[VAR_1:.*]] = mpir.var "y" : <Operand>
// CHECK:           %[[ALT_0:.*]] = mpir.alt {
  %u_r = mpir.use @addOrSub capture %c (%0, %1, %0, %y) <result_name = "r", flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value], metaflags = [#mpir.metaflag<"o", [1], loc("expand-matchers.mlir":921:1)>]> : (!mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Value>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:             %[[INST_0:.*]] = mpir.inst <add> capture %[[VAR_0]] (%[[TYPE_0]], %[[INT_0]], %[[TYPE_0]], %[[VAR_1]]) <flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value], result_name = "r"> : (!mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Value>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:             mpir.yield %[[INST_0]] : <Instruction>
// CHECK:           }, {
// CHECK:             %[[INST_1:.*]] = mpir.inst <sub> capture %[[VAR_0]] (%[[TYPE_0]], %[[INT_0]], %[[TYPE_0]], %[[VAR_1]]) <flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value], result_name = "r"> : (!mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Value>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:             mpir.yield %[[INST_1]] : <Instruction>
// CHECK:           }, {
// CHECK:             mpir.bind %[[VAR_0]], %[[VAR_1]] : <Instruction>, <Operand>
// CHECK:             mpir.yield %[[VAR_1]] : <Operand>
// CHECK:           } <result_name = "r"> : <Instruction>
  %2 = mpir.type.int 32 : <Type> loc("expand-matchers.mlir":931:1)
// CHECK:           %[[TYPE_1:.*]] = mpir.type.int 32 : <Type>
  %3 = mpir.int 1 : ui1 : <Value> loc("expand-matchers.mlir":933:1)
// CHECK:           %[[INT_1:.*]] = mpir.int 1 : ui1 : <Value>
// CHECK:           %[[ALT_1:.*]] = mpir.alt {
  %u_s = mpir.use @addOrSub (%2, %u_r, %2, %3) <result_name = "s", flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value], metaflags = [#mpir.metaflag<"o", [], loc("expand-matchers.mlir":936:1)>]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
// CHECK:             %[[INST_2:.*]] = mpir.inst <add> (%[[TYPE_1]], %[[ALT_0]], %[[TYPE_1]], %[[INT_1]]) <flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value], result_name = "s"> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
// CHECK:             mpir.yield %[[INST_2]] : <Instruction>
// CHECK:           }, {
// CHECK:             %[[INST_3:.*]] = mpir.inst <sub> (%[[TYPE_1]], %[[ALT_0]], %[[TYPE_1]], %[[INT_1]]) <flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value], result_name = "s"> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
// CHECK:             mpir.yield %[[INST_3]] : <Instruction>
// CHECK:           }, {
// CHECK:             mpir.yield %[[ALT_0]] : <Instruction>
// CHECK:           } <result_name = "s"> : <Instruction>
} loc("expand-matchers.mlir":945:1)
// CHECK:         }

// -----

// The use's block and setting go to the instructions of the branch.
mpir.matcher @addOrSub <supported_flags = [], syntax = binary, arity = 2, param_names = ["ty", "a", "b"], param_is_type = [true, false, false]> {
// CHECK-LABEL:   mpir.matcher @addOrSub <supported_flags = [], syntax = binary, arity = 2, param_names = ["ty", "a", "b"], param_is_type = [true, false, false]> {
  %ty = mpir.var "ty" : <Type> loc("expand-matchers.mlir":953:1)
// CHECK:           %[[VAR_0:.*]] = mpir.var "ty" : <Type>
  mpir.signature %ty : !mpir.sort<Type> loc("expand-matchers.mlir":955:1)
// CHECK:           mpir.signature %[[VAR_0]] : !mpir.sort<Type>
  mpir.branch <param_args = [0, 1, 2], fixed_flags = [], fixed_flag_values = []> {
// CHECK:           mpir.branch <fixed_flags = [], param_args = [0, 1, 2], fixed_flag_values = []> {
// CHECK:           ^bb0(%[[VAL_0:.*]]: !mpir.sort<Type>, %[[VAL_1:.*]]: !mpir.sort<Operand>, %[[VAL_2:.*]]: !mpir.sort<Operand>):
  ^bb0(%arg0: !mpir.sort<Type>, %arg1: !mpir.sort<Operand>, %arg2: !mpir.sort<Operand>):
    %i_ret = mpir.inst <add> (%arg0, %arg1, %arg0, %arg2) <result_name = "ret", flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction> loc("expand-matchers.mlir":961:1)
// CHECK:             %[[INST_0:.*]] = mpir.inst <add> (%[[VAL_0]], %[[VAL_1]], %[[VAL_0]], %[[VAL_2]]) <flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value], result_name = "ret"> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
    mpir.yield %i_ret : <Instruction> loc("expand-matchers.mlir":963:1)
// CHECK:             mpir.yield %[[INST_0]] : <Instruction>
  } loc("expand-matchers.mlir":965:1)
// CHECK:           }
  mpir.branch <param_args = [0, 1, 2], fixed_flags = [], fixed_flag_values = []> {
// CHECK:           mpir.branch <fixed_flags = [], param_args = [0, 1, 2], fixed_flag_values = []> {
// CHECK:           ^bb0(%[[VAL_3:.*]]: !mpir.sort<Type>, %[[VAL_4:.*]]: !mpir.sort<Operand>, %[[VAL_5:.*]]: !mpir.sort<Operand>):
  ^bb0(%arg0: !mpir.sort<Type>, %arg1: !mpir.sort<Operand>, %arg2: !mpir.sort<Operand>):
    %i_ret = mpir.inst <sub> (%arg0, %arg1, %arg0, %arg2) <result_name = "ret", flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction> loc("expand-matchers.mlir":971:1)
// CHECK:             %[[INST_1:.*]] = mpir.inst <sub> (%[[VAL_3]], %[[VAL_4]], %[[VAL_3]], %[[VAL_5]]) <flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value], result_name = "ret"> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
    mpir.yield %i_ret : <Instruction> loc("expand-matchers.mlir":973:1)
// CHECK:             mpir.yield %[[INST_1]] : <Instruction>
  } loc("expand-matchers.mlir":975:1)
// CHECK:           }
} loc("expand-matchers.mlir":977:1)
// CHECK:         }
mpir.pattern {
// CHECK-LABEL:   mpir.pattern {
  %bb = mpir.var "bb" : <BasicBlock> loc("expand-matchers.mlir":981:1)
// CHECK:           %[[VAR_0:.*]] = mpir.var "bb" : <BasicBlock>
  %0 = mpir.type.int 32 : <Type> loc("expand-matchers.mlir":983:1)
// CHECK:           %[[TYPE_0:.*]] = mpir.type.int 32 : <Type>
  %x = mpir.var "x" : <Operand> loc("expand-matchers.mlir":985:1)
// CHECK:           %[[VAR_1:.*]] = mpir.var "x" : <Operand>
  %y = mpir.var "y" : <Operand> loc("expand-matchers.mlir":987:1)
// CHECK:           %[[VAR_2:.*]] = mpir.var "y" : <Operand>
// CHECK:           %[[ALT_0:.*]] = mpir.alt {
  %u_r = mpir.use @addOrSub block %bb (%0, %x, %0, %y) <result_name = "r", flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value], treat_int_as_vec = true> : (!mpir.sort<BasicBlock>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction> loc("expand-matchers.mlir":990:1)
// CHECK:             %[[INST_0:.*]] = mpir.inst <add> block %[[VAR_0]] (%[[TYPE_0]], %[[VAR_1]], %[[TYPE_0]], %[[VAR_2]]) <flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value], result_name = "r", treat_int_as_vec = true> : (!mpir.sort<BasicBlock>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:             mpir.yield %[[INST_0]] : <Instruction>
// CHECK:           }, {
// CHECK:             %[[INST_1:.*]] = mpir.inst <sub> block %[[VAR_0]] (%[[TYPE_0]], %[[VAR_1]], %[[TYPE_0]], %[[VAR_2]]) <flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value], result_name = "r", treat_int_as_vec = true> : (!mpir.sort<BasicBlock>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:             mpir.yield %[[INST_1]] : <Instruction>
// CHECK:           } <result_name = "r"> : <Instruction>
} loc("expand-matchers.mlir":997:1)
// CHECK:         }

// -----

// Metaflags in a branch and on the use, already constraints: the branch's
// are in its region, and read the root by the use's capture.
mpir.matcher @addz <supported_flags = [], syntax = binary, arity = 2, param_names = ["ty", "a", "b"], param_is_type = [true, false, false]> {
// CHECK-LABEL:   mpir.matcher @addz <supported_flags = [], syntax = binary, arity = 2, param_names = ["ty", "a", "b"], param_is_type = [true, false, false]> {
  %ty = mpir.var "ty" : <Type> loc("expand-matchers.mlir":1006:1)
// CHECK:           %[[VAR_0:.*]] = mpir.var "ty" : <Type>
  mpir.signature %ty : !mpir.sort<Type> loc("expand-matchers.mlir":1008:1)
// CHECK:           mpir.signature %[[VAR_0]] : !mpir.sort<Type>
  mpir.branch <param_args = [0, 1, 2], fixed_flags = [], fixed_flag_values = []> {
// CHECK:           mpir.branch <fixed_flags = [], param_args = [0, 1, 2], fixed_flag_values = []> {
// CHECK:           ^bb0(%[[VAL_0:.*]]: !mpir.sort<Type>, %[[VAL_1:.*]]: !mpir.sort<Operand>, %[[VAL_2:.*]]: !mpir.sort<Operand>):
  ^bb0(%arg0: !mpir.sort<Type>, %arg1: !mpir.sort<Operand>, %arg2: !mpir.sort<Operand>):
    %i_ret = mpir.inst <add> (%arg0, %arg1, %arg0, %arg2) <result_name = "ret", flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction> loc("expand-matchers.mlir":1014:1)
// CHECK:             %[[INST_0:.*]] = mpir.inst <add> (%[[VAL_0]], %[[VAL_1]], %[[VAL_0]], %[[VAL_2]]) <flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value], result_name = "ret"> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
    %0 = mpir_expr.read %i_ret : (!mpir.sort<Instruction>) -> !mpir.sort<Value> loc("expand-matchers.mlir":1016:1)
// CHECK:             %[[READ_0:.*]] = mpir_expr.read %[[INST_0]] : (!mpir.sort<Instruction>) -> !mpir.sort<Value>
    %1 = mpir_expr.call call "hasOneUse"(%0) anchor %i_ret : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("expand-matchers.mlir":1018:1)
// CHECK:             %[[CALL_0:.*]] = mpir_expr.call call "hasOneUse"(%[[READ_0]]) anchor %[[INST_0]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
    mpir.require %1 <from_metaflag> : <Boolean> loc("expand-matchers.mlir":1020:1)
// CHECK:             mpir.require %[[CALL_0]] <from_metaflag> : <Boolean>
    %2 = mpir_expr.read %arg1 : (!mpir.sort<Operand>) -> !mpir.sort<Value> loc("expand-matchers.mlir":1022:1)
// CHECK:             %[[READ_1:.*]] = mpir_expr.read %[[VAL_1]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
    %3 = mpir_expr.call call "isZero"(%2) anchor %i_ret : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("expand-matchers.mlir":1024:1)
// CHECK:             %[[CALL_1:.*]] = mpir_expr.call call "isZero"(%[[READ_1]]) anchor %[[INST_0]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
    mpir.require %3 <from_metaflag> : <Boolean> loc("expand-matchers.mlir":1026:1)
// CHECK:             mpir.require %[[CALL_1]] <from_metaflag> : <Boolean>
    mpir.yield %i_ret : <Instruction> loc("expand-matchers.mlir":1028:1)
// CHECK:             mpir.yield %[[INST_0]] : <Instruction>
  } loc("expand-matchers.mlir":1030:1)
// CHECK:           }
} loc("expand-matchers.mlir":1032:1)
// CHECK:         }
mpir.pattern {
// CHECK-LABEL:   mpir.pattern {
  %c = mpir.var "c" : <Instruction> loc("expand-matchers.mlir":1036:1)
// CHECK:           %[[VAR_0:.*]] = mpir.var "c" : <Instruction>
  %0 = mpir.type.int 32 : <Type> loc("expand-matchers.mlir":1038:1)
// CHECK:           %[[TYPE_0:.*]] = mpir.type.int 32 : <Type>
  %x = mpir.var "x" : <Operand> loc("expand-matchers.mlir":1040:1)
// CHECK:           %[[VAR_1:.*]] = mpir.var "x" : <Operand>
  %y = mpir.var "y" : <Operand> loc("expand-matchers.mlir":1042:1)
// CHECK:           %[[VAR_2:.*]] = mpir.var "y" : <Operand>
  %u_r = mpir.use @addz capture %c (%0, %x, %0, %y) <result_name = "r", flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value]> : (!mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction> loc("expand-matchers.mlir":1044:1)
// CHECK:           %[[ALT_0:.*]] = mpir.alt {
// CHECK:             %[[INST_0:.*]] = mpir.inst <add> capture %[[VAR_0]] (%[[TYPE_0]], %[[VAR_1]], %[[TYPE_0]], %[[VAR_2]]) <flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value], result_name = "r"> : (!mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:             %[[READ_0:.*]] = mpir_expr.read %[[VAR_0]] : (!mpir.sort<Instruction>) -> !mpir.sort<Value>
// CHECK:             %[[CALL_0:.*]] = mpir_expr.call call "hasOneUse"(%[[READ_0]]) anchor %[[INST_0]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:             mpir.require %[[CALL_0]] <from_metaflag> : <Boolean>
// CHECK:             %[[READ_1:.*]] = mpir_expr.read %[[VAR_1]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
// CHECK:             %[[CALL_1:.*]] = mpir_expr.call call "isZero"(%[[READ_1]]) anchor %[[INST_0]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:             mpir.require %[[CALL_1]] <from_metaflag> : <Boolean>
// CHECK:             mpir.yield %[[INST_0]] : <Instruction>
// CHECK:           } <result_name = "r"> : <Instruction>
  %1 = mpir_expr.read %c : (!mpir.sort<Instruction>) -> !mpir.sort<Value> loc("expand-matchers.mlir":1055:1)
// CHECK:           %[[READ_2:.*]] = mpir_expr.read %[[VAR_0]] : (!mpir.sort<Instruction>) -> !mpir.sort<Value>
  %2 = mpir_expr.call call "hasOneUse"(%1) anchor %u_r : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("expand-matchers.mlir":1057:1)
// CHECK:           %[[CALL_2:.*]] = mpir_expr.call call "hasOneUse"(%[[READ_2]]) anchor %[[ALT_0]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
  mpir.require %2 <from_metaflag> : <Boolean> loc("expand-matchers.mlir":1059:1)
// CHECK:           mpir.require %[[CALL_2]] <from_metaflag> : <Boolean>
  %3 = mpir_expr.read %y : (!mpir.sort<Operand>) -> !mpir.sort<Value> loc("expand-matchers.mlir":1061:1)
// CHECK:           %[[READ_3:.*]] = mpir_expr.read %[[VAR_2]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
  %4 = mpir_expr.call call "isPower2"(%3) anchor %u_r : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("expand-matchers.mlir":1063:1)
// CHECK:           %[[CALL_3:.*]] = mpir_expr.call call "isPower2"(%[[READ_3]]) anchor %[[ALT_0]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
  mpir.require %4 <from_metaflag> : <Boolean> loc("expand-matchers.mlir":1065:1)
// CHECK:           mpir.require %[[CALL_3]] <from_metaflag> : <Boolean>
} loc("expand-matchers.mlir":1067:1)
// CHECK:         }

// -----

// A flag passed through two matchers: omitted in the outer use, it is
// omitted in the inner.
mpir.matcher @inner <supported_flags = [nsw], syntax = binary, arity = 2, param_names = ["ty", "a", "b"], param_is_type = [true, false, false]> {
// CHECK-LABEL:   mpir.matcher @inner <supported_flags = [nsw], syntax = binary, arity = 2, param_names = ["ty", "a", "b"], param_is_type = [true, false, false]> {
  %ty = mpir.var "ty" : <Type> loc("expand-matchers.mlir":1076:1)
// CHECK:           %[[VAR_0:.*]] = mpir.var "ty" : <Type>
  mpir.signature %ty : !mpir.sort<Type> loc("expand-matchers.mlir":1078:1)
// CHECK:           mpir.signature %[[VAR_0]] : !mpir.sort<Type>
  mpir.branch <param_args = [0, 1, 2], fixed_flags = [], fixed_flag_values = []> {
// CHECK:           mpir.branch <fixed_flags = [], param_args = [0, 1, 2], fixed_flag_values = []> {
// CHECK:           ^bb0(%[[VAL_0:.*]]: !mpir.sort<Type>, %[[VAL_1:.*]]: !mpir.sort<Operand>, %[[VAL_2:.*]]: !mpir.sort<Operand>):
  ^bb0(%arg0: !mpir.sort<Type>, %arg1: !mpir.sort<Operand>, %arg2: !mpir.sort<Operand>):
    %f = mpir.var "f" : <Boolean> loc("expand-matchers.mlir":1084:1)
// CHECK:             %[[VAR_1:.*]] = mpir.var "f" : <Boolean>
    %i_ret = mpir.inst <add> flags(%f) (%arg0, %arg1, %arg0, %arg2) <result_name = "ret", flags = [nsw], flag_modes = [captured], operand_kinds = [typed_value, typed_value]> : (!mpir.sort<Boolean>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction> loc("expand-matchers.mlir":1086:1)
// CHECK:             %[[INST_0:.*]] = mpir.inst <add> flags(%[[VAR_1]]) (%[[VAL_0]], %[[VAL_1]], %[[VAL_0]], %[[VAL_2]]) <flags = [nsw], flag_modes = [captured], operand_kinds = [typed_value, typed_value], result_name = "ret"> : (!mpir.sort<Boolean>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
    mpir.yield %i_ret : <Instruction> loc("expand-matchers.mlir":1088:1)
// CHECK:             mpir.yield %[[INST_0]] : <Instruction>
  } loc("expand-matchers.mlir":1090:1)
// CHECK:           }
} loc("expand-matchers.mlir":1092:1)
// CHECK:         }
mpir.matcher @outer <supported_flags = [nsw], syntax = binary, arity = 2, param_names = ["ty", "a", "b"], param_is_type = [true, false, false]> {
// CHECK-LABEL:   mpir.matcher @outer <supported_flags = [nsw], syntax = binary, arity = 2, param_names = ["ty", "a", "b"], param_is_type = [true, false, false]> {
  %ty = mpir.var "ty" : <Type> loc("expand-matchers.mlir":1096:1)
// CHECK:           %[[VAR_0:.*]] = mpir.var "ty" : <Type>
  mpir.signature %ty : !mpir.sort<Type> loc("expand-matchers.mlir":1098:1)
// CHECK:           mpir.signature %[[VAR_0]] : !mpir.sort<Type>
  mpir.branch <param_args = [0, 1, 2], fixed_flags = [], fixed_flag_values = []> {
// CHECK:           mpir.branch <fixed_flags = [], param_args = [0, 1, 2], fixed_flag_values = []> {
// CHECK:           ^bb0(%[[VAL_0:.*]]: !mpir.sort<Type>, %[[VAL_1:.*]]: !mpir.sort<Operand>, %[[VAL_2:.*]]: !mpir.sort<Operand>):
  ^bb0(%arg0: !mpir.sort<Type>, %arg1: !mpir.sort<Operand>, %arg2: !mpir.sort<Operand>):
    %g = mpir.var "g" : <Boolean> loc("expand-matchers.mlir":1104:1)
// CHECK:             %[[VAR_1:.*]] = mpir.var "g" : <Boolean>
    %u_ret = mpir.use @inner flags(%g) (%arg0, %arg1, %arg0, %arg2) <result_name = "ret", flags = [nsw], flag_modes = [captured], operand_kinds = [typed_value, typed_value]> : (!mpir.sort<Boolean>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction> loc("expand-matchers.mlir":1106:1)
// CHECK:             %[[USE_0:.*]] = mpir.use @inner flags(%[[VAR_1]]) (%[[VAL_0]], %[[VAL_1]], %[[VAL_0]], %[[VAL_2]]) <flags = [nsw], flag_modes = [captured], operand_kinds = [typed_value, typed_value], result_name = "ret"> : (!mpir.sort<Boolean>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
    mpir.yield %u_ret : <Instruction> loc("expand-matchers.mlir":1108:1)
// CHECK:             mpir.yield %[[USE_0]] : <Instruction>
  } loc("expand-matchers.mlir":1110:1)
// CHECK:           }
} loc("expand-matchers.mlir":1112:1)
// CHECK:         }
mpir.pattern {
// CHECK-LABEL:   mpir.pattern {
  %0 = mpir.type.int 32 : <Type> loc("expand-matchers.mlir":1116:1)
// CHECK:           %[[TYPE_0:.*]] = mpir.type.int 32 : <Type>
  %x = mpir.var "x" : <Operand> loc("expand-matchers.mlir":1118:1)
// CHECK:           %[[VAR_0:.*]] = mpir.var "x" : <Operand>
  %y = mpir.var "y" : <Operand> loc("expand-matchers.mlir":1120:1)
// CHECK:           %[[VAR_1:.*]] = mpir.var "y" : <Operand>
  %u_r = mpir.use @outer (%0, %x, %0, %y) <result_name = "r", flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction> loc("expand-matchers.mlir":1122:1)
// CHECK:           %[[VAR_2:.*]] = mpir.var "_flag$r$nsw" : <Boolean>
// CHECK:           %[[ALT_0:.*]] = mpir.alt {
// CHECK:             %[[ALT_1:.*]] = mpir.alt {
// CHECK:               %[[INST_0:.*]] = mpir.inst <add> flags(%[[VAR_2]]) (%[[TYPE_0]], %[[VAR_0]], %[[TYPE_0]], %[[VAR_1]]) <flags = [nsw], flag_modes = [captured], operand_kinds = [typed_value, typed_value], result_name = "r"> : (!mpir.sort<Boolean>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:               mpir.yield %[[INST_0]] : <Instruction>
// CHECK:             } <result_name = "r"> : <Instruction>
// CHECK:             mpir.yield %[[ALT_1]] : <Instruction>
// CHECK:           } <result_name = "r"> : <Instruction>
  %1 = mpir.type.int 32 : <Type> loc("expand-matchers.mlir":1131:1)
// CHECK:           %[[TYPE_1:.*]] = mpir.type.int 32 : <Type>
  %u_s = mpir.use @outer (%1, %u_r, %1, %y) <result_name = "s", flags = [nsw], flag_modes = [required], operand_kinds = [typed_value, typed_value]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction> loc("expand-matchers.mlir":1133:1)
// CHECK:           %[[INT_0:.*]] = mpir.int 1 : ui1 : <Value>
// CHECK:           %[[ALT_2:.*]] = mpir.alt {
// CHECK:             %[[INT_1:.*]] = mpir.int 1 : ui1 : <Value>
// CHECK:             %[[ALT_3:.*]] = mpir.alt {
// CHECK:               %[[INST_1:.*]] = mpir.inst <add> (%[[TYPE_1]], %[[ALT_0]], %[[TYPE_1]], %[[VAR_1]]) <flags = [nsw], flag_modes = [required], operand_kinds = [typed_value, typed_value], result_name = "s"> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:               mpir.yield %[[INST_1]] : <Instruction>
// CHECK:             } <result_name = "s"> : <Instruction>
// CHECK:             mpir.yield %[[ALT_3]] : <Instruction>
// CHECK:           } <result_name = "s"> : <Instruction>
} loc("expand-matchers.mlir":1143:1)
// CHECK:         }

// -----

// A fixed parameter type of another width, or of another shape, than the
// use's: no branch fits.
mpir.matcher @pick <supported_flags = [], syntax = nary, arity = 3, param_names = ["", "c", "", "t", "", "f"], param_is_type = [true, false, true, false, true, false]> {
// CHECK-LABEL:   mpir.matcher @pick <supported_flags = [], syntax = nary, arity = 3, param_names = ["", "c", "", "t", "", "f"], param_is_type = [true, false, true, false, true, false]> {
  %0 = mpir.type.int 1 : <Type> loc("expand-matchers.mlir":1152:1)
// CHECK:           %[[TYPE_0:.*]] = mpir.type.int 1 : <Type>
  %1 = mpir.type.int 8 : <Type> loc("expand-matchers.mlir":1154:1)
// CHECK:           %[[TYPE_1:.*]] = mpir.type.int 8 : <Type>
  %2 = mpir.type.seq array 4 x %1 : (!mpir.sort<Type>) -> !mpir.sort<Type> loc("expand-matchers.mlir":1156:1)
// CHECK:           %[[TYPE_2:.*]] = mpir.type.seq array 4 x %[[TYPE_1]] : (!mpir.sort<Type>) -> !mpir.sort<Type>
  %3 = mpir.type.int 8 : <Type> loc("expand-matchers.mlir":1158:1)
// CHECK:           %[[TYPE_3:.*]] = mpir.type.int 8 : <Type>
  %4 = mpir.type.int 8 : <Type> loc("expand-matchers.mlir":1160:1)
// CHECK:           %[[TYPE_4:.*]] = mpir.type.int 8 : <Type>
  %5 = mpir.type.struct{%3, %4} : (!mpir.sort<Type>, !mpir.sort<Type>) -> !mpir.sort<Type> loc("expand-matchers.mlir":1162:1)
// CHECK:           %[[TYPE_5:.*]] = mpir.type.struct{%[[TYPE_3]], %[[TYPE_4]]} : (!mpir.sort<Type>, !mpir.sort<Type>) -> !mpir.sort<Type>
  mpir.signature %0, %2, %5 : !mpir.sort<Type>, !mpir.sort<Type>, !mpir.sort<Type> loc("expand-matchers.mlir":1164:1)
// CHECK:           mpir.signature %[[TYPE_0]], %[[TYPE_2]], %[[TYPE_5]] : !mpir.sort<Type>, !mpir.sort<Type>, !mpir.sort<Type>
  mpir.branch <param_args = [-1, 0, -1, 1, -1, 2], fixed_flags = [], fixed_flag_values = []> {
// CHECK:           mpir.branch <fixed_flags = [], param_args = [-1, 0, -1, 1, -1, 2], fixed_flag_values = []> {
// CHECK:           ^bb0(%[[VAL_0:.*]]: !mpir.sort<Boolean>, %[[VAL_1:.*]]: !mpir.sort<Operand>, %[[VAL_2:.*]]: !mpir.sort<Unknown>):
  ^bb0(%arg0: !mpir.sort<Boolean>, %arg1: !mpir.sort<Operand>, %arg2: !mpir.sort<Unknown>):
    %6 = mpir.type.int 1 : <Type> loc("expand-matchers.mlir":1170:1)
// CHECK:             %[[TYPE_6:.*]] = mpir.type.int 1 : <Type>
    %7 = mpir.type.int 8 : <Type> loc("expand-matchers.mlir":1172:1)
// CHECK:             %[[TYPE_7:.*]] = mpir.type.int 8 : <Type>
    %8 = mpir.type.seq array 4 x %7 : (!mpir.sort<Type>) -> !mpir.sort<Type> loc("expand-matchers.mlir":1174:1)
// CHECK:             %[[TYPE_8:.*]] = mpir.type.seq array 4 x %[[TYPE_7]] : (!mpir.sort<Type>) -> !mpir.sort<Type>
    %9 = mpir.type.int 8 : <Type> loc("expand-matchers.mlir":1176:1)
// CHECK:             %[[TYPE_9:.*]] = mpir.type.int 8 : <Type>
    %10 = mpir.type.seq array 4 x %9 : (!mpir.sort<Type>) -> !mpir.sort<Type> loc("expand-matchers.mlir":1178:1)
// CHECK:             %[[TYPE_10:.*]] = mpir.type.seq array 4 x %[[TYPE_9]] : (!mpir.sort<Type>) -> !mpir.sort<Type>
    %i_ret = mpir.inst <select> (%6, %arg0, %8, %arg1, %10, %arg1) <result_name = "ret", flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value, typed_value]> : (!mpir.sort<Type>, !mpir.sort<Boolean>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction> loc("expand-matchers.mlir":1180:1)
// CHECK:             %[[INST_0:.*]] = mpir.inst <select> (%[[TYPE_6]], %[[VAL_0]], %[[TYPE_8]], %[[VAL_1]], %[[TYPE_10]], %[[VAL_1]]) <flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value, typed_value], result_name = "ret"> : (!mpir.sort<Type>, !mpir.sort<Boolean>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
    mpir.yield %i_ret : <Instruction> loc("expand-matchers.mlir":1182:1)
// CHECK:             mpir.yield %[[INST_0]] : <Instruction>
  } loc("expand-matchers.mlir":1184:1)
// CHECK:           }
} loc("expand-matchers.mlir":1186:1)
// CHECK:         }
mpir.pattern {
// CHECK-LABEL:   mpir.pattern {
  %0 = mpir.type.int 8 : <Type> loc("expand-matchers.mlir":1190:1)
// CHECK:           %[[TYPE_0:.*]] = mpir.type.int 8 : <Type>
  %cond = mpir.var "cond" : <Boolean> loc("expand-matchers.mlir":1192:1)
// CHECK:           %[[VAR_0:.*]] = mpir.var "cond" : <Boolean>
  %1 = mpir.type.int 8 : <Type> loc("expand-matchers.mlir":1194:1)
// CHECK:           %[[TYPE_1:.*]] = mpir.type.int 8 : <Type>
  %2 = mpir.type.seq array 4 x %1 : (!mpir.sort<Type>) -> !mpir.sort<Type> loc("expand-matchers.mlir":1196:1)
// CHECK:           %[[TYPE_2:.*]] = mpir.type.seq array 4 x %[[TYPE_1]] : (!mpir.sort<Type>) -> !mpir.sort<Type>
  %a = mpir.var "a" : <Operand> loc("expand-matchers.mlir":1198:1)
// CHECK:           %[[VAR_1:.*]] = mpir.var "a" : <Operand>
  %3 = mpir.type.int 8 : <Type> loc("expand-matchers.mlir":1200:1)
// CHECK:           %[[TYPE_3:.*]] = mpir.type.int 8 : <Type>
  %4 = mpir.type.int 8 : <Type> loc("expand-matchers.mlir":1202:1)
// CHECK:           %[[TYPE_4:.*]] = mpir.type.int 8 : <Type>
  %5 = mpir.type.struct{%3, %4} : (!mpir.sort<Type>, !mpir.sort<Type>) -> !mpir.sort<Type> loc("expand-matchers.mlir":1204:1)
// CHECK:           %[[TYPE_5:.*]] = mpir.type.struct{%[[TYPE_3]], %[[TYPE_4]]} : (!mpir.sort<Type>, !mpir.sort<Type>) -> !mpir.sort<Type>
  %b = mpir.var "b" : <Operand> loc("expand-matchers.mlir":1206:1)
// CHECK:           %[[VAR_2:.*]] = mpir.var "b" : <Operand>
  %u_r = mpir.use @pick (%0, %cond, %2, %a, %5, %b) <result_name = "r", flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value, typed_value]> : (!mpir.sort<Type>, !mpir.sort<Boolean>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction> loc("expand-matchers.mlir":1208:1)
// CHECK:           %[[ALT_0:.*]] = mpir.alt  <result_name = "r"> : <Instruction>
  %6 = mpir.type.int 1 : <Type> loc("expand-matchers.mlir":1210:1)
// CHECK:           %[[TYPE_6:.*]] = mpir.type.int 1 : <Type>
  %7 = mpir.type.int 8 : <Type> loc("expand-matchers.mlir":1212:1)
// CHECK:           %[[TYPE_7:.*]] = mpir.type.int 8 : <Type>
  %8 = mpir.type.seq array 8 x %7 : (!mpir.sort<Type>) -> !mpir.sort<Type> loc("expand-matchers.mlir":1214:1)
// CHECK:           %[[TYPE_8:.*]] = mpir.type.seq array 8 x %[[TYPE_7]] : (!mpir.sort<Type>) -> !mpir.sort<Type>
  %9 = mpir.type.int 8 : <Type> loc("expand-matchers.mlir":1216:1)
// CHECK:           %[[TYPE_9:.*]] = mpir.type.int 8 : <Type>
  %10 = mpir.type.int 8 : <Type> loc("expand-matchers.mlir":1218:1)
// CHECK:           %[[TYPE_10:.*]] = mpir.type.int 8 : <Type>
  %11 = mpir.type.struct{%9, %10} : (!mpir.sort<Type>, !mpir.sort<Type>) -> !mpir.sort<Type> loc("expand-matchers.mlir":1220:1)
// CHECK:           %[[TYPE_11:.*]] = mpir.type.struct{%[[TYPE_9]], %[[TYPE_10]]} : (!mpir.sort<Type>, !mpir.sort<Type>) -> !mpir.sort<Type>
  %u_s = mpir.use @pick (%6, %cond, %8, %a, %11, %b) <result_name = "s", flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value, typed_value]> : (!mpir.sort<Type>, !mpir.sort<Boolean>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction> loc("expand-matchers.mlir":1222:1)
// CHECK:           %[[ALT_1:.*]] = mpir.alt  <result_name = "s"> : <Instruction>
  %12 = mpir.type.int 1 : <Type> loc("expand-matchers.mlir":1224:1)
// CHECK:           %[[TYPE_12:.*]] = mpir.type.int 1 : <Type>
  %13 = mpir.type.int 8 : <Type> loc("expand-matchers.mlir":1226:1)
// CHECK:           %[[TYPE_13:.*]] = mpir.type.int 8 : <Type>
  %14 = mpir.type.seq array 4 x %13 : (!mpir.sort<Type>) -> !mpir.sort<Type> loc("expand-matchers.mlir":1228:1)
// CHECK:           %[[TYPE_14:.*]] = mpir.type.seq array 4 x %[[TYPE_13]] : (!mpir.sort<Type>) -> !mpir.sort<Type>
  %15 = mpir.type.int 8 : <Type> loc("expand-matchers.mlir":1230:1)
// CHECK:           %[[TYPE_15:.*]] = mpir.type.int 8 : <Type>
  %16 = mpir.type.struct{%15} : (!mpir.sort<Type>) -> !mpir.sort<Type> loc("expand-matchers.mlir":1232:1)
// CHECK:           %[[TYPE_16:.*]] = mpir.type.struct{%[[TYPE_15]]} : (!mpir.sort<Type>) -> !mpir.sort<Type>
  %u_t = mpir.use @pick (%12, %cond, %14, %a, %16, %b) <result_name = "t", flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value, typed_value]> : (!mpir.sort<Type>, !mpir.sort<Boolean>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction> loc("expand-matchers.mlir":1234:1)
// CHECK:           %[[ALT_2:.*]] = mpir.alt  <result_name = "t"> : <Instruction>
  %17 = mpir.type.int 1 : <Type> loc("expand-matchers.mlir":1236:1)
// CHECK:           %[[TYPE_17:.*]] = mpir.type.int 1 : <Type>
  %18 = mpir.type.int 16 : <Type> loc("expand-matchers.mlir":1238:1)
// CHECK:           %[[TYPE_18:.*]] = mpir.type.int 16 : <Type>
  %19 = mpir.type.seq array 4 x %18 : (!mpir.sort<Type>) -> !mpir.sort<Type> loc("expand-matchers.mlir":1240:1)
// CHECK:           %[[TYPE_19:.*]] = mpir.type.seq array 4 x %[[TYPE_18]] : (!mpir.sort<Type>) -> !mpir.sort<Type>
  %20 = mpir.type.int 8 : <Type> loc("expand-matchers.mlir":1242:1)
// CHECK:           %[[TYPE_20:.*]] = mpir.type.int 8 : <Type>
  %21 = mpir.type.int 8 : <Type> loc("expand-matchers.mlir":1244:1)
// CHECK:           %[[TYPE_21:.*]] = mpir.type.int 8 : <Type>
  %22 = mpir.type.struct{%20, %21} : (!mpir.sort<Type>, !mpir.sort<Type>) -> !mpir.sort<Type> loc("expand-matchers.mlir":1246:1)
// CHECK:           %[[TYPE_22:.*]] = mpir.type.struct{%[[TYPE_20]], %[[TYPE_21]]} : (!mpir.sort<Type>, !mpir.sort<Type>) -> !mpir.sort<Type>
  %u_u = mpir.use @pick (%17, %cond, %19, %a, %22, %b) <result_name = "u", flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value, typed_value]> : (!mpir.sort<Type>, !mpir.sort<Boolean>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction> loc("expand-matchers.mlir":1248:1)
// CHECK:           %[[ALT_3:.*]] = mpir.alt  <result_name = "u"> : <Instruction>
  %23 = mpir.type.int 1 : <Type> loc("expand-matchers.mlir":1250:1)
// CHECK:           %[[TYPE_23:.*]] = mpir.type.int 1 : <Type>
  %24 = mpir.type.int 8 : <Type> loc("expand-matchers.mlir":1252:1)
// CHECK:           %[[TYPE_24:.*]] = mpir.type.int 8 : <Type>
  %25 = mpir.type.seq array 4 x %24 : (!mpir.sort<Type>) -> !mpir.sort<Type> loc("expand-matchers.mlir":1254:1)
// CHECK:           %[[TYPE_25:.*]] = mpir.type.seq array 4 x %[[TYPE_24]] : (!mpir.sort<Type>) -> !mpir.sort<Type>
  %26 = mpir.type.int 8 : <Type> loc("expand-matchers.mlir":1256:1)
// CHECK:           %[[TYPE_26:.*]] = mpir.type.int 8 : <Type>
  %27 = mpir.type.int 8 : <Type> loc("expand-matchers.mlir":1258:1)
// CHECK:           %[[TYPE_27:.*]] = mpir.type.int 8 : <Type>
  %28 = mpir.type.struct{%26, %27} : (!mpir.sort<Type>, !mpir.sort<Type>) -> !mpir.sort<Type> loc("expand-matchers.mlir":1260:1)
// CHECK:           %[[TYPE_28:.*]] = mpir.type.struct{%[[TYPE_26]], %[[TYPE_27]]} : (!mpir.sort<Type>, !mpir.sort<Type>) -> !mpir.sort<Type>
  %u_v = mpir.use @pick (%23, %cond, %25, %a, %28, %b) <result_name = "v", flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value, typed_value]> : (!mpir.sort<Type>, !mpir.sort<Boolean>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction> loc("expand-matchers.mlir":1262:1)
// CHECK:           %[[ALT_4:.*]] = mpir.alt {
// CHECK:             %[[TYPE_29:.*]] = mpir.type.int 1 : <Type>
// CHECK:             %[[TYPE_30:.*]] = mpir.type.int 8 : <Type>
// CHECK:             %[[TYPE_31:.*]] = mpir.type.seq array 4 x %[[TYPE_30]] : (!mpir.sort<Type>) -> !mpir.sort<Type>
// CHECK:             %[[TYPE_32:.*]] = mpir.type.int 8 : <Type>
// CHECK:             %[[TYPE_33:.*]] = mpir.type.seq array 4 x %[[TYPE_32]] : (!mpir.sort<Type>) -> !mpir.sort<Type>
// CHECK:             %[[INST_0:.*]] = mpir.inst <select> (%[[TYPE_29]], %[[VAR_0]], %[[TYPE_31]], %[[VAR_1]], %[[TYPE_33]], %[[VAR_1]]) <flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value, typed_value], result_name = "v"> : (!mpir.sort<Type>, !mpir.sort<Boolean>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:             mpir.yield %[[INST_0]] : <Instruction>
// CHECK:           } <result_name = "v"> : <Instruction>
} loc("expand-matchers.mlir":1272:1)
// CHECK:         }

// -----

// Flags of a branch's other instructions, and those of its root the
// matcher does not declare, stay as written.
mpir.matcher @shifted <supported_flags = [exact], syntax = binary, arity = 2, param_names = ["ty", "a", "b"], param_is_type = [true, false, false]> {
// CHECK-LABEL:   mpir.matcher @shifted <supported_flags = [exact], syntax = binary, arity = 2, param_names = ["ty", "a", "b"], param_is_type = [true, false, false]> {
  %ty = mpir.var "ty" : <Type> loc("expand-matchers.mlir":1281:1)
// CHECK:           %[[VAR_0:.*]] = mpir.var "ty" : <Type>
  mpir.signature %ty : !mpir.sort<Type> loc("expand-matchers.mlir":1283:1)
// CHECK:           mpir.signature %[[VAR_0]] : !mpir.sort<Type>
  mpir.branch <param_args = [0, 1, 2], fixed_flags = [], fixed_flag_values = []> {
// CHECK:           mpir.branch <fixed_flags = [], param_args = [0, 1, 2], fixed_flag_values = []> {
// CHECK:           ^bb0(%[[VAL_0:.*]]: !mpir.sort<Type>, %[[VAL_1:.*]]: !mpir.sort<Operand>, %[[VAL_2:.*]]: !mpir.sort<Operand>):
  ^bb0(%arg0: !mpir.sort<Type>, %arg1: !mpir.sort<Operand>, %arg2: !mpir.sort<Operand>):
    %u = mpir.var "u" : <Boolean> loc("expand-matchers.mlir":1289:1)
// CHECK:             %[[VAR_1:.*]] = mpir.var "u" : <Boolean>
    %i_s = mpir.inst <shl> flags(%u) (%arg0, %arg1, %arg0, %arg2) <result_name = "s", flags = [nsw, nuw], flag_modes = [required, captured], operand_kinds = [typed_value, typed_value]> : (!mpir.sort<Boolean>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction> loc("expand-matchers.mlir":1291:1)
// CHECK:             %[[INST_0:.*]] = mpir.inst <shl> flags(%[[VAR_1]]) (%[[VAL_0]], %[[VAL_1]], %[[VAL_0]], %[[VAL_2]]) <flags = [nsw, nuw], flag_modes = [required, captured], operand_kinds = [typed_value, typed_value], result_name = "s"> : (!mpir.sort<Boolean>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
    %e = mpir.var "e" : <Boolean> loc("expand-matchers.mlir":1293:1)
// CHECK:             %[[VAR_2:.*]] = mpir.var "e" : <Boolean>
    %i_ret = mpir.inst <lshr> flags(%e) (%arg0, %i_s, %arg0, %arg2) <result_name = "ret", flags = [exact], flag_modes = [captured], operand_kinds = [typed_value, typed_value]> : (!mpir.sort<Boolean>, !mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction> loc("expand-matchers.mlir":1295:1)
// CHECK:             %[[INST_1:.*]] = mpir.inst <lshr> flags(%[[VAR_2]]) (%[[VAL_0]], %[[INST_0]], %[[VAL_0]], %[[VAL_2]]) <flags = [exact], flag_modes = [captured], operand_kinds = [typed_value, typed_value], result_name = "ret"> : (!mpir.sort<Boolean>, !mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
    mpir.yield %i_ret : <Instruction> loc("expand-matchers.mlir":1297:1)
// CHECK:             mpir.yield %[[INST_1]] : <Instruction>
  } loc("expand-matchers.mlir":1299:1)
// CHECK:           }
  mpir.branch <param_args = [0, 1, 2], fixed_flags = [], fixed_flag_values = []> {
// CHECK:           mpir.branch <fixed_flags = [], param_args = [0, 1, 2], fixed_flag_values = []> {
// CHECK:           ^bb0(%[[VAL_3:.*]]: !mpir.sort<Type>, %[[VAL_4:.*]]: !mpir.sort<Operand>, %[[VAL_5:.*]]: !mpir.sort<Operand>):
  ^bb0(%arg0: !mpir.sort<Type>, %arg1: !mpir.sort<Operand>, %arg2: !mpir.sort<Operand>):
    %w = mpir.var "w" : <Boolean> loc("expand-matchers.mlir":1305:1)
// CHECK:             %[[VAR_3:.*]] = mpir.var "w" : <Boolean>
    %i_s = mpir.inst <add> flags(%w) (%arg0, %arg1, %arg0, %arg2) <result_name = "s", flags = [nsw], flag_modes = [captured], operand_kinds = [typed_value, typed_value]> : (!mpir.sort<Boolean>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction> loc("expand-matchers.mlir":1307:1)
// CHECK:             %[[INST_2:.*]] = mpir.inst <add> flags(%[[VAR_3]]) (%[[VAL_3]], %[[VAL_4]], %[[VAL_3]], %[[VAL_5]]) <flags = [nsw], flag_modes = [captured], operand_kinds = [typed_value, typed_value], result_name = "s"> : (!mpir.sort<Boolean>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
    %i_ret = mpir.inst <or> (%arg0, %i_s, %arg0, %arg2) <result_name = "ret", flags = [disjoint], flag_modes = [required], operand_kinds = [typed_value, typed_value]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction> loc("expand-matchers.mlir":1309:1)
// CHECK:             %[[INST_3:.*]] = mpir.inst <or> (%[[VAL_3]], %[[INST_2]], %[[VAL_3]], %[[VAL_5]]) <flags = [disjoint], flag_modes = [required], operand_kinds = [typed_value, typed_value], result_name = "ret"> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
    mpir.yield %i_ret : <Instruction> loc("expand-matchers.mlir":1311:1)
// CHECK:             mpir.yield %[[INST_3]] : <Instruction>
  } loc("expand-matchers.mlir":1313:1)
// CHECK:           }
} loc("expand-matchers.mlir":1315:1)
// CHECK:         }
mpir.pattern {
// CHECK-LABEL:   mpir.pattern {
  %0 = mpir.type.int 32 : <Type> loc("expand-matchers.mlir":1319:1)
// CHECK:           %[[TYPE_0:.*]] = mpir.type.int 32 : <Type>
  %x = mpir.var "x" : <Operand> loc("expand-matchers.mlir":1321:1)
// CHECK:           %[[VAR_0:.*]] = mpir.var "x" : <Operand>
  %y = mpir.var "y" : <Operand> loc("expand-matchers.mlir":1323:1)
// CHECK:           %[[VAR_1:.*]] = mpir.var "y" : <Operand>
  %u_r = mpir.use @shifted (%0, %x, %0, %y) <result_name = "r", flags = [exact], flag_modes = [required], operand_kinds = [typed_value, typed_value]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction> loc("expand-matchers.mlir":1325:1)
// CHECK:           %[[INT_0:.*]] = mpir.int 1 : ui1 : <Value>
// CHECK:           %[[ALT_0:.*]] = mpir.alt {
// CHECK:             %[[VAR_2:.*]] = mpir.var "r$u" : <Boolean>
// CHECK:             %[[INST_0:.*]] = mpir.inst <shl> flags(%[[VAR_2]]) (%[[TYPE_0]], %[[VAR_0]], %[[TYPE_0]], %[[VAR_1]]) <flags = [nsw, nuw], flag_modes = [required, captured], operand_kinds = [typed_value, typed_value], result_name = "r$s"> : (!mpir.sort<Boolean>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:             %[[INST_1:.*]] = mpir.inst <lshr> (%[[TYPE_0]], %[[INST_0]], %[[TYPE_0]], %[[VAR_1]]) <flags = [exact], flag_modes = [required], operand_kinds = [typed_value, typed_value], result_name = "r"> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:             mpir.yield %[[INST_1]] : <Instruction>
// CHECK:           }, {
// CHECK:             %[[VAR_3:.*]] = mpir.var "r$w" : <Boolean>
// CHECK:             %[[INST_2:.*]] = mpir.inst <add> flags(%[[VAR_3]]) (%[[TYPE_0]], %[[VAR_0]], %[[TYPE_0]], %[[VAR_1]]) <flags = [nsw], flag_modes = [captured], operand_kinds = [typed_value, typed_value], result_name = "r$s"> : (!mpir.sort<Boolean>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:             %[[INST_3:.*]] = mpir.inst <or> (%[[TYPE_0]], %[[INST_2]], %[[TYPE_0]], %[[VAR_1]]) <flags = [disjoint], flag_modes = [required], operand_kinds = [typed_value, typed_value], result_name = "r"> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:             mpir.yield %[[INST_3]] : <Instruction>
// CHECK:           } <result_name = "r"> : <Instruction>
} loc("expand-matchers.mlir":1338:1)
// CHECK:         }

// -----

// The choices of a branch's instructions (':c', ':o') stay on them, for
// mpir-lower-alternatives.
mpir.matcher @commuted <supported_flags = [], syntax = binary, arity = 2, param_names = ["ty", "a", "b"], param_is_type = [true, false, false]> {
// CHECK-LABEL:   mpir.matcher @commuted <supported_flags = [], syntax = binary, arity = 2, param_names = ["ty", "a", "b"], param_is_type = [true, false, false]> {
  %ty = mpir.var "ty" : <Type> loc("expand-matchers.mlir":1347:1)
// CHECK:           %[[VAR_0:.*]] = mpir.var "ty" : <Type>
  mpir.signature %ty : !mpir.sort<Type> loc("expand-matchers.mlir":1349:1)
// CHECK:           mpir.signature %[[VAR_0]] : !mpir.sort<Type>
  mpir.branch <param_args = [0, 1, 2], fixed_flags = [], fixed_flag_values = []> {
// CHECK:           mpir.branch <fixed_flags = [], param_args = [0, 1, 2], fixed_flag_values = []> {
// CHECK:           ^bb0(%[[VAL_0:.*]]: !mpir.sort<Type>, %[[VAL_1:.*]]: !mpir.sort<Operand>, %[[VAL_2:.*]]: !mpir.sort<Operand>):
  ^bb0(%arg0: !mpir.sort<Type>, %arg1: !mpir.sort<Operand>, %arg2: !mpir.sort<Operand>):
    %0 = mpir.int 3 : ui2 : <Value> loc("expand-matchers.mlir":1355:1)
// CHECK:             %[[INT_0:.*]] = mpir.int 3 : ui2 : <Value>
    %i_m = mpir.inst <mul> (%arg0, %arg1, %arg0, %0) <result_name = "m", flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value], metaflags = [#mpir.metaflag<"c", [], loc("expand-matchers.mlir":1357:1)>]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
// CHECK:             %[[INST_0:.*]] = mpir.inst <mul> (%[[VAL_0]], %[[VAL_1]], %[[VAL_0]], %[[INT_0]]) <flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value], result_name = "m", metaflags = [#mpir.metaflag<"c", [], {{.*}}>]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
    %i_ret = mpir.inst <add> (%arg0, %arg2, %arg0, %i_m) <result_name = "ret", flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value], metaflags = [#mpir.metaflag<"o", [1], loc("expand-matchers.mlir":1359:1)>]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Instruction>) -> !mpir.sort<Instruction>
// CHECK:             %[[INST_1:.*]] = mpir.inst <add> (%[[VAL_0]], %[[VAL_2]], %[[VAL_0]], %[[INST_0]]) <flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value], result_name = "ret", metaflags = [#mpir.metaflag<"o", [1], {{.*}}>]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Instruction>) -> !mpir.sort<Instruction>
    mpir.yield %i_ret : <Instruction> loc("expand-matchers.mlir":1361:1)
// CHECK:             mpir.yield %[[INST_1]] : <Instruction>
  } loc("expand-matchers.mlir":1363:1)
// CHECK:           }
} loc("expand-matchers.mlir":1365:1)
// CHECK:         }
mpir.pattern {
// CHECK-LABEL:   mpir.pattern {
  %0 = mpir.type.int 32 : <Type> loc("expand-matchers.mlir":1369:1)
// CHECK:           %[[TYPE_0:.*]] = mpir.type.int 32 : <Type>
  %x = mpir.var "x" : <Operand> loc("expand-matchers.mlir":1371:1)
// CHECK:           %[[VAR_0:.*]] = mpir.var "x" : <Operand>
  %y = mpir.var "y" : <Operand> loc("expand-matchers.mlir":1373:1)
// CHECK:           %[[VAR_1:.*]] = mpir.var "y" : <Operand>
  %u_r = mpir.use @commuted (%0, %x, %0, %y) <result_name = "r", flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction> loc("expand-matchers.mlir":1375:1)
// CHECK:           %[[ALT_0:.*]] = mpir.alt {
// CHECK:             %[[INT_0:.*]] = mpir.int 3 : ui2 : <Value>
// CHECK:             %[[INST_0:.*]] = mpir.inst <mul> (%[[TYPE_0]], %[[VAR_0]], %[[TYPE_0]], %[[INT_0]]) <flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value], result_name = "r$m", metaflags = [#mpir.metaflag<"c", [], {{.*}}>]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
// CHECK:             %[[INST_1:.*]] = mpir.inst <add> (%[[TYPE_0]], %[[VAR_1]], %[[TYPE_0]], %[[INST_0]]) <flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value], result_name = "r", metaflags = [#mpir.metaflag<"o", [1], {{.*}}>]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Instruction>) -> !mpir.sort<Instruction>
// CHECK:             mpir.yield %[[INST_1]] : <Instruction>
// CHECK:           } <result_name = "r"> : <Instruction>
} loc("expand-matchers.mlir":1382:1)
// CHECK:         }
