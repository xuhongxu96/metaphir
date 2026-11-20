// RUN: %metaphir-opt --split-input-file --mpir-desugar-metaflags %s | FileCheck %s
// mpir-desugar-metaflags turns each metaflag into an mpir.require of its
// definition's body, read on the flag's subject: the operand it is written
// on, or the instruction. ':c' and ':o' are choices, and stay.

// A defined metaflag on an operand: its body, with the subject read as a
// value.
mpir.metaflag_def @zero <param_names = ["v"], placement = operand> {
// CHECK-LABEL:   mpir.metaflag_def @zero <placement = operand, param_names = ["v"]> {
// CHECK:         ^bb0(%[[VAL_0:.*]]: !mpir.sort<Unknown>):
^bb0(%arg0: !mpir.sort<Unknown>):
  %0 = mpir_expr.read %arg0 : (!mpir.sort<Unknown>) -> !mpir.sort<Unknown> loc("desugar-metaflags.mlir":12:1)
// CHECK:           %[[READ_0:.*]] = mpir_expr.read %[[VAL_0]] : (!mpir.sort<Unknown>) -> !mpir.sort<Unknown>
  %1 = mpir_expr.call call "isZero"(%0) : (!mpir.sort<Unknown>) -> !mpir.sort<Boolean> loc("desugar-metaflags.mlir":14:1)
// CHECK:           %[[CALL_0:.*]] = mpir_expr.call call "isZero"(%[[READ_0]]) : (!mpir.sort<Unknown>) -> !mpir.sort<Boolean>
  mpir.yield %1 : <Boolean> loc("desugar-metaflags.mlir":16:1)
// CHECK:           mpir.yield %[[CALL_0]] : <Boolean>
} loc("desugar-metaflags.mlir":18:1)
// CHECK:         }
mpir.pattern {
// CHECK-LABEL:   mpir.pattern {
  %0 = mpir.type.int 32 : <Type> loc("desugar-metaflags.mlir":22:1)
// CHECK:           %[[TYPE_0:.*]] = mpir.type.int 32 : <Type>
  %x = mpir.var "x" : <Operand> loc("desugar-metaflags.mlir":24:1)
// CHECK:           %[[VAR_0:.*]] = mpir.var "x" : <Operand>
  %y = mpir.var "y" : <Operand> loc("desugar-metaflags.mlir":26:1)
// CHECK:           %[[VAR_1:.*]] = mpir.var "y" : <Operand>
  %i_a = mpir.inst <add> (%0, %x, %0, %y) <result_name = "a", flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value], operand_metaflags = [[#mpir.metaflag<"zero", [], loc("desugar-metaflags.mlir":28:1)>], []]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:           %[[INST_0:.*]] = mpir.inst <add> (%[[TYPE_0]], %[[VAR_0]], %[[TYPE_0]], %[[VAR_1]]) <flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value], result_name = "a"> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:           %[[READ_0:.*]] = mpir_expr.read %[[VAR_0]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
// CHECK:           %[[CALL_0:.*]] = mpir_expr.call call "isZero"(%[[READ_0]]) anchor %[[INST_0]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:           mpir.require %[[CALL_0]] <from_metaflag> : <Boolean>
} loc("desugar-metaflags.mlir":33:1)
// CHECK:         }

// -----

// On an instruction: the subject is the instruction itself.
mpir.metaflag_def @s <param_names = ["v"], placement = instruction|operand> {
// CHECK-LABEL:   mpir.metaflag_def @s <placement = instruction|operand, param_names = ["v"]> {
// CHECK:         ^bb0(%[[VAL_0:.*]]: !mpir.sort<Unknown>):
^bb0(%arg0: !mpir.sort<Unknown>):
  %0 = mpir_expr.read %arg0 : (!mpir.sort<Unknown>) -> !mpir.sort<Unknown> loc("desugar-metaflags.mlir":43:1)
// CHECK:           %[[READ_0:.*]] = mpir_expr.read %[[VAL_0]] : (!mpir.sort<Unknown>) -> !mpir.sort<Unknown>
  %1 = mpir_expr.call call "hasOneUse"(%0) : (!mpir.sort<Unknown>) -> !mpir.sort<Boolean> loc("desugar-metaflags.mlir":45:1)
// CHECK:           %[[CALL_0:.*]] = mpir_expr.call call "hasOneUse"(%[[READ_0]]) : (!mpir.sort<Unknown>) -> !mpir.sort<Boolean>
  mpir.yield %1 : <Boolean> loc("desugar-metaflags.mlir":47:1)
// CHECK:           mpir.yield %[[CALL_0]] : <Boolean>
} loc("desugar-metaflags.mlir":49:1)
// CHECK:         }
mpir.pattern {
// CHECK-LABEL:   mpir.pattern {
  %0 = mpir.type.int 32 : <Type> loc("desugar-metaflags.mlir":53:1)
// CHECK:           %[[TYPE_0:.*]] = mpir.type.int 32 : <Type>
  %x = mpir.var "x" : <Operand> loc("desugar-metaflags.mlir":55:1)
// CHECK:           %[[VAR_0:.*]] = mpir.var "x" : <Operand>
  %y = mpir.var "y" : <Operand> loc("desugar-metaflags.mlir":57:1)
// CHECK:           %[[VAR_1:.*]] = mpir.var "y" : <Operand>
  %i_a = mpir.inst <add> (%0, %x, %0, %y) <result_name = "a", flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value], metaflags = [#mpir.metaflag<"s", [], loc("desugar-metaflags.mlir":59:1)>]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:           %[[INST_0:.*]] = mpir.inst <add> (%[[TYPE_0]], %[[VAR_0]], %[[TYPE_0]], %[[VAR_1]]) <flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value], result_name = "a"> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:           %[[READ_0:.*]] = mpir_expr.read %[[INST_0]] : (!mpir.sort<Instruction>) -> !mpir.sort<Value>
// CHECK:           %[[CALL_0:.*]] = mpir_expr.call call "hasOneUse"(%[[READ_0]]) anchor %[[INST_0]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:           mpir.require %[[CALL_0]] <from_metaflag> : <Boolean>
} loc("desugar-metaflags.mlir":64:1)
// CHECK:         }

// -----

// On an operand that is another instruction of the pattern.
mpir.metaflag_def @s <param_names = ["v"], placement = instruction|operand> {
// CHECK-LABEL:   mpir.metaflag_def @s <placement = instruction|operand, param_names = ["v"]> {
// CHECK:         ^bb0(%[[VAL_0:.*]]: !mpir.sort<Unknown>):
^bb0(%arg0: !mpir.sort<Unknown>):
  %0 = mpir_expr.read %arg0 : (!mpir.sort<Unknown>) -> !mpir.sort<Unknown> loc("desugar-metaflags.mlir":74:1)
// CHECK:           %[[READ_0:.*]] = mpir_expr.read %[[VAL_0]] : (!mpir.sort<Unknown>) -> !mpir.sort<Unknown>
  %1 = mpir_expr.call call "hasOneUse"(%0) : (!mpir.sort<Unknown>) -> !mpir.sort<Boolean> loc("desugar-metaflags.mlir":76:1)
// CHECK:           %[[CALL_0:.*]] = mpir_expr.call call "hasOneUse"(%[[READ_0]]) : (!mpir.sort<Unknown>) -> !mpir.sort<Boolean>
  mpir.yield %1 : <Boolean> loc("desugar-metaflags.mlir":78:1)
// CHECK:           mpir.yield %[[CALL_0]] : <Boolean>
} loc("desugar-metaflags.mlir":80:1)
// CHECK:         }
mpir.pattern {
// CHECK-LABEL:   mpir.pattern {
  %0 = mpir.type.int 32 : <Type> loc("desugar-metaflags.mlir":84:1)
// CHECK:           %[[TYPE_0:.*]] = mpir.type.int 32 : <Type>
  %x = mpir.var "x" : <Operand> loc("desugar-metaflags.mlir":86:1)
// CHECK:           %[[VAR_0:.*]] = mpir.var "x" : <Operand>
  %y = mpir.var "y" : <Operand> loc("desugar-metaflags.mlir":88:1)
// CHECK:           %[[VAR_1:.*]] = mpir.var "y" : <Operand>
  %i_a = mpir.inst <add> (%0, %x, %0, %y) <result_name = "a", flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction> loc("desugar-metaflags.mlir":90:1)
// CHECK:           %[[INST_0:.*]] = mpir.inst <add> (%[[TYPE_0]], %[[VAR_0]], %[[TYPE_0]], %[[VAR_1]]) <flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value], result_name = "a"> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
  %1 = mpir.type.int 32 : <Type> loc("desugar-metaflags.mlir":92:1)
// CHECK:           %[[TYPE_1:.*]] = mpir.type.int 32 : <Type>
  %i_b = mpir.inst <mul> (%1, %i_a, %1, %y) <result_name = "b", flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value], operand_metaflags = [[#mpir.metaflag<"s", [], loc("desugar-metaflags.mlir":94:1)>], []]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:           %[[INST_1:.*]] = mpir.inst <mul> (%[[TYPE_1]], %[[INST_0]], %[[TYPE_1]], %[[VAR_1]]) <flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value], result_name = "b"> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:           %[[READ_0:.*]] = mpir_expr.read %[[INST_0]] : (!mpir.sort<Instruction>) -> !mpir.sort<Value>
// CHECK:           %[[CALL_0:.*]] = mpir_expr.call call "hasOneUse"(%[[READ_0]]) anchor %[[INST_1]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:           mpir.require %[[CALL_0]] <from_metaflag> : <Boolean>
} loc("desugar-metaflags.mlir":99:1)
// CHECK:         }

// -----

// ':or' is the disjunction of its flags, ':not' the negation.
mpir.metaflag_def @power2 <param_names = ["v"], placement = operand> {
// CHECK-LABEL:   mpir.metaflag_def @power2 <placement = operand, param_names = ["v"]> {
// CHECK:         ^bb0(%[[VAL_0:.*]]: !mpir.sort<Unknown>):
^bb0(%arg0: !mpir.sort<Unknown>):
  %0 = mpir_expr.read %arg0 : (!mpir.sort<Unknown>) -> !mpir.sort<Unknown> loc("desugar-metaflags.mlir":109:1)
// CHECK:           %[[READ_0:.*]] = mpir_expr.read %[[VAL_0]] : (!mpir.sort<Unknown>) -> !mpir.sort<Unknown>
  %1 = mpir_expr.call call "isPower2"(%0) : (!mpir.sort<Unknown>) -> !mpir.sort<Boolean> loc("desugar-metaflags.mlir":111:1)
// CHECK:           %[[CALL_0:.*]] = mpir_expr.call call "isPower2"(%[[READ_0]]) : (!mpir.sort<Unknown>) -> !mpir.sort<Boolean>
  mpir.yield %1 : <Boolean> loc("desugar-metaflags.mlir":113:1)
// CHECK:           mpir.yield %[[CALL_0]] : <Boolean>
} loc("desugar-metaflags.mlir":115:1)
// CHECK:         }
mpir.metaflag_def @zero <param_names = ["v"], placement = operand> {
// CHECK-LABEL:   mpir.metaflag_def @zero <placement = operand, param_names = ["v"]> {
// CHECK:         ^bb0(%[[VAL_0:.*]]: !mpir.sort<Unknown>):
^bb0(%arg0: !mpir.sort<Unknown>):
  %0 = mpir_expr.read %arg0 : (!mpir.sort<Unknown>) -> !mpir.sort<Unknown> loc("desugar-metaflags.mlir":121:1)
// CHECK:           %[[READ_0:.*]] = mpir_expr.read %[[VAL_0]] : (!mpir.sort<Unknown>) -> !mpir.sort<Unknown>
  %1 = mpir_expr.call call "isZero"(%0) : (!mpir.sort<Unknown>) -> !mpir.sort<Boolean> loc("desugar-metaflags.mlir":123:1)
// CHECK:           %[[CALL_0:.*]] = mpir_expr.call call "isZero"(%[[READ_0]]) : (!mpir.sort<Unknown>) -> !mpir.sort<Boolean>
  mpir.yield %1 : <Boolean> loc("desugar-metaflags.mlir":125:1)
// CHECK:           mpir.yield %[[CALL_0]] : <Boolean>
} loc("desugar-metaflags.mlir":127:1)
// CHECK:         }
mpir.metaflag_def @allOnes <param_names = ["v"], placement = operand> {
// CHECK-LABEL:   mpir.metaflag_def @allOnes <placement = operand, param_names = ["v"]> {
// CHECK:         ^bb0(%[[VAL_0:.*]]: !mpir.sort<Unknown>):
^bb0(%arg0: !mpir.sort<Unknown>):
  %0 = mpir_expr.read %arg0 : (!mpir.sort<Unknown>) -> !mpir.sort<Unknown> loc("desugar-metaflags.mlir":133:1)
// CHECK:           %[[READ_0:.*]] = mpir_expr.read %[[VAL_0]] : (!mpir.sort<Unknown>) -> !mpir.sort<Unknown>
  %1 = mpir_expr.call call "isAllOnes"(%0) : (!mpir.sort<Unknown>) -> !mpir.sort<Boolean> loc("desugar-metaflags.mlir":135:1)
// CHECK:           %[[CALL_0:.*]] = mpir_expr.call call "isAllOnes"(%[[READ_0]]) : (!mpir.sort<Unknown>) -> !mpir.sort<Boolean>
  mpir.yield %1 : <Boolean> loc("desugar-metaflags.mlir":137:1)
// CHECK:           mpir.yield %[[CALL_0]] : <Boolean>
} loc("desugar-metaflags.mlir":139:1)
// CHECK:         }
mpir.pattern {
// CHECK-LABEL:   mpir.pattern {
  %0 = mpir.type.int 32 : <Type> loc("desugar-metaflags.mlir":143:1)
// CHECK:           %[[TYPE_0:.*]] = mpir.type.int 32 : <Type>
  %x = mpir.var "x" : <Operand> loc("desugar-metaflags.mlir":145:1)
// CHECK:           %[[VAR_0:.*]] = mpir.var "x" : <Operand>
  %y = mpir.var "y" : <Operand> loc("desugar-metaflags.mlir":147:1)
// CHECK:           %[[VAR_1:.*]] = mpir.var "y" : <Operand>
  %i_a = mpir.inst <add> (%0, %x, %0, %y) <result_name = "a", flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value], operand_metaflags = [[#mpir.metaflag<"or", [#mpir.metaflag<"zero", [], loc("desugar-metaflags.mlir":149:1)>, #mpir.metaflag<"allOnes", [], loc("desugar-metaflags.mlir":149:1)>, #mpir.metaflag<"power2", [], loc("desugar-metaflags.mlir":149:1)>], loc("desugar-metaflags.mlir":149:1)>], [#mpir.metaflag<"not", [#mpir.metaflag<"zero", [], loc("desugar-metaflags.mlir":149:1)>], loc("desugar-metaflags.mlir":149:1)>]]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:           %[[INST_0:.*]] = mpir.inst <add> (%[[TYPE_0]], %[[VAR_0]], %[[TYPE_0]], %[[VAR_1]]) <flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value], result_name = "a"> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:           %[[READ_0:.*]] = mpir_expr.read %[[VAR_0]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
// CHECK:           %[[CALL_0:.*]] = mpir_expr.call call "isZero"(%[[READ_0]]) anchor %[[INST_0]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:           %[[READ_1:.*]] = mpir_expr.read %[[VAR_0]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
// CHECK:           %[[CALL_1:.*]] = mpir_expr.call call "isAllOnes"(%[[READ_1]]) anchor %[[INST_0]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:           %[[CALL_2:.*]] = mpir_expr.call binary "||"(%[[CALL_0]], %[[CALL_1]]) anchor %[[INST_0]] : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:           %[[READ_2:.*]] = mpir_expr.read %[[VAR_0]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
// CHECK:           %[[CALL_3:.*]] = mpir_expr.call call "isPower2"(%[[READ_2]]) anchor %[[INST_0]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:           %[[CALL_4:.*]] = mpir_expr.call binary "||"(%[[CALL_2]], %[[CALL_3]]) anchor %[[INST_0]] : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:           mpir.require %[[CALL_4]] <from_metaflag> : <Boolean>
// CHECK:           %[[READ_3:.*]] = mpir_expr.read %[[VAR_1]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
// CHECK:           %[[CALL_5:.*]] = mpir_expr.call call "isZero"(%[[READ_3]]) anchor %[[INST_0]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:           %[[CALL_6:.*]] = mpir_expr.call unary "!"(%[[CALL_5]]) anchor %[[INST_0]] : (!mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:           mpir.require %[[CALL_6]] <from_metaflag> : <Boolean>
} loc("desugar-metaflags.mlir":164:1)
// CHECK:         }

// -----

// Nested combinators.
mpir.metaflag_def @power2 <param_names = ["v"], placement = operand> {
// CHECK-LABEL:   mpir.metaflag_def @power2 <placement = operand, param_names = ["v"]> {
// CHECK:         ^bb0(%[[VAL_0:.*]]: !mpir.sort<Unknown>):
^bb0(%arg0: !mpir.sort<Unknown>):
  %0 = mpir_expr.read %arg0 : (!mpir.sort<Unknown>) -> !mpir.sort<Unknown> loc("desugar-metaflags.mlir":174:1)
// CHECK:           %[[READ_0:.*]] = mpir_expr.read %[[VAL_0]] : (!mpir.sort<Unknown>) -> !mpir.sort<Unknown>
  %1 = mpir_expr.call call "isPower2"(%0) : (!mpir.sort<Unknown>) -> !mpir.sort<Boolean> loc("desugar-metaflags.mlir":176:1)
// CHECK:           %[[CALL_0:.*]] = mpir_expr.call call "isPower2"(%[[READ_0]]) : (!mpir.sort<Unknown>) -> !mpir.sort<Boolean>
  mpir.yield %1 : <Boolean> loc("desugar-metaflags.mlir":178:1)
// CHECK:           mpir.yield %[[CALL_0]] : <Boolean>
} loc("desugar-metaflags.mlir":180:1)
// CHECK:         }
mpir.metaflag_def @zero <param_names = ["v"], placement = operand> {
// CHECK-LABEL:   mpir.metaflag_def @zero <placement = operand, param_names = ["v"]> {
// CHECK:         ^bb0(%[[VAL_0:.*]]: !mpir.sort<Unknown>):
^bb0(%arg0: !mpir.sort<Unknown>):
  %0 = mpir_expr.read %arg0 : (!mpir.sort<Unknown>) -> !mpir.sort<Unknown> loc("desugar-metaflags.mlir":186:1)
// CHECK:           %[[READ_0:.*]] = mpir_expr.read %[[VAL_0]] : (!mpir.sort<Unknown>) -> !mpir.sort<Unknown>
  %1 = mpir_expr.call call "isZero"(%0) : (!mpir.sort<Unknown>) -> !mpir.sort<Boolean> loc("desugar-metaflags.mlir":188:1)
// CHECK:           %[[CALL_0:.*]] = mpir_expr.call call "isZero"(%[[READ_0]]) : (!mpir.sort<Unknown>) -> !mpir.sort<Boolean>
  mpir.yield %1 : <Boolean> loc("desugar-metaflags.mlir":190:1)
// CHECK:           mpir.yield %[[CALL_0]] : <Boolean>
} loc("desugar-metaflags.mlir":192:1)
// CHECK:         }
mpir.metaflag_def @allOnes <param_names = ["v"], placement = operand> {
// CHECK-LABEL:   mpir.metaflag_def @allOnes <placement = operand, param_names = ["v"]> {
// CHECK:         ^bb0(%[[VAL_0:.*]]: !mpir.sort<Unknown>):
^bb0(%arg0: !mpir.sort<Unknown>):
  %0 = mpir_expr.read %arg0 : (!mpir.sort<Unknown>) -> !mpir.sort<Unknown> loc("desugar-metaflags.mlir":198:1)
// CHECK:           %[[READ_0:.*]] = mpir_expr.read %[[VAL_0]] : (!mpir.sort<Unknown>) -> !mpir.sort<Unknown>
  %1 = mpir_expr.call call "isAllOnes"(%0) : (!mpir.sort<Unknown>) -> !mpir.sort<Boolean> loc("desugar-metaflags.mlir":200:1)
// CHECK:           %[[CALL_0:.*]] = mpir_expr.call call "isAllOnes"(%[[READ_0]]) : (!mpir.sort<Unknown>) -> !mpir.sort<Boolean>
  mpir.yield %1 : <Boolean> loc("desugar-metaflags.mlir":202:1)
// CHECK:           mpir.yield %[[CALL_0]] : <Boolean>
} loc("desugar-metaflags.mlir":204:1)
// CHECK:         }
mpir.pattern {
// CHECK-LABEL:   mpir.pattern {
  %0 = mpir.type.int 32 : <Type> loc("desugar-metaflags.mlir":208:1)
// CHECK:           %[[TYPE_0:.*]] = mpir.type.int 32 : <Type>
  %x = mpir.var "x" : <Operand> loc("desugar-metaflags.mlir":210:1)
// CHECK:           %[[VAR_0:.*]] = mpir.var "x" : <Operand>
  %y = mpir.var "y" : <Operand> loc("desugar-metaflags.mlir":212:1)
// CHECK:           %[[VAR_1:.*]] = mpir.var "y" : <Operand>
  %i_a = mpir.inst <add> (%0, %x, %0, %y) <result_name = "a", flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value], operand_metaflags = [[#mpir.metaflag<"or", [#mpir.metaflag<"not", [#mpir.metaflag<"zero", [], loc("desugar-metaflags.mlir":214:1)>], loc("desugar-metaflags.mlir":214:1)>, #mpir.metaflag<"not", [#mpir.metaflag<"or", [#mpir.metaflag<"allOnes", [], loc("desugar-metaflags.mlir":214:1)>, #mpir.metaflag<"power2", [], loc("desugar-metaflags.mlir":214:1)>], loc("desugar-metaflags.mlir":214:1)>], loc("desugar-metaflags.mlir":214:1)>], loc("desugar-metaflags.mlir":214:1)>], []]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:           %[[INST_0:.*]] = mpir.inst <add> (%[[TYPE_0]], %[[VAR_0]], %[[TYPE_0]], %[[VAR_1]]) <flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value], result_name = "a"> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:           %[[READ_0:.*]] = mpir_expr.read %[[VAR_0]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
// CHECK:           %[[CALL_0:.*]] = mpir_expr.call call "isZero"(%[[READ_0]]) anchor %[[INST_0]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:           %[[CALL_1:.*]] = mpir_expr.call unary "!"(%[[CALL_0]]) anchor %[[INST_0]] : (!mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:           %[[READ_1:.*]] = mpir_expr.read %[[VAR_0]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
// CHECK:           %[[CALL_2:.*]] = mpir_expr.call call "isAllOnes"(%[[READ_1]]) anchor %[[INST_0]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:           %[[READ_2:.*]] = mpir_expr.read %[[VAR_0]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
// CHECK:           %[[CALL_3:.*]] = mpir_expr.call call "isPower2"(%[[READ_2]]) anchor %[[INST_0]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:           %[[CALL_4:.*]] = mpir_expr.call binary "||"(%[[CALL_2]], %[[CALL_3]]) anchor %[[INST_0]] : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:           %[[CALL_5:.*]] = mpir_expr.call unary "!"(%[[CALL_4]]) anchor %[[INST_0]] : (!mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:           %[[CALL_6:.*]] = mpir_expr.call binary "||"(%[[CALL_1]], %[[CALL_5]]) anchor %[[INST_0]] : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:           mpir.require %[[CALL_6]] <from_metaflag> : <Boolean>
} loc("desugar-metaflags.mlir":227:1)
// CHECK:         }

// -----

// Integer arguments become literals, signed when negative.
mpir.metaflag_def @between <param_names = ["v", "lo", "hi"], placement = operand> {
// CHECK-LABEL:   mpir.metaflag_def @between <placement = operand, param_names = ["v", "lo", "hi"]> {
// CHECK:         ^bb0(%[[VAL_0:.*]]: !mpir.sort<Unknown>, %[[VAL_1:.*]]: !mpir.sort<Unknown>, %[[VAL_2:.*]]: !mpir.sort<Unknown>):
^bb0(%arg0: !mpir.sort<Unknown>, %arg1: !mpir.sort<Unknown>, %arg2: !mpir.sort<Unknown>):
  %0 = mpir_expr.read %arg1 : (!mpir.sort<Unknown>) -> !mpir.sort<Unknown> loc("desugar-metaflags.mlir":237:1)
// CHECK:           %[[READ_0:.*]] = mpir_expr.read %[[VAL_1]] : (!mpir.sort<Unknown>) -> !mpir.sort<Unknown>
  %1 = mpir_expr.read %arg0 : (!mpir.sort<Unknown>) -> !mpir.sort<Unknown> loc("desugar-metaflags.mlir":239:1)
// CHECK:           %[[READ_1:.*]] = mpir_expr.read %[[VAL_0]] : (!mpir.sort<Unknown>) -> !mpir.sort<Unknown>
  %2 = mpir_expr.call call "sle"(%0, %1) : (!mpir.sort<Unknown>, !mpir.sort<Unknown>) -> !mpir.sort<Boolean> loc("desugar-metaflags.mlir":241:1)
// CHECK:           %[[CALL_0:.*]] = mpir_expr.call call "sle"(%[[READ_0]], %[[READ_1]]) : (!mpir.sort<Unknown>, !mpir.sort<Unknown>) -> !mpir.sort<Boolean>
  %3 = mpir_expr.read %arg0 : (!mpir.sort<Unknown>) -> !mpir.sort<Unknown> loc("desugar-metaflags.mlir":243:1)
// CHECK:           %[[READ_2:.*]] = mpir_expr.read %[[VAL_0]] : (!mpir.sort<Unknown>) -> !mpir.sort<Unknown>
  %4 = mpir_expr.read %arg2 : (!mpir.sort<Unknown>) -> !mpir.sort<Unknown> loc("desugar-metaflags.mlir":245:1)
// CHECK:           %[[READ_3:.*]] = mpir_expr.read %[[VAL_2]] : (!mpir.sort<Unknown>) -> !mpir.sort<Unknown>
  %5 = mpir_expr.call call "sle"(%3, %4) : (!mpir.sort<Unknown>, !mpir.sort<Unknown>) -> !mpir.sort<Boolean> loc("desugar-metaflags.mlir":247:1)
// CHECK:           %[[CALL_1:.*]] = mpir_expr.call call "sle"(%[[READ_2]], %[[READ_3]]) : (!mpir.sort<Unknown>, !mpir.sort<Unknown>) -> !mpir.sort<Boolean>
  %6 = mpir_expr.call binary "&&"(%2, %5) : (!mpir.sort<Boolean>, !mpir.sort<Boolean>) -> !mpir.sort<Boolean> loc("desugar-metaflags.mlir":249:1)
// CHECK:           %[[CALL_2:.*]] = mpir_expr.call binary "&&"(%[[CALL_0]], %[[CALL_1]]) : (!mpir.sort<Boolean>, !mpir.sort<Boolean>) -> !mpir.sort<Boolean>
  mpir.yield %6 : <Boolean> loc("desugar-metaflags.mlir":251:1)
// CHECK:           mpir.yield %[[CALL_2]] : <Boolean>
} loc("desugar-metaflags.mlir":253:1)
// CHECK:         }
mpir.pattern {
// CHECK-LABEL:   mpir.pattern {
  %0 = mpir.type.int 32 : <Type> loc("desugar-metaflags.mlir":257:1)
// CHECK:           %[[TYPE_0:.*]] = mpir.type.int 32 : <Type>
  %x = mpir.var "x" : <Operand> loc("desugar-metaflags.mlir":259:1)
// CHECK:           %[[VAR_0:.*]] = mpir.var "x" : <Operand>
  %y = mpir.var "y" : <Operand> loc("desugar-metaflags.mlir":261:1)
// CHECK:           %[[VAR_1:.*]] = mpir.var "y" : <Operand>
  %i_a = mpir.inst <add> (%0, %x, %0, %y) <result_name = "a", flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value], operand_metaflags = [[#mpir.metaflag<"between", [-5, 10], loc("desugar-metaflags.mlir":263:1)>], []]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:           %[[INST_0:.*]] = mpir.inst <add> (%[[TYPE_0]], %[[VAR_0]], %[[TYPE_0]], %[[VAR_1]]) <flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value], result_name = "a"> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:           %[[INT_0:.*]] = mpir_expr.int -5 : si64 : <Integer>
// CHECK:           %[[READ_0:.*]] = mpir_expr.read %[[VAR_0]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
// CHECK:           %[[CALL_0:.*]] = mpir_expr.call call "sle"(%[[INT_0]], %[[READ_0]]) anchor %[[INST_0]] : (!mpir.sort<Integer>, !mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:           %[[READ_1:.*]] = mpir_expr.read %[[VAR_0]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
// CHECK:           %[[INT_1:.*]] = mpir_expr.int 10 : ui64 : <Integer>
// CHECK:           %[[CALL_1:.*]] = mpir_expr.call call "sle"(%[[READ_1]], %[[INT_1]]) anchor %[[INST_0]] : (!mpir.sort<Value>, !mpir.sort<Integer>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:           %[[CALL_2:.*]] = mpir_expr.call binary "&&"(%[[CALL_0]], %[[CALL_1]]) anchor %[[INST_0]] : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:           mpir.require %[[CALL_2]] <from_metaflag> : <Boolean>
} loc("desugar-metaflags.mlir":273:1)
// CHECK:         }

// -----

// The choices ':c' and ':o' are kept; the others around them go.
mpir.metaflag_def @zero <param_names = ["v"], placement = operand> {
// CHECK-LABEL:   mpir.metaflag_def @zero <placement = operand, param_names = ["v"]> {
// CHECK:         ^bb0(%[[VAL_0:.*]]: !mpir.sort<Unknown>):
^bb0(%arg0: !mpir.sort<Unknown>):
  %0 = mpir_expr.read %arg0 : (!mpir.sort<Unknown>) -> !mpir.sort<Unknown> loc("desugar-metaflags.mlir":283:1)
// CHECK:           %[[READ_0:.*]] = mpir_expr.read %[[VAL_0]] : (!mpir.sort<Unknown>) -> !mpir.sort<Unknown>
  %1 = mpir_expr.call call "isZero"(%0) : (!mpir.sort<Unknown>) -> !mpir.sort<Boolean> loc("desugar-metaflags.mlir":285:1)
// CHECK:           %[[CALL_0:.*]] = mpir_expr.call call "isZero"(%[[READ_0]]) : (!mpir.sort<Unknown>) -> !mpir.sort<Boolean>
  mpir.yield %1 : <Boolean> loc("desugar-metaflags.mlir":287:1)
// CHECK:           mpir.yield %[[CALL_0]] : <Boolean>
} loc("desugar-metaflags.mlir":289:1)
// CHECK:         }
mpir.metaflag_def @s <param_names = ["v"], placement = instruction|operand> {
// CHECK-LABEL:   mpir.metaflag_def @s <placement = instruction|operand, param_names = ["v"]> {
// CHECK:         ^bb0(%[[VAL_0:.*]]: !mpir.sort<Unknown>):
^bb0(%arg0: !mpir.sort<Unknown>):
  %0 = mpir_expr.read %arg0 : (!mpir.sort<Unknown>) -> !mpir.sort<Unknown> loc("desugar-metaflags.mlir":295:1)
// CHECK:           %[[READ_0:.*]] = mpir_expr.read %[[VAL_0]] : (!mpir.sort<Unknown>) -> !mpir.sort<Unknown>
  %1 = mpir_expr.call call "hasOneUse"(%0) : (!mpir.sort<Unknown>) -> !mpir.sort<Boolean> loc("desugar-metaflags.mlir":297:1)
// CHECK:           %[[CALL_0:.*]] = mpir_expr.call call "hasOneUse"(%[[READ_0]]) : (!mpir.sort<Unknown>) -> !mpir.sort<Boolean>
  mpir.yield %1 : <Boolean> loc("desugar-metaflags.mlir":299:1)
// CHECK:           mpir.yield %[[CALL_0]] : <Boolean>
} loc("desugar-metaflags.mlir":301:1)
// CHECK:         }
mpir.pattern {
// CHECK-LABEL:   mpir.pattern {
  %0 = mpir.type.int 32 : <Type> loc("desugar-metaflags.mlir":305:1)
// CHECK:           %[[TYPE_0:.*]] = mpir.type.int 32 : <Type>
  %x = mpir.var "x" : <Operand> loc("desugar-metaflags.mlir":307:1)
// CHECK:           %[[VAR_0:.*]] = mpir.var "x" : <Operand>
  %y = mpir.var "y" : <Operand> loc("desugar-metaflags.mlir":309:1)
// CHECK:           %[[VAR_1:.*]] = mpir.var "y" : <Operand>
  %i_a = mpir.inst <add> (%0, %x, %0, %y) <result_name = "a", flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value], metaflags = [#mpir.metaflag<"c", [], loc("desugar-metaflags.mlir":311:1)>, #mpir.metaflag<"s", [], loc("desugar-metaflags.mlir":311:1)>], operand_metaflags = [[#mpir.metaflag<"zero", [], loc("desugar-metaflags.mlir":311:1)>], []]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:           %[[INST_0:.*]] = mpir.inst <add> (%[[TYPE_0]], %[[VAR_0]], %[[TYPE_0]], %[[VAR_1]]) <flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value], result_name = "a", metaflags = [#mpir.metaflag<"c", [], {{.*}}>]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
  %1 = mpir.type.int 32 : <Type> loc("desugar-metaflags.mlir":313:1)
// CHECK:           %[[TYPE_1:.*]] = mpir.type.int 32 : <Type>
  %2 = mpir.int 0 : ui1 : <Value> loc("desugar-metaflags.mlir":315:1)
// CHECK:           %[[INT_0:.*]] = mpir.int 0 : ui1 : <Value>
  %i_b = mpir.inst <sub> (%1, %2, %1, %i_a) <result_name = "b", flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value], metaflags = [#mpir.metaflag<"o", [1], loc("desugar-metaflags.mlir":317:1)>, #mpir.metaflag<"s", [], loc("desugar-metaflags.mlir":317:1)>]> : (!mpir.sort<Type>, !mpir.sort<Value>, !mpir.sort<Type>, !mpir.sort<Instruction>) -> !mpir.sort<Instruction>
// CHECK:           %[[INST_1:.*]] = mpir.inst <sub> (%[[TYPE_1]], %[[INT_0]], %[[TYPE_1]], %[[INST_0]]) <flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value], result_name = "b", metaflags = [#mpir.metaflag<"o", [1], {{.*}}>]> : (!mpir.sort<Type>, !mpir.sort<Value>, !mpir.sort<Type>, !mpir.sort<Instruction>) -> !mpir.sort<Instruction>
// CHECK:           %[[READ_0:.*]] = mpir_expr.read %[[INST_0]] : (!mpir.sort<Instruction>) -> !mpir.sort<Value>
// CHECK:           %[[CALL_0:.*]] = mpir_expr.call call "hasOneUse"(%[[READ_0]]) anchor %[[INST_0]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:           mpir.require %[[CALL_0]] <from_metaflag> : <Boolean>
// CHECK:           %[[READ_1:.*]] = mpir_expr.read %[[VAR_0]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
// CHECK:           %[[CALL_1:.*]] = mpir_expr.call call "isZero"(%[[READ_1]]) anchor %[[INST_0]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:           mpir.require %[[CALL_1]] <from_metaflag> : <Boolean>
// CHECK:           %[[READ_2:.*]] = mpir_expr.read %[[INST_1]] : (!mpir.sort<Instruction>) -> !mpir.sort<Value>
// CHECK:           %[[CALL_2:.*]] = mpir_expr.call call "hasOneUse"(%[[READ_2]]) anchor %[[INST_1]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:           mpir.require %[[CALL_2]] <from_metaflag> : <Boolean>
} loc("desugar-metaflags.mlir":328:1)
// CHECK:         }

// -----

// A value-tracking operator in a definition is anchored at the instruction
// the flag is written on.
mpir.metaflag_def @knownNegative <param_names = ["v"], placement = operand> {
// CHECK-LABEL:   mpir.metaflag_def @knownNegative <placement = operand, param_names = ["v"]> {
// CHECK:         ^bb0(%[[VAL_0:.*]]: !mpir.sort<Unknown>):
^bb0(%arg0: !mpir.sort<Unknown>):
  %0 = mpir_expr.read %arg0 : (!mpir.sort<Unknown>) -> !mpir.sort<Unknown> loc("desugar-metaflags.mlir":339:1)
// CHECK:           %[[READ_0:.*]] = mpir_expr.read %[[VAL_0]] : (!mpir.sort<Unknown>) -> !mpir.sort<Unknown>
  %1 = mpir_expr.call call "isKnownNegative"(%0) : (!mpir.sort<Unknown>) -> !mpir.sort<Boolean> loc("desugar-metaflags.mlir":341:1)
// CHECK:           %[[CALL_0:.*]] = mpir_expr.call call "isKnownNegative"(%[[READ_0]]) : (!mpir.sort<Unknown>) -> !mpir.sort<Boolean>
  mpir.yield %1 : <Boolean> loc("desugar-metaflags.mlir":343:1)
// CHECK:           mpir.yield %[[CALL_0]] : <Boolean>
} loc("desugar-metaflags.mlir":345:1)
// CHECK:         }
mpir.pattern {
// CHECK-LABEL:   mpir.pattern {
  %0 = mpir.type.int 32 : <Type> loc("desugar-metaflags.mlir":349:1)
// CHECK:           %[[TYPE_0:.*]] = mpir.type.int 32 : <Type>
  %x = mpir.var "x" : <Operand> loc("desugar-metaflags.mlir":351:1)
// CHECK:           %[[VAR_0:.*]] = mpir.var "x" : <Operand>
  %y = mpir.var "y" : <Operand> loc("desugar-metaflags.mlir":353:1)
// CHECK:           %[[VAR_1:.*]] = mpir.var "y" : <Operand>
  %i_a = mpir.inst <add> (%0, %x, %0, %y) <result_name = "a", flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value], operand_metaflags = [[#mpir.metaflag<"knownNegative", [], loc("desugar-metaflags.mlir":355:1)>], []]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:           %[[INST_0:.*]] = mpir.inst <add> (%[[TYPE_0]], %[[VAR_0]], %[[TYPE_0]], %[[VAR_1]]) <flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value], result_name = "a"> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:           %[[READ_0:.*]] = mpir_expr.read %[[VAR_0]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
// CHECK:           %[[CALL_0:.*]] = mpir_expr.call call "isKnownNegative"(%[[READ_0]]) anchor %[[INST_0]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:           mpir.require %[[CALL_0]] <from_metaflag> : <Boolean>
} loc("desugar-metaflags.mlir":360:1)
// CHECK:         }

// -----

// A definition that calls a 'constraint' definition keeps the call.
mpir.constraint_def @isConstantInt <param_names = ["v"]> {
// CHECK-LABEL:   mpir.constraint_def @isConstantInt <param_names = ["v"]> {
// CHECK:         ^bb0(%[[VAL_0:.*]]: !mpir.sort<Unknown>):
^bb0(%arg0: !mpir.sort<Unknown>):
  %0 = mpir_expr.read %arg0 : (!mpir.sort<Unknown>) -> !mpir.sort<Unknown> loc("desugar-metaflags.mlir":370:1)
// CHECK:           %[[READ_0:.*]] = mpir_expr.read %[[VAL_0]] : (!mpir.sort<Unknown>) -> !mpir.sort<Unknown>
  %1 = mpir_expr.str "ConstantInt" : <String> loc("desugar-metaflags.mlir":372:1)
// CHECK:           %[[STR_0:.*]] = mpir_expr.str "ConstantInt" : <String>
  %2 = mpir_expr.call call "isa"(%0, %1) : (!mpir.sort<Unknown>, !mpir.sort<String>) -> !mpir.sort<Boolean> loc("desugar-metaflags.mlir":374:1)
// CHECK:           %[[CALL_0:.*]] = mpir_expr.call call "isa"(%[[READ_0]], %[[STR_0]]) : (!mpir.sort<Unknown>, !mpir.sort<String>) -> !mpir.sort<Boolean>
  mpir.yield %2 : <Boolean> loc("desugar-metaflags.mlir":376:1)
// CHECK:           mpir.yield %[[CALL_0]] : <Boolean>
} loc("desugar-metaflags.mlir":378:1)
// CHECK:         }
mpir.constraint_def @isAPIntAllowPoison <param_names = ["v"]> {
// CHECK-LABEL:   mpir.constraint_def @isAPIntAllowPoison <param_names = ["v"]> {
// CHECK:         ^bb0(%[[VAL_0:.*]]: !mpir.sort<Unknown>):
^bb0(%arg0: !mpir.sort<Unknown>):
  %0 = mpir_expr.read %arg0 : (!mpir.sort<Unknown>) -> !mpir.sort<Unknown> loc("desugar-metaflags.mlir":384:1)
// CHECK:           %[[READ_0:.*]] = mpir_expr.read %[[VAL_0]] : (!mpir.sort<Unknown>) -> !mpir.sort<Unknown>
  %1 = mpir_expr.apply @isConstantInt(%0) : (!mpir.sort<Unknown>) -> !mpir.sort<Boolean> loc("desugar-metaflags.mlir":386:1)
// CHECK:           %[[APPLY_0:.*]] = mpir_expr.apply @isConstantInt(%[[READ_0]]) : (!mpir.sort<Unknown>) -> !mpir.sort<Boolean>
  %2 = mpir_expr.read %arg0 : (!mpir.sort<Unknown>) -> !mpir.sort<Unknown> loc("desugar-metaflags.mlir":388:1)
// CHECK:           %[[READ_1:.*]] = mpir_expr.read %[[VAL_0]] : (!mpir.sort<Unknown>) -> !mpir.sort<Unknown>
  %3 = mpir_expr.call call "isConstantSplat"(%2) : (!mpir.sort<Unknown>) -> !mpir.sort<Boolean> loc("desugar-metaflags.mlir":390:1)
// CHECK:           %[[CALL_0:.*]] = mpir_expr.call call "isConstantSplat"(%[[READ_1]]) : (!mpir.sort<Unknown>) -> !mpir.sort<Boolean>
  %4 = mpir_expr.call binary "||"(%1, %3) : (!mpir.sort<Boolean>, !mpir.sort<Boolean>) -> !mpir.sort<Boolean> loc("desugar-metaflags.mlir":392:1)
// CHECK:           %[[CALL_1:.*]] = mpir_expr.call binary "||"(%[[APPLY_0]], %[[CALL_0]]) : (!mpir.sort<Boolean>, !mpir.sort<Boolean>) -> !mpir.sort<Boolean>
  %5 = mpir_expr.read %arg0 : (!mpir.sort<Unknown>) -> !mpir.sort<Unknown> loc("desugar-metaflags.mlir":394:1)
// CHECK:           %[[READ_2:.*]] = mpir_expr.read %[[VAL_0]] : (!mpir.sort<Unknown>) -> !mpir.sort<Unknown>
  %6 = mpir_expr.call call "isAnyIntegralConstant"(%5) : (!mpir.sort<Unknown>) -> !mpir.sort<Boolean> loc("desugar-metaflags.mlir":396:1)
// CHECK:           %[[CALL_2:.*]] = mpir_expr.call call "isAnyIntegralConstant"(%[[READ_2]]) : (!mpir.sort<Unknown>) -> !mpir.sort<Boolean>
  %7 = mpir_expr.call binary "&&"(%4, %6) : (!mpir.sort<Boolean>, !mpir.sort<Boolean>) -> !mpir.sort<Boolean> loc("desugar-metaflags.mlir":398:1)
// CHECK:           %[[CALL_3:.*]] = mpir_expr.call binary "&&"(%[[CALL_1]], %[[CALL_2]]) : (!mpir.sort<Boolean>, !mpir.sort<Boolean>) -> !mpir.sort<Boolean>
  mpir.yield %7 : <Boolean> loc("desugar-metaflags.mlir":400:1)
// CHECK:           mpir.yield %[[CALL_3]] : <Boolean>
} loc("desugar-metaflags.mlir":402:1)
// CHECK:         }
mpir.constraint_def @isAPInt <param_names = ["v"]> {
// CHECK-LABEL:   mpir.constraint_def @isAPInt <param_names = ["v"]> {
// CHECK:         ^bb0(%[[VAL_0:.*]]: !mpir.sort<Unknown>):
^bb0(%arg0: !mpir.sort<Unknown>):
  %0 = mpir_expr.read %arg0 : (!mpir.sort<Unknown>) -> !mpir.sort<Unknown> loc("desugar-metaflags.mlir":408:1)
// CHECK:           %[[READ_0:.*]] = mpir_expr.read %[[VAL_0]] : (!mpir.sort<Unknown>) -> !mpir.sort<Unknown>
  %1 = mpir_expr.apply @isAPIntAllowPoison(%0) : (!mpir.sort<Unknown>) -> !mpir.sort<Boolean> loc("desugar-metaflags.mlir":410:1)
// CHECK:           %[[APPLY_0:.*]] = mpir_expr.apply @isAPIntAllowPoison(%[[READ_0]]) : (!mpir.sort<Unknown>) -> !mpir.sort<Boolean>
  %2 = mpir_expr.read %arg0 : (!mpir.sort<Unknown>) -> !mpir.sort<Unknown> loc("desugar-metaflags.mlir":412:1)
// CHECK:           %[[READ_1:.*]] = mpir_expr.read %[[VAL_0]] : (!mpir.sort<Unknown>) -> !mpir.sort<Unknown>
  %3 = mpir_expr.call call "isForbidPoison"(%2) : (!mpir.sort<Unknown>) -> !mpir.sort<Boolean> loc("desugar-metaflags.mlir":414:1)
// CHECK:           %[[CALL_0:.*]] = mpir_expr.call call "isForbidPoison"(%[[READ_1]]) : (!mpir.sort<Unknown>) -> !mpir.sort<Boolean>
  %4 = mpir_expr.call binary "&&"(%1, %3) : (!mpir.sort<Boolean>, !mpir.sort<Boolean>) -> !mpir.sort<Boolean> loc("desugar-metaflags.mlir":416:1)
// CHECK:           %[[CALL_1:.*]] = mpir_expr.call binary "&&"(%[[APPLY_0]], %[[CALL_0]]) : (!mpir.sort<Boolean>, !mpir.sort<Boolean>) -> !mpir.sort<Boolean>
  mpir.yield %4 : <Boolean> loc("desugar-metaflags.mlir":418:1)
// CHECK:           mpir.yield %[[CALL_1]] : <Boolean>
} loc("desugar-metaflags.mlir":420:1)
// CHECK:         }
mpir.metaflag_def @apInt <param_names = ["v"], placement = operand> {
// CHECK-LABEL:   mpir.metaflag_def @apInt <placement = operand, param_names = ["v"]> {
// CHECK:         ^bb0(%[[VAL_0:.*]]: !mpir.sort<Unknown>):
^bb0(%arg0: !mpir.sort<Unknown>):
  %0 = mpir_expr.read %arg0 : (!mpir.sort<Unknown>) -> !mpir.sort<Unknown> loc("desugar-metaflags.mlir":426:1)
// CHECK:           %[[READ_0:.*]] = mpir_expr.read %[[VAL_0]] : (!mpir.sort<Unknown>) -> !mpir.sort<Unknown>
  %1 = mpir_expr.apply @isAPInt(%0) : (!mpir.sort<Unknown>) -> !mpir.sort<Boolean> loc("desugar-metaflags.mlir":428:1)
// CHECK:           %[[APPLY_0:.*]] = mpir_expr.apply @isAPInt(%[[READ_0]]) : (!mpir.sort<Unknown>) -> !mpir.sort<Boolean>
  mpir.yield %1 : <Boolean> loc("desugar-metaflags.mlir":430:1)
// CHECK:           mpir.yield %[[APPLY_0]] : <Boolean>
} loc("desugar-metaflags.mlir":432:1)
// CHECK:         }
mpir.pattern {
// CHECK-LABEL:   mpir.pattern {
  %0 = mpir.type.int 32 : <Type> loc("desugar-metaflags.mlir":436:1)
// CHECK:           %[[TYPE_0:.*]] = mpir.type.int 32 : <Type>
  %x = mpir.var "x" : <Operand> loc("desugar-metaflags.mlir":438:1)
// CHECK:           %[[VAR_0:.*]] = mpir.var "x" : <Operand>
  %y = mpir.var "y" : <Operand> loc("desugar-metaflags.mlir":440:1)
// CHECK:           %[[VAR_1:.*]] = mpir.var "y" : <Operand>
  %i_a = mpir.inst <add> (%0, %x, %0, %y) <result_name = "a", flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value], operand_metaflags = [[#mpir.metaflag<"apInt", [], loc("desugar-metaflags.mlir":442:1)>], []]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:           %[[INST_0:.*]] = mpir.inst <add> (%[[TYPE_0]], %[[VAR_0]], %[[TYPE_0]], %[[VAR_1]]) <flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value], result_name = "a"> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:           %[[READ_0:.*]] = mpir_expr.read %[[VAR_0]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
// CHECK:           %[[APPLY_0:.*]] = mpir_expr.apply @isAPInt(%[[READ_0]]) : (!mpir.sort<Value>) -> !mpir.sort<Boolean>
// CHECK:           mpir.require %[[APPLY_0]] <from_metaflag> : <Boolean>
} loc("desugar-metaflags.mlir":447:1)
// CHECK:         }

// -----

// A definition for instructions, reading the instruction's opcode.
mpir.metaflag_def @isadd <param_names = ["i"], placement = instruction> {
// CHECK-LABEL:   mpir.metaflag_def @isadd <placement = instruction, param_names = ["i"]> {
// CHECK:         ^bb0(%[[VAL_0:.*]]: !mpir.sort<Unknown>):
^bb0(%arg0: !mpir.sort<Unknown>):
  %0 = mpir_expr.read %arg0 : (!mpir.sort<Unknown>) -> !mpir.sort<Unknown> loc("desugar-metaflags.mlir":457:1)
// CHECK:           %[[READ_0:.*]] = mpir_expr.read %[[VAL_0]] : (!mpir.sort<Unknown>) -> !mpir.sort<Unknown>
  %1 = mpir_expr.call call "opcode"(%0) : (!mpir.sort<Unknown>) -> !mpir.sort<String> loc("desugar-metaflags.mlir":459:1)
// CHECK:           %[[CALL_0:.*]] = mpir_expr.call call "opcode"(%[[READ_0]]) : (!mpir.sort<Unknown>) -> !mpir.sort<String>
  %2 = mpir_expr.str "add" : <String> loc("desugar-metaflags.mlir":461:1)
// CHECK:           %[[STR_0:.*]] = mpir_expr.str "add" : <String>
  %3 = mpir_expr.call binary "=="(%1, %2) : (!mpir.sort<String>, !mpir.sort<String>) -> !mpir.sort<Boolean> loc("desugar-metaflags.mlir":463:1)
// CHECK:           %[[CALL_1:.*]] = mpir_expr.call binary "=="(%[[CALL_0]], %[[STR_0]]) : (!mpir.sort<String>, !mpir.sort<String>) -> !mpir.sort<Boolean>
  mpir.yield %3 : <Boolean> loc("desugar-metaflags.mlir":465:1)
// CHECK:           mpir.yield %[[CALL_1]] : <Boolean>
} loc("desugar-metaflags.mlir":467:1)
// CHECK:         }
mpir.pattern {
// CHECK-LABEL:   mpir.pattern {
  %0 = mpir.type.int 32 : <Type> loc("desugar-metaflags.mlir":471:1)
// CHECK:           %[[TYPE_0:.*]] = mpir.type.int 32 : <Type>
  %x = mpir.var "x" : <Operand> loc("desugar-metaflags.mlir":473:1)
// CHECK:           %[[VAR_0:.*]] = mpir.var "x" : <Operand>
  %y = mpir.var "y" : <Operand> loc("desugar-metaflags.mlir":475:1)
// CHECK:           %[[VAR_1:.*]] = mpir.var "y" : <Operand>
  %i_a = mpir.inst <add> (%0, %x, %0, %y) <result_name = "a", flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value], metaflags = [#mpir.metaflag<"isadd", [], loc("desugar-metaflags.mlir":477:1)>]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:           %[[INST_0:.*]] = mpir.inst <add> (%[[TYPE_0]], %[[VAR_0]], %[[TYPE_0]], %[[VAR_1]]) <flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value], result_name = "a"> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:           %[[READ_0:.*]] = mpir_expr.read %[[INST_0]] : (!mpir.sort<Instruction>) -> !mpir.sort<Value>
// CHECK:           %[[CALL_0:.*]] = mpir_expr.call call "opcode"(%[[READ_0]]) anchor %[[INST_0]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<String>
// CHECK:           %[[STR_0:.*]] = mpir_expr.str "add" : <String>
// CHECK:           %[[CALL_1:.*]] = mpir_expr.call binary "=="(%[[CALL_0]], %[[STR_0]]) anchor %[[INST_0]] : (!mpir.sort<String>, !mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:           mpir.require %[[CALL_1]] <from_metaflag> : <Boolean>
} loc("desugar-metaflags.mlir":484:1)
// CHECK:         }

// -----

// Several flags on one operand, and on both operands: one requirement
// each, in order.
mpir.metaflag_def @power2 <param_names = ["v"], placement = operand> {
// CHECK-LABEL:   mpir.metaflag_def @power2 <placement = operand, param_names = ["v"]> {
// CHECK:         ^bb0(%[[VAL_0:.*]]: !mpir.sort<Unknown>):
^bb0(%arg0: !mpir.sort<Unknown>):
  %0 = mpir_expr.read %arg0 : (!mpir.sort<Unknown>) -> !mpir.sort<Unknown> loc("desugar-metaflags.mlir":495:1)
// CHECK:           %[[READ_0:.*]] = mpir_expr.read %[[VAL_0]] : (!mpir.sort<Unknown>) -> !mpir.sort<Unknown>
  %1 = mpir_expr.call call "isPower2"(%0) : (!mpir.sort<Unknown>) -> !mpir.sort<Boolean> loc("desugar-metaflags.mlir":497:1)
// CHECK:           %[[CALL_0:.*]] = mpir_expr.call call "isPower2"(%[[READ_0]]) : (!mpir.sort<Unknown>) -> !mpir.sort<Boolean>
  mpir.yield %1 : <Boolean> loc("desugar-metaflags.mlir":499:1)
// CHECK:           mpir.yield %[[CALL_0]] : <Boolean>
} loc("desugar-metaflags.mlir":501:1)
// CHECK:         }
mpir.metaflag_def @zero <param_names = ["v"], placement = operand> {
// CHECK-LABEL:   mpir.metaflag_def @zero <placement = operand, param_names = ["v"]> {
// CHECK:         ^bb0(%[[VAL_0:.*]]: !mpir.sort<Unknown>):
^bb0(%arg0: !mpir.sort<Unknown>):
  %0 = mpir_expr.read %arg0 : (!mpir.sort<Unknown>) -> !mpir.sort<Unknown> loc("desugar-metaflags.mlir":507:1)
// CHECK:           %[[READ_0:.*]] = mpir_expr.read %[[VAL_0]] : (!mpir.sort<Unknown>) -> !mpir.sort<Unknown>
  %1 = mpir_expr.call call "isZero"(%0) : (!mpir.sort<Unknown>) -> !mpir.sort<Boolean> loc("desugar-metaflags.mlir":509:1)
// CHECK:           %[[CALL_0:.*]] = mpir_expr.call call "isZero"(%[[READ_0]]) : (!mpir.sort<Unknown>) -> !mpir.sort<Boolean>
  mpir.yield %1 : <Boolean> loc("desugar-metaflags.mlir":511:1)
// CHECK:           mpir.yield %[[CALL_0]] : <Boolean>
} loc("desugar-metaflags.mlir":513:1)
// CHECK:         }
mpir.metaflag_def @allOnes <param_names = ["v"], placement = operand> {
// CHECK-LABEL:   mpir.metaflag_def @allOnes <placement = operand, param_names = ["v"]> {
// CHECK:         ^bb0(%[[VAL_0:.*]]: !mpir.sort<Unknown>):
^bb0(%arg0: !mpir.sort<Unknown>):
  %0 = mpir_expr.read %arg0 : (!mpir.sort<Unknown>) -> !mpir.sort<Unknown> loc("desugar-metaflags.mlir":519:1)
// CHECK:           %[[READ_0:.*]] = mpir_expr.read %[[VAL_0]] : (!mpir.sort<Unknown>) -> !mpir.sort<Unknown>
  %1 = mpir_expr.call call "isAllOnes"(%0) : (!mpir.sort<Unknown>) -> !mpir.sort<Boolean> loc("desugar-metaflags.mlir":521:1)
// CHECK:           %[[CALL_0:.*]] = mpir_expr.call call "isAllOnes"(%[[READ_0]]) : (!mpir.sort<Unknown>) -> !mpir.sort<Boolean>
  mpir.yield %1 : <Boolean> loc("desugar-metaflags.mlir":523:1)
// CHECK:           mpir.yield %[[CALL_0]] : <Boolean>
} loc("desugar-metaflags.mlir":525:1)
// CHECK:         }
mpir.pattern {
// CHECK-LABEL:   mpir.pattern {
  %0 = mpir.type.int 32 : <Type> loc("desugar-metaflags.mlir":529:1)
// CHECK:           %[[TYPE_0:.*]] = mpir.type.int 32 : <Type>
  %x = mpir.var "x" : <Operand> loc("desugar-metaflags.mlir":531:1)
// CHECK:           %[[VAR_0:.*]] = mpir.var "x" : <Operand>
  %y = mpir.var "y" : <Operand> loc("desugar-metaflags.mlir":533:1)
// CHECK:           %[[VAR_1:.*]] = mpir.var "y" : <Operand>
  %i_a = mpir.inst <add> (%0, %x, %0, %y) <result_name = "a", flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value], operand_metaflags = [[#mpir.metaflag<"zero", [], loc("desugar-metaflags.mlir":535:1)>, #mpir.metaflag<"power2", [], loc("desugar-metaflags.mlir":535:1)>], [#mpir.metaflag<"allOnes", [], loc("desugar-metaflags.mlir":535:1)>]]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:           %[[INST_0:.*]] = mpir.inst <add> (%[[TYPE_0]], %[[VAR_0]], %[[TYPE_0]], %[[VAR_1]]) <flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value], result_name = "a"> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:           %[[READ_0:.*]] = mpir_expr.read %[[VAR_0]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
// CHECK:           %[[CALL_0:.*]] = mpir_expr.call call "isZero"(%[[READ_0]]) anchor %[[INST_0]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:           mpir.require %[[CALL_0]] <from_metaflag> : <Boolean>
// CHECK:           %[[READ_1:.*]] = mpir_expr.read %[[VAR_0]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
// CHECK:           %[[CALL_1:.*]] = mpir_expr.call call "isPower2"(%[[READ_1]]) anchor %[[INST_0]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:           mpir.require %[[CALL_1]] <from_metaflag> : <Boolean>
// CHECK:           %[[READ_2:.*]] = mpir_expr.read %[[VAR_1]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
// CHECK:           %[[CALL_2:.*]] = mpir_expr.call call "isAllOnes"(%[[READ_2]]) anchor %[[INST_0]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:           mpir.require %[[CALL_2]] <from_metaflag> : <Boolean>
} loc("desugar-metaflags.mlir":546:1)
// CHECK:         }

// -----

// On a use of a matcher, and inside a matcher's branches, whose parameters
// are the subjects.
mpir.metaflag_def @power2 <param_names = ["v"], placement = operand> {
// CHECK-LABEL:   mpir.metaflag_def @power2 <placement = operand, param_names = ["v"]> {
// CHECK:         ^bb0(%[[VAL_0:.*]]: !mpir.sort<Unknown>):
^bb0(%arg0: !mpir.sort<Unknown>):
  %0 = mpir_expr.read %arg0 : (!mpir.sort<Unknown>) -> !mpir.sort<Unknown> loc("desugar-metaflags.mlir":557:1)
// CHECK:           %[[READ_0:.*]] = mpir_expr.read %[[VAL_0]] : (!mpir.sort<Unknown>) -> !mpir.sort<Unknown>
  %1 = mpir_expr.call call "isPower2"(%0) : (!mpir.sort<Unknown>) -> !mpir.sort<Boolean> loc("desugar-metaflags.mlir":559:1)
// CHECK:           %[[CALL_0:.*]] = mpir_expr.call call "isPower2"(%[[READ_0]]) : (!mpir.sort<Unknown>) -> !mpir.sort<Boolean>
  mpir.yield %1 : <Boolean> loc("desugar-metaflags.mlir":561:1)
// CHECK:           mpir.yield %[[CALL_0]] : <Boolean>
} loc("desugar-metaflags.mlir":563:1)
// CHECK:         }
mpir.metaflag_def @zero <param_names = ["v"], placement = operand> {
// CHECK-LABEL:   mpir.metaflag_def @zero <placement = operand, param_names = ["v"]> {
// CHECK:         ^bb0(%[[VAL_0:.*]]: !mpir.sort<Unknown>):
^bb0(%arg0: !mpir.sort<Unknown>):
  %0 = mpir_expr.read %arg0 : (!mpir.sort<Unknown>) -> !mpir.sort<Unknown> loc("desugar-metaflags.mlir":569:1)
// CHECK:           %[[READ_0:.*]] = mpir_expr.read %[[VAL_0]] : (!mpir.sort<Unknown>) -> !mpir.sort<Unknown>
  %1 = mpir_expr.call call "isZero"(%0) : (!mpir.sort<Unknown>) -> !mpir.sort<Boolean> loc("desugar-metaflags.mlir":571:1)
// CHECK:           %[[CALL_0:.*]] = mpir_expr.call call "isZero"(%[[READ_0]]) : (!mpir.sort<Unknown>) -> !mpir.sort<Boolean>
  mpir.yield %1 : <Boolean> loc("desugar-metaflags.mlir":573:1)
// CHECK:           mpir.yield %[[CALL_0]] : <Boolean>
} loc("desugar-metaflags.mlir":575:1)
// CHECK:         }
mpir.metaflag_def @allOnes <param_names = ["v"], placement = operand> {
// CHECK-LABEL:   mpir.metaflag_def @allOnes <placement = operand, param_names = ["v"]> {
// CHECK:         ^bb0(%[[VAL_0:.*]]: !mpir.sort<Unknown>):
^bb0(%arg0: !mpir.sort<Unknown>):
  %0 = mpir_expr.read %arg0 : (!mpir.sort<Unknown>) -> !mpir.sort<Unknown> loc("desugar-metaflags.mlir":581:1)
// CHECK:           %[[READ_0:.*]] = mpir_expr.read %[[VAL_0]] : (!mpir.sort<Unknown>) -> !mpir.sort<Unknown>
  %1 = mpir_expr.call call "isAllOnes"(%0) : (!mpir.sort<Unknown>) -> !mpir.sort<Boolean> loc("desugar-metaflags.mlir":583:1)
// CHECK:           %[[CALL_0:.*]] = mpir_expr.call call "isAllOnes"(%[[READ_0]]) : (!mpir.sort<Unknown>) -> !mpir.sort<Boolean>
  mpir.yield %1 : <Boolean> loc("desugar-metaflags.mlir":585:1)
// CHECK:           mpir.yield %[[CALL_0]] : <Boolean>
} loc("desugar-metaflags.mlir":587:1)
// CHECK:         }
mpir.metaflag_def @s <param_names = ["v"], placement = instruction|operand> {
// CHECK-LABEL:   mpir.metaflag_def @s <placement = instruction|operand, param_names = ["v"]> {
// CHECK:         ^bb0(%[[VAL_0:.*]]: !mpir.sort<Unknown>):
^bb0(%arg0: !mpir.sort<Unknown>):
  %0 = mpir_expr.read %arg0 : (!mpir.sort<Unknown>) -> !mpir.sort<Unknown> loc("desugar-metaflags.mlir":593:1)
// CHECK:           %[[READ_0:.*]] = mpir_expr.read %[[VAL_0]] : (!mpir.sort<Unknown>) -> !mpir.sort<Unknown>
  %1 = mpir_expr.call call "hasOneUse"(%0) : (!mpir.sort<Unknown>) -> !mpir.sort<Boolean> loc("desugar-metaflags.mlir":595:1)
// CHECK:           %[[CALL_0:.*]] = mpir_expr.call call "hasOneUse"(%[[READ_0]]) : (!mpir.sort<Unknown>) -> !mpir.sort<Boolean>
  mpir.yield %1 : <Boolean> loc("desugar-metaflags.mlir":597:1)
// CHECK:           mpir.yield %[[CALL_0]] : <Boolean>
} loc("desugar-metaflags.mlir":599:1)
// CHECK:         }
mpir.matcher @addz <supported_flags = [], syntax = binary, arity = 2, param_names = ["ty", "a", "b"], param_is_type = [true, false, false]> {
// CHECK-LABEL:   mpir.matcher @addz <supported_flags = [], syntax = binary, arity = 2, param_names = ["ty", "a", "b"], param_is_type = [true, false, false]> {
  %ty = mpir.var "ty" : <Type> loc("desugar-metaflags.mlir":603:1)
// CHECK:           %[[VAR_0:.*]] = mpir.var "ty" : <Type>
  mpir.signature %ty : !mpir.sort<Type> loc("desugar-metaflags.mlir":605:1)
// CHECK:           mpir.signature %[[VAR_0]] : !mpir.sort<Type>
  mpir.branch <param_args = [0, 1, 2], fixed_flags = [], fixed_flag_values = []> {
// CHECK:           mpir.branch <fixed_flags = [], param_args = [0, 1, 2], fixed_flag_values = []> {
// CHECK:           ^bb0(%[[VAL_0:.*]]: !mpir.sort<Type>, %[[VAL_1:.*]]: !mpir.sort<Operand>, %[[VAL_2:.*]]: !mpir.sort<Operand>):
  ^bb0(%arg0: !mpir.sort<Type>, %arg1: !mpir.sort<Operand>, %arg2: !mpir.sort<Operand>):
    %i_ret = mpir.inst <add> (%arg0, %arg1, %arg0, %arg2) <result_name = "ret", flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value], operand_metaflags = [[#mpir.metaflag<"zero", [], loc("desugar-metaflags.mlir":611:1)>], []]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:             %[[INST_0:.*]] = mpir.inst <add> (%[[VAL_0]], %[[VAL_1]], %[[VAL_0]], %[[VAL_2]]) <flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value], result_name = "ret"> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:             %[[READ_0:.*]] = mpir_expr.read %[[VAL_1]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
// CHECK:             %[[CALL_0:.*]] = mpir_expr.call call "isZero"(%[[READ_0]]) anchor %[[INST_0]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:             mpir.require %[[CALL_0]] <from_metaflag> : <Boolean>
    mpir.yield %i_ret : <Instruction> loc("desugar-metaflags.mlir":616:1)
// CHECK:             mpir.yield %[[INST_0]] : <Instruction>
  } loc("desugar-metaflags.mlir":618:1)
// CHECK:           }
  mpir.branch <param_args = [0, 1, 2], fixed_flags = [], fixed_flag_values = []> {
// CHECK:           mpir.branch <fixed_flags = [], param_args = [0, 1, 2], fixed_flag_values = []> {
// CHECK:           ^bb0(%[[VAL_3:.*]]: !mpir.sort<Type>, %[[VAL_4:.*]]: !mpir.sort<Operand>, %[[VAL_5:.*]]: !mpir.sort<Operand>):
  ^bb0(%arg0: !mpir.sort<Type>, %arg1: !mpir.sort<Operand>, %arg2: !mpir.sort<Operand>):
    %i_ret = mpir.inst <sub> (%arg0, %arg1, %arg0, %arg2) <result_name = "ret", flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value], metaflags = [#mpir.metaflag<"s", [], loc("desugar-metaflags.mlir":624:1)>], operand_metaflags = [[], [#mpir.metaflag<"power2", [], loc("desugar-metaflags.mlir":624:1)>]]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:             %[[INST_1:.*]] = mpir.inst <sub> (%[[VAL_3]], %[[VAL_4]], %[[VAL_3]], %[[VAL_5]]) <flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value], result_name = "ret"> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:             %[[READ_1:.*]] = mpir_expr.read %[[INST_1]] : (!mpir.sort<Instruction>) -> !mpir.sort<Value>
// CHECK:             %[[CALL_1:.*]] = mpir_expr.call call "hasOneUse"(%[[READ_1]]) anchor %[[INST_1]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:             mpir.require %[[CALL_1]] <from_metaflag> : <Boolean>
// CHECK:             %[[READ_2:.*]] = mpir_expr.read %[[VAL_5]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
// CHECK:             %[[CALL_2:.*]] = mpir_expr.call call "isPower2"(%[[READ_2]]) anchor %[[INST_1]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:             mpir.require %[[CALL_2]] <from_metaflag> : <Boolean>
    mpir.yield %i_ret : <Instruction> loc("desugar-metaflags.mlir":632:1)
// CHECK:             mpir.yield %[[INST_1]] : <Instruction>
  } loc("desugar-metaflags.mlir":634:1)
// CHECK:           }
} loc("desugar-metaflags.mlir":636:1)
// CHECK:         }
mpir.pattern {
// CHECK-LABEL:   mpir.pattern {
  %0 = mpir.type.int 32 : <Type> loc("desugar-metaflags.mlir":640:1)
// CHECK:           %[[TYPE_0:.*]] = mpir.type.int 32 : <Type>
  %x = mpir.var "x" : <Operand> loc("desugar-metaflags.mlir":642:1)
// CHECK:           %[[VAR_0:.*]] = mpir.var "x" : <Operand>
  %y = mpir.var "y" : <Operand> loc("desugar-metaflags.mlir":644:1)
// CHECK:           %[[VAR_1:.*]] = mpir.var "y" : <Operand>
  %u_r = mpir.use @addz (%0, %x, %0, %y) <result_name = "r", flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value], metaflags = [#mpir.metaflag<"s", [], loc("desugar-metaflags.mlir":646:1)>], operand_metaflags = [[#mpir.metaflag<"allOnes", [], loc("desugar-metaflags.mlir":646:1)>], []]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:           %[[USE_0:.*]] = mpir.use @addz (%[[TYPE_0]], %[[VAR_0]], %[[TYPE_0]], %[[VAR_1]]) <flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value], result_name = "r"> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:           %[[READ_0:.*]] = mpir_expr.read %[[USE_0]] : (!mpir.sort<Instruction>) -> !mpir.sort<Value>
// CHECK:           %[[CALL_0:.*]] = mpir_expr.call call "hasOneUse"(%[[READ_0]]) anchor %[[USE_0]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:           mpir.require %[[CALL_0]] <from_metaflag> : <Boolean>
// CHECK:           %[[READ_1:.*]] = mpir_expr.read %[[VAR_0]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
// CHECK:           %[[CALL_1:.*]] = mpir_expr.call call "isAllOnes"(%[[READ_1]]) anchor %[[USE_0]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:           mpir.require %[[CALL_1]] <from_metaflag> : <Boolean>
} loc("desugar-metaflags.mlir":654:1)
// CHECK:         }

// -----

// On a flag-captured, typed and array operands' neighbours: only value
// operands have subjects.
mpir.metaflag_def @zero <param_names = ["v"], placement = operand> {
// CHECK-LABEL:   mpir.metaflag_def @zero <placement = operand, param_names = ["v"]> {
// CHECK:         ^bb0(%[[VAL_0:.*]]: !mpir.sort<Unknown>):
^bb0(%arg0: !mpir.sort<Unknown>):
  %0 = mpir_expr.read %arg0 : (!mpir.sort<Unknown>) -> !mpir.sort<Unknown> loc("desugar-metaflags.mlir":665:1)
// CHECK:           %[[READ_0:.*]] = mpir_expr.read %[[VAL_0]] : (!mpir.sort<Unknown>) -> !mpir.sort<Unknown>
  %1 = mpir_expr.call call "isZero"(%0) : (!mpir.sort<Unknown>) -> !mpir.sort<Boolean> loc("desugar-metaflags.mlir":667:1)
// CHECK:           %[[CALL_0:.*]] = mpir_expr.call call "isZero"(%[[READ_0]]) : (!mpir.sort<Unknown>) -> !mpir.sort<Boolean>
  mpir.yield %1 : <Boolean> loc("desugar-metaflags.mlir":669:1)
// CHECK:           mpir.yield %[[CALL_0]] : <Boolean>
} loc("desugar-metaflags.mlir":671:1)
// CHECK:         }
mpir.metaflag_def @s <param_names = ["v"], placement = instruction|operand> {
// CHECK-LABEL:   mpir.metaflag_def @s <placement = instruction|operand, param_names = ["v"]> {
// CHECK:         ^bb0(%[[VAL_0:.*]]: !mpir.sort<Unknown>):
^bb0(%arg0: !mpir.sort<Unknown>):
  %0 = mpir_expr.read %arg0 : (!mpir.sort<Unknown>) -> !mpir.sort<Unknown> loc("desugar-metaflags.mlir":677:1)
// CHECK:           %[[READ_0:.*]] = mpir_expr.read %[[VAL_0]] : (!mpir.sort<Unknown>) -> !mpir.sort<Unknown>
  %1 = mpir_expr.call call "hasOneUse"(%0) : (!mpir.sort<Unknown>) -> !mpir.sort<Boolean> loc("desugar-metaflags.mlir":679:1)
// CHECK:           %[[CALL_0:.*]] = mpir_expr.call call "hasOneUse"(%[[READ_0]]) : (!mpir.sort<Unknown>) -> !mpir.sort<Boolean>
  mpir.yield %1 : <Boolean> loc("desugar-metaflags.mlir":681:1)
// CHECK:           mpir.yield %[[CALL_0]] : <Boolean>
} loc("desugar-metaflags.mlir":683:1)
// CHECK:         }
mpir.metaflag_def @notUndef <param_names = ["v"], placement = operand> {
// CHECK-LABEL:   mpir.metaflag_def @notUndef <placement = operand, param_names = ["v"]> {
// CHECK:         ^bb0(%[[VAL_0:.*]]: !mpir.sort<Unknown>):
^bb0(%arg0: !mpir.sort<Unknown>):
  %0 = mpir_expr.read %arg0 : (!mpir.sort<Unknown>) -> !mpir.sort<Unknown> loc("desugar-metaflags.mlir":689:1)
// CHECK:           %[[READ_0:.*]] = mpir_expr.read %[[VAL_0]] : (!mpir.sort<Unknown>) -> !mpir.sort<Unknown>
  %1 = mpir_expr.call call "isGuaranteedNotToBeUndef"(%0) : (!mpir.sort<Unknown>) -> !mpir.sort<Boolean> loc("desugar-metaflags.mlir":691:1)
// CHECK:           %[[CALL_0:.*]] = mpir_expr.call call "isGuaranteedNotToBeUndef"(%[[READ_0]]) : (!mpir.sort<Unknown>) -> !mpir.sort<Boolean>
  mpir.yield %1 : <Boolean> loc("desugar-metaflags.mlir":693:1)
// CHECK:           mpir.yield %[[CALL_0]] : <Boolean>
} loc("desugar-metaflags.mlir":695:1)
// CHECK:         }
mpir.pattern {
// CHECK-LABEL:   mpir.pattern {
  %p = mpir.var "p" : <CmpPredicate> loc("desugar-metaflags.mlir":699:1)
// CHECK:           %[[VAR_0:.*]] = mpir.var "p" : <CmpPredicate>
  %0 = mpir.type.int 32 : <Type> loc("desugar-metaflags.mlir":701:1)
// CHECK:           %[[TYPE_0:.*]] = mpir.type.int 32 : <Type>
  %x = mpir.var "x" : <Operand> loc("desugar-metaflags.mlir":703:1)
// CHECK:           %[[VAR_1:.*]] = mpir.var "x" : <Operand>
  %y = mpir.var "y" : <Operand> loc("desugar-metaflags.mlir":705:1)
// CHECK:           %[[VAR_2:.*]] = mpir.var "y" : <Operand>
  %i_c = mpir.inst <icmp> (%p, %0, %x, %0, %y) <result_name = "c", flags = [], flag_modes = [], operand_kinds = [predicate, typed_value, typed_value], operand_metaflags = [[], [#mpir.metaflag<"zero", [], loc("desugar-metaflags.mlir":707:1)>], []]> : (!mpir.sort<CmpPredicate>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:           %[[INST_0:.*]] = mpir.inst <icmp> (%[[VAR_0]], %[[TYPE_0]], %[[VAR_1]], %[[TYPE_0]], %[[VAR_2]]) <flags = [], flag_modes = [], operand_kinds = [predicate, typed_value, typed_value], result_name = "c"> : (!mpir.sort<CmpPredicate>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
  %1 = mpir.type.int 32 : <Type> loc("desugar-metaflags.mlir":709:1)
// CHECK:           %[[TYPE_1:.*]] = mpir.type.int 32 : <Type>
  %2 = mpir.type.ptr : () -> !mpir.sort<Type> loc("desugar-metaflags.mlir":711:1)
// CHECK:           %[[TYPE_2:.*]] = mpir.type.ptr : () -> !mpir.sort<Type>
  %q = mpir.var "q" : <Operand> loc("desugar-metaflags.mlir":713:1)
// CHECK:           %[[VAR_3:.*]] = mpir.var "q" : <Operand>
  %al = mpir.var "al" : <Nat> loc("desugar-metaflags.mlir":715:1)
// CHECK:           %[[VAR_4:.*]] = mpir.var "al" : <Nat>
  %i_l = mpir.inst <load> (%1, %2, %q, %al) <result_name = "l", flags = [], flag_modes = [], operand_kinds = [type_only, typed_value, alignment], operand_metaflags = [[], [#mpir.metaflag<"notUndef", [], loc("desugar-metaflags.mlir":717:1)>], []]> : (!mpir.sort<Type>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Nat>) -> !mpir.sort<Instruction>
// CHECK:           %[[INST_1:.*]] = mpir.inst <load> (%[[TYPE_1]], %[[TYPE_2]], %[[VAR_3]], %[[VAR_4]]) <flags = [], flag_modes = [], operand_kinds = [type_only, typed_value, alignment], result_name = "l"> : (!mpir.sort<Type>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Nat>) -> !mpir.sort<Instruction>
  %3 = mpir.type.int 32 : <Type> loc("desugar-metaflags.mlir":719:1)
// CHECK:           %[[TYPE_3:.*]] = mpir.type.int 32 : <Type>
  %4 = mpir.global "f" : <Value> loc("desugar-metaflags.mlir":721:1)
// CHECK:           %[[GLOBAL_0:.*]] = mpir.global "f" : <Value>
  %5 = mpir.type.int 32 : <Type> loc("desugar-metaflags.mlir":723:1)
// CHECK:           %[[TYPE_4:.*]] = mpir.type.int 32 : <Type>
  %ts = mpir.var "ts" : <TypeArray> loc("desugar-metaflags.mlir":725:1)
// CHECK:           %[[VAR_5:.*]] = mpir.var "ts" : <TypeArray>
  %vs = mpir.var "vs" : <ValueArray> loc("desugar-metaflags.mlir":727:1)
// CHECK:           %[[VAR_6:.*]] = mpir.var "vs" : <ValueArray>
  %i_f = mpir.inst <call> (%3, %4, %5, %i_l, %ts, %vs) <result_name = "f", flags = [], flag_modes = [], operand_kinds = [type_only, value, typed_value, typed_value_array], operand_metaflags = [[], [], [#mpir.metaflag<"s", [], loc("desugar-metaflags.mlir":729:1)>], []]> : (!mpir.sort<Type>, !mpir.sort<Value>, !mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<TypeArray>, !mpir.sort<ValueArray>) -> !mpir.sort<Instruction>
// CHECK:           %[[INST_2:.*]] = mpir.inst <call> (%[[TYPE_3]], %[[GLOBAL_0]], %[[TYPE_4]], %[[INST_1]], %[[VAR_5]], %[[VAR_6]]) <flags = [], flag_modes = [], operand_kinds = [type_only, value, typed_value, typed_value_array], result_name = "f"> : (!mpir.sort<Type>, !mpir.sort<Value>, !mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<TypeArray>, !mpir.sort<ValueArray>) -> !mpir.sort<Instruction>
// CHECK:           %[[READ_0:.*]] = mpir_expr.read %[[VAR_1]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
// CHECK:           %[[CALL_0:.*]] = mpir_expr.call call "isZero"(%[[READ_0]]) anchor %[[INST_0]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:           mpir.require %[[CALL_0]] <from_metaflag> : <Boolean>
// CHECK:           %[[READ_1:.*]] = mpir_expr.read %[[VAR_3]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
// CHECK:           %[[CALL_1:.*]] = mpir_expr.call call "isGuaranteedNotToBeUndef"(%[[READ_1]]) anchor %[[INST_1]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:           mpir.require %[[CALL_1]] <from_metaflag> : <Boolean>
// CHECK:           %[[READ_2:.*]] = mpir_expr.read %[[INST_1]] : (!mpir.sort<Instruction>) -> !mpir.sort<Value>
// CHECK:           %[[CALL_2:.*]] = mpir_expr.call call "hasOneUse"(%[[READ_2]]) anchor %[[INST_2]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:           mpir.require %[[CALL_2]] <from_metaflag> : <Boolean>
} loc("desugar-metaflags.mlir":740:1)
// CHECK:         }

// -----

// Constraints written in the pattern come after the flags' requirements
// of the instructions before them.
mpir.metaflag_def @power2 <param_names = ["v"], placement = operand> {
// CHECK-LABEL:   mpir.metaflag_def @power2 <placement = operand, param_names = ["v"]> {
// CHECK:         ^bb0(%[[VAL_0:.*]]: !mpir.sort<Unknown>):
^bb0(%arg0: !mpir.sort<Unknown>):
  %0 = mpir_expr.read %arg0 : (!mpir.sort<Unknown>) -> !mpir.sort<Unknown> loc("desugar-metaflags.mlir":751:1)
// CHECK:           %[[READ_0:.*]] = mpir_expr.read %[[VAL_0]] : (!mpir.sort<Unknown>) -> !mpir.sort<Unknown>
  %1 = mpir_expr.call call "isPower2"(%0) : (!mpir.sort<Unknown>) -> !mpir.sort<Boolean> loc("desugar-metaflags.mlir":753:1)
// CHECK:           %[[CALL_0:.*]] = mpir_expr.call call "isPower2"(%[[READ_0]]) : (!mpir.sort<Unknown>) -> !mpir.sort<Boolean>
  mpir.yield %1 : <Boolean> loc("desugar-metaflags.mlir":755:1)
// CHECK:           mpir.yield %[[CALL_0]] : <Boolean>
} loc("desugar-metaflags.mlir":757:1)
// CHECK:         }
mpir.metaflag_def @zero <param_names = ["v"], placement = operand> {
// CHECK-LABEL:   mpir.metaflag_def @zero <placement = operand, param_names = ["v"]> {
// CHECK:         ^bb0(%[[VAL_0:.*]]: !mpir.sort<Unknown>):
^bb0(%arg0: !mpir.sort<Unknown>):
  %0 = mpir_expr.read %arg0 : (!mpir.sort<Unknown>) -> !mpir.sort<Unknown> loc("desugar-metaflags.mlir":763:1)
// CHECK:           %[[READ_0:.*]] = mpir_expr.read %[[VAL_0]] : (!mpir.sort<Unknown>) -> !mpir.sort<Unknown>
  %1 = mpir_expr.call call "isZero"(%0) : (!mpir.sort<Unknown>) -> !mpir.sort<Boolean> loc("desugar-metaflags.mlir":765:1)
// CHECK:           %[[CALL_0:.*]] = mpir_expr.call call "isZero"(%[[READ_0]]) : (!mpir.sort<Unknown>) -> !mpir.sort<Boolean>
  mpir.yield %1 : <Boolean> loc("desugar-metaflags.mlir":767:1)
// CHECK:           mpir.yield %[[CALL_0]] : <Boolean>
} loc("desugar-metaflags.mlir":769:1)
// CHECK:         }
mpir.pattern {
// CHECK-LABEL:   mpir.pattern {
  %0 = mpir.type.int 32 : <Type> loc("desugar-metaflags.mlir":773:1)
// CHECK:           %[[TYPE_0:.*]] = mpir.type.int 32 : <Type>
  %x = mpir.var "x" : <Operand> loc("desugar-metaflags.mlir":775:1)
// CHECK:           %[[VAR_0:.*]] = mpir.var "x" : <Operand>
  %y = mpir.var "y" : <Operand> loc("desugar-metaflags.mlir":777:1)
// CHECK:           %[[VAR_1:.*]] = mpir.var "y" : <Operand>
  %i_a = mpir.inst <add> (%0, %x, %0, %y) <result_name = "a", flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value], operand_metaflags = [[#mpir.metaflag<"zero", [], loc("desugar-metaflags.mlir":779:1)>], []]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:           %[[INST_0:.*]] = mpir.inst <add> (%[[TYPE_0]], %[[VAR_0]], %[[TYPE_0]], %[[VAR_1]]) <flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value], result_name = "a"> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
  %1 = mpir_expr.read %y : (!mpir.sort<Operand>) -> !mpir.sort<Value> loc("desugar-metaflags.mlir":781:1)
// CHECK:           %[[READ_0:.*]] = mpir_expr.read %[[VAR_1]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
  %2 = mpir_expr.int 1 : ui64 : <Integer> loc("desugar-metaflags.mlir":783:1)
// CHECK:           %[[INT_0:.*]] = mpir_expr.int 1 : ui64 : <Integer>
  %3 = mpir_expr.call binary "=="(%1, %2) anchor %i_a : (!mpir.sort<Value>, !mpir.sort<Integer>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("desugar-metaflags.mlir":785:1)
// CHECK:           %[[CALL_0:.*]] = mpir_expr.call binary "=="(%[[READ_0]], %[[INT_0]]) anchor %[[INST_0]] : (!mpir.sort<Value>, !mpir.sort<Integer>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:           %[[READ_1:.*]] = mpir_expr.read %[[VAR_0]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
// CHECK:           %[[CALL_1:.*]] = mpir_expr.call call "isZero"(%[[READ_1]]) anchor %[[INST_0]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
// CHECK:           mpir.require %[[CALL_1]] <from_metaflag> : <Boolean>
// CHECK:           %[[READ_2:.*]] = mpir_expr.read %[[VAL_0:.*]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
// CHECK:           %[[CALL_2:.*]] = mpir_expr.call call "isPower2"(%[[READ_2]]) anchor %[[VAL_1:.*]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
  mpir.require %3 : <Boolean> loc("desugar-metaflags.mlir":792:1)
  %4 = mpir.type.int 32 : <Type> loc("desugar-metaflags.mlir":793:1)
  %z = mpir.var "z" : <Operand> loc("desugar-metaflags.mlir":794:1)
  %i_b = mpir.inst <mul> (%4, %i_a, %4, %z) <result_name = "b", flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value], operand_metaflags = [[], [#mpir.metaflag<"power2", [], loc("desugar-metaflags.mlir":795:1)>]]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:           mpir.require %[[CALL_2]] <from_metaflag> : <Boolean>
// CHECK:           mpir.require %[[CALL_0]] : <Boolean>
// CHECK:           %[[TYPE_1:.*]] = mpir.type.int 32 : <Type>
// CHECK:           %[[VAL_0]] = mpir.var "z" : <Operand>
// CHECK:           %[[VAL_1]] = mpir.inst <mul> (%[[TYPE_1]], %[[INST_0]], %[[TYPE_1]], %[[VAL_0]]) <flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value], result_name = "b"> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
  %5 = mpir_expr.read %z : (!mpir.sort<Operand>) -> !mpir.sort<Value> loc("desugar-metaflags.mlir":801:1)
// CHECK:           %[[READ_3:.*]] = mpir_expr.read %[[VAL_0]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
  %6 = mpir_expr.int 2 : ui64 : <Integer> loc("desugar-metaflags.mlir":803:1)
// CHECK:           %[[INT_1:.*]] = mpir_expr.int 2 : ui64 : <Integer>
  %7 = mpir_expr.call binary "=="(%5, %6) anchor %i_b : (!mpir.sort<Value>, !mpir.sort<Integer>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("desugar-metaflags.mlir":805:1)
// CHECK:           %[[CALL_3:.*]] = mpir_expr.call binary "=="(%[[READ_3]], %[[INT_1]]) anchor %[[VAL_1]] : (!mpir.sort<Value>, !mpir.sort<Integer>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
  mpir.require %7 : <Boolean> loc("desugar-metaflags.mlir":807:1)
// CHECK:           mpir.require %[[CALL_3]] : <Boolean>
} loc("desugar-metaflags.mlir":809:1)
// CHECK:         }
