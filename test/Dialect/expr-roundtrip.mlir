// RUN: %metaphir-opt %s | %metaphir-opt | FileCheck %s
// The mpir_expr dialect's operations print as they parse: literals, arrays
// and their elements, reads of pattern values, built-in operators of each
// kind and calls of definitions, each with and without an anchor.

mpir.constraint_def @isOne <param_names = ["v"]> {
// CHECK-LABEL:   mpir.constraint_def @isOne <param_names = ["v"]> {
// CHECK:         ^bb0(%[[VAL_0:.*]]: !mpir.sort<Unknown>):
^bb0(%v: !mpir.sort<Unknown>):
  %r = mpir_expr.read %v : (!mpir.sort<Unknown>) -> !mpir.sort<Integer> loc("expr-roundtrip.mlir":10:1)
// CHECK:           %[[READ_0:.*]] = mpir_expr.read %[[VAL_0]] : (!mpir.sort<Unknown>) -> !mpir.sort<Integer>
  %one = mpir_expr.int 1 : ui64 : !mpir.sort<Integer> loc("expr-roundtrip.mlir":12:1)
// CHECK:           %[[INT_0:.*]] = mpir_expr.int 1 : ui64 : <Integer>
  %eq = mpir_expr.call binary "=="(%r, %one) : (!mpir.sort<Integer>, !mpir.sort<Integer>) -> !mpir.sort<Boolean> loc("expr-roundtrip.mlir":14:1)
// CHECK:           %[[CALL_0:.*]] = mpir_expr.call binary "=="(%[[READ_0]], %[[INT_0]]) : (!mpir.sort<Integer>, !mpir.sort<Integer>) -> !mpir.sort<Boolean>
  mpir.yield %eq : !mpir.sort<Boolean> loc("expr-roundtrip.mlir":16:1)
// CHECK:           mpir.yield %[[CALL_0]] : <Boolean>
} loc("expr-roundtrip.mlir":18:1)
// CHECK:         }
mpir.pattern {
// CHECK-LABEL:   mpir.pattern {
  %x = mpir.var "x" : !mpir.sort<Operand> loc("expr-roundtrip.mlir":22:1)
// CHECK:           %[[VAR_0:.*]] = mpir.var "x" : <Operand>
  %i32 = mpir.type.int 32 : !mpir.sort<Type> loc("expr-roundtrip.mlir":24:1)
// CHECK:           %[[TYPE_0:.*]] = mpir.type.int 32 : <Type>
  %i = mpir.inst <freeze>(%i32, %x) <result_name = "f", flags = [], flag_modes = [], operand_kinds = [typed_value]> : (!mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction> loc("expr-roundtrip.mlir":26:1)
// CHECK:           %[[INST_0:.*]] = mpir.inst <freeze> (%[[TYPE_0]], %[[VAR_0]]) <flags = [], flag_modes = [], operand_kinds = [typed_value], result_name = "f"> : (!mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
  %rx = mpir_expr.read %x : (!mpir.sort<Operand>) -> !mpir.sort<Value> loc("expr-roundtrip.mlir":28:1)
// CHECK:           %[[READ_0:.*]] = mpir_expr.read %[[VAR_0]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
  %ri = mpir_expr.read %i : (!mpir.sort<Instruction>) -> !mpir.sort<Value> loc("expr-roundtrip.mlir":30:1)
// CHECK:           %[[READ_1:.*]] = mpir_expr.read %[[INST_0]] : (!mpir.sort<Instruction>) -> !mpir.sort<Value>
  %neg = mpir_expr.int -3 : si64 : !mpir.sort<Integer> loc("expr-roundtrip.mlir":32:1)
// CHECK:           %[[INT_0:.*]] = mpir_expr.int -3 : si64 : <Integer>
  %big = mpir_expr.int 18446744073709551615 : ui64 : !mpir.sort<Integer> loc("expr-roundtrip.mlir":34:1)
// CHECK:           %[[INT_1:.*]] = mpir_expr.int 18446744073709551615 : ui64 : <Integer>
  %t = mpir_expr.bool true : !mpir.sort<Boolean> loc("expr-roundtrip.mlir":36:1)
// CHECK:           %[[BOOL_0:.*]] = mpir_expr.bool true : <Boolean>
  %f = mpir_expr.bool false : !mpir.sort<Boolean> loc("expr-roundtrip.mlir":38:1)
// CHECK:           %[[BOOL_1:.*]] = mpir_expr.bool false : <Boolean>
  %s = mpir_expr.str "llvm.ctlz" : !mpir.sort<String> loc("expr-roundtrip.mlir":40:1)
// CHECK:           %[[STR_0:.*]] = mpir_expr.str "llvm.ctlz" : <String>
  %e = mpir_expr.str "" : !mpir.sort<String> loc("expr-roundtrip.mlir":42:1)
// CHECK:           %[[STR_1:.*]] = mpir_expr.str "" : <String>
  %arr = mpir_expr.array %s, %e : (!mpir.sort<String>, !mpir.sort<String>) -> !mpir.sort<StringArray> loc("expr-roundtrip.mlir":44:1)
// CHECK:           %[[ARRAY_0:.*]] = mpir_expr.array %[[STR_0]], %[[STR_1]] : (!mpir.sort<String>, !mpir.sort<String>) -> !mpir.sort<StringArray>
  %none = mpir_expr.array : () -> !mpir.sort<StringArray> loc("expr-roundtrip.mlir":46:1)
// CHECK:           %[[ARRAY_1:.*]] = mpir_expr.array  : () -> !mpir.sort<StringArray>
  %el = mpir_expr.index %arr[%neg] : (!mpir.sort<StringArray>, !mpir.sort<Integer>) -> !mpir.sort<String> loc("expr-roundtrip.mlir":48:1)
// CHECK:           %[[INDEX_0:.*]] = mpir_expr.index %[[ARRAY_0]]{{\[}}%[[INT_0]]] : (!mpir.sort<StringArray>, !mpir.sort<Integer>) -> !mpir.sort<String>
  %not = mpir_expr.call unary "!"(%t) : (!mpir.sort<Boolean>) -> !mpir.sort<Boolean> loc("expr-roundtrip.mlir":50:1)
// CHECK:           %[[CALL_0:.*]] = mpir_expr.call unary "!"(%[[BOOL_0]]) : (!mpir.sort<Boolean>) -> !mpir.sort<Boolean>
  %minus = mpir_expr.call unary "-"(%neg) : (!mpir.sort<Integer>) -> !mpir.sort<Integer> loc("expr-roundtrip.mlir":52:1)
// CHECK:           %[[CALL_1:.*]] = mpir_expr.call unary "-"(%[[INT_0]]) : (!mpir.sort<Integer>) -> !mpir.sort<Integer>
  %sub = mpir_expr.call binary "-"(%neg, %big) : (!mpir.sort<Integer>, !mpir.sort<Integer>) -> !mpir.sort<Integer> loc("expr-roundtrip.mlir":54:1)
// CHECK:           %[[CALL_2:.*]] = mpir_expr.call binary "-"(%[[INT_0]], %[[INT_1]]) : (!mpir.sort<Integer>, !mpir.sort<Integer>) -> !mpir.sort<Integer>
  %and = mpir_expr.call binary "&&"(%t, %f) : (!mpir.sort<Boolean>, !mpir.sort<Boolean>) -> !mpir.sort<Boolean> loc("expr-roundtrip.mlir":56:1)
// CHECK:           %[[CALL_3:.*]] = mpir_expr.call binary "&&"(%[[BOOL_0]], %[[BOOL_1]]) : (!mpir.sort<Boolean>, !mpir.sort<Boolean>) -> !mpir.sort<Boolean>
  %or = mpir_expr.call binary "||"(%not, %and) : (!mpir.sort<Boolean>, !mpir.sort<Boolean>) -> !mpir.sort<Boolean> loc("expr-roundtrip.mlir":58:1)
// CHECK:           %[[CALL_4:.*]] = mpir_expr.call binary "||"(%[[CALL_0]], %[[CALL_3]]) : (!mpir.sort<Boolean>, !mpir.sort<Boolean>) -> !mpir.sort<Boolean>
  %ult = mpir_expr.call call "ult"(%neg, %big) : (!mpir.sort<Integer>, !mpir.sort<Integer>) -> !mpir.sort<Boolean> loc("expr-roundtrip.mlir":60:1)
// CHECK:           %[[CALL_5:.*]] = mpir_expr.call call "ult"(%[[INT_0]], %[[INT_1]]) : (!mpir.sort<Integer>, !mpir.sort<Integer>) -> !mpir.sort<Boolean>
  %zero = mpir_expr.call call "isZero"(%rx) anchor %i : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("expr-roundtrip.mlir":62:1)
// CHECK:           %[[CALL_6:.*]] = mpir_expr.call call "isZero"(%[[READ_0]]) anchor %[[INST_0]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
  %ctx = mpir_expr.call call "isKnownNonZero"(%rx, %ri) : (!mpir.sort<Value>, !mpir.sort<Value>) -> !mpir.sort<Boolean> loc("expr-roundtrip.mlir":64:1)
// CHECK:           %[[CALL_7:.*]] = mpir_expr.call call "isKnownNonZero"(%[[READ_0]], %[[READ_1]]) : (!mpir.sort<Value>, !mpir.sort<Value>) -> !mpir.sort<Boolean>
  %one = mpir_expr.apply @isOne(%rx) : (!mpir.sort<Value>) -> !mpir.sort<Boolean> loc("expr-roundtrip.mlir":66:1)
// CHECK:           %[[APPLY_0:.*]] = mpir_expr.apply @isOne(%[[READ_0]]) : (!mpir.sort<Value>) -> !mpir.sort<Boolean>
  %oneAt = mpir_expr.apply @isOne(%rx) anchor %i : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean> loc("expr-roundtrip.mlir":68:1)
// CHECK:           %[[APPLY_1:.*]] = mpir_expr.apply @isOne(%[[READ_0]]) anchor %[[INST_0]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
  mpir.require %oneAt : !mpir.sort<Boolean> loc("expr-roundtrip.mlir":70:1)
// CHECK:           mpir.require %[[APPLY_1]] : <Boolean>
  %all = mpir_expr.call binary "&&"(%or, %one) : (!mpir.sort<Boolean>, !mpir.sort<Boolean>) -> !mpir.sort<Boolean> loc("expr-roundtrip.mlir":72:1)
// CHECK:           %[[CALL_8:.*]] = mpir_expr.call binary "&&"(%[[CALL_4]], %[[APPLY_0]]) : (!mpir.sort<Boolean>, !mpir.sort<Boolean>) -> !mpir.sort<Boolean>
  mpir.require %all : !mpir.sort<Boolean> loc("expr-roundtrip.mlir":74:1)
// CHECK:           mpir.require %[[CALL_8]] : <Boolean>
  mpir.require %zero : !mpir.sort<Boolean> loc("expr-roundtrip.mlir":76:1)
// CHECK:           mpir.require %[[CALL_6]] : <Boolean>
  mpir.require %ctx : !mpir.sort<Boolean> loc("expr-roundtrip.mlir":78:1)
// CHECK:           mpir.require %[[CALL_7]] : <Boolean>
  mpir.require %ult : !mpir.sort<Boolean> loc("expr-roundtrip.mlir":80:1)
// CHECK:           mpir.require %[[CALL_5]] : <Boolean>
  %eqs = mpir_expr.call binary "=="(%el, %s) : (!mpir.sort<String>, !mpir.sort<String>) -> !mpir.sort<Boolean> loc("expr-roundtrip.mlir":82:1)
// CHECK:           %[[CALL_9:.*]] = mpir_expr.call binary "=="(%[[INDEX_0]], %[[STR_0]]) : (!mpir.sort<String>, !mpir.sort<String>) -> !mpir.sort<Boolean>
  mpir.require %eqs : !mpir.sort<Boolean> loc("expr-roundtrip.mlir":84:1)
// CHECK:           mpir.require %[[CALL_9]] : <Boolean>
  %m = mpir_expr.call binary "=="(%minus, %sub) : (!mpir.sort<Integer>, !mpir.sort<Integer>) -> !mpir.sort<Boolean> loc("expr-roundtrip.mlir":86:1)
// CHECK:           %[[CALL_10:.*]] = mpir_expr.call binary "=="(%[[CALL_1]], %[[CALL_2]]) : (!mpir.sort<Integer>, !mpir.sort<Integer>) -> !mpir.sort<Boolean>
  mpir.require %m : !mpir.sort<Boolean> loc("expr-roundtrip.mlir":88:1)
// CHECK:           mpir.require %[[CALL_10]] : <Boolean>
  %n = mpir_expr.call binary "=="(%none, %arr) : (!mpir.sort<StringArray>, !mpir.sort<StringArray>) -> !mpir.sort<Boolean> loc("expr-roundtrip.mlir":90:1)
// CHECK:           %[[CALL_11:.*]] = mpir_expr.call binary "=="(%[[ARRAY_1]], %[[ARRAY_0]]) : (!mpir.sort<StringArray>, !mpir.sort<StringArray>) -> !mpir.sort<Boolean>
  mpir.require %n : !mpir.sort<Boolean> loc("expr-roundtrip.mlir":92:1)
// CHECK:           mpir.require %[[CALL_11]] : <Boolean>
} loc("expr-roundtrip.mlir":94:1)
// CHECK:         }
