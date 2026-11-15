// RUN: %metaphir-opt --split-input-file --mpir-expand-matchers %s | FileCheck %s
// mpir-expand-matchers replaces each use of a 'match' matcher by an mpir.alt
// with a region per branch the use can match: the branch's body, with its
// parameters bound to the use's operands, its instructions named after the
// use, and its root standing for the use.

// One branch: its root takes the use's name.
mpir.matcher @twice <supported_flags = [], syntax = 0, arity = 1, param_names = ["ty", "a"], param_is_type = [true, false]> {
  %ty = mpir.var "ty" : <Type>
  mpir.signature %ty : !mpir.sort<Type>
  mpir.branch <param_args = [0, 1], fixed_flags = [], fixed_flag_values = []> {
  ^bb0(%arg0: !mpir.sort<Type>, %arg1: !mpir.sort<Operand>):
    %i_ret = mpir.inst <add> (%arg0, %arg1, %arg0, %arg1) <result_name = "ret", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
    mpir.yield %i_ret : <Instruction>
  }
}
mpir.pattern {
  %0 = mpir.type.int 32 : <Type>
  %x = mpir.var "x" : <Operand>
  %u_d = mpir.use @twice (%0, %x) <result_name = "d", flags = [], flag_modes = [], operand_kinds = [0]> : (!mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
}
// CHECK-LABEL:   mpir.matcher @twice <supported_flags = [], syntax = 0, arity = 1, param_names = ["ty", "a"], param_is_type = [true, false]> {
// CHECK:           %[[VAR_0:.*]] = mpir.var "ty" : <Type>
// CHECK:           mpir.signature %[[VAR_0]] : !mpir.sort<Type>
// CHECK:           mpir.branch <param_args = [0, 1], fixed_flags = [], fixed_flag_values = []> {
// CHECK:           ^bb0(%[[VAL_0:.*]]: !mpir.sort<Type>, %[[VAL_1:.*]]: !mpir.sort<Operand>):
// CHECK:             %[[INST_0:.*]] = mpir.inst <add> (%[[VAL_0]], %[[VAL_1]], %[[VAL_0]], %[[VAL_1]]) <result_name = "ret", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:             mpir.yield %[[INST_0]] : <Instruction>
// CHECK:           }
// CHECK:         }
// CHECK-LABEL:   mpir.pattern {
// CHECK:           %[[TYPE_0:.*]] = mpir.type.int 32 : <Type>
// CHECK:           %[[VAR_0:.*]] = mpir.var "x" : <Operand>
// CHECK:           %[[ALT_0:.*]] = mpir.alt {
// CHECK:             %[[INST_0:.*]] = mpir.inst <add> (%[[TYPE_0]], %[[VAR_0]], %[[TYPE_0]], %[[VAR_0]]) <result_name = "d", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:             mpir.yield %[[INST_0]] : <Instruction>
// CHECK:           } attributes {result_name = "d"} : <Instruction>
// CHECK:         }

// -----

// A region per branch, in order.
mpir.matcher @addOrSub <supported_flags = [], syntax = 1, arity = 2, param_names = ["ty", "a", "b"], param_is_type = [true, false, false]> {
  %ty = mpir.var "ty" : <Type>
  mpir.signature %ty : !mpir.sort<Type>
  mpir.branch <param_args = [0, 1, 2], fixed_flags = [], fixed_flag_values = []> {
  ^bb0(%arg0: !mpir.sort<Type>, %arg1: !mpir.sort<Operand>, %arg2: !mpir.sort<Operand>):
    %i_ret = mpir.inst <add> (%arg0, %arg1, %arg0, %arg2) <result_name = "ret", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
    mpir.yield %i_ret : <Instruction>
  }
  mpir.branch <param_args = [0, 1, 2], fixed_flags = [], fixed_flag_values = []> {
  ^bb0(%arg0: !mpir.sort<Type>, %arg1: !mpir.sort<Operand>, %arg2: !mpir.sort<Operand>):
    %i_ret = mpir.inst <sub> (%arg0, %arg1, %arg0, %arg2) <result_name = "ret", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
    mpir.yield %i_ret : <Instruction>
  }
}
mpir.pattern {
  %0 = mpir.type.int 32 : <Type>
  %x = mpir.var "x" : <Operand>
  %y = mpir.var "y" : <Operand>
  %u_r = mpir.use @addOrSub (%0, %x, %0, %y) <result_name = "r", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
}
// CHECK-LABEL:   mpir.matcher @addOrSub <supported_flags = [], syntax = 1, arity = 2, param_names = ["ty", "a", "b"], param_is_type = [true, false, false]> {
// CHECK:           %[[VAR_0:.*]] = mpir.var "ty" : <Type>
// CHECK:           mpir.signature %[[VAR_0]] : !mpir.sort<Type>
// CHECK:           mpir.branch <param_args = [0, 1, 2], fixed_flags = [], fixed_flag_values = []> {
// CHECK:           ^bb0(%[[VAL_0:.*]]: !mpir.sort<Type>, %[[VAL_1:.*]]: !mpir.sort<Operand>, %[[VAL_2:.*]]: !mpir.sort<Operand>):
// CHECK:             %[[INST_0:.*]] = mpir.inst <add> (%[[VAL_0]], %[[VAL_1]], %[[VAL_0]], %[[VAL_2]]) <result_name = "ret", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:             mpir.yield %[[INST_0]] : <Instruction>
// CHECK:           }
// CHECK:           mpir.branch <param_args = [0, 1, 2], fixed_flags = [], fixed_flag_values = []> {
// CHECK:           ^bb0(%[[VAL_3:.*]]: !mpir.sort<Type>, %[[VAL_4:.*]]: !mpir.sort<Operand>, %[[VAL_5:.*]]: !mpir.sort<Operand>):
// CHECK:             %[[INST_1:.*]] = mpir.inst <sub> (%[[VAL_3]], %[[VAL_4]], %[[VAL_3]], %[[VAL_5]]) <result_name = "ret", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:             mpir.yield %[[INST_1]] : <Instruction>
// CHECK:           }
// CHECK:         }
// CHECK-LABEL:   mpir.pattern {
// CHECK:           %[[TYPE_0:.*]] = mpir.type.int 32 : <Type>
// CHECK:           %[[VAR_0:.*]] = mpir.var "x" : <Operand>
// CHECK:           %[[VAR_1:.*]] = mpir.var "y" : <Operand>
// CHECK:           %[[ALT_0:.*]] = mpir.alt {
// CHECK:             %[[INST_0:.*]] = mpir.inst <add> (%[[TYPE_0]], %[[VAR_0]], %[[TYPE_0]], %[[VAR_1]]) <result_name = "r", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:             mpir.yield %[[INST_0]] : <Instruction>
// CHECK:           }, {
// CHECK:             %[[INST_1:.*]] = mpir.inst <sub> (%[[TYPE_0]], %[[VAR_0]], %[[TYPE_0]], %[[VAR_1]]) <result_name = "r", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:             mpir.yield %[[INST_1]] : <Instruction>
// CHECK:           } attributes {result_name = "r"} : <Instruction>
// CHECK:         }

// -----

// ':c' on the use: each branch with the operands in both orders.
mpir.matcher @addOrSub <commutative, supported_flags = [], syntax = 1, arity = 2, param_names = ["ty", "a", "b"], param_is_type = [true, false, false]> {
  %ty = mpir.var "ty" : <Type>
  mpir.signature %ty : !mpir.sort<Type>
  mpir.branch <param_args = [0, 1, 2], fixed_flags = [], fixed_flag_values = []> {
  ^bb0(%arg0: !mpir.sort<Type>, %arg1: !mpir.sort<Operand>, %arg2: !mpir.sort<Operand>):
    %i_ret = mpir.inst <add> (%arg0, %arg1, %arg0, %arg2) <result_name = "ret", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
    mpir.yield %i_ret : <Instruction>
  }
  mpir.branch <param_args = [0, 1, 2], fixed_flags = [], fixed_flag_values = []> {
  ^bb0(%arg0: !mpir.sort<Type>, %arg1: !mpir.sort<Operand>, %arg2: !mpir.sort<Operand>):
    %i_ret = mpir.inst <sub> (%arg0, %arg1, %arg0, %arg2) <result_name = "ret", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
    mpir.yield %i_ret : <Instruction>
  }
}
mpir.pattern {
  %0 = mpir.type.int 32 : <Type>
  %x = mpir.var "x" : <Operand>
  %1 = mpir.int 1 : ui1 : <Value>
  %u_r = mpir.use @addOrSub (%0, %x, %0, %1) <result_name = "r", flags = [], flag_modes = [], operand_kinds = [0, 0], metaflags = [#mpir.metaflag<"c", [], loc(unknown)>]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
}
// CHECK-LABEL:   mpir.matcher @addOrSub <commutative, supported_flags = [], syntax = 1, arity = 2, param_names = ["ty", "a", "b"], param_is_type = [true, false, false]> {
// CHECK:           %[[VAR_0:.*]] = mpir.var "ty" : <Type>
// CHECK:           mpir.signature %[[VAR_0]] : !mpir.sort<Type>
// CHECK:           mpir.branch <param_args = [0, 1, 2], fixed_flags = [], fixed_flag_values = []> {
// CHECK:           ^bb0(%[[VAL_0:.*]]: !mpir.sort<Type>, %[[VAL_1:.*]]: !mpir.sort<Operand>, %[[VAL_2:.*]]: !mpir.sort<Operand>):
// CHECK:             %[[INST_0:.*]] = mpir.inst <add> (%[[VAL_0]], %[[VAL_1]], %[[VAL_0]], %[[VAL_2]]) <result_name = "ret", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:             mpir.yield %[[INST_0]] : <Instruction>
// CHECK:           }
// CHECK:           mpir.branch <param_args = [0, 1, 2], fixed_flags = [], fixed_flag_values = []> {
// CHECK:           ^bb0(%[[VAL_3:.*]]: !mpir.sort<Type>, %[[VAL_4:.*]]: !mpir.sort<Operand>, %[[VAL_5:.*]]: !mpir.sort<Operand>):
// CHECK:             %[[INST_1:.*]] = mpir.inst <sub> (%[[VAL_3]], %[[VAL_4]], %[[VAL_3]], %[[VAL_5]]) <result_name = "ret", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:             mpir.yield %[[INST_1]] : <Instruction>
// CHECK:           }
// CHECK:         }
// CHECK-LABEL:   mpir.pattern {
// CHECK:           %[[TYPE_0:.*]] = mpir.type.int 32 : <Type>
// CHECK:           %[[VAR_0:.*]] = mpir.var "x" : <Operand>
// CHECK:           %[[INT_0:.*]] = mpir.int 1 : ui1 : <Value>
// CHECK:           %[[ALT_0:.*]] = mpir.alt {
// CHECK:             %[[INST_0:.*]] = mpir.inst <add> (%[[TYPE_0]], %[[VAR_0]], %[[TYPE_0]], %[[INT_0]]) <result_name = "r", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
// CHECK:             mpir.yield %[[INST_0]] : <Instruction>
// CHECK:           }, {
// CHECK:             %[[INST_1:.*]] = mpir.inst <add> (%[[TYPE_0]], %[[INT_0]], %[[TYPE_0]], %[[VAR_0]]) <result_name = "r", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Value>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:             mpir.yield %[[INST_1]] : <Instruction>
// CHECK:           }, {
// CHECK:             %[[INST_2:.*]] = mpir.inst <sub> (%[[TYPE_0]], %[[VAR_0]], %[[TYPE_0]], %[[INT_0]]) <result_name = "r", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
// CHECK:             mpir.yield %[[INST_2]] : <Instruction>
// CHECK:           }, {
// CHECK:             %[[INST_3:.*]] = mpir.inst <sub> (%[[TYPE_0]], %[[INT_0]], %[[TYPE_0]], %[[VAR_0]]) <result_name = "r", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Value>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:             mpir.yield %[[INST_3]] : <Instruction>
// CHECK:           } attributes {result_name = "r"} : <Instruction>
// CHECK:         }

// -----

// A flag the use omits is a fresh variable on the root; a branch that fixes
// flags leaves them out of its root.
mpir.matcher @addish <supported_flags = [0, 1], syntax = 1, arity = 2, param_names = ["ty", "a", "b"], param_is_type = [true, false, false]> {
  %ty = mpir.var "ty" : <Type>
  mpir.signature %ty : !mpir.sort<Type>
  mpir.branch <param_args = [0, 1, 2], fixed_flags = [], fixed_flag_values = []> {
  ^bb0(%arg0: !mpir.sort<Type>, %arg1: !mpir.sort<Operand>, %arg2: !mpir.sort<Operand>):
    %nsw = mpir.var "nsw" : <Boolean>
    %nuw = mpir.var "nuw" : <Boolean>
    %i_ret = mpir.inst <add> flags(%nsw, %nuw) (%arg0, %arg1, %arg0, %arg2) <result_name = "ret", flags = [0, 1], flag_modes = [2, 2], operand_kinds = [0, 0]> : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
    mpir.yield %i_ret : <Instruction>
  }
  mpir.branch <param_args = [0, 1, 2], fixed_flags = [0, 1], fixed_flag_values = [true, false]> {
  ^bb0(%arg0: !mpir.sort<Type>, %arg1: !mpir.sort<Operand>, %arg2: !mpir.sort<Operand>):
    %i_ret = mpir.inst <or> (%arg0, %arg1, %arg0, %arg2) <result_name = "ret", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
    mpir.yield %i_ret : <Instruction>
  }
}
mpir.pattern {
  %0 = mpir.type.int 32 : <Type>
  %x = mpir.var "x" : <Operand>
  %y = mpir.var "y" : <Operand>
  %u_r = mpir.use @addish (%0, %x, %0, %y) <result_name = "r", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
}
// CHECK-LABEL:   mpir.matcher @addish <supported_flags = [0, 1], syntax = 1, arity = 2, param_names = ["ty", "a", "b"], param_is_type = [true, false, false]> {
// CHECK:           %[[VAR_0:.*]] = mpir.var "ty" : <Type>
// CHECK:           mpir.signature %[[VAR_0]] : !mpir.sort<Type>
// CHECK:           mpir.branch <param_args = [0, 1, 2], fixed_flags = [], fixed_flag_values = []> {
// CHECK:           ^bb0(%[[VAL_0:.*]]: !mpir.sort<Type>, %[[VAL_1:.*]]: !mpir.sort<Operand>, %[[VAL_2:.*]]: !mpir.sort<Operand>):
// CHECK:             %[[VAR_1:.*]] = mpir.var "nsw" : <Boolean>
// CHECK:             %[[VAR_2:.*]] = mpir.var "nuw" : <Boolean>
// CHECK:             %[[INST_0:.*]] = mpir.inst <add> flags(%[[VAR_1]], %[[VAR_2]]) (%[[VAL_0]], %[[VAL_1]], %[[VAL_0]], %[[VAL_2]]) <result_name = "ret", flags = [0, 1], flag_modes = [2, 2], operand_kinds = [0, 0]> : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:             mpir.yield %[[INST_0]] : <Instruction>
// CHECK:           }
// CHECK:           mpir.branch <param_args = [0, 1, 2], fixed_flags = [0, 1], fixed_flag_values = [true, false]> {
// CHECK:           ^bb0(%[[VAL_3:.*]]: !mpir.sort<Type>, %[[VAL_4:.*]]: !mpir.sort<Operand>, %[[VAL_5:.*]]: !mpir.sort<Operand>):
// CHECK:             %[[INST_1:.*]] = mpir.inst <or> (%[[VAL_3]], %[[VAL_4]], %[[VAL_3]], %[[VAL_5]]) <result_name = "ret", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:             mpir.yield %[[INST_1]] : <Instruction>
// CHECK:           }
// CHECK:         }
// CHECK-LABEL:   mpir.pattern {
// CHECK:           %[[TYPE_0:.*]] = mpir.type.int 32 : <Type>
// CHECK:           %[[VAR_0:.*]] = mpir.var "x" : <Operand>
// CHECK:           %[[VAR_1:.*]] = mpir.var "y" : <Operand>
// CHECK:           %[[VAR_2:.*]] = mpir.var "_flag$r$nsw" : <Boolean>
// CHECK:           %[[VAR_3:.*]] = mpir.var "_flag$r$nuw" : <Boolean>
// CHECK:           %[[ALT_0:.*]] = mpir.alt {
// CHECK:             %[[INST_0:.*]] = mpir.inst <add> flags(%[[VAR_2]], %[[VAR_3]]) (%[[TYPE_0]], %[[VAR_0]], %[[TYPE_0]], %[[VAR_1]]) <result_name = "r", flags = [0, 1], flag_modes = [2, 2], operand_kinds = [0, 0]> : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:             mpir.yield %[[INST_0]] : <Instruction>
// CHECK:           }, {
// CHECK:             %[[INST_1:.*]] = mpir.inst <or> (%[[TYPE_0]], %[[VAR_0]], %[[TYPE_0]], %[[VAR_1]]) <result_name = "r", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:             mpir.yield %[[INST_1]] : <Instruction>
// CHECK:           } attributes {result_name = "r"} : <Instruction>
// CHECK:         }

// -----

// A flag the use requires or forbids: the root requires or forbids it, and
// a branch that fixes it otherwise is left out.
mpir.matcher @addish <supported_flags = [0, 1], syntax = 1, arity = 2, param_names = ["ty", "a", "b"], param_is_type = [true, false, false]> {
  %ty = mpir.var "ty" : <Type>
  mpir.signature %ty : !mpir.sort<Type>
  mpir.branch <param_args = [0, 1, 2], fixed_flags = [], fixed_flag_values = []> {
  ^bb0(%arg0: !mpir.sort<Type>, %arg1: !mpir.sort<Operand>, %arg2: !mpir.sort<Operand>):
    %nsw = mpir.var "nsw" : <Boolean>
    %nuw = mpir.var "nuw" : <Boolean>
    %i_ret = mpir.inst <add> flags(%nsw, %nuw) (%arg0, %arg1, %arg0, %arg2) <result_name = "ret", flags = [0, 1], flag_modes = [2, 2], operand_kinds = [0, 0]> : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
    mpir.yield %i_ret : <Instruction>
  }
  mpir.branch <param_args = [0, 1, 2], fixed_flags = [0, 1], fixed_flag_values = [true, false]> {
  ^bb0(%arg0: !mpir.sort<Type>, %arg1: !mpir.sort<Operand>, %arg2: !mpir.sort<Operand>):
    %i_ret = mpir.inst <or> (%arg0, %arg1, %arg0, %arg2) <result_name = "ret", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
    mpir.yield %i_ret : <Instruction>
  }
}
mpir.pattern {
  %0 = mpir.type.int 32 : <Type>
  %x = mpir.var "x" : <Operand>
  %y = mpir.var "y" : <Operand>
  %u_r = mpir.use @addish (%0, %x, %0, %y) <result_name = "r", flags = [0, 1], flag_modes = [0, 1], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
  %1 = mpir.type.int 32 : <Type>
  %u_s = mpir.use @addish (%1, %u_r, %1, %y) <result_name = "s", flags = [0], flag_modes = [1], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
}
// CHECK-LABEL:   mpir.matcher @addish <supported_flags = [0, 1], syntax = 1, arity = 2, param_names = ["ty", "a", "b"], param_is_type = [true, false, false]> {
// CHECK:           %[[VAR_0:.*]] = mpir.var "ty" : <Type>
// CHECK:           mpir.signature %[[VAR_0]] : !mpir.sort<Type>
// CHECK:           mpir.branch <param_args = [0, 1, 2], fixed_flags = [], fixed_flag_values = []> {
// CHECK:           ^bb0(%[[VAL_0:.*]]: !mpir.sort<Type>, %[[VAL_1:.*]]: !mpir.sort<Operand>, %[[VAL_2:.*]]: !mpir.sort<Operand>):
// CHECK:             %[[VAR_1:.*]] = mpir.var "nsw" : <Boolean>
// CHECK:             %[[VAR_2:.*]] = mpir.var "nuw" : <Boolean>
// CHECK:             %[[INST_0:.*]] = mpir.inst <add> flags(%[[VAR_1]], %[[VAR_2]]) (%[[VAL_0]], %[[VAL_1]], %[[VAL_0]], %[[VAL_2]]) <result_name = "ret", flags = [0, 1], flag_modes = [2, 2], operand_kinds = [0, 0]> : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:             mpir.yield %[[INST_0]] : <Instruction>
// CHECK:           }
// CHECK:           mpir.branch <param_args = [0, 1, 2], fixed_flags = [0, 1], fixed_flag_values = [true, false]> {
// CHECK:           ^bb0(%[[VAL_3:.*]]: !mpir.sort<Type>, %[[VAL_4:.*]]: !mpir.sort<Operand>, %[[VAL_5:.*]]: !mpir.sort<Operand>):
// CHECK:             %[[INST_1:.*]] = mpir.inst <or> (%[[VAL_3]], %[[VAL_4]], %[[VAL_3]], %[[VAL_5]]) <result_name = "ret", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:             mpir.yield %[[INST_1]] : <Instruction>
// CHECK:           }
// CHECK:         }
// CHECK-LABEL:   mpir.pattern {
// CHECK:           %[[TYPE_0:.*]] = mpir.type.int 32 : <Type>
// CHECK:           %[[VAR_0:.*]] = mpir.var "x" : <Operand>
// CHECK:           %[[VAR_1:.*]] = mpir.var "y" : <Operand>
// CHECK:           %[[INT_0:.*]] = mpir.int 1 : ui1 : <Value>
// CHECK:           %[[INT_1:.*]] = mpir.int 0 : ui1 : <Value>
// CHECK:           %[[ALT_0:.*]] = mpir.alt {
// CHECK:             %[[INST_0:.*]] = mpir.inst <add> (%[[TYPE_0]], %[[VAR_0]], %[[TYPE_0]], %[[VAR_1]]) <result_name = "r", flags = [0, 1], flag_modes = [0, 1], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:             mpir.yield %[[INST_0]] : <Instruction>
// CHECK:           }, {
// CHECK:             %[[INST_1:.*]] = mpir.inst <or> (%[[TYPE_0]], %[[VAR_0]], %[[TYPE_0]], %[[VAR_1]]) <result_name = "r", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:             mpir.yield %[[INST_1]] : <Instruction>
// CHECK:           } attributes {result_name = "r"} : <Instruction>
// CHECK:           %[[TYPE_1:.*]] = mpir.type.int 32 : <Type>
// CHECK:           %[[INT_2:.*]] = mpir.int 0 : ui1 : <Value>
// CHECK:           %[[VAR_2:.*]] = mpir.var "_flag$s$nuw" : <Boolean>
// CHECK:           %[[ALT_1:.*]] = mpir.alt {
// CHECK:             %[[INST_2:.*]] = mpir.inst <add> flags(%[[VAR_2]]) (%[[TYPE_1]], %[[ALT_0]], %[[TYPE_1]], %[[VAR_1]]) <result_name = "s", flags = [0, 1], flag_modes = [1, 2], operand_kinds = [0, 0]> : (!mpir.sort<Boolean>, !mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:             mpir.yield %[[INST_2]] : <Instruction>
// CHECK:           } attributes {result_name = "s"} : <Instruction>
// CHECK:         }

// -----

// A flag the use captures: the root captures it, and a branch that fixes it
// binds the capture.
mpir.matcher @addish <supported_flags = [0, 1], syntax = 1, arity = 2, param_names = ["ty", "a", "b"], param_is_type = [true, false, false]> {
  %ty = mpir.var "ty" : <Type>
  mpir.signature %ty : !mpir.sort<Type>
  mpir.branch <param_args = [0, 1, 2], fixed_flags = [], fixed_flag_values = []> {
  ^bb0(%arg0: !mpir.sort<Type>, %arg1: !mpir.sort<Operand>, %arg2: !mpir.sort<Operand>):
    %nsw = mpir.var "nsw" : <Boolean>
    %nuw = mpir.var "nuw" : <Boolean>
    %i_ret = mpir.inst <add> flags(%nsw, %nuw) (%arg0, %arg1, %arg0, %arg2) <result_name = "ret", flags = [0, 1], flag_modes = [2, 2], operand_kinds = [0, 0]> : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
    mpir.yield %i_ret : <Instruction>
  }
  mpir.branch <param_args = [0, 1, 2], fixed_flags = [0, 1], fixed_flag_values = [true, false]> {
  ^bb0(%arg0: !mpir.sort<Type>, %arg1: !mpir.sort<Operand>, %arg2: !mpir.sort<Operand>):
    %i_ret = mpir.inst <or> (%arg0, %arg1, %arg0, %arg2) <result_name = "ret", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
    mpir.yield %i_ret : <Instruction>
  }
}
mpir.pattern {
  %wrap = mpir.var "wrap" : <Boolean>
  %uwrap = mpir.var "uwrap" : <Boolean>
  %0 = mpir.type.int 32 : <Type>
  %x = mpir.var "x" : <Operand>
  %y = mpir.var "y" : <Operand>
  %u_r = mpir.use @addish flags(%wrap, %uwrap) (%0, %x, %0, %y) <result_name = "r", flags = [0, 1], flag_modes = [2, 2], operand_kinds = [0, 0]> : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
}
// CHECK-LABEL:   mpir.matcher @addish <supported_flags = [0, 1], syntax = 1, arity = 2, param_names = ["ty", "a", "b"], param_is_type = [true, false, false]> {
// CHECK:           %[[VAR_0:.*]] = mpir.var "ty" : <Type>
// CHECK:           mpir.signature %[[VAR_0]] : !mpir.sort<Type>
// CHECK:           mpir.branch <param_args = [0, 1, 2], fixed_flags = [], fixed_flag_values = []> {
// CHECK:           ^bb0(%[[VAL_0:.*]]: !mpir.sort<Type>, %[[VAL_1:.*]]: !mpir.sort<Operand>, %[[VAL_2:.*]]: !mpir.sort<Operand>):
// CHECK:             %[[VAR_1:.*]] = mpir.var "nsw" : <Boolean>
// CHECK:             %[[VAR_2:.*]] = mpir.var "nuw" : <Boolean>
// CHECK:             %[[INST_0:.*]] = mpir.inst <add> flags(%[[VAR_1]], %[[VAR_2]]) (%[[VAL_0]], %[[VAL_1]], %[[VAL_0]], %[[VAL_2]]) <result_name = "ret", flags = [0, 1], flag_modes = [2, 2], operand_kinds = [0, 0]> : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:             mpir.yield %[[INST_0]] : <Instruction>
// CHECK:           }
// CHECK:           mpir.branch <param_args = [0, 1, 2], fixed_flags = [0, 1], fixed_flag_values = [true, false]> {
// CHECK:           ^bb0(%[[VAL_3:.*]]: !mpir.sort<Type>, %[[VAL_4:.*]]: !mpir.sort<Operand>, %[[VAL_5:.*]]: !mpir.sort<Operand>):
// CHECK:             %[[INST_1:.*]] = mpir.inst <or> (%[[VAL_3]], %[[VAL_4]], %[[VAL_3]], %[[VAL_5]]) <result_name = "ret", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:             mpir.yield %[[INST_1]] : <Instruction>
// CHECK:           }
// CHECK:         }
// CHECK-LABEL:   mpir.pattern {
// CHECK:           %[[VAR_0:.*]] = mpir.var "wrap" : <Boolean>
// CHECK:           %[[VAR_1:.*]] = mpir.var "uwrap" : <Boolean>
// CHECK:           %[[TYPE_0:.*]] = mpir.type.int 32 : <Type>
// CHECK:           %[[VAR_2:.*]] = mpir.var "x" : <Operand>
// CHECK:           %[[VAR_3:.*]] = mpir.var "y" : <Operand>
// CHECK:           %[[ALT_0:.*]] = mpir.alt {
// CHECK:             %[[INST_0:.*]] = mpir.inst <add> flags(%[[VAR_0]], %[[VAR_1]]) (%[[TYPE_0]], %[[VAR_2]], %[[TYPE_0]], %[[VAR_3]]) <result_name = "r", flags = [0, 1], flag_modes = [2, 2], operand_kinds = [0, 0]> : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:             mpir.yield %[[INST_0]] : <Instruction>
// CHECK:           }, {
// CHECK:             %[[INST_1:.*]] = mpir.inst <or> (%[[TYPE_0]], %[[VAR_2]], %[[TYPE_0]], %[[VAR_3]]) <result_name = "r", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:             %[[INT_0:.*]] = mpir.int 1 : ui1 : <Value>
// CHECK:             mpir.bind %[[VAR_0]], %[[INT_0]] : <Boolean>, <Value>
// CHECK:             %[[INT_1:.*]] = mpir.int 0 : ui1 : <Value>
// CHECK:             mpir.bind %[[VAR_1]], %[[INT_1]] : <Boolean>, <Value>
// CHECK:             mpir.yield %[[INST_1]] : <Instruction>
// CHECK:           } attributes {result_name = "r"} : <Instruction>
// CHECK:         }

// -----

// A parameter of a fixed type: a branch fits only a use of that type.
mpir.matcher @pick <supported_flags = [], syntax = 0, arity = 3, param_names = ["", "c", "ty", "t", "ty", "f"], param_is_type = [true, false, true, false, true, false]> {
  %0 = mpir.type.int 1 : <Type>
  %ty = mpir.var "ty" : <Type>
  mpir.signature %0, %ty, %ty : !mpir.sort<Type>, !mpir.sort<Type>, !mpir.sort<Type>
  mpir.branch <param_args = [-1, 0, 1, 2, 1, 3], fixed_flags = [], fixed_flag_values = []> {
  ^bb0(%arg0: !mpir.sort<Boolean>, %arg1: !mpir.sort<Type>, %arg2: !mpir.sort<Operand>, %arg3: !mpir.sort<Operand>):
    %1 = mpir.type.int 1 : <Type>
    %i_ret = mpir.inst <select> (%1, %arg0, %arg1, %arg2, %arg1, %arg3) <result_name = "ret", flags = [], flag_modes = [], operand_kinds = [0, 0, 0]> : (!mpir.sort<Type>, !mpir.sort<Boolean>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
    mpir.yield %i_ret : <Instruction>
  }
}
mpir.pattern {
  %0 = mpir.type.int 1 : <Type>
  %cond = mpir.var "cond" : <Boolean>
  %1 = mpir.type.int 32 : <Type>
  %a = mpir.var "a" : <Operand>
  %2 = mpir.type.int 32 : <Type>
  %b = mpir.var "b" : <Operand>
  %u_r = mpir.use @pick (%0, %cond, %1, %a, %2, %b) <result_name = "r", flags = [], flag_modes = [], operand_kinds = [0, 0, 0]> : (!mpir.sort<Type>, !mpir.sort<Boolean>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
}
// CHECK-LABEL:   mpir.matcher @pick <supported_flags = [], syntax = 0, arity = 3, param_names = ["", "c", "ty", "t", "ty", "f"], param_is_type = [true, false, true, false, true, false]> {
// CHECK:           %[[TYPE_0:.*]] = mpir.type.int 1 : <Type>
// CHECK:           %[[VAR_0:.*]] = mpir.var "ty" : <Type>
// CHECK:           mpir.signature %[[TYPE_0]], %[[VAR_0]], %[[VAR_0]] : !mpir.sort<Type>, !mpir.sort<Type>, !mpir.sort<Type>
// CHECK:           mpir.branch <param_args = [-1, 0, 1, 2, 1, 3], fixed_flags = [], fixed_flag_values = []> {
// CHECK:           ^bb0(%[[VAL_0:.*]]: !mpir.sort<Boolean>, %[[VAL_1:.*]]: !mpir.sort<Type>, %[[VAL_2:.*]]: !mpir.sort<Operand>, %[[VAL_3:.*]]: !mpir.sort<Operand>):
// CHECK:             %[[TYPE_1:.*]] = mpir.type.int 1 : <Type>
// CHECK:             %[[INST_0:.*]] = mpir.inst <select> (%[[TYPE_1]], %[[VAL_0]], %[[VAL_1]], %[[VAL_2]], %[[VAL_1]], %[[VAL_3]]) <result_name = "ret", flags = [], flag_modes = [], operand_kinds = [0, 0, 0]> : (!mpir.sort<Type>, !mpir.sort<Boolean>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:             mpir.yield %[[INST_0]] : <Instruction>
// CHECK:           }
// CHECK:         }
// CHECK-LABEL:   mpir.pattern {
// CHECK:           %[[TYPE_0:.*]] = mpir.type.int 1 : <Type>
// CHECK:           %[[VAR_0:.*]] = mpir.var "cond" : <Boolean>
// CHECK:           %[[TYPE_1:.*]] = mpir.type.int 32 : <Type>
// CHECK:           %[[VAR_1:.*]] = mpir.var "a" : <Operand>
// CHECK:           %[[TYPE_2:.*]] = mpir.type.int 32 : <Type>
// CHECK:           %[[VAR_2:.*]] = mpir.var "b" : <Operand>
// CHECK:           %[[ALT_0:.*]] = mpir.alt {
// CHECK:             %[[TYPE_3:.*]] = mpir.type.int 1 : <Type>
// CHECK:             %[[INST_0:.*]] = mpir.inst <select> (%[[TYPE_3]], %[[VAR_0]], %[[TYPE_1]], %[[VAR_1]], %[[TYPE_1]], %[[VAR_2]]) <result_name = "r", flags = [], flag_modes = [], operand_kinds = [0, 0, 0]> : (!mpir.sort<Type>, !mpir.sort<Boolean>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:             mpir.yield %[[INST_0]] : <Instruction>
// CHECK:           } attributes {result_name = "r"} : <Instruction>
// CHECK:         }

// -----

// A type parameter used for two operands must be one type: a use with two
// types has no branch to match (the alt is empty).
mpir.matcher @pick <supported_flags = [], syntax = 0, arity = 3, param_names = ["", "c", "ty", "t", "ty", "f"], param_is_type = [true, false, true, false, true, false]> {
  %0 = mpir.type.int 1 : <Type>
  %ty = mpir.var "ty" : <Type>
  mpir.signature %0, %ty, %ty : !mpir.sort<Type>, !mpir.sort<Type>, !mpir.sort<Type>
  mpir.branch <param_args = [-1, 0, 1, 2, 1, 3], fixed_flags = [], fixed_flag_values = []> {
  ^bb0(%arg0: !mpir.sort<Boolean>, %arg1: !mpir.sort<Type>, %arg2: !mpir.sort<Operand>, %arg3: !mpir.sort<Operand>):
    %1 = mpir.type.int 1 : <Type>
    %i_ret = mpir.inst <select> (%1, %arg0, %arg1, %arg2, %arg1, %arg3) <result_name = "ret", flags = [], flag_modes = [], operand_kinds = [0, 0, 0]> : (!mpir.sort<Type>, !mpir.sort<Boolean>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
    mpir.yield %i_ret : <Instruction>
  }
}
mpir.pattern {
  %0 = mpir.type.int 1 : <Type>
  %cond = mpir.var "cond" : <Boolean>
  %1 = mpir.type.int 32 : <Type>
  %a = mpir.var "a" : <Operand>
  %2 = mpir.type.int 64 : <Type>
  %b = mpir.var "b" : <Operand>
  %u_r = mpir.use @pick (%0, %cond, %1, %a, %2, %b) <result_name = "r", flags = [], flag_modes = [], operand_kinds = [0, 0, 0]> : (!mpir.sort<Type>, !mpir.sort<Boolean>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
}
// CHECK-LABEL:   mpir.matcher @pick <supported_flags = [], syntax = 0, arity = 3, param_names = ["", "c", "ty", "t", "ty", "f"], param_is_type = [true, false, true, false, true, false]> {
// CHECK:           %[[TYPE_0:.*]] = mpir.type.int 1 : <Type>
// CHECK:           %[[VAR_0:.*]] = mpir.var "ty" : <Type>
// CHECK:           mpir.signature %[[TYPE_0]], %[[VAR_0]], %[[VAR_0]] : !mpir.sort<Type>, !mpir.sort<Type>, !mpir.sort<Type>
// CHECK:           mpir.branch <param_args = [-1, 0, 1, 2, 1, 3], fixed_flags = [], fixed_flag_values = []> {
// CHECK:           ^bb0(%[[VAL_0:.*]]: !mpir.sort<Boolean>, %[[VAL_1:.*]]: !mpir.sort<Type>, %[[VAL_2:.*]]: !mpir.sort<Operand>, %[[VAL_3:.*]]: !mpir.sort<Operand>):
// CHECK:             %[[TYPE_1:.*]] = mpir.type.int 1 : <Type>
// CHECK:             %[[INST_0:.*]] = mpir.inst <select> (%[[TYPE_1]], %[[VAL_0]], %[[VAL_1]], %[[VAL_2]], %[[VAL_1]], %[[VAL_3]]) <result_name = "ret", flags = [], flag_modes = [], operand_kinds = [0, 0, 0]> : (!mpir.sort<Type>, !mpir.sort<Boolean>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:             mpir.yield %[[INST_0]] : <Instruction>
// CHECK:           }
// CHECK:         }
// CHECK-LABEL:   mpir.pattern {
// CHECK:           %[[TYPE_0:.*]] = mpir.type.int 1 : <Type>
// CHECK:           %[[VAR_0:.*]] = mpir.var "cond" : <Boolean>
// CHECK:           %[[TYPE_1:.*]] = mpir.type.int 32 : <Type>
// CHECK:           %[[VAR_1:.*]] = mpir.var "a" : <Operand>
// CHECK:           %[[TYPE_2:.*]] = mpir.type.int 64 : <Type>
// CHECK:           %[[VAR_2:.*]] = mpir.var "b" : <Operand>
// CHECK:           %[[ALT_0:.*]] = mpir.alt  attributes {result_name = "r"} : <Instruction>
// CHECK:         }

// -----

// ...unless one is only known once matched.
mpir.matcher @pick <supported_flags = [], syntax = 0, arity = 3, param_names = ["", "c", "ty", "t", "ty", "f"], param_is_type = [true, false, true, false, true, false]> {
  %0 = mpir.type.int 1 : <Type>
  %ty = mpir.var "ty" : <Type>
  mpir.signature %0, %ty, %ty : !mpir.sort<Type>, !mpir.sort<Type>, !mpir.sort<Type>
  mpir.branch <param_args = [-1, 0, 1, 2, 1, 3], fixed_flags = [], fixed_flag_values = []> {
  ^bb0(%arg0: !mpir.sort<Boolean>, %arg1: !mpir.sort<Type>, %arg2: !mpir.sort<Operand>, %arg3: !mpir.sort<Operand>):
    %1 = mpir.type.int 1 : <Type>
    %i_ret = mpir.inst <select> (%1, %arg0, %arg1, %arg2, %arg1, %arg3) <result_name = "ret", flags = [], flag_modes = [], operand_kinds = [0, 0, 0]> : (!mpir.sort<Type>, !mpir.sort<Boolean>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
    mpir.yield %i_ret : <Instruction>
  }
}
mpir.pattern {
  %0 = mpir.type.int 1 : <Type>
  %cond = mpir.var "cond" : <Boolean>
  %1 = mpir.type.int 32 : <Type>
  %a = mpir.var "a" : <Operand>
  %other = mpir.var "other" : <Type>
  %b = mpir.var "b" : <Operand>
  %u_r = mpir.use @pick (%0, %cond, %1, %a, %other, %b) <result_name = "r", flags = [], flag_modes = [], operand_kinds = [0, 0, 0]> : (!mpir.sort<Type>, !mpir.sort<Boolean>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
  %2 = mpir.type.int 1 : <Type>
  %n = mpir.var "n" : <Nat>
  %3 = mpir.type.meta_int %n : (!mpir.sort<Nat>) -> !mpir.sort<Type>
  %4 = mpir.type.meta_int %n : (!mpir.sort<Nat>) -> !mpir.sort<Type>
  %u_s = mpir.use @pick (%2, %cond, %3, %u_r, %4, %b) <result_name = "s", flags = [], flag_modes = [], operand_kinds = [0, 0, 0]> : (!mpir.sort<Type>, !mpir.sort<Boolean>, !mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
}
// CHECK-LABEL:   mpir.matcher @pick <supported_flags = [], syntax = 0, arity = 3, param_names = ["", "c", "ty", "t", "ty", "f"], param_is_type = [true, false, true, false, true, false]> {
// CHECK:           %[[TYPE_0:.*]] = mpir.type.int 1 : <Type>
// CHECK:           %[[VAR_0:.*]] = mpir.var "ty" : <Type>
// CHECK:           mpir.signature %[[TYPE_0]], %[[VAR_0]], %[[VAR_0]] : !mpir.sort<Type>, !mpir.sort<Type>, !mpir.sort<Type>
// CHECK:           mpir.branch <param_args = [-1, 0, 1, 2, 1, 3], fixed_flags = [], fixed_flag_values = []> {
// CHECK:           ^bb0(%[[VAL_0:.*]]: !mpir.sort<Boolean>, %[[VAL_1:.*]]: !mpir.sort<Type>, %[[VAL_2:.*]]: !mpir.sort<Operand>, %[[VAL_3:.*]]: !mpir.sort<Operand>):
// CHECK:             %[[TYPE_1:.*]] = mpir.type.int 1 : <Type>
// CHECK:             %[[INST_0:.*]] = mpir.inst <select> (%[[TYPE_1]], %[[VAL_0]], %[[VAL_1]], %[[VAL_2]], %[[VAL_1]], %[[VAL_3]]) <result_name = "ret", flags = [], flag_modes = [], operand_kinds = [0, 0, 0]> : (!mpir.sort<Type>, !mpir.sort<Boolean>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:             mpir.yield %[[INST_0]] : <Instruction>
// CHECK:           }
// CHECK:         }
// CHECK-LABEL:   mpir.pattern {
// CHECK:           %[[TYPE_0:.*]] = mpir.type.int 1 : <Type>
// CHECK:           %[[VAR_0:.*]] = mpir.var "cond" : <Boolean>
// CHECK:           %[[TYPE_1:.*]] = mpir.type.int 32 : <Type>
// CHECK:           %[[VAR_1:.*]] = mpir.var "a" : <Operand>
// CHECK:           %[[VAR_2:.*]] = mpir.var "other" : <Type>
// CHECK:           %[[VAR_3:.*]] = mpir.var "b" : <Operand>
// CHECK:           %[[ALT_0:.*]] = mpir.alt {
// CHECK:             %[[TYPE_2:.*]] = mpir.type.int 1 : <Type>
// CHECK:             %[[INST_0:.*]] = mpir.inst <select> (%[[TYPE_2]], %[[VAR_0]], %[[TYPE_1]], %[[VAR_1]], %[[TYPE_1]], %[[VAR_3]]) <result_name = "r", flags = [], flag_modes = [], operand_kinds = [0, 0, 0]> : (!mpir.sort<Type>, !mpir.sort<Boolean>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:             mpir.yield %[[INST_0]] : <Instruction>
// CHECK:           } attributes {result_name = "r"} : <Instruction>
// CHECK:           %[[TYPE_3:.*]] = mpir.type.int 1 : <Type>
// CHECK:           %[[VAR_4:.*]] = mpir.var "n" : <Nat>
// CHECK:           %[[TYPE_4:.*]] = mpir.type.meta_int %[[VAR_4]] : (!mpir.sort<Nat>) -> !mpir.sort<Type>
// CHECK:           %[[TYPE_5:.*]] = mpir.type.meta_int %[[VAR_4]] : (!mpir.sort<Nat>) -> !mpir.sort<Type>
// CHECK:           %[[ALT_1:.*]] = mpir.alt {
// CHECK:             %[[TYPE_6:.*]] = mpir.type.int 1 : <Type>
// CHECK:             %[[INST_1:.*]] = mpir.inst <select> (%[[TYPE_6]], %[[VAR_0]], %[[TYPE_4]], %[[ALT_0]], %[[TYPE_4]], %[[VAR_3]]) <result_name = "s", flags = [], flag_modes = [], operand_kinds = [0, 0, 0]> : (!mpir.sort<Type>, !mpir.sort<Boolean>, !mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:             mpir.yield %[[INST_1]] : <Instruction>
// CHECK:           } attributes {result_name = "s"} : <Instruction>
// CHECK:         }

// -----

// An 'i?bits' parameter stands for the use's type, and its width for a
// value the branch's constraints read: a literal, or the use's variable.
mpir.matcher @low <supported_flags = [], syntax = 0, arity = 1, param_names = ["bits", "a"], param_is_type = [true, false]> {
  %bits = mpir.var "bits" : <Nat>
  %0 = mpir.type.meta_int %bits : (!mpir.sort<Nat>) -> !mpir.sort<Type>
  mpir.signature %0 : !mpir.sort<Type>
  mpir.branch <param_args = [0, 1], fixed_flags = [], fixed_flag_values = []> {
  ^bb0(%arg0: !mpir.sort<Nat>, %arg1: !mpir.sort<Operand>):
    %1 = mpir.type.meta_int %arg0 : (!mpir.sort<Nat>) -> !mpir.sort<Type>
    %2 = mpir.type.int 8 : <Type>
    %i_ret = mpir.inst <trunc> (%1, %arg1, %2) <result_name = "ret", flags = [], flag_modes = [], operand_kinds = [0, 2]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>) -> !mpir.sort<Instruction>
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
  %u_r = mpir.use @low (%0, %x) <result_name = "r", flags = [], flag_modes = [], operand_kinds = [0]> : (!mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
  %w = mpir.var "w" : <Nat>
  %1 = mpir.type.meta_int %w : (!mpir.sort<Nat>) -> !mpir.sort<Type>
  %y = mpir.var "y" : <Operand>
  %u_s = mpir.use @low (%1, %y) <result_name = "s", flags = [], flag_modes = [], operand_kinds = [0]> : (!mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
}
// CHECK-LABEL:   mpir.matcher @low <supported_flags = [], syntax = 0, arity = 1, param_names = ["bits", "a"], param_is_type = [true, false]> {
// CHECK:           %[[VAR_0:.*]] = mpir.var "bits" : <Nat>
// CHECK:           %[[TYPE_0:.*]] = mpir.type.meta_int %[[VAR_0]] : (!mpir.sort<Nat>) -> !mpir.sort<Type>
// CHECK:           mpir.signature %[[TYPE_0]] : !mpir.sort<Type>
// CHECK:           mpir.branch <param_args = [0, 1], fixed_flags = [], fixed_flag_values = []> {
// CHECK:           ^bb0(%[[VAL_0:.*]]: !mpir.sort<Nat>, %[[VAL_1:.*]]: !mpir.sort<Operand>):
// CHECK:             %[[TYPE_1:.*]] = mpir.type.meta_int %[[VAL_0]] : (!mpir.sort<Nat>) -> !mpir.sort<Type>
// CHECK:             %[[TYPE_2:.*]] = mpir.type.int 8 : <Type>
// CHECK:             %[[INST_0:.*]] = mpir.inst <trunc> (%[[TYPE_1]], %[[VAL_1]], %[[TYPE_2]]) <result_name = "ret", flags = [], flag_modes = [], operand_kinds = [0, 2]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>) -> !mpir.sort<Instruction>
// CHECK:             %[[READ_0:.*]] = mpir_expr.read %[[VAL_0]] : (!mpir.sort<Nat>) -> !mpir.sort<Integer>
// CHECK:             %[[INT_0:.*]] = mpir_expr.int 32 : ui64 : <Integer>
// CHECK:             %[[CALL_0:.*]] = mpir_expr.call binary "=="(%[[READ_0]], %[[INT_0]]) anchor %[[INST_0]] : (!mpir.sort<Integer>, !mpir.sort<Integer>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:             mpir.require %[[CALL_0]] : <Boolean>
// CHECK:             mpir.yield %[[INST_0]] : <Instruction>
// CHECK:           }
// CHECK:         }
// CHECK-LABEL:   mpir.pattern {
// CHECK:           %[[TYPE_0:.*]] = mpir.type.int 32 : <Type>
// CHECK:           %[[VAR_0:.*]] = mpir.var "x" : <Operand>
// CHECK:           %[[INT_0:.*]] = mpir.int 32 : ui64 : <Value>
// CHECK:           %[[ALT_0:.*]] = mpir.alt {
// CHECK:             %[[TYPE_1:.*]] = mpir.type.int 8 : <Type>
// CHECK:             %[[INST_0:.*]] = mpir.inst <trunc> (%[[TYPE_0]], %[[VAR_0]], %[[TYPE_1]]) <result_name = "r", flags = [], flag_modes = [], operand_kinds = [0, 2]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>) -> !mpir.sort<Instruction>
// CHECK:             %[[READ_0:.*]] = mpir_expr.read %[[INT_0]] : (!mpir.sort<Value>) -> !mpir.sort<Integer>
// CHECK:             %[[INT_1:.*]] = mpir_expr.int 32 : ui64 : <Integer>
// CHECK:             %[[CALL_0:.*]] = mpir_expr.call binary "=="(%[[READ_0]], %[[INT_1]]) anchor %[[INST_0]] : (!mpir.sort<Integer>, !mpir.sort<Integer>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:             mpir.require %[[CALL_0]] : <Boolean>
// CHECK:             mpir.yield %[[INST_0]] : <Instruction>
// CHECK:           } attributes {result_name = "r"} : <Instruction>
// CHECK:           %[[VAR_1:.*]] = mpir.var "w" : <Nat>
// CHECK:           %[[TYPE_2:.*]] = mpir.type.meta_int %[[VAR_1]] : (!mpir.sort<Nat>) -> !mpir.sort<Type>
// CHECK:           %[[VAR_2:.*]] = mpir.var "y" : <Operand>
// CHECK:           %[[ALT_1:.*]] = mpir.alt {
// CHECK:             %[[TYPE_3:.*]] = mpir.type.int 8 : <Type>
// CHECK:             %[[INST_1:.*]] = mpir.inst <trunc> (%[[TYPE_2]], %[[VAR_2]], %[[TYPE_3]]) <result_name = "s", flags = [], flag_modes = [], operand_kinds = [0, 2]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>) -> !mpir.sort<Instruction>
// CHECK:             %[[READ_1:.*]] = mpir_expr.read %[[VAR_1]] : (!mpir.sort<Nat>) -> !mpir.sort<Integer>
// CHECK:             %[[INT_2:.*]] = mpir_expr.int 32 : ui64 : <Integer>
// CHECK:             %[[CALL_1:.*]] = mpir_expr.call binary "=="(%[[READ_1]], %[[INT_2]]) anchor %[[INST_1]] : (!mpir.sort<Integer>, !mpir.sort<Integer>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:             mpir.require %[[CALL_1]] : <Boolean>
// CHECK:             mpir.yield %[[INST_1]] : <Instruction>
// CHECK:           } attributes {result_name = "s"} : <Instruction>
// CHECK:         }

// -----

// A cast: the source and the destination type.
mpir.matcher @widen <supported_flags = [8], syntax = 2, arity = 1, param_names = ["from", "a", "to"], param_is_type = [true, false, true]> {
  %from = mpir.var "from" : <Type>
  %to = mpir.var "to" : <Type>
  mpir.signature %from, %to : !mpir.sort<Type>, !mpir.sort<Type>
  mpir.branch <param_args = [0, 1, 2], fixed_flags = [], fixed_flag_values = []> {
  ^bb0(%arg0: !mpir.sort<Type>, %arg1: !mpir.sort<Operand>, %arg2: !mpir.sort<Type>):
    %i_ret = mpir.inst <zext> (%arg0, %arg1, %arg2) <result_name = "ret", flags = [], flag_modes = [], operand_kinds = [0, 2]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>) -> !mpir.sort<Instruction>
    mpir.yield %i_ret : <Instruction>
  }
  mpir.branch <param_args = [0, 1, 2], fixed_flags = [8], fixed_flag_values = [false]> {
  ^bb0(%arg0: !mpir.sort<Type>, %arg1: !mpir.sort<Operand>, %arg2: !mpir.sort<Type>):
    %i_ret = mpir.inst <sext> (%arg0, %arg1, %arg2) <result_name = "ret", flags = [], flag_modes = [], operand_kinds = [0, 2]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>) -> !mpir.sort<Instruction>
    mpir.yield %i_ret : <Instruction>
  }
}
mpir.pattern {
  %0 = mpir.type.int 8 : <Type>
  %x = mpir.var "x" : <Operand>
  %1 = mpir.type.int 32 : <Type>
  %u_r = mpir.use @widen (%0, %x, %1) <result_name = "r", flags = [], flag_modes = [], operand_kinds = [0, 2]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>) -> !mpir.sort<Instruction>
  %2 = mpir.type.int 32 : <Type>
  %wide = mpir.var "wide" : <Type>
  %u_s = mpir.use @widen (%2, %u_r, %wide) <result_name = "s", flags = [8], flag_modes = [0], operand_kinds = [0, 2]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>) -> !mpir.sort<Instruction>
}
// CHECK-LABEL:   mpir.matcher @widen <supported_flags = [8], syntax = 2, arity = 1, param_names = ["from", "a", "to"], param_is_type = [true, false, true]> {
// CHECK:           %[[VAR_0:.*]] = mpir.var "from" : <Type>
// CHECK:           %[[VAR_1:.*]] = mpir.var "to" : <Type>
// CHECK:           mpir.signature %[[VAR_0]], %[[VAR_1]] : !mpir.sort<Type>, !mpir.sort<Type>
// CHECK:           mpir.branch <param_args = [0, 1, 2], fixed_flags = [], fixed_flag_values = []> {
// CHECK:           ^bb0(%[[VAL_0:.*]]: !mpir.sort<Type>, %[[VAL_1:.*]]: !mpir.sort<Operand>, %[[VAL_2:.*]]: !mpir.sort<Type>):
// CHECK:             %[[INST_0:.*]] = mpir.inst <zext> (%[[VAL_0]], %[[VAL_1]], %[[VAL_2]]) <result_name = "ret", flags = [], flag_modes = [], operand_kinds = [0, 2]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>) -> !mpir.sort<Instruction>
// CHECK:             mpir.yield %[[INST_0]] : <Instruction>
// CHECK:           }
// CHECK:           mpir.branch <param_args = [0, 1, 2], fixed_flags = [8], fixed_flag_values = [false]> {
// CHECK:           ^bb0(%[[VAL_3:.*]]: !mpir.sort<Type>, %[[VAL_4:.*]]: !mpir.sort<Operand>, %[[VAL_5:.*]]: !mpir.sort<Type>):
// CHECK:             %[[INST_1:.*]] = mpir.inst <sext> (%[[VAL_3]], %[[VAL_4]], %[[VAL_5]]) <result_name = "ret", flags = [], flag_modes = [], operand_kinds = [0, 2]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>) -> !mpir.sort<Instruction>
// CHECK:             mpir.yield %[[INST_1]] : <Instruction>
// CHECK:           }
// CHECK:         }
// CHECK-LABEL:   mpir.pattern {
// CHECK:           %[[TYPE_0:.*]] = mpir.type.int 8 : <Type>
// CHECK:           %[[VAR_0:.*]] = mpir.var "x" : <Operand>
// CHECK:           %[[TYPE_1:.*]] = mpir.type.int 32 : <Type>
// CHECK:           %[[VAR_1:.*]] = mpir.var "_flag$r$nneg" : <Boolean>
// CHECK:           %[[ALT_0:.*]] = mpir.alt {
// CHECK:             %[[INST_0:.*]] = mpir.inst <zext> (%[[TYPE_0]], %[[VAR_0]], %[[TYPE_1]]) <result_name = "r", flags = [], flag_modes = [], operand_kinds = [0, 2]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>) -> !mpir.sort<Instruction>
// CHECK:             mpir.yield %[[INST_0]] : <Instruction>
// CHECK:           }, {
// CHECK:             %[[INST_1:.*]] = mpir.inst <sext> (%[[TYPE_0]], %[[VAR_0]], %[[TYPE_1]]) <result_name = "r", flags = [], flag_modes = [], operand_kinds = [0, 2]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>) -> !mpir.sort<Instruction>
// CHECK:             mpir.yield %[[INST_1]] : <Instruction>
// CHECK:           } attributes {result_name = "r"} : <Instruction>
// CHECK:           %[[TYPE_2:.*]] = mpir.type.int 32 : <Type>
// CHECK:           %[[VAR_2:.*]] = mpir.var "wide" : <Type>
// CHECK:           %[[ALT_1:.*]] = mpir.alt {
// CHECK:             %[[INST_2:.*]] = mpir.inst <zext> (%[[TYPE_2]], %[[ALT_0]], %[[VAR_2]]) <result_name = "s", flags = [], flag_modes = [], operand_kinds = [0, 2]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>) -> !mpir.sort<Instruction>
// CHECK:             mpir.yield %[[INST_2]] : <Instruction>
// CHECK:           } attributes {result_name = "s"} : <Instruction>
// CHECK:         }

// -----

// A branch's own variables and instructions are copies named after the
// use, one set per use.
mpir.matcher @mulAdd <supported_flags = [], syntax = 1, arity = 2, param_names = ["ty", "a", "b"], param_is_type = [true, false, false]> {
  %ty = mpir.var "ty" : <Type>
  mpir.signature %ty : !mpir.sort<Type>
  mpir.branch <param_args = [0, 1, 2], fixed_flags = [], fixed_flag_values = []> {
  ^bb0(%arg0: !mpir.sort<Type>, %arg1: !mpir.sort<Operand>, %arg2: !mpir.sort<Operand>):
    %k = mpir.var "k" : <Operand>
    %i_m = mpir.inst <mul> (%arg0, %arg1, %arg0, %k) <result_name = "m", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
    %i_ret = mpir.inst <add> (%arg0, %i_m, %arg0, %arg2) <result_name = "ret", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
    %0 = mpir_expr.read %k : (!mpir.sort<Operand>) -> !mpir.sort<Value>
    %1 = mpir_expr.int 3 : ui64 : <Integer>
    %2 = mpir_expr.call binary "=="(%0, %1) anchor %i_ret : (!mpir.sort<Value>, !mpir.sort<Integer>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
    mpir.require %2 : <Boolean>
    mpir.yield %i_ret : <Instruction>
  }
}
mpir.pattern {
  %0 = mpir.type.int 32 : <Type>
  %x = mpir.var "x" : <Operand>
  %y = mpir.var "y" : <Operand>
  %u_r = mpir.use @mulAdd (%0, %x, %0, %y) <result_name = "r", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
  %1 = mpir.type.int 32 : <Type>
  %u_s = mpir.use @mulAdd (%1, %u_r, %1, %y) <result_name = "s", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
}
// CHECK-LABEL:   mpir.matcher @mulAdd <supported_flags = [], syntax = 1, arity = 2, param_names = ["ty", "a", "b"], param_is_type = [true, false, false]> {
// CHECK:           %[[VAR_0:.*]] = mpir.var "ty" : <Type>
// CHECK:           mpir.signature %[[VAR_0]] : !mpir.sort<Type>
// CHECK:           mpir.branch <param_args = [0, 1, 2], fixed_flags = [], fixed_flag_values = []> {
// CHECK:           ^bb0(%[[VAL_0:.*]]: !mpir.sort<Type>, %[[VAL_1:.*]]: !mpir.sort<Operand>, %[[VAL_2:.*]]: !mpir.sort<Operand>):
// CHECK:             %[[VAR_1:.*]] = mpir.var "k" : <Operand>
// CHECK:             %[[INST_0:.*]] = mpir.inst <mul> (%[[VAL_0]], %[[VAL_1]], %[[VAL_0]], %[[VAR_1]]) <result_name = "m", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:             %[[INST_1:.*]] = mpir.inst <add> (%[[VAL_0]], %[[INST_0]], %[[VAL_0]], %[[VAL_2]]) <result_name = "ret", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:             %[[READ_0:.*]] = mpir_expr.read %[[VAR_1]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
// CHECK:             %[[INT_0:.*]] = mpir_expr.int 3 : ui64 : <Integer>
// CHECK:             %[[CALL_0:.*]] = mpir_expr.call binary "=="(%[[READ_0]], %[[INT_0]]) anchor %[[INST_1]] : (!mpir.sort<Value>, !mpir.sort<Integer>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:             mpir.require %[[CALL_0]] : <Boolean>
// CHECK:             mpir.yield %[[INST_1]] : <Instruction>
// CHECK:           }
// CHECK:         }
// CHECK-LABEL:   mpir.pattern {
// CHECK:           %[[TYPE_0:.*]] = mpir.type.int 32 : <Type>
// CHECK:           %[[VAR_0:.*]] = mpir.var "x" : <Operand>
// CHECK:           %[[VAR_1:.*]] = mpir.var "y" : <Operand>
// CHECK:           %[[ALT_0:.*]] = mpir.alt {
// CHECK:             %[[VAR_2:.*]] = mpir.var "r$k" : <Operand>
// CHECK:             %[[INST_0:.*]] = mpir.inst <mul> (%[[TYPE_0]], %[[VAR_0]], %[[TYPE_0]], %[[VAR_2]]) <result_name = "r$m", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:             %[[INST_1:.*]] = mpir.inst <add> (%[[TYPE_0]], %[[INST_0]], %[[TYPE_0]], %[[VAR_1]]) <result_name = "r", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:             %[[READ_0:.*]] = mpir_expr.read %[[VAR_2]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
// CHECK:             %[[INT_0:.*]] = mpir_expr.int 3 : ui64 : <Integer>
// CHECK:             %[[CALL_0:.*]] = mpir_expr.call binary "=="(%[[READ_0]], %[[INT_0]]) anchor %[[INST_1]] : (!mpir.sort<Value>, !mpir.sort<Integer>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:             mpir.require %[[CALL_0]] : <Boolean>
// CHECK:             mpir.yield %[[INST_1]] : <Instruction>
// CHECK:           } attributes {result_name = "r"} : <Instruction>
// CHECK:           %[[TYPE_1:.*]] = mpir.type.int 32 : <Type>
// CHECK:           %[[ALT_1:.*]] = mpir.alt {
// CHECK:             %[[VAR_3:.*]] = mpir.var "s$k" : <Operand>
// CHECK:             %[[INST_2:.*]] = mpir.inst <mul> (%[[TYPE_1]], %[[ALT_0]], %[[TYPE_1]], %[[VAR_3]]) <result_name = "s$m", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:             %[[INST_3:.*]] = mpir.inst <add> (%[[TYPE_1]], %[[INST_2]], %[[TYPE_1]], %[[VAR_1]]) <result_name = "s", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:             %[[READ_1:.*]] = mpir_expr.read %[[VAR_3]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
// CHECK:             %[[INT_1:.*]] = mpir_expr.int 3 : ui64 : <Integer>
// CHECK:             %[[CALL_1:.*]] = mpir_expr.call binary "=="(%[[READ_1]], %[[INT_1]]) anchor %[[INST_3]] : (!mpir.sort<Value>, !mpir.sort<Integer>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:             mpir.require %[[CALL_1]] : <Boolean>
// CHECK:             mpir.yield %[[INST_3]] : <Instruction>
// CHECK:           } attributes {result_name = "s"} : <Instruction>
// CHECK:         }

// -----

// A matcher that uses another: expanded until none is left.
mpir.matcher @addOrSub <supported_flags = [], syntax = 1, arity = 2, param_names = ["ty", "a", "b"], param_is_type = [true, false, false]> {
  %ty = mpir.var "ty" : <Type>
  mpir.signature %ty : !mpir.sort<Type>
  mpir.branch <param_args = [0, 1, 2], fixed_flags = [], fixed_flag_values = []> {
  ^bb0(%arg0: !mpir.sort<Type>, %arg1: !mpir.sort<Operand>, %arg2: !mpir.sort<Operand>):
    %i_ret = mpir.inst <add> (%arg0, %arg1, %arg0, %arg2) <result_name = "ret", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
    mpir.yield %i_ret : <Instruction>
  }
  mpir.branch <param_args = [0, 1, 2], fixed_flags = [], fixed_flag_values = []> {
  ^bb0(%arg0: !mpir.sort<Type>, %arg1: !mpir.sort<Operand>, %arg2: !mpir.sort<Operand>):
    %i_ret = mpir.inst <sub> (%arg0, %arg1, %arg0, %arg2) <result_name = "ret", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
    mpir.yield %i_ret : <Instruction>
  }
}
mpir.matcher @outer <supported_flags = [], syntax = 1, arity = 2, param_names = ["ty", "a", "b"], param_is_type = [true, false, false]> {
  %ty = mpir.var "ty" : <Type>
  mpir.signature %ty : !mpir.sort<Type>
  mpir.branch <param_args = [0, 1, 2], fixed_flags = [], fixed_flag_values = []> {
  ^bb0(%arg0: !mpir.sort<Type>, %arg1: !mpir.sort<Operand>, %arg2: !mpir.sort<Operand>):
    %u_inner = mpir.use @addOrSub (%arg0, %arg1, %arg0, %arg2) <result_name = "inner", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
    %i_ret = mpir.inst <mul> (%arg0, %u_inner, %arg0, %arg2) <result_name = "ret", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
    mpir.yield %i_ret : <Instruction>
  }
}
mpir.pattern {
  %0 = mpir.type.int 32 : <Type>
  %x = mpir.var "x" : <Operand>
  %y = mpir.var "y" : <Operand>
  %u_r = mpir.use @outer (%0, %x, %0, %y) <result_name = "r", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
}
// CHECK-LABEL:   mpir.matcher @addOrSub <supported_flags = [], syntax = 1, arity = 2, param_names = ["ty", "a", "b"], param_is_type = [true, false, false]> {
// CHECK:           %[[VAR_0:.*]] = mpir.var "ty" : <Type>
// CHECK:           mpir.signature %[[VAR_0]] : !mpir.sort<Type>
// CHECK:           mpir.branch <param_args = [0, 1, 2], fixed_flags = [], fixed_flag_values = []> {
// CHECK:           ^bb0(%[[VAL_0:.*]]: !mpir.sort<Type>, %[[VAL_1:.*]]: !mpir.sort<Operand>, %[[VAL_2:.*]]: !mpir.sort<Operand>):
// CHECK:             %[[INST_0:.*]] = mpir.inst <add> (%[[VAL_0]], %[[VAL_1]], %[[VAL_0]], %[[VAL_2]]) <result_name = "ret", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:             mpir.yield %[[INST_0]] : <Instruction>
// CHECK:           }
// CHECK:           mpir.branch <param_args = [0, 1, 2], fixed_flags = [], fixed_flag_values = []> {
// CHECK:           ^bb0(%[[VAL_3:.*]]: !mpir.sort<Type>, %[[VAL_4:.*]]: !mpir.sort<Operand>, %[[VAL_5:.*]]: !mpir.sort<Operand>):
// CHECK:             %[[INST_1:.*]] = mpir.inst <sub> (%[[VAL_3]], %[[VAL_4]], %[[VAL_3]], %[[VAL_5]]) <result_name = "ret", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:             mpir.yield %[[INST_1]] : <Instruction>
// CHECK:           }
// CHECK:         }
// CHECK-LABEL:   mpir.matcher @outer <supported_flags = [], syntax = 1, arity = 2, param_names = ["ty", "a", "b"], param_is_type = [true, false, false]> {
// CHECK:           %[[VAR_0:.*]] = mpir.var "ty" : <Type>
// CHECK:           mpir.signature %[[VAR_0]] : !mpir.sort<Type>
// CHECK:           mpir.branch <param_args = [0, 1, 2], fixed_flags = [], fixed_flag_values = []> {
// CHECK:           ^bb0(%[[VAL_0:.*]]: !mpir.sort<Type>, %[[VAL_1:.*]]: !mpir.sort<Operand>, %[[VAL_2:.*]]: !mpir.sort<Operand>):
// CHECK:             %[[USE_0:.*]] = mpir.use @addOrSub (%[[VAL_0]], %[[VAL_1]], %[[VAL_0]], %[[VAL_2]]) <result_name = "inner", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:             %[[INST_0:.*]] = mpir.inst <mul> (%[[VAL_0]], %[[USE_0]], %[[VAL_0]], %[[VAL_2]]) <result_name = "ret", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:             mpir.yield %[[INST_0]] : <Instruction>
// CHECK:           }
// CHECK:         }
// CHECK-LABEL:   mpir.pattern {
// CHECK:           %[[TYPE_0:.*]] = mpir.type.int 32 : <Type>
// CHECK:           %[[VAR_0:.*]] = mpir.var "x" : <Operand>
// CHECK:           %[[VAR_1:.*]] = mpir.var "y" : <Operand>
// CHECK:           %[[ALT_0:.*]] = mpir.alt {
// CHECK:             %[[ALT_1:.*]] = mpir.alt {
// CHECK:               %[[INST_0:.*]] = mpir.inst <add> (%[[TYPE_0]], %[[VAR_0]], %[[TYPE_0]], %[[VAR_1]]) <result_name = "r$inner", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:               mpir.yield %[[INST_0]] : <Instruction>
// CHECK:             }, {
// CHECK:               %[[INST_1:.*]] = mpir.inst <sub> (%[[TYPE_0]], %[[VAR_0]], %[[TYPE_0]], %[[VAR_1]]) <result_name = "r$inner", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:               mpir.yield %[[INST_1]] : <Instruction>
// CHECK:             } attributes {result_name = "r$inner"} : <Instruction>
// CHECK:             %[[INST_2:.*]] = mpir.inst <mul> (%[[TYPE_0]], %[[ALT_1]], %[[TYPE_0]], %[[VAR_1]]) <result_name = "r", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:             mpir.yield %[[INST_2]] : <Instruction>
// CHECK:           } attributes {result_name = "r"} : <Instruction>
// CHECK:         }

// -----

// A use that is not named gets a number.
mpir.matcher @addOrSub <supported_flags = [], syntax = 1, arity = 2, param_names = ["ty", "a", "b"], param_is_type = [true, false, false]> {
  %ty = mpir.var "ty" : <Type>
  mpir.signature %ty : !mpir.sort<Type>
  mpir.branch <param_args = [0, 1, 2], fixed_flags = [], fixed_flag_values = []> {
  ^bb0(%arg0: !mpir.sort<Type>, %arg1: !mpir.sort<Operand>, %arg2: !mpir.sort<Operand>):
    %i_ret = mpir.inst <add> (%arg0, %arg1, %arg0, %arg2) <result_name = "ret", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
    mpir.yield %i_ret : <Instruction>
  }
  mpir.branch <param_args = [0, 1, 2], fixed_flags = [], fixed_flag_values = []> {
  ^bb0(%arg0: !mpir.sort<Type>, %arg1: !mpir.sort<Operand>, %arg2: !mpir.sort<Operand>):
    %i_ret = mpir.inst <sub> (%arg0, %arg1, %arg0, %arg2) <result_name = "ret", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
    mpir.yield %i_ret : <Instruction>
  }
}
mpir.pattern {
  %0 = mpir.type.int 32 : <Type>
  %x = mpir.var "x" : <Operand>
  %y = mpir.var "y" : <Operand>
  %i_a = mpir.inst <mul> (%0, %x, %0, %y) <result_name = "a", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
  %1 = mpir.type.int 32 : <Type>
  %2 = mpir.use @addOrSub (%1, %i_a, %1, %y) <flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
}
// CHECK-LABEL:   mpir.matcher @addOrSub <supported_flags = [], syntax = 1, arity = 2, param_names = ["ty", "a", "b"], param_is_type = [true, false, false]> {
// CHECK:           %[[VAR_0:.*]] = mpir.var "ty" : <Type>
// CHECK:           mpir.signature %[[VAR_0]] : !mpir.sort<Type>
// CHECK:           mpir.branch <param_args = [0, 1, 2], fixed_flags = [], fixed_flag_values = []> {
// CHECK:           ^bb0(%[[VAL_0:.*]]: !mpir.sort<Type>, %[[VAL_1:.*]]: !mpir.sort<Operand>, %[[VAL_2:.*]]: !mpir.sort<Operand>):
// CHECK:             %[[INST_0:.*]] = mpir.inst <add> (%[[VAL_0]], %[[VAL_1]], %[[VAL_0]], %[[VAL_2]]) <result_name = "ret", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:             mpir.yield %[[INST_0]] : <Instruction>
// CHECK:           }
// CHECK:           mpir.branch <param_args = [0, 1, 2], fixed_flags = [], fixed_flag_values = []> {
// CHECK:           ^bb0(%[[VAL_3:.*]]: !mpir.sort<Type>, %[[VAL_4:.*]]: !mpir.sort<Operand>, %[[VAL_5:.*]]: !mpir.sort<Operand>):
// CHECK:             %[[INST_1:.*]] = mpir.inst <sub> (%[[VAL_3]], %[[VAL_4]], %[[VAL_3]], %[[VAL_5]]) <result_name = "ret", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:             mpir.yield %[[INST_1]] : <Instruction>
// CHECK:           }
// CHECK:         }
// CHECK-LABEL:   mpir.pattern {
// CHECK:           %[[TYPE_0:.*]] = mpir.type.int 32 : <Type>
// CHECK:           %[[VAR_0:.*]] = mpir.var "x" : <Operand>
// CHECK:           %[[VAR_1:.*]] = mpir.var "y" : <Operand>
// CHECK:           %[[INST_0:.*]] = mpir.inst <mul> (%[[TYPE_0]], %[[VAR_0]], %[[TYPE_0]], %[[VAR_1]]) <result_name = "a", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:           %[[TYPE_1:.*]] = mpir.type.int 32 : <Type>
// CHECK:           %[[ALT_0:.*]] = mpir.alt {
// CHECK:             %[[INST_1:.*]] = mpir.inst <add> (%[[TYPE_1]], %[[INST_0]], %[[TYPE_1]], %[[VAR_1]]) <flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:             mpir.yield %[[INST_1]] : <Instruction>
// CHECK:           }, {
// CHECK:             %[[INST_2:.*]] = mpir.inst <sub> (%[[TYPE_1]], %[[INST_0]], %[[TYPE_1]], %[[VAR_1]]) <flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:             mpir.yield %[[INST_2]] : <Instruction>
// CHECK:           } : <Instruction>
// CHECK:         }

// -----

// The use's capture names the root, and the root's own capture is the
// use's.
mpir.matcher @capt <supported_flags = [], syntax = 1, arity = 2, param_names = ["ty", "a", "b"], param_is_type = [true, false, false]> {
  %ty = mpir.var "ty" : <Type>
  mpir.signature %ty : !mpir.sort<Type>
  mpir.branch <param_args = [0, 1, 2], fixed_flags = [], fixed_flag_values = []> {
  ^bb0(%arg0: !mpir.sort<Type>, %arg1: !mpir.sort<Operand>, %arg2: !mpir.sort<Operand>):
    %self = mpir.var "self" : <Instruction>
    %i_ret = mpir.inst <add> capture %self (%arg0, %arg1, %arg0, %arg2) <result_name = "ret", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
    %0 = mpir_expr.read %self : (!mpir.sort<Instruction>) -> !mpir.sort<Value>
    %1 = mpir_expr.call call "hasOneUse"(%0) anchor %i_ret : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
    mpir.require %1 : <Boolean>
    mpir.yield %i_ret : <Instruction>
  }
}
mpir.pattern {
  %mine = mpir.var "mine" : <Instruction>
  %0 = mpir.type.int 32 : <Type>
  %x = mpir.var "x" : <Operand>
  %y = mpir.var "y" : <Operand>
  %u_r = mpir.use @capt capture %mine (%0, %x, %0, %y) <result_name = "r", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
  %1 = mpir.type.int 32 : <Type>
  %u_s = mpir.use @capt (%1, %u_r, %1, %y) <result_name = "s", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
}
// CHECK-LABEL:   mpir.matcher @capt <supported_flags = [], syntax = 1, arity = 2, param_names = ["ty", "a", "b"], param_is_type = [true, false, false]> {
// CHECK:           %[[VAR_0:.*]] = mpir.var "ty" : <Type>
// CHECK:           mpir.signature %[[VAR_0]] : !mpir.sort<Type>
// CHECK:           mpir.branch <param_args = [0, 1, 2], fixed_flags = [], fixed_flag_values = []> {
// CHECK:           ^bb0(%[[VAL_0:.*]]: !mpir.sort<Type>, %[[VAL_1:.*]]: !mpir.sort<Operand>, %[[VAL_2:.*]]: !mpir.sort<Operand>):
// CHECK:             %[[VAR_1:.*]] = mpir.var "self" : <Instruction>
// CHECK:             %[[INST_0:.*]] = mpir.inst <add> capture %[[VAR_1]] (%[[VAL_0]], %[[VAL_1]], %[[VAL_0]], %[[VAL_2]]) <result_name = "ret", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:             %[[READ_0:.*]] = mpir_expr.read %[[VAR_1]] : (!mpir.sort<Instruction>) -> !mpir.sort<Value>
// CHECK:             %[[CALL_0:.*]] = mpir_expr.call call "hasOneUse"(%[[READ_0]]) anchor %[[INST_0]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:             mpir.require %[[CALL_0]] : <Boolean>
// CHECK:             mpir.yield %[[INST_0]] : <Instruction>
// CHECK:           }
// CHECK:         }
// CHECK-LABEL:   mpir.pattern {
// CHECK:           %[[VAR_0:.*]] = mpir.var "mine" : <Instruction>
// CHECK:           %[[TYPE_0:.*]] = mpir.type.int 32 : <Type>
// CHECK:           %[[VAR_1:.*]] = mpir.var "x" : <Operand>
// CHECK:           %[[VAR_2:.*]] = mpir.var "y" : <Operand>
// CHECK:           %[[ALT_0:.*]] = mpir.alt {
// CHECK:             %[[INST_0:.*]] = mpir.inst <add> capture %[[VAR_0]] (%[[TYPE_0]], %[[VAR_1]], %[[TYPE_0]], %[[VAR_2]]) <result_name = "r", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:             %[[READ_0:.*]] = mpir_expr.read %[[VAR_0]] : (!mpir.sort<Instruction>) -> !mpir.sort<Value>
// CHECK:             %[[CALL_0:.*]] = mpir_expr.call call "hasOneUse"(%[[READ_0]]) anchor %[[INST_0]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:             mpir.require %[[CALL_0]] : <Boolean>
// CHECK:             mpir.yield %[[INST_0]] : <Instruction>
// CHECK:           } attributes {result_name = "r"} : <Instruction>
// CHECK:           %[[TYPE_1:.*]] = mpir.type.int 32 : <Type>
// CHECK:           %[[ALT_1:.*]] = mpir.alt {
// CHECK:             %[[VAR_3:.*]] = mpir.var "s$self" : <Instruction>
// CHECK:             %[[INST_1:.*]] = mpir.inst <add> capture %[[VAR_3]] (%[[TYPE_1]], %[[ALT_0]], %[[TYPE_1]], %[[VAR_2]]) <result_name = "s", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:             %[[READ_1:.*]] = mpir_expr.read %[[VAR_3]] : (!mpir.sort<Instruction>) -> !mpir.sort<Value>
// CHECK:             %[[CALL_1:.*]] = mpir_expr.call call "hasOneUse"(%[[READ_1]]) anchor %[[INST_1]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:             mpir.require %[[CALL_1]] : <Boolean>
// CHECK:             mpir.yield %[[INST_1]] : <Instruction>
// CHECK:           } attributes {result_name = "s"} : <Instruction>
// CHECK:         }

// -----

// ':o' on a use: its operand may stand for the use, bound to the capture.
mpir.matcher @addOrSub <supported_flags = [], syntax = 1, arity = 2, param_names = ["ty", "a", "b"], param_is_type = [true, false, false]> {
  %ty = mpir.var "ty" : <Type>
  mpir.signature %ty : !mpir.sort<Type>
  mpir.branch <param_args = [0, 1, 2], fixed_flags = [], fixed_flag_values = []> {
  ^bb0(%arg0: !mpir.sort<Type>, %arg1: !mpir.sort<Operand>, %arg2: !mpir.sort<Operand>):
    %i_ret = mpir.inst <add> (%arg0, %arg1, %arg0, %arg2) <result_name = "ret", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
    mpir.yield %i_ret : <Instruction>
  }
  mpir.branch <param_args = [0, 1, 2], fixed_flags = [], fixed_flag_values = []> {
  ^bb0(%arg0: !mpir.sort<Type>, %arg1: !mpir.sort<Operand>, %arg2: !mpir.sort<Operand>):
    %i_ret = mpir.inst <sub> (%arg0, %arg1, %arg0, %arg2) <result_name = "ret", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
    mpir.yield %i_ret : <Instruction>
  }
}
mpir.pattern {
  %c = mpir.var "c" : <Instruction>
  %0 = mpir.type.int 32 : <Type>
  %1 = mpir.int 0 : ui1 : <Value>
  %y = mpir.var "y" : <Operand>
  %u_r = mpir.use @addOrSub capture %c (%0, %1, %0, %y) <result_name = "r", flags = [], flag_modes = [], operand_kinds = [0, 0], metaflags = [#mpir.metaflag<"o", [1], loc(unknown)>]> : (!mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Value>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
  %2 = mpir.type.int 32 : <Type>
  %3 = mpir.int 1 : ui1 : <Value>
  %u_s = mpir.use @addOrSub (%2, %u_r, %2, %3) <result_name = "s", flags = [], flag_modes = [], operand_kinds = [0, 0], metaflags = [#mpir.metaflag<"o", [], loc(unknown)>]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
}
// CHECK-LABEL:   mpir.matcher @addOrSub <supported_flags = [], syntax = 1, arity = 2, param_names = ["ty", "a", "b"], param_is_type = [true, false, false]> {
// CHECK:           %[[VAR_0:.*]] = mpir.var "ty" : <Type>
// CHECK:           mpir.signature %[[VAR_0]] : !mpir.sort<Type>
// CHECK:           mpir.branch <param_args = [0, 1, 2], fixed_flags = [], fixed_flag_values = []> {
// CHECK:           ^bb0(%[[VAL_0:.*]]: !mpir.sort<Type>, %[[VAL_1:.*]]: !mpir.sort<Operand>, %[[VAL_2:.*]]: !mpir.sort<Operand>):
// CHECK:             %[[INST_0:.*]] = mpir.inst <add> (%[[VAL_0]], %[[VAL_1]], %[[VAL_0]], %[[VAL_2]]) <result_name = "ret", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:             mpir.yield %[[INST_0]] : <Instruction>
// CHECK:           }
// CHECK:           mpir.branch <param_args = [0, 1, 2], fixed_flags = [], fixed_flag_values = []> {
// CHECK:           ^bb0(%[[VAL_3:.*]]: !mpir.sort<Type>, %[[VAL_4:.*]]: !mpir.sort<Operand>, %[[VAL_5:.*]]: !mpir.sort<Operand>):
// CHECK:             %[[INST_1:.*]] = mpir.inst <sub> (%[[VAL_3]], %[[VAL_4]], %[[VAL_3]], %[[VAL_5]]) <result_name = "ret", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:             mpir.yield %[[INST_1]] : <Instruction>
// CHECK:           }
// CHECK:         }
// CHECK-LABEL:   mpir.pattern {
// CHECK:           %[[VAR_0:.*]] = mpir.var "c" : <Instruction>
// CHECK:           %[[TYPE_0:.*]] = mpir.type.int 32 : <Type>
// CHECK:           %[[INT_0:.*]] = mpir.int 0 : ui1 : <Value>
// CHECK:           %[[VAR_1:.*]] = mpir.var "y" : <Operand>
// CHECK:           %[[ALT_0:.*]] = mpir.alt {
// CHECK:             %[[INST_0:.*]] = mpir.inst <add> capture %[[VAR_0]] (%[[TYPE_0]], %[[INT_0]], %[[TYPE_0]], %[[VAR_1]]) <result_name = "r", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Value>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:             mpir.yield %[[INST_0]] : <Instruction>
// CHECK:           }, {
// CHECK:             %[[INST_1:.*]] = mpir.inst <sub> capture %[[VAR_0]] (%[[TYPE_0]], %[[INT_0]], %[[TYPE_0]], %[[VAR_1]]) <result_name = "r", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Value>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:             mpir.yield %[[INST_1]] : <Instruction>
// CHECK:           }, {
// CHECK:             mpir.bind %[[VAR_0]], %[[VAR_1]] : <Instruction>, <Operand>
// CHECK:             mpir.yield %[[VAR_1]] : <Operand>
// CHECK:           } attributes {or_self_of = "addOrSub", or_self_region = 2 : i32, result_name = "r"} : <Instruction>
// CHECK:           %[[TYPE_1:.*]] = mpir.type.int 32 : <Type>
// CHECK:           %[[INT_1:.*]] = mpir.int 1 : ui1 : <Value>
// CHECK:           %[[ALT_1:.*]] = mpir.alt {
// CHECK:             %[[INST_2:.*]] = mpir.inst <add> (%[[TYPE_1]], %[[ALT_0]], %[[TYPE_1]], %[[INT_1]]) <result_name = "s", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
// CHECK:             mpir.yield %[[INST_2]] : <Instruction>
// CHECK:           }, {
// CHECK:             %[[INST_3:.*]] = mpir.inst <sub> (%[[TYPE_1]], %[[ALT_0]], %[[TYPE_1]], %[[INT_1]]) <result_name = "s", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
// CHECK:             mpir.yield %[[INST_3]] : <Instruction>
// CHECK:           }, {
// CHECK:             mpir.yield %[[ALT_0]] : <Instruction>
// CHECK:           } attributes {or_self_of = "addOrSub", or_self_region = 2 : i32, result_name = "s"} : <Instruction>
// CHECK:         }

// -----

// The use's block and setting go to the instructions of the branch.
mpir.matcher @addOrSub <supported_flags = [], syntax = 1, arity = 2, param_names = ["ty", "a", "b"], param_is_type = [true, false, false]> {
  %ty = mpir.var "ty" : <Type>
  mpir.signature %ty : !mpir.sort<Type>
  mpir.branch <param_args = [0, 1, 2], fixed_flags = [], fixed_flag_values = []> {
  ^bb0(%arg0: !mpir.sort<Type>, %arg1: !mpir.sort<Operand>, %arg2: !mpir.sort<Operand>):
    %i_ret = mpir.inst <add> (%arg0, %arg1, %arg0, %arg2) <result_name = "ret", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
    mpir.yield %i_ret : <Instruction>
  }
  mpir.branch <param_args = [0, 1, 2], fixed_flags = [], fixed_flag_values = []> {
  ^bb0(%arg0: !mpir.sort<Type>, %arg1: !mpir.sort<Operand>, %arg2: !mpir.sort<Operand>):
    %i_ret = mpir.inst <sub> (%arg0, %arg1, %arg0, %arg2) <result_name = "ret", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
    mpir.yield %i_ret : <Instruction>
  }
}
mpir.pattern {
  %bb = mpir.var "bb" : <BasicBlock>
  %0 = mpir.type.int 32 : <Type>
  %x = mpir.var "x" : <Operand>
  %y = mpir.var "y" : <Operand>
  %u_r = mpir.use @addOrSub block %bb (%0, %x, %0, %y) <result_name = "r", flags = [], flag_modes = [], operand_kinds = [0, 0], treat_int_as_vec = true> : (!mpir.sort<BasicBlock>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
}
// CHECK-LABEL:   mpir.matcher @addOrSub <supported_flags = [], syntax = 1, arity = 2, param_names = ["ty", "a", "b"], param_is_type = [true, false, false]> {
// CHECK:           %[[VAR_0:.*]] = mpir.var "ty" : <Type>
// CHECK:           mpir.signature %[[VAR_0]] : !mpir.sort<Type>
// CHECK:           mpir.branch <param_args = [0, 1, 2], fixed_flags = [], fixed_flag_values = []> {
// CHECK:           ^bb0(%[[VAL_0:.*]]: !mpir.sort<Type>, %[[VAL_1:.*]]: !mpir.sort<Operand>, %[[VAL_2:.*]]: !mpir.sort<Operand>):
// CHECK:             %[[INST_0:.*]] = mpir.inst <add> (%[[VAL_0]], %[[VAL_1]], %[[VAL_0]], %[[VAL_2]]) <result_name = "ret", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:             mpir.yield %[[INST_0]] : <Instruction>
// CHECK:           }
// CHECK:           mpir.branch <param_args = [0, 1, 2], fixed_flags = [], fixed_flag_values = []> {
// CHECK:           ^bb0(%[[VAL_3:.*]]: !mpir.sort<Type>, %[[VAL_4:.*]]: !mpir.sort<Operand>, %[[VAL_5:.*]]: !mpir.sort<Operand>):
// CHECK:             %[[INST_1:.*]] = mpir.inst <sub> (%[[VAL_3]], %[[VAL_4]], %[[VAL_3]], %[[VAL_5]]) <result_name = "ret", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:             mpir.yield %[[INST_1]] : <Instruction>
// CHECK:           }
// CHECK:         }
// CHECK-LABEL:   mpir.pattern {
// CHECK:           %[[VAR_0:.*]] = mpir.var "bb" : <BasicBlock>
// CHECK:           %[[TYPE_0:.*]] = mpir.type.int 32 : <Type>
// CHECK:           %[[VAR_1:.*]] = mpir.var "x" : <Operand>
// CHECK:           %[[VAR_2:.*]] = mpir.var "y" : <Operand>
// CHECK:           %[[ALT_0:.*]] = mpir.alt {
// CHECK:             %[[INST_0:.*]] = mpir.inst <add> block %[[VAR_0]] (%[[TYPE_0]], %[[VAR_1]], %[[TYPE_0]], %[[VAR_2]]) <result_name = "r", flags = [], flag_modes = [], operand_kinds = [0, 0], treat_int_as_vec = true> : (!mpir.sort<BasicBlock>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:             mpir.yield %[[INST_0]] : <Instruction>
// CHECK:           }, {
// CHECK:             %[[INST_1:.*]] = mpir.inst <sub> block %[[VAR_0]] (%[[TYPE_0]], %[[VAR_1]], %[[TYPE_0]], %[[VAR_2]]) <result_name = "r", flags = [], flag_modes = [], operand_kinds = [0, 0], treat_int_as_vec = true> : (!mpir.sort<BasicBlock>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:             mpir.yield %[[INST_1]] : <Instruction>
// CHECK:           } attributes {result_name = "r"} : <Instruction>
// CHECK:         }

// -----

// Metaflags in a branch and on the use, already constraints: the branch's
// are in its region, and read the root by the use's capture.
mpir.matcher @addz <supported_flags = [], syntax = 1, arity = 2, param_names = ["ty", "a", "b"], param_is_type = [true, false, false]> {
  %ty = mpir.var "ty" : <Type>
  mpir.signature %ty : !mpir.sort<Type>
  mpir.branch <param_args = [0, 1, 2], fixed_flags = [], fixed_flag_values = []> {
  ^bb0(%arg0: !mpir.sort<Type>, %arg1: !mpir.sort<Operand>, %arg2: !mpir.sort<Operand>):
    %i_ret = mpir.inst <add> (%arg0, %arg1, %arg0, %arg2) <result_name = "ret", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
    %0 = mpir_expr.read %i_ret : (!mpir.sort<Instruction>) -> !mpir.sort<Value>
    %1 = mpir_expr.call call "hasOneUse"(%0) anchor %i_ret : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
    mpir.require %1 {from_metaflag} : <Boolean>
    %2 = mpir_expr.read %arg1 : (!mpir.sort<Operand>) -> !mpir.sort<Value>
    %3 = mpir_expr.call call "isZero"(%2) anchor %i_ret : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
    mpir.require %3 {from_metaflag} : <Boolean>
    mpir.yield %i_ret : <Instruction>
  }
}
mpir.pattern {
  %c = mpir.var "c" : <Instruction>
  %0 = mpir.type.int 32 : <Type>
  %x = mpir.var "x" : <Operand>
  %y = mpir.var "y" : <Operand>
  %u_r = mpir.use @addz capture %c (%0, %x, %0, %y) <result_name = "r", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
  %1 = mpir_expr.read %c : (!mpir.sort<Instruction>) -> !mpir.sort<Value>
  %2 = mpir_expr.call call "hasOneUse"(%1) anchor %u_r : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
  mpir.require %2 {from_metaflag} : <Boolean>
  %3 = mpir_expr.read %y : (!mpir.sort<Operand>) -> !mpir.sort<Value>
  %4 = mpir_expr.call call "isPower2"(%3) anchor %u_r : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
  mpir.require %4 {from_metaflag} : <Boolean>
}
// CHECK-LABEL:   mpir.matcher @addz <supported_flags = [], syntax = 1, arity = 2, param_names = ["ty", "a", "b"], param_is_type = [true, false, false]> {
// CHECK:           %[[VAR_0:.*]] = mpir.var "ty" : <Type>
// CHECK:           mpir.signature %[[VAR_0]] : !mpir.sort<Type>
// CHECK:           mpir.branch <param_args = [0, 1, 2], fixed_flags = [], fixed_flag_values = []> {
// CHECK:           ^bb0(%[[VAL_0:.*]]: !mpir.sort<Type>, %[[VAL_1:.*]]: !mpir.sort<Operand>, %[[VAL_2:.*]]: !mpir.sort<Operand>):
// CHECK:             %[[INST_0:.*]] = mpir.inst <add> (%[[VAL_0]], %[[VAL_1]], %[[VAL_0]], %[[VAL_2]]) <result_name = "ret", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:             %[[READ_0:.*]] = mpir_expr.read %[[INST_0]] : (!mpir.sort<Instruction>) -> !mpir.sort<Value>
// CHECK:             %[[CALL_0:.*]] = mpir_expr.call call "hasOneUse"(%[[READ_0]]) anchor %[[INST_0]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:             mpir.require %[[CALL_0]] {from_metaflag} : <Boolean>
// CHECK:             %[[READ_1:.*]] = mpir_expr.read %[[VAL_1]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
// CHECK:             %[[CALL_1:.*]] = mpir_expr.call call "isZero"(%[[READ_1]]) anchor %[[INST_0]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:             mpir.require %[[CALL_1]] {from_metaflag} : <Boolean>
// CHECK:             mpir.yield %[[INST_0]] : <Instruction>
// CHECK:           }
// CHECK:         }
// CHECK-LABEL:   mpir.pattern {
// CHECK:           %[[VAR_0:.*]] = mpir.var "c" : <Instruction>
// CHECK:           %[[TYPE_0:.*]] = mpir.type.int 32 : <Type>
// CHECK:           %[[VAR_1:.*]] = mpir.var "x" : <Operand>
// CHECK:           %[[VAR_2:.*]] = mpir.var "y" : <Operand>
// CHECK:           %[[ALT_0:.*]] = mpir.alt {
// CHECK:             %[[INST_0:.*]] = mpir.inst <add> capture %[[VAR_0]] (%[[TYPE_0]], %[[VAR_1]], %[[TYPE_0]], %[[VAR_2]]) <result_name = "r", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:             %[[READ_0:.*]] = mpir_expr.read %[[VAR_0]] : (!mpir.sort<Instruction>) -> !mpir.sort<Value>
// CHECK:             %[[CALL_0:.*]] = mpir_expr.call call "hasOneUse"(%[[READ_0]]) anchor %[[INST_0]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:             mpir.require %[[CALL_0]] {from_metaflag} : <Boolean>
// CHECK:             %[[READ_1:.*]] = mpir_expr.read %[[VAR_1]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
// CHECK:             %[[CALL_1:.*]] = mpir_expr.call call "isZero"(%[[READ_1]]) anchor %[[INST_0]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:             mpir.require %[[CALL_1]] {from_metaflag} : <Boolean>
// CHECK:             mpir.yield %[[INST_0]] : <Instruction>
// CHECK:           } attributes {result_name = "r"} : <Instruction>
// CHECK:           %[[READ_2:.*]] = mpir_expr.read %[[VAR_0]] : (!mpir.sort<Instruction>) -> !mpir.sort<Value>
// CHECK:           %[[CALL_2:.*]] = mpir_expr.call call "hasOneUse"(%[[READ_2]]) anchor %[[ALT_0]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:           mpir.require %[[CALL_2]] {from_metaflag} : <Boolean>
// CHECK:           %[[READ_3:.*]] = mpir_expr.read %[[VAR_2]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
// CHECK:           %[[CALL_3:.*]] = mpir_expr.call call "isPower2"(%[[READ_3]]) anchor %[[ALT_0]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:           mpir.require %[[CALL_3]] {from_metaflag} : <Boolean>
// CHECK:         }

// -----

// A flag passed through two matchers: omitted in the outer use, it is
// omitted in the inner.
mpir.matcher @inner <supported_flags = [0], syntax = 1, arity = 2, param_names = ["ty", "a", "b"], param_is_type = [true, false, false]> {
  %ty = mpir.var "ty" : <Type>
  mpir.signature %ty : !mpir.sort<Type>
  mpir.branch <param_args = [0, 1, 2], fixed_flags = [], fixed_flag_values = []> {
  ^bb0(%arg0: !mpir.sort<Type>, %arg1: !mpir.sort<Operand>, %arg2: !mpir.sort<Operand>):
    %f = mpir.var "f" : <Boolean>
    %i_ret = mpir.inst <add> flags(%f) (%arg0, %arg1, %arg0, %arg2) <result_name = "ret", flags = [0], flag_modes = [2], operand_kinds = [0, 0]> : (!mpir.sort<Boolean>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
    mpir.yield %i_ret : <Instruction>
  }
}
mpir.matcher @outer <supported_flags = [0], syntax = 1, arity = 2, param_names = ["ty", "a", "b"], param_is_type = [true, false, false]> {
  %ty = mpir.var "ty" : <Type>
  mpir.signature %ty : !mpir.sort<Type>
  mpir.branch <param_args = [0, 1, 2], fixed_flags = [], fixed_flag_values = []> {
  ^bb0(%arg0: !mpir.sort<Type>, %arg1: !mpir.sort<Operand>, %arg2: !mpir.sort<Operand>):
    %g = mpir.var "g" : <Boolean>
    %u_ret = mpir.use @inner flags(%g) (%arg0, %arg1, %arg0, %arg2) <result_name = "ret", flags = [0], flag_modes = [2], operand_kinds = [0, 0]> : (!mpir.sort<Boolean>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
    mpir.yield %u_ret : <Instruction>
  }
}
mpir.pattern {
  %0 = mpir.type.int 32 : <Type>
  %x = mpir.var "x" : <Operand>
  %y = mpir.var "y" : <Operand>
  %u_r = mpir.use @outer (%0, %x, %0, %y) <result_name = "r", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
  %1 = mpir.type.int 32 : <Type>
  %u_s = mpir.use @outer (%1, %u_r, %1, %y) <result_name = "s", flags = [0], flag_modes = [0], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
}
// CHECK-LABEL:   mpir.matcher @inner <supported_flags = [0], syntax = 1, arity = 2, param_names = ["ty", "a", "b"], param_is_type = [true, false, false]> {
// CHECK:           %[[VAR_0:.*]] = mpir.var "ty" : <Type>
// CHECK:           mpir.signature %[[VAR_0]] : !mpir.sort<Type>
// CHECK:           mpir.branch <param_args = [0, 1, 2], fixed_flags = [], fixed_flag_values = []> {
// CHECK:           ^bb0(%[[VAL_0:.*]]: !mpir.sort<Type>, %[[VAL_1:.*]]: !mpir.sort<Operand>, %[[VAL_2:.*]]: !mpir.sort<Operand>):
// CHECK:             %[[VAR_1:.*]] = mpir.var "f" : <Boolean>
// CHECK:             %[[INST_0:.*]] = mpir.inst <add> flags(%[[VAR_1]]) (%[[VAL_0]], %[[VAL_1]], %[[VAL_0]], %[[VAL_2]]) <result_name = "ret", flags = [0], flag_modes = [2], operand_kinds = [0, 0]> : (!mpir.sort<Boolean>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:             mpir.yield %[[INST_0]] : <Instruction>
// CHECK:           }
// CHECK:         }
// CHECK-LABEL:   mpir.matcher @outer <supported_flags = [0], syntax = 1, arity = 2, param_names = ["ty", "a", "b"], param_is_type = [true, false, false]> {
// CHECK:           %[[VAR_0:.*]] = mpir.var "ty" : <Type>
// CHECK:           mpir.signature %[[VAR_0]] : !mpir.sort<Type>
// CHECK:           mpir.branch <param_args = [0, 1, 2], fixed_flags = [], fixed_flag_values = []> {
// CHECK:           ^bb0(%[[VAL_0:.*]]: !mpir.sort<Type>, %[[VAL_1:.*]]: !mpir.sort<Operand>, %[[VAL_2:.*]]: !mpir.sort<Operand>):
// CHECK:             %[[VAR_1:.*]] = mpir.var "g" : <Boolean>
// CHECK:             %[[USE_0:.*]] = mpir.use @inner flags(%[[VAR_1]]) (%[[VAL_0]], %[[VAL_1]], %[[VAL_0]], %[[VAL_2]]) <result_name = "ret", flags = [0], flag_modes = [2], operand_kinds = [0, 0]> : (!mpir.sort<Boolean>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:             mpir.yield %[[USE_0]] : <Instruction>
// CHECK:           }
// CHECK:         }
// CHECK-LABEL:   mpir.pattern {
// CHECK:           %[[TYPE_0:.*]] = mpir.type.int 32 : <Type>
// CHECK:           %[[VAR_0:.*]] = mpir.var "x" : <Operand>
// CHECK:           %[[VAR_1:.*]] = mpir.var "y" : <Operand>
// CHECK:           %[[VAR_2:.*]] = mpir.var "_flag$r$nsw" : <Boolean>
// CHECK:           %[[ALT_0:.*]] = mpir.alt {
// CHECK:             %[[VAR_3:.*]] = mpir.var "_flag$r$nsw" : <Boolean>
// CHECK:             %[[ALT_1:.*]] = mpir.alt {
// CHECK:               %[[INST_0:.*]] = mpir.inst <add> flags(%[[VAR_3]]) (%[[TYPE_0]], %[[VAR_0]], %[[TYPE_0]], %[[VAR_1]]) <result_name = "r", flags = [0], flag_modes = [2], operand_kinds = [0, 0]> : (!mpir.sort<Boolean>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:               mpir.yield %[[INST_0]] : <Instruction>
// CHECK:             } attributes {result_name = "r"} : <Instruction>
// CHECK:             mpir.yield %[[ALT_1]] : <Instruction>
// CHECK:           } attributes {result_name = "r"} : <Instruction>
// CHECK:           %[[TYPE_1:.*]] = mpir.type.int 32 : <Type>
// CHECK:           %[[INT_0:.*]] = mpir.int 1 : ui1 : <Value>
// CHECK:           %[[ALT_2:.*]] = mpir.alt {
// CHECK:             %[[INT_1:.*]] = mpir.int 1 : ui1 : <Value>
// CHECK:             %[[ALT_3:.*]] = mpir.alt {
// CHECK:               %[[INST_1:.*]] = mpir.inst <add> (%[[TYPE_1]], %[[ALT_0]], %[[TYPE_1]], %[[VAR_1]]) <result_name = "s", flags = [0], flag_modes = [0], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:               mpir.yield %[[INST_1]] : <Instruction>
// CHECK:             } attributes {result_name = "s"} : <Instruction>
// CHECK:             mpir.yield %[[ALT_3]] : <Instruction>
// CHECK:           } attributes {result_name = "s"} : <Instruction>
// CHECK:         }

// -----

// A fixed parameter type of another width, or of another shape, than the
// use's: no branch fits.
mpir.matcher @pick <supported_flags = [], syntax = 0, arity = 3, param_names = ["", "c", "", "t", "", "f"], param_is_type = [true, false, true, false, true, false]> {
  %0 = mpir.type.int 1 : <Type>
  %1 = mpir.type.int 8 : <Type>
  %2 = mpir.type.seq array 4 x %1 : (!mpir.sort<Type>) -> !mpir.sort<Type>
  %3 = mpir.type.int 8 : <Type>
  %4 = mpir.type.int 8 : <Type>
  %5 = mpir.type.struct{%3, %4} : (!mpir.sort<Type>, !mpir.sort<Type>) -> !mpir.sort<Type>
  mpir.signature %0, %2, %5 : !mpir.sort<Type>, !mpir.sort<Type>, !mpir.sort<Type>
  mpir.branch <param_args = [-1, 0, -1, 1, -1, 2], fixed_flags = [], fixed_flag_values = []> {
  ^bb0(%arg0: !mpir.sort<Boolean>, %arg1: !mpir.sort<Operand>, %arg2: !mpir.sort<Unknown>):
    %6 = mpir.type.int 1 : <Type>
    %7 = mpir.type.int 8 : <Type>
    %8 = mpir.type.seq array 4 x %7 : (!mpir.sort<Type>) -> !mpir.sort<Type>
    %9 = mpir.type.int 8 : <Type>
    %10 = mpir.type.seq array 4 x %9 : (!mpir.sort<Type>) -> !mpir.sort<Type>
    %i_ret = mpir.inst <select> (%6, %arg0, %8, %arg1, %10, %arg1) <result_name = "ret", flags = [], flag_modes = [], operand_kinds = [0, 0, 0]> : (!mpir.sort<Type>, !mpir.sort<Boolean>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
    mpir.yield %i_ret : <Instruction>
  }
}
mpir.pattern {
  %0 = mpir.type.int 8 : <Type>
  %cond = mpir.var "cond" : <Boolean>
  %1 = mpir.type.int 8 : <Type>
  %2 = mpir.type.seq array 4 x %1 : (!mpir.sort<Type>) -> !mpir.sort<Type>
  %a = mpir.var "a" : <Operand>
  %3 = mpir.type.int 8 : <Type>
  %4 = mpir.type.int 8 : <Type>
  %5 = mpir.type.struct{%3, %4} : (!mpir.sort<Type>, !mpir.sort<Type>) -> !mpir.sort<Type>
  %b = mpir.var "b" : <Operand>
  %u_r = mpir.use @pick (%0, %cond, %2, %a, %5, %b) <result_name = "r", flags = [], flag_modes = [], operand_kinds = [0, 0, 0]> : (!mpir.sort<Type>, !mpir.sort<Boolean>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
  %6 = mpir.type.int 1 : <Type>
  %7 = mpir.type.int 8 : <Type>
  %8 = mpir.type.seq array 8 x %7 : (!mpir.sort<Type>) -> !mpir.sort<Type>
  %9 = mpir.type.int 8 : <Type>
  %10 = mpir.type.int 8 : <Type>
  %11 = mpir.type.struct{%9, %10} : (!mpir.sort<Type>, !mpir.sort<Type>) -> !mpir.sort<Type>
  %u_s = mpir.use @pick (%6, %cond, %8, %a, %11, %b) <result_name = "s", flags = [], flag_modes = [], operand_kinds = [0, 0, 0]> : (!mpir.sort<Type>, !mpir.sort<Boolean>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
  %12 = mpir.type.int 1 : <Type>
  %13 = mpir.type.int 8 : <Type>
  %14 = mpir.type.seq array 4 x %13 : (!mpir.sort<Type>) -> !mpir.sort<Type>
  %15 = mpir.type.int 8 : <Type>
  %16 = mpir.type.struct{%15} : (!mpir.sort<Type>) -> !mpir.sort<Type>
  %u_t = mpir.use @pick (%12, %cond, %14, %a, %16, %b) <result_name = "t", flags = [], flag_modes = [], operand_kinds = [0, 0, 0]> : (!mpir.sort<Type>, !mpir.sort<Boolean>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
  %17 = mpir.type.int 1 : <Type>
  %18 = mpir.type.int 16 : <Type>
  %19 = mpir.type.seq array 4 x %18 : (!mpir.sort<Type>) -> !mpir.sort<Type>
  %20 = mpir.type.int 8 : <Type>
  %21 = mpir.type.int 8 : <Type>
  %22 = mpir.type.struct{%20, %21} : (!mpir.sort<Type>, !mpir.sort<Type>) -> !mpir.sort<Type>
  %u_u = mpir.use @pick (%17, %cond, %19, %a, %22, %b) <result_name = "u", flags = [], flag_modes = [], operand_kinds = [0, 0, 0]> : (!mpir.sort<Type>, !mpir.sort<Boolean>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
  %23 = mpir.type.int 1 : <Type>
  %24 = mpir.type.int 8 : <Type>
  %25 = mpir.type.seq array 4 x %24 : (!mpir.sort<Type>) -> !mpir.sort<Type>
  %26 = mpir.type.int 8 : <Type>
  %27 = mpir.type.int 8 : <Type>
  %28 = mpir.type.struct{%26, %27} : (!mpir.sort<Type>, !mpir.sort<Type>) -> !mpir.sort<Type>
  %u_v = mpir.use @pick (%23, %cond, %25, %a, %28, %b) <result_name = "v", flags = [], flag_modes = [], operand_kinds = [0, 0, 0]> : (!mpir.sort<Type>, !mpir.sort<Boolean>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
}
// CHECK-LABEL:   mpir.matcher @pick <supported_flags = [], syntax = 0, arity = 3, param_names = ["", "c", "", "t", "", "f"], param_is_type = [true, false, true, false, true, false]> {
// CHECK:           %[[TYPE_0:.*]] = mpir.type.int 1 : <Type>
// CHECK:           %[[TYPE_1:.*]] = mpir.type.int 8 : <Type>
// CHECK:           %[[TYPE_2:.*]] = mpir.type.seq array 4 x %[[TYPE_1]] : (!mpir.sort<Type>) -> !mpir.sort<Type>
// CHECK:           %[[TYPE_3:.*]] = mpir.type.int 8 : <Type>
// CHECK:           %[[TYPE_4:.*]] = mpir.type.int 8 : <Type>
// CHECK:           %[[TYPE_5:.*]] = mpir.type.struct{%[[TYPE_3]], %[[TYPE_4]]} : (!mpir.sort<Type>, !mpir.sort<Type>) -> !mpir.sort<Type>
// CHECK:           mpir.signature %[[TYPE_0]], %[[TYPE_2]], %[[TYPE_5]] : !mpir.sort<Type>, !mpir.sort<Type>, !mpir.sort<Type>
// CHECK:           mpir.branch <param_args = [-1, 0, -1, 1, -1, 2], fixed_flags = [], fixed_flag_values = []> {
// CHECK:           ^bb0(%[[VAL_0:.*]]: !mpir.sort<Boolean>, %[[VAL_1:.*]]: !mpir.sort<Operand>, %[[VAL_2:.*]]: !mpir.sort<Unknown>):
// CHECK:             %[[TYPE_6:.*]] = mpir.type.int 1 : <Type>
// CHECK:             %[[TYPE_7:.*]] = mpir.type.int 8 : <Type>
// CHECK:             %[[TYPE_8:.*]] = mpir.type.seq array 4 x %[[TYPE_7]] : (!mpir.sort<Type>) -> !mpir.sort<Type>
// CHECK:             %[[TYPE_9:.*]] = mpir.type.int 8 : <Type>
// CHECK:             %[[TYPE_10:.*]] = mpir.type.seq array 4 x %[[TYPE_9]] : (!mpir.sort<Type>) -> !mpir.sort<Type>
// CHECK:             %[[INST_0:.*]] = mpir.inst <select> (%[[TYPE_6]], %[[VAL_0]], %[[TYPE_8]], %[[VAL_1]], %[[TYPE_10]], %[[VAL_1]]) <result_name = "ret", flags = [], flag_modes = [], operand_kinds = [0, 0, 0]> : (!mpir.sort<Type>, !mpir.sort<Boolean>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:             mpir.yield %[[INST_0]] : <Instruction>
// CHECK:           }
// CHECK:         }
// CHECK-LABEL:   mpir.pattern {
// CHECK:           %[[TYPE_0:.*]] = mpir.type.int 8 : <Type>
// CHECK:           %[[VAR_0:.*]] = mpir.var "cond" : <Boolean>
// CHECK:           %[[TYPE_1:.*]] = mpir.type.int 8 : <Type>
// CHECK:           %[[TYPE_2:.*]] = mpir.type.seq array 4 x %[[TYPE_1]] : (!mpir.sort<Type>) -> !mpir.sort<Type>
// CHECK:           %[[VAR_1:.*]] = mpir.var "a" : <Operand>
// CHECK:           %[[TYPE_3:.*]] = mpir.type.int 8 : <Type>
// CHECK:           %[[TYPE_4:.*]] = mpir.type.int 8 : <Type>
// CHECK:           %[[TYPE_5:.*]] = mpir.type.struct{%[[TYPE_3]], %[[TYPE_4]]} : (!mpir.sort<Type>, !mpir.sort<Type>) -> !mpir.sort<Type>
// CHECK:           %[[VAR_2:.*]] = mpir.var "b" : <Operand>
// CHECK:           %[[ALT_0:.*]] = mpir.alt  attributes {result_name = "r"} : <Instruction>
// CHECK:           %[[TYPE_6:.*]] = mpir.type.int 1 : <Type>
// CHECK:           %[[TYPE_7:.*]] = mpir.type.int 8 : <Type>
// CHECK:           %[[TYPE_8:.*]] = mpir.type.seq array 8 x %[[TYPE_7]] : (!mpir.sort<Type>) -> !mpir.sort<Type>
// CHECK:           %[[TYPE_9:.*]] = mpir.type.int 8 : <Type>
// CHECK:           %[[TYPE_10:.*]] = mpir.type.int 8 : <Type>
// CHECK:           %[[TYPE_11:.*]] = mpir.type.struct{%[[TYPE_9]], %[[TYPE_10]]} : (!mpir.sort<Type>, !mpir.sort<Type>) -> !mpir.sort<Type>
// CHECK:           %[[ALT_1:.*]] = mpir.alt  attributes {result_name = "s"} : <Instruction>
// CHECK:           %[[TYPE_12:.*]] = mpir.type.int 1 : <Type>
// CHECK:           %[[TYPE_13:.*]] = mpir.type.int 8 : <Type>
// CHECK:           %[[TYPE_14:.*]] = mpir.type.seq array 4 x %[[TYPE_13]] : (!mpir.sort<Type>) -> !mpir.sort<Type>
// CHECK:           %[[TYPE_15:.*]] = mpir.type.int 8 : <Type>
// CHECK:           %[[TYPE_16:.*]] = mpir.type.struct{%[[TYPE_15]]} : (!mpir.sort<Type>) -> !mpir.sort<Type>
// CHECK:           %[[ALT_2:.*]] = mpir.alt  attributes {result_name = "t"} : <Instruction>
// CHECK:           %[[TYPE_17:.*]] = mpir.type.int 1 : <Type>
// CHECK:           %[[TYPE_18:.*]] = mpir.type.int 16 : <Type>
// CHECK:           %[[TYPE_19:.*]] = mpir.type.seq array 4 x %[[TYPE_18]] : (!mpir.sort<Type>) -> !mpir.sort<Type>
// CHECK:           %[[TYPE_20:.*]] = mpir.type.int 8 : <Type>
// CHECK:           %[[TYPE_21:.*]] = mpir.type.int 8 : <Type>
// CHECK:           %[[TYPE_22:.*]] = mpir.type.struct{%[[TYPE_20]], %[[TYPE_21]]} : (!mpir.sort<Type>, !mpir.sort<Type>) -> !mpir.sort<Type>
// CHECK:           %[[ALT_3:.*]] = mpir.alt  attributes {result_name = "u"} : <Instruction>
// CHECK:           %[[TYPE_23:.*]] = mpir.type.int 1 : <Type>
// CHECK:           %[[TYPE_24:.*]] = mpir.type.int 8 : <Type>
// CHECK:           %[[TYPE_25:.*]] = mpir.type.seq array 4 x %[[TYPE_24]] : (!mpir.sort<Type>) -> !mpir.sort<Type>
// CHECK:           %[[TYPE_26:.*]] = mpir.type.int 8 : <Type>
// CHECK:           %[[TYPE_27:.*]] = mpir.type.int 8 : <Type>
// CHECK:           %[[TYPE_28:.*]] = mpir.type.struct{%[[TYPE_26]], %[[TYPE_27]]} : (!mpir.sort<Type>, !mpir.sort<Type>) -> !mpir.sort<Type>
// CHECK:           %[[ALT_4:.*]] = mpir.alt {
// CHECK:             %[[TYPE_29:.*]] = mpir.type.int 1 : <Type>
// CHECK:             %[[TYPE_30:.*]] = mpir.type.int 8 : <Type>
// CHECK:             %[[TYPE_31:.*]] = mpir.type.seq array 4 x %[[TYPE_30]] : (!mpir.sort<Type>) -> !mpir.sort<Type>
// CHECK:             %[[TYPE_32:.*]] = mpir.type.int 8 : <Type>
// CHECK:             %[[TYPE_33:.*]] = mpir.type.seq array 4 x %[[TYPE_32]] : (!mpir.sort<Type>) -> !mpir.sort<Type>
// CHECK:             %[[INST_0:.*]] = mpir.inst <select> (%[[TYPE_29]], %[[VAR_0]], %[[TYPE_31]], %[[VAR_1]], %[[TYPE_33]], %[[VAR_1]]) <result_name = "v", flags = [], flag_modes = [], operand_kinds = [0, 0, 0]> : (!mpir.sort<Type>, !mpir.sort<Boolean>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:             mpir.yield %[[INST_0]] : <Instruction>
// CHECK:           } attributes {result_name = "v"} : <Instruction>
// CHECK:         }

// -----

// Flags of a branch's other instructions, and those of its root the
// matcher does not declare, stay as written.
mpir.matcher @shifted <supported_flags = [2], syntax = 1, arity = 2, param_names = ["ty", "a", "b"], param_is_type = [true, false, false]> {
  %ty = mpir.var "ty" : <Type>
  mpir.signature %ty : !mpir.sort<Type>
  mpir.branch <param_args = [0, 1, 2], fixed_flags = [], fixed_flag_values = []> {
  ^bb0(%arg0: !mpir.sort<Type>, %arg1: !mpir.sort<Operand>, %arg2: !mpir.sort<Operand>):
    %u = mpir.var "u" : <Boolean>
    %i_s = mpir.inst <shl> flags(%u) (%arg0, %arg1, %arg0, %arg2) <result_name = "s", flags = [0, 1], flag_modes = [0, 2], operand_kinds = [0, 0]> : (!mpir.sort<Boolean>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
    %e = mpir.var "e" : <Boolean>
    %i_ret = mpir.inst <lshr> flags(%e) (%arg0, %i_s, %arg0, %arg2) <result_name = "ret", flags = [2], flag_modes = [2], operand_kinds = [0, 0]> : (!mpir.sort<Boolean>, !mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
    mpir.yield %i_ret : <Instruction>
  }
  mpir.branch <param_args = [0, 1, 2], fixed_flags = [], fixed_flag_values = []> {
  ^bb0(%arg0: !mpir.sort<Type>, %arg1: !mpir.sort<Operand>, %arg2: !mpir.sort<Operand>):
    %w = mpir.var "w" : <Boolean>
    %i_s = mpir.inst <add> flags(%w) (%arg0, %arg1, %arg0, %arg2) <result_name = "s", flags = [0], flag_modes = [2], operand_kinds = [0, 0]> : (!mpir.sort<Boolean>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
    %i_ret = mpir.inst <or> (%arg0, %i_s, %arg0, %arg2) <result_name = "ret", flags = [3], flag_modes = [0], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
    mpir.yield %i_ret : <Instruction>
  }
}
mpir.pattern {
  %0 = mpir.type.int 32 : <Type>
  %x = mpir.var "x" : <Operand>
  %y = mpir.var "y" : <Operand>
  %u_r = mpir.use @shifted (%0, %x, %0, %y) <result_name = "r", flags = [2], flag_modes = [0], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
}
// CHECK-LABEL:   mpir.matcher @shifted <supported_flags = [2], syntax = 1, arity = 2, param_names = ["ty", "a", "b"], param_is_type = [true, false, false]> {
// CHECK:           %[[VAR_0:.*]] = mpir.var "ty" : <Type>
// CHECK:           mpir.signature %[[VAR_0]] : !mpir.sort<Type>
// CHECK:           mpir.branch <param_args = [0, 1, 2], fixed_flags = [], fixed_flag_values = []> {
// CHECK:           ^bb0(%[[VAL_0:.*]]: !mpir.sort<Type>, %[[VAL_1:.*]]: !mpir.sort<Operand>, %[[VAL_2:.*]]: !mpir.sort<Operand>):
// CHECK:             %[[VAR_1:.*]] = mpir.var "u" : <Boolean>
// CHECK:             %[[INST_0:.*]] = mpir.inst <shl> flags(%[[VAR_1]]) (%[[VAL_0]], %[[VAL_1]], %[[VAL_0]], %[[VAL_2]]) <result_name = "s", flags = [0, 1], flag_modes = [0, 2], operand_kinds = [0, 0]> : (!mpir.sort<Boolean>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:             %[[VAR_2:.*]] = mpir.var "e" : <Boolean>
// CHECK:             %[[INST_1:.*]] = mpir.inst <lshr> flags(%[[VAR_2]]) (%[[VAL_0]], %[[INST_0]], %[[VAL_0]], %[[VAL_2]]) <result_name = "ret", flags = [2], flag_modes = [2], operand_kinds = [0, 0]> : (!mpir.sort<Boolean>, !mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:             mpir.yield %[[INST_1]] : <Instruction>
// CHECK:           }
// CHECK:           mpir.branch <param_args = [0, 1, 2], fixed_flags = [], fixed_flag_values = []> {
// CHECK:           ^bb0(%[[VAL_3:.*]]: !mpir.sort<Type>, %[[VAL_4:.*]]: !mpir.sort<Operand>, %[[VAL_5:.*]]: !mpir.sort<Operand>):
// CHECK:             %[[VAR_3:.*]] = mpir.var "w" : <Boolean>
// CHECK:             %[[INST_2:.*]] = mpir.inst <add> flags(%[[VAR_3]]) (%[[VAL_3]], %[[VAL_4]], %[[VAL_3]], %[[VAL_5]]) <result_name = "s", flags = [0], flag_modes = [2], operand_kinds = [0, 0]> : (!mpir.sort<Boolean>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:             %[[INST_3:.*]] = mpir.inst <or> (%[[VAL_3]], %[[INST_2]], %[[VAL_3]], %[[VAL_5]]) <result_name = "ret", flags = [3], flag_modes = [0], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:             mpir.yield %[[INST_3]] : <Instruction>
// CHECK:           }
// CHECK:         }
// CHECK-LABEL:   mpir.pattern {
// CHECK:           %[[TYPE_0:.*]] = mpir.type.int 32 : <Type>
// CHECK:           %[[VAR_0:.*]] = mpir.var "x" : <Operand>
// CHECK:           %[[VAR_1:.*]] = mpir.var "y" : <Operand>
// CHECK:           %[[INT_0:.*]] = mpir.int 1 : ui1 : <Value>
// CHECK:           %[[ALT_0:.*]] = mpir.alt {
// CHECK:             %[[VAR_2:.*]] = mpir.var "r$u" : <Boolean>
// CHECK:             %[[INST_0:.*]] = mpir.inst <shl> flags(%[[VAR_2]]) (%[[TYPE_0]], %[[VAR_0]], %[[TYPE_0]], %[[VAR_1]]) <result_name = "r$s", flags = [0, 1], flag_modes = [0, 2], operand_kinds = [0, 0]> : (!mpir.sort<Boolean>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:             %[[INST_1:.*]] = mpir.inst <lshr> (%[[TYPE_0]], %[[INST_0]], %[[TYPE_0]], %[[VAR_1]]) <result_name = "r", flags = [2], flag_modes = [0], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:             mpir.yield %[[INST_1]] : <Instruction>
// CHECK:           }, {
// CHECK:             %[[VAR_3:.*]] = mpir.var "r$w" : <Boolean>
// CHECK:             %[[INST_2:.*]] = mpir.inst <add> flags(%[[VAR_3]]) (%[[TYPE_0]], %[[VAR_0]], %[[TYPE_0]], %[[VAR_1]]) <result_name = "r$s", flags = [0], flag_modes = [2], operand_kinds = [0, 0]> : (!mpir.sort<Boolean>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:             %[[INST_3:.*]] = mpir.inst <or> (%[[TYPE_0]], %[[INST_2]], %[[TYPE_0]], %[[VAR_1]]) <result_name = "r", flags = [3], flag_modes = [0], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:             mpir.yield %[[INST_3]] : <Instruction>
// CHECK:           } attributes {result_name = "r"} : <Instruction>
// CHECK:         }

// -----

// The choices of a branch's instructions (':c', ':o') stay on them, for
// mpir-lower-alternatives.
mpir.matcher @commuted <supported_flags = [], syntax = 1, arity = 2, param_names = ["ty", "a", "b"], param_is_type = [true, false, false]> {
  %ty = mpir.var "ty" : <Type>
  mpir.signature %ty : !mpir.sort<Type>
  mpir.branch <param_args = [0, 1, 2], fixed_flags = [], fixed_flag_values = []> {
  ^bb0(%arg0: !mpir.sort<Type>, %arg1: !mpir.sort<Operand>, %arg2: !mpir.sort<Operand>):
    %0 = mpir.int 3 : ui2 : <Value>
    %i_m = mpir.inst <mul> (%arg0, %arg1, %arg0, %0) <result_name = "m", flags = [], flag_modes = [], operand_kinds = [0, 0], metaflags = [#mpir.metaflag<"c", [], loc(unknown)>]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
    %i_ret = mpir.inst <add> (%arg0, %arg2, %arg0, %i_m) <result_name = "ret", flags = [], flag_modes = [], operand_kinds = [0, 0], metaflags = [#mpir.metaflag<"o", [1], loc(unknown)>]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Instruction>) -> !mpir.sort<Instruction>
    mpir.yield %i_ret : <Instruction>
  }
}
mpir.pattern {
  %0 = mpir.type.int 32 : <Type>
  %x = mpir.var "x" : <Operand>
  %y = mpir.var "y" : <Operand>
  %u_r = mpir.use @commuted (%0, %x, %0, %y) <result_name = "r", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
}
// CHECK-LABEL:   mpir.matcher @commuted <supported_flags = [], syntax = 1, arity = 2, param_names = ["ty", "a", "b"], param_is_type = [true, false, false]> {
// CHECK:           %[[VAR_0:.*]] = mpir.var "ty" : <Type>
// CHECK:           mpir.signature %[[VAR_0]] : !mpir.sort<Type>
// CHECK:           mpir.branch <param_args = [0, 1, 2], fixed_flags = [], fixed_flag_values = []> {
// CHECK:           ^bb0(%[[VAL_0:.*]]: !mpir.sort<Type>, %[[VAL_1:.*]]: !mpir.sort<Operand>, %[[VAL_2:.*]]: !mpir.sort<Operand>):
// CHECK:             %[[INT_0:.*]] = mpir.int 3 : ui2 : <Value>
// CHECK:             %[[INST_0:.*]] = mpir.inst <mul> (%[[VAL_0]], %[[VAL_1]], %[[VAL_0]], %[[INT_0]]) <result_name = "m", flags = [], flag_modes = [], operand_kinds = [0, 0], metaflags = [#mpir.metaflag<"c", [], {{.*}}>]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
// CHECK:             %[[INST_1:.*]] = mpir.inst <add> (%[[VAL_0]], %[[VAL_2]], %[[VAL_0]], %[[INST_0]]) <result_name = "ret", flags = [], flag_modes = [], operand_kinds = [0, 0], metaflags = [#mpir.metaflag<"o", [1], {{.*}}>]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Instruction>) -> !mpir.sort<Instruction>
// CHECK:             mpir.yield %[[INST_1]] : <Instruction>
// CHECK:           }
// CHECK:         }
// CHECK-LABEL:   mpir.pattern {
// CHECK:           %[[TYPE_0:.*]] = mpir.type.int 32 : <Type>
// CHECK:           %[[VAR_0:.*]] = mpir.var "x" : <Operand>
// CHECK:           %[[VAR_1:.*]] = mpir.var "y" : <Operand>
// CHECK:           %[[ALT_0:.*]] = mpir.alt {
// CHECK:             %[[INT_0:.*]] = mpir.int 3 : ui2 : <Value>
// CHECK:             %[[INST_0:.*]] = mpir.inst <mul> (%[[TYPE_0]], %[[VAR_0]], %[[TYPE_0]], %[[INT_0]]) <result_name = "r$m", flags = [], flag_modes = [], operand_kinds = [0, 0], metaflags = [#mpir.metaflag<"c", [], {{.*}}>]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
// CHECK:             %[[INST_1:.*]] = mpir.inst <add> (%[[TYPE_0]], %[[VAR_1]], %[[TYPE_0]], %[[INST_0]]) <result_name = "r", flags = [], flag_modes = [], operand_kinds = [0, 0], metaflags = [#mpir.metaflag<"o", [1], {{.*}}>]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Instruction>) -> !mpir.sort<Instruction>
// CHECK:             mpir.yield %[[INST_1]] : <Instruction>
// CHECK:           } attributes {result_name = "r"} : <Instruction>
// CHECK:         }
