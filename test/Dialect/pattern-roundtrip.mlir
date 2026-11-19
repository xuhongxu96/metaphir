// RUN: %metaphir-opt --split-input-file %s | %metaphir-opt --split-input-file | FileCheck %s
// The mpir dialect's operations print as they parse.

// Values: meta variables of each sort, literals, keywords, globals and
// aggregates.
mpir.pattern {
// CHECK-LABEL:   mpir.pattern {
  %v = mpir.var "v" : !mpir.sort<Value> loc("pattern-roundtrip.mlir":8:1)
// CHECK:           %[[VAR_0:.*]] = mpir.var "v" : <Value>
  %o = mpir.var "o" : !mpir.sort<Operand> loc("pattern-roundtrip.mlir":10:1)
// CHECK:           %[[VAR_1:.*]] = mpir.var "o" : <Operand>
  %n = mpir.var "n" : !mpir.sort<Nat> loc("pattern-roundtrip.mlir":12:1)
// CHECK:           %[[VAR_2:.*]] = mpir.var "n" : <Nat>
  %b = mpir.var "b" : !mpir.sort<Boolean> loc("pattern-roundtrip.mlir":14:1)
// CHECK:           %[[VAR_3:.*]] = mpir.var "b" : <Boolean>
  %p = mpir.var "p" : !mpir.sort<CmpPredicate> loc("pattern-roundtrip.mlir":16:1)
// CHECK:           %[[VAR_4:.*]] = mpir.var "p" : <CmpPredicate>
  %f = mpir.var "f" : !mpir.sort<Function> loc("pattern-roundtrip.mlir":18:1)
// CHECK:           %[[VAR_5:.*]] = mpir.var "f" : <Function>
  %bb = mpir.var "bb" : !mpir.sort<BasicBlock> loc("pattern-roundtrip.mlir":20:1)
// CHECK:           %[[VAR_6:.*]] = mpir.var "bb" : <BasicBlock>
  %ta = mpir.var "ta" : !mpir.sort<TypeArray> loc("pattern-roundtrip.mlir":22:1)
// CHECK:           %[[VAR_7:.*]] = mpir.var "ta" : <TypeArray>
  %va = mpir.var "va" : !mpir.sort<ValueArray> loc("pattern-roundtrip.mlir":24:1)
// CHECK:           %[[VAR_8:.*]] = mpir.var "va" : <ValueArray>
  %s = mpir.var "s" : !mpir.sort<String> loc("pattern-roundtrip.mlir":26:1)
// CHECK:           %[[VAR_9:.*]] = mpir.var "s" : <String>
  %i = mpir.var "i" : !mpir.sort<Instruction> loc("pattern-roundtrip.mlir":28:1)
// CHECK:           %[[VAR_10:.*]] = mpir.var "i" : <Instruction>
  %u = mpir.var "u" : !mpir.sort<Unknown> loc("pattern-roundtrip.mlir":30:1)
// CHECK:           %[[VAR_11:.*]] = mpir.var "u" : <Unknown>
  %odd = mpir.var "has.dots-and space" : !mpir.sort<Value> loc("pattern-roundtrip.mlir":32:1)
// CHECK:           %[[VAR_12:.*]] = mpir.var "has.dots-and space" : <Value>
  %one = mpir.int 1 : ui1 : !mpir.sort<Value> loc("pattern-roundtrip.mlir":34:1)
// CHECK:           %[[INT_0:.*]] = mpir.int 1 : ui1 : <Value>
  %neg = mpir.int -5 : si64 : !mpir.sort<Value> loc("pattern-roundtrip.mlir":36:1)
// CHECK:           %[[INT_1:.*]] = mpir.int -5 : si64 : <Value>
  %half = mpir.float 1.5 : f64 -> !mpir.sort<Value> loc("pattern-roundtrip.mlir":38:1)
// CHECK:           %[[FLOAT_0:.*]] = mpir.float 1.500000e+00 : f64 -> <Value>
  %null = mpir.keyword null : !mpir.sort<Value> loc("pattern-roundtrip.mlir":40:1)
// CHECK:           %[[KEYWORD_0:.*]] = mpir.keyword null : <Value>
  %poison = mpir.keyword poison : !mpir.sort<Value> loc("pattern-roundtrip.mlir":42:1)
// CHECK:           %[[KEYWORD_1:.*]] = mpir.keyword poison : <Value>
  %eq = mpir.keyword eq : !mpir.sort<CmpPredicate> loc("pattern-roundtrip.mlir":44:1)
// CHECK:           %[[KEYWORD_2:.*]] = mpir.keyword eq : <CmpPredicate>
  %g = mpir.global "llvm.ctlz" : !mpir.sort<Function> loc("pattern-roundtrip.mlir":46:1)
// CHECK:           %[[GLOBAL_0:.*]] = mpir.global "llvm.ctlz" : <Function>
  %i32 = mpir.type.int 32 : !mpir.sort<Type> loc("pattern-roundtrip.mlir":48:1)
// CHECK:           %[[TYPE_0:.*]] = mpir.type.int 32 : <Type>
  %arr = mpir.aggregate array(%i32, %one, %i32, %neg) : (!mpir.sort<Type>, !mpir.sort<Value>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Value> loc("pattern-roundtrip.mlir":50:1)
// CHECK:           %[[AGGREGATE_0:.*]] = mpir.aggregate array(%[[TYPE_0]], %[[INT_0]], %[[TYPE_0]], %[[INT_1]]) : (!mpir.sort<Type>, !mpir.sort<Value>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Value>
  %st = mpir.aggregate struct(%i32, %one) : (!mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Value> loc("pattern-roundtrip.mlir":52:1)
// CHECK:           %[[AGGREGATE_1:.*]] = mpir.aggregate struct(%[[TYPE_0]], %[[INT_0]]) : (!mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Value>
  %vec = mpir.aggregate vector(%i32, %poison, %i32, %one) : (!mpir.sort<Type>, !mpir.sort<Value>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Value> loc("pattern-roundtrip.mlir":54:1)
// CHECK:           %[[AGGREGATE_2:.*]] = mpir.aggregate vector(%[[TYPE_0]], %[[KEYWORD_1]], %[[TYPE_0]], %[[INT_0]]) : (!mpir.sort<Type>, !mpir.sort<Value>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Value>
  %empty = mpir.aggregate struct() : () -> !mpir.sort<Value> loc("pattern-roundtrip.mlir":56:1)
// CHECK:           %[[AGGREGATE_3:.*]] = mpir.aggregate struct() : () -> !mpir.sort<Value>
} loc("pattern-roundtrip.mlir":58:1)
// CHECK:         }

// -----

// Type patterns: integers and bytes, meta widths, primitives, pointers,
// sequences, structs and functions.
mpir.pattern {
// CHECK-LABEL:   mpir.pattern {
  %n = mpir.var "n" : !mpir.sort<Nat> loc("pattern-roundtrip.mlir":67:1)
// CHECK:           %[[VAR_0:.*]] = mpir.var "n" : <Nat>
  %t = mpir.var "t" : !mpir.sort<Type> loc("pattern-roundtrip.mlir":69:1)
// CHECK:           %[[VAR_1:.*]] = mpir.var "t" : <Type>
  %i1 = mpir.type.int 1 : !mpir.sort<Type> loc("pattern-roundtrip.mlir":71:1)
// CHECK:           %[[TYPE_0:.*]] = mpir.type.int 1 : <Type>
  %b8 = mpir.type.int 8 byte : !mpir.sort<Type> loc("pattern-roundtrip.mlir":73:1)
// CHECK:           %[[TYPE_1:.*]] = mpir.type.int 8 byte : <Type>
  %in = mpir.type.meta_int %n : (!mpir.sort<Nat>) -> !mpir.sort<Type> loc("pattern-roundtrip.mlir":75:1)
// CHECK:           %[[TYPE_2:.*]] = mpir.type.meta_int %[[VAR_0]] : (!mpir.sort<Nat>) -> !mpir.sort<Type>
  %bn = mpir.type.meta_int %n byte : (!mpir.sort<Nat>) -> !mpir.sort<Type> loc("pattern-roundtrip.mlir":77:1)
// CHECK:           %[[TYPE_3:.*]] = mpir.type.meta_int %[[VAR_0]] byte : (!mpir.sort<Nat>) -> !mpir.sort<Type>
  %h = mpir.type.prim half : !mpir.sort<Type> loc("pattern-roundtrip.mlir":79:1)
// CHECK:           %[[TYPE_4:.*]] = mpir.type.prim half : <Type>
  %bf = mpir.type.prim bfloat : !mpir.sort<Type> loc("pattern-roundtrip.mlir":81:1)
// CHECK:           %[[TYPE_5:.*]] = mpir.type.prim bfloat : <Type>
  %fl = mpir.type.prim float : !mpir.sort<Type> loc("pattern-roundtrip.mlir":83:1)
// CHECK:           %[[TYPE_6:.*]] = mpir.type.prim float : <Type>
  %d = mpir.type.prim double : !mpir.sort<Type> loc("pattern-roundtrip.mlir":85:1)
// CHECK:           %[[TYPE_7:.*]] = mpir.type.prim double : <Type>
  %q = mpir.type.prim fp128 : !mpir.sort<Type> loc("pattern-roundtrip.mlir":87:1)
// CHECK:           %[[TYPE_8:.*]] = mpir.type.prim fp128 : <Type>
  %vd = mpir.type.prim void : !mpir.sort<Type> loc("pattern-roundtrip.mlir":89:1)
// CHECK:           %[[TYPE_9:.*]] = mpir.type.prim void : <Type>
  %lb = mpir.type.prim label : !mpir.sort<Type> loc("pattern-roundtrip.mlir":91:1)
// CHECK:           %[[TYPE_10:.*]] = mpir.type.prim label : <Type>
  %ptr = mpir.type.ptr : () -> !mpir.sort<Type> loc("pattern-roundtrip.mlir":93:1)
// CHECK:           %[[TYPE_11:.*]] = mpir.type.ptr : () -> !mpir.sort<Type>
  %ptr3 = mpir.type.ptr addrspace(3) : () -> !mpir.sort<Type> loc("pattern-roundtrip.mlir":95:1)
// CHECK:           %[[TYPE_12:.*]] = mpir.type.ptr addrspace(3) : () -> !mpir.sort<Type>
  %typed = mpir.type.ptr %i1 : (!mpir.sort<Type>) -> !mpir.sort<Type> loc("pattern-roundtrip.mlir":97:1)
// CHECK:           %[[TYPE_13:.*]] = mpir.type.ptr %[[TYPE_0]] : (!mpir.sort<Type>) -> !mpir.sort<Type>
  %typed2 = mpir.type.ptr %i1 addrspace(1) : (!mpir.sort<Type>) -> !mpir.sort<Type> loc("pattern-roundtrip.mlir":99:1)
// CHECK:           %[[TYPE_14:.*]] = mpir.type.ptr %[[TYPE_0]] addrspace(1) : (!mpir.sort<Type>) -> !mpir.sort<Type>
  %a = mpir.type.seq array 4 x %b8 : (!mpir.sort<Type>) -> !mpir.sort<Type> loc("pattern-roundtrip.mlir":101:1)
// CHECK:           %[[TYPE_15:.*]] = mpir.type.seq array 4 x %[[TYPE_1]] : (!mpir.sort<Type>) -> !mpir.sort<Type>
  %v = mpir.type.seq vector 2 x %in : (!mpir.sort<Type>) -> !mpir.sort<Type> loc("pattern-roundtrip.mlir":103:1)
// CHECK:           %[[TYPE_16:.*]] = mpir.type.seq vector 2 x %[[TYPE_2]] : (!mpir.sort<Type>) -> !mpir.sort<Type>
  %sv = mpir.type.seq scalable 4 x %fl : (!mpir.sort<Type>) -> !mpir.sort<Type> loc("pattern-roundtrip.mlir":105:1)
// CHECK:           %[[TYPE_17:.*]] = mpir.type.seq scalable 4 x %[[TYPE_6]] : (!mpir.sort<Type>) -> !mpir.sort<Type>
  %counted = mpir.type.seq array 0 x %t count %n : (!mpir.sort<Type>, !mpir.sort<Nat>) -> !mpir.sort<Type> loc("pattern-roundtrip.mlir":107:1)
// CHECK:           %[[TYPE_18:.*]] = mpir.type.seq array 0 x %[[VAR_1]] count %[[VAR_0]] : (!mpir.sort<Type>, !mpir.sort<Nat>) -> !mpir.sort<Type>
  %s = mpir.type.struct {%i1, %h} : (!mpir.sort<Type>, !mpir.sort<Type>) -> !mpir.sort<Type> loc("pattern-roundtrip.mlir":109:1)
// CHECK:           %[[TYPE_19:.*]] = mpir.type.struct{%[[TYPE_0]], %[[TYPE_4]]} : (!mpir.sort<Type>, !mpir.sort<Type>) -> !mpir.sort<Type>
  %ps = mpir.type.struct packed {%i1} : (!mpir.sort<Type>) -> !mpir.sort<Type> loc("pattern-roundtrip.mlir":111:1)
// CHECK:           %[[TYPE_20:.*]] = mpir.type.struct packed{%[[TYPE_0]]} : (!mpir.sort<Type>) -> !mpir.sort<Type>
  %es = mpir.type.struct {} : () -> !mpir.sort<Type> loc("pattern-roundtrip.mlir":113:1)
// CHECK:           %[[TYPE_21:.*]] = mpir.type.struct{} : () -> !mpir.sort<Type>
  %fn = mpir.type.func %vd(%i1, %ptr) : (!mpir.sort<Type>, !mpir.sort<Type>, !mpir.sort<Type>) -> !mpir.sort<Type> loc("pattern-roundtrip.mlir":115:1)
// CHECK:           %[[TYPE_22:.*]] = mpir.type.func %[[TYPE_9]](%[[TYPE_0]], %[[TYPE_11]]) : (!mpir.sort<Type>, !mpir.sort<Type>, !mpir.sort<Type>) -> !mpir.sort<Type>
  %va = mpir.type.func %i1(%i1) vararg : (!mpir.sort<Type>, !mpir.sort<Type>) -> !mpir.sort<Type> loc("pattern-roundtrip.mlir":117:1)
// CHECK:           %[[TYPE_23:.*]] = mpir.type.func %[[TYPE_0]](%[[TYPE_0]]) vararg : (!mpir.sort<Type>, !mpir.sort<Type>) -> !mpir.sort<Type>
  %nop = mpir.type.func %vd() : (!mpir.sort<Type>) -> !mpir.sort<Type> loc("pattern-roundtrip.mlir":119:1)
// CHECK:           %[[TYPE_24:.*]] = mpir.type.func %[[TYPE_9]]() : (!mpir.sort<Type>) -> !mpir.sort<Type>
} loc("pattern-roundtrip.mlir":121:1)
// CHECK:         }

// -----

// Instruction matchers with all they can have: flags (required, absent,
// captured), metaflags on the instruction and on operands, a capture, a
// parent block, keyed and array operands and the settings.
mpir.pattern {
// CHECK-LABEL:   mpir.pattern {
  %i32 = mpir.type.int 32 : !mpir.sort<Type> loc("pattern-roundtrip.mlir":131:1)
// CHECK:           %[[TYPE_0:.*]] = mpir.type.int 32 : <Type>
  %x = mpir.var "x" : !mpir.sort<Operand> loc("pattern-roundtrip.mlir":133:1)
// CHECK:           %[[VAR_0:.*]] = mpir.var "x" : <Operand>
  %y = mpir.var "y" : !mpir.sort<Operand> loc("pattern-roundtrip.mlir":135:1)
// CHECK:           %[[VAR_1:.*]] = mpir.var "y" : <Operand>
  %nsw = mpir.var "nsw" : !mpir.sort<Boolean> loc("pattern-roundtrip.mlir":137:1)
// CHECK:           %[[VAR_2:.*]] = mpir.var "nsw" : <Boolean>
  %cap = mpir.var "cap" : !mpir.sort<Instruction> loc("pattern-roundtrip.mlir":139:1)
// CHECK:           %[[VAR_3:.*]] = mpir.var "cap" : <Instruction>
  %blk = mpir.var "blk" : !mpir.sort<BasicBlock> loc("pattern-roundtrip.mlir":141:1)
// CHECK:           %[[VAR_4:.*]] = mpir.var "blk" : <BasicBlock>
  %add = mpir.inst <add> capture %cap block %blk flags(%nsw) (%i32, %x, %i32, %y) <result_name = "sum", flags = [nsw, nuw], flag_modes = [captured, required], operand_kinds = [typed_value, typed_value], metaflags = [#mpir.metaflag<"c", [], loc("pattern-roundtrip.mlir":143:1)>, #mpir.metaflag<"s", [], loc("pattern-roundtrip.mlir":143:1)>], operand_metaflags = [[#mpir.metaflag<"or", [#mpir.metaflag<"zero", [], loc("pattern-roundtrip.mlir":143:1)>, #mpir.metaflag<"one", [], loc("pattern-roundtrip.mlir":143:1)>], loc("pattern-roundtrip.mlir":143:1)>], []], treat_int_as_vec = true> : (!mpir.sort<Instruction>, !mpir.sort<BasicBlock>, !mpir.sort<Boolean>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:           %[[INST_0:.*]] = mpir.inst <add> capture %[[VAR_3]] block %[[VAR_4]] flags(%[[VAR_2]]) (%[[TYPE_0]], %[[VAR_0]], %[[TYPE_0]], %[[VAR_1]]) <flags = [nsw, nuw], flag_modes = [captured, required], operand_kinds = [typed_value, typed_value], result_name = "sum", metaflags = [#mpir.metaflag<"c", [], {{.*}}>, #mpir.metaflag<"s", [], {{.*}}>], operand_metaflags = {{\[\[}}#mpir.metaflag<"or", [#mpir.metaflag<"zero", [], {{.*}}>, #mpir.metaflag<"one", [], {{.*}}>], {{.*}}>], []], treat_int_as_vec = true> : (!mpir.sort<Instruction>, !mpir.sort<BasicBlock>, !mpir.sort<Boolean>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
  %sub = mpir.inst <sub>(%i32, %add, %i32, %x) <result_name = "d", flags = [nuw], flag_modes = [negated], operand_kinds = [typed_value, typed_value], metaflags = [#mpir.metaflag<"o", [1], loc("pattern-roundtrip.mlir":145:1)>]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:           %[[INST_1:.*]] = mpir.inst <sub> (%[[TYPE_0]], %[[INST_0]], %[[TYPE_0]], %[[VAR_0]]) <flags = [nuw], flag_modes = [negated], operand_kinds = [typed_value, typed_value], result_name = "d", metaflags = [#mpir.metaflag<"o", [1], {{.*}}>]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
  %p = mpir.var "p" : !mpir.sort<CmpPredicate> loc("pattern-roundtrip.mlir":147:1)
// CHECK:           %[[VAR_5:.*]] = mpir.var "p" : <CmpPredicate>
  %cmp = mpir.inst <icmp>(%p, %i32, %x, %i32, %y) <flags = [], flag_modes = [], operand_kinds = [predicate, typed_value, typed_value]> : (!mpir.sort<CmpPredicate>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction> loc("pattern-roundtrip.mlir":149:1)
// CHECK:           %[[INST_2:.*]] = mpir.inst <icmp> (%[[VAR_5]], %[[TYPE_0]], %[[VAR_0]], %[[TYPE_0]], %[[VAR_1]]) <flags = [], flag_modes = [], operand_kinds = [predicate, typed_value, typed_value]> : (!mpir.sort<CmpPredicate>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
  %ptr = mpir.type.ptr : () -> !mpir.sort<Type> loc("pattern-roundtrip.mlir":151:1)
// CHECK:           %[[TYPE_1:.*]] = mpir.type.ptr : () -> !mpir.sort<Type>
  %pp = mpir.var "pp" : !mpir.sort<Operand> loc("pattern-roundtrip.mlir":153:1)
// CHECK:           %[[VAR_6:.*]] = mpir.var "pp" : <Operand>
  %al = mpir.var "al" : !mpir.sort<Nat> loc("pattern-roundtrip.mlir":155:1)
// CHECK:           %[[VAR_7:.*]] = mpir.var "al" : <Nat>
  %load = mpir.inst <load>(%i32, %ptr, %pp, %al) <result_name = "ld", flags = [], flag_modes = [], operand_kinds = [type_only, typed_value, alignment]> : (!mpir.sort<Type>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Nat>) -> !mpir.sort<Instruction> loc("pattern-roundtrip.mlir":157:1)
// CHECK:           %[[INST_3:.*]] = mpir.inst <load> (%[[TYPE_0]], %[[TYPE_1]], %[[VAR_6]], %[[VAR_7]]) <flags = [], flag_modes = [], operand_kinds = [type_only, typed_value, alignment], result_name = "ld"> : (!mpir.sort<Type>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Nat>) -> !mpir.sort<Instruction>
  %f = mpir.var "f" : !mpir.sort<Function> loc("pattern-roundtrip.mlir":159:1)
// CHECK:           %[[VAR_8:.*]] = mpir.var "f" : <Function>
  %tys = mpir.var "tys" : !mpir.sort<TypeArray> loc("pattern-roundtrip.mlir":161:1)
// CHECK:           %[[VAR_9:.*]] = mpir.var "tys" : <TypeArray>
  %vals = mpir.var "vals" : !mpir.sort<ValueArray> loc("pattern-roundtrip.mlir":163:1)
// CHECK:           %[[VAR_10:.*]] = mpir.var "vals" : <ValueArray>
  %call = mpir.inst <call>(%i32, %f, %tys, %vals) <flags = [], flag_modes = [], operand_kinds = [type_only, value, typed_value_array]> : (!mpir.sort<Type>, !mpir.sort<Function>, !mpir.sort<TypeArray>, !mpir.sort<ValueArray>) -> !mpir.sort<Instruction> loc("pattern-roundtrip.mlir":165:1)
// CHECK:           %[[INST_4:.*]] = mpir.inst <call> (%[[TYPE_0]], %[[VAR_8]], %[[VAR_9]], %[[VAR_10]]) <flags = [], flag_modes = [], operand_kinds = [type_only, value, typed_value_array]> : (!mpir.sort<Type>, !mpir.sort<Function>, !mpir.sort<TypeArray>, !mpir.sort<ValueArray>) -> !mpir.sort<Instruction>
  %idx = mpir.inst <extractvalue>(%i32, %x, %vals) <flags = [], flag_modes = [], operand_kinds = [typed_value, value_array]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<ValueArray>) -> !mpir.sort<Instruction> loc("pattern-roundtrip.mlir":167:1)
// CHECK:           %[[INST_5:.*]] = mpir.inst <extractvalue> (%[[TYPE_0]], %[[VAR_0]], %[[VAR_10]]) <flags = [], flag_modes = [], operand_kinds = [typed_value, value_array]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<ValueArray>) -> !mpir.sort<Instruction>
} loc("pattern-roundtrip.mlir":169:1)
// CHECK:         }

// -----

// Definitions: a matcher with branches and fixed flags, used; a constraint
// and a metaflag definition, called; alternatives, bindings and
// requirements of the lowered form.
mpir.matcher @addLike <commutative, supported_flags = [nsw, nuw], syntax = binary, arity = 2, param_names = ["ty", "x", "y"], param_is_type = [true, false, false]> {
// CHECK-LABEL:   mpir.matcher @addLike <supported_flags = [nsw, nuw], syntax = binary, commutative, arity = 2, param_names = ["ty", "x", "y"], param_is_type = [true, false, false]> {
  %ty = mpir.var "ty" : !mpir.sort<Type> loc("pattern-roundtrip.mlir":179:1)
// CHECK:           %[[VAR_0:.*]] = mpir.var "ty" : <Type>
  mpir.signature %ty : !mpir.sort<Type> loc("pattern-roundtrip.mlir":181:1)
// CHECK:           mpir.signature %[[VAR_0]] : !mpir.sort<Type>
  mpir.branch <param_args = [0, 1, 2], fixed_flags = [], fixed_flag_values = []> {
// CHECK:           mpir.branch <fixed_flags = [], param_args = [0, 1, 2], fixed_flag_values = []> {
// CHECK:           ^bb0(%[[VAL_0:.*]]: !mpir.sort<Type>, %[[VAL_1:.*]]: !mpir.sort<Operand>, %[[VAL_2:.*]]: !mpir.sort<Operand>):
  ^bb0(%t: !mpir.sort<Type>, %a: !mpir.sort<Operand>, %b: !mpir.sort<Operand>):
    %r = mpir.inst <add>(%t, %a, %t, %b) <result_name = "ret", flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction> loc("pattern-roundtrip.mlir":187:1)
// CHECK:             %[[INST_0:.*]] = mpir.inst <add> (%[[VAL_0]], %[[VAL_1]], %[[VAL_0]], %[[VAL_2]]) <flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value], result_name = "ret"> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
    mpir.yield %r : !mpir.sort<Instruction> loc("pattern-roundtrip.mlir":189:1)
// CHECK:             mpir.yield %[[INST_0]] : <Instruction>
  } loc("pattern-roundtrip.mlir":191:1)
// CHECK:           }
  mpir.branch <param_args = [0, 1, 2], fixed_flags = [nsw, nuw], fixed_flag_values = [true, false]> {
// CHECK:           mpir.branch <fixed_flags = [nsw, nuw], param_args = [0, 1, 2], fixed_flag_values = [true, false]> {
// CHECK:           ^bb0(%[[VAL_3:.*]]: !mpir.sort<Type>, %[[VAL_4:.*]]: !mpir.sort<Operand>, %[[VAL_5:.*]]: !mpir.sort<Operand>):
  ^bb0(%t: !mpir.sort<Type>, %a: !mpir.sort<Operand>, %b: !mpir.sort<Operand>):
    %r = mpir.inst <or>(%t, %a, %t, %b) <result_name = "ret", flags = [disjoint], flag_modes = [required], operand_kinds = [typed_value, typed_value]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction> loc("pattern-roundtrip.mlir":197:1)
// CHECK:             %[[INST_1:.*]] = mpir.inst <or> (%[[VAL_3]], %[[VAL_4]], %[[VAL_3]], %[[VAL_5]]) <flags = [disjoint], flag_modes = [required], operand_kinds = [typed_value, typed_value], result_name = "ret"> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
    mpir.yield %r : !mpir.sort<Instruction> loc("pattern-roundtrip.mlir":199:1)
// CHECK:             mpir.yield %[[INST_1]] : <Instruction>
  } loc("pattern-roundtrip.mlir":201:1)
// CHECK:           }
} loc("pattern-roundtrip.mlir":203:1)
// CHECK:         }
mpir.matcher @private_one <sym_visibility = "private", supported_flags = [], syntax = nary, arity = 1, param_names = [""], param_is_type = [false]> {
// CHECK-LABEL:   mpir.matcher @private_one <supported_flags = [], syntax = nary, sym_visibility = "private", arity = 1, param_names = [""], param_is_type = [false]> {
  mpir.signature loc("pattern-roundtrip.mlir":207:1)
// CHECK:           mpir.signature
} loc("pattern-roundtrip.mlir":209:1)
// CHECK:         }
mpir.constraint_def @same <param_names = ["a", "b"]> {
// CHECK-LABEL:   mpir.constraint_def @same <param_names = ["a", "b"]> {
// CHECK:         ^bb0(%[[VAL_0:.*]]: !mpir.sort<Unknown>, %[[VAL_1:.*]]: !mpir.sort<Unknown>):
^bb0(%a: !mpir.sort<Unknown>, %b: !mpir.sort<Unknown>):
  %ra = mpir_expr.read %a : (!mpir.sort<Unknown>) -> !mpir.sort<Unknown> loc("pattern-roundtrip.mlir":215:1)
// CHECK:           %[[READ_0:.*]] = mpir_expr.read %[[VAL_0]] : (!mpir.sort<Unknown>) -> !mpir.sort<Unknown>
  %rb = mpir_expr.read %b : (!mpir.sort<Unknown>) -> !mpir.sort<Unknown> loc("pattern-roundtrip.mlir":217:1)
// CHECK:           %[[READ_1:.*]] = mpir_expr.read %[[VAL_1]] : (!mpir.sort<Unknown>) -> !mpir.sort<Unknown>
  %eq = mpir_expr.call binary "=="(%ra, %rb) : (!mpir.sort<Unknown>, !mpir.sort<Unknown>) -> !mpir.sort<Boolean> loc("pattern-roundtrip.mlir":219:1)
// CHECK:           %[[CALL_0:.*]] = mpir_expr.call binary "=="(%[[READ_0]], %[[READ_1]]) : (!mpir.sort<Unknown>, !mpir.sort<Unknown>) -> !mpir.sort<Boolean>
  mpir.yield %eq : !mpir.sort<Boolean> loc("pattern-roundtrip.mlir":221:1)
// CHECK:           mpir.yield %[[CALL_0]] : <Boolean>
} loc("pattern-roundtrip.mlir":223:1)
// CHECK:         }
mpir.metaflag_def @small <param_names = ["v", "lim"], placement = operand> {
// CHECK-LABEL:   mpir.metaflag_def @small <placement = operand, param_names = ["v", "lim"]> {
// CHECK:         ^bb0(%[[VAL_0:.*]]: !mpir.sort<Value>, %[[VAL_1:.*]]: !mpir.sort<Integer>):
^bb0(%v: !mpir.sort<Value>, %lim: !mpir.sort<Integer>):
  %rv = mpir_expr.read %v : (!mpir.sort<Value>) -> !mpir.sort<Integer> loc("pattern-roundtrip.mlir":229:1)
// CHECK:           %[[READ_0:.*]] = mpir_expr.read %[[VAL_0]] : (!mpir.sort<Value>) -> !mpir.sort<Integer>
  %rl = mpir_expr.read %lim : (!mpir.sort<Integer>) -> !mpir.sort<Integer> loc("pattern-roundtrip.mlir":231:1)
// CHECK:           %[[READ_1:.*]] = mpir_expr.read %[[VAL_1]] : (!mpir.sort<Integer>) -> !mpir.sort<Integer>
  %lt = mpir_expr.call call "ult"(%rv, %rl) : (!mpir.sort<Integer>, !mpir.sort<Integer>) -> !mpir.sort<Boolean> loc("pattern-roundtrip.mlir":233:1)
// CHECK:           %[[CALL_0:.*]] = mpir_expr.call call "ult"(%[[READ_0]], %[[READ_1]]) : (!mpir.sort<Integer>, !mpir.sort<Integer>) -> !mpir.sort<Boolean>
  mpir.yield %lt : !mpir.sort<Boolean> loc("pattern-roundtrip.mlir":235:1)
// CHECK:           mpir.yield %[[CALL_0]] : <Boolean>
} loc("pattern-roundtrip.mlir":237:1)
// CHECK:         }
mpir.pattern {
// CHECK-LABEL:   mpir.pattern {
  %i32 = mpir.type.int 32 : !mpir.sort<Type> loc("pattern-roundtrip.mlir":241:1)
// CHECK:           %[[TYPE_0:.*]] = mpir.type.int 32 : <Type>
  %x = mpir.var "x" : !mpir.sort<Operand> loc("pattern-roundtrip.mlir":243:1)
// CHECK:           %[[VAR_0:.*]] = mpir.var "x" : <Operand>
  %y = mpir.var "y" : !mpir.sort<Operand> loc("pattern-roundtrip.mlir":245:1)
// CHECK:           %[[VAR_1:.*]] = mpir.var "y" : <Operand>
  %use = mpir.use @addLike(%i32, %x, %i32, %y) <result_name = "u", flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction> loc("pattern-roundtrip.mlir":247:1)
// CHECK:           %[[USE_0:.*]] = mpir.use @addLike (%[[TYPE_0]], %[[VAR_0]], %[[TYPE_0]], %[[VAR_1]]) <flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value], result_name = "u"> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
  %s = mpir.var "s" : !mpir.sort<Instruction> loc("pattern-roundtrip.mlir":249:1)
// CHECK:           %[[VAR_2:.*]] = mpir.var "s" : <Instruction>
// CHECK:           %[[ALT_0:.*]] = mpir.alt {
  %alt = mpir.alt {
    mpir.bind %s, %use : !mpir.sort<Instruction>, !mpir.sort<Instruction> loc("pattern-roundtrip.mlir":253:1)
// CHECK:             mpir.bind %[[VAR_2]], %[[USE_0]] : <Instruction>, <Instruction>
    mpir.yield %use : !mpir.sort<Instruction> loc("pattern-roundtrip.mlir":255:1)
// CHECK:             mpir.yield %[[USE_0]] : <Instruction>
  }, {
// CHECK:           }, {
    mpir.yield %x : !mpir.sort<Operand> loc("pattern-roundtrip.mlir":259:1)
// CHECK:             mpir.yield %[[VAR_0]] : <Operand>
  } <or_self_of = "add"> : !mpir.sort<Instruction> loc("pattern-roundtrip.mlir":261:1)
// CHECK:           } <or_self_of = "add"> : <Instruction>
  %rx = mpir_expr.read %x : (!mpir.sort<Operand>) -> !mpir.sort<Value> loc("pattern-roundtrip.mlir":263:1)
// CHECK:           %[[READ_0:.*]] = mpir_expr.read %[[VAR_0]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
  %ry = mpir_expr.read %y : (!mpir.sort<Operand>) -> !mpir.sort<Value> loc("pattern-roundtrip.mlir":265:1)
// CHECK:           %[[READ_1:.*]] = mpir_expr.read %[[VAR_1]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
  %same = mpir_expr.apply @same(%rx, %ry) : (!mpir.sort<Value>, !mpir.sort<Value>) -> !mpir.sort<Boolean> loc("pattern-roundtrip.mlir":267:1)
// CHECK:           %[[APPLY_0:.*]] = mpir_expr.apply @same(%[[READ_0]], %[[READ_1]]) : (!mpir.sort<Value>, !mpir.sort<Value>) -> !mpir.sort<Boolean>
  mpir.require %same <from_metaflag> : !mpir.sort<Boolean> loc("pattern-roundtrip.mlir":269:1)
// CHECK:           mpir.require %[[APPLY_0]] <from_metaflag> : <Boolean>
} loc("pattern-roundtrip.mlir":271:1)
// CHECK:         }

// -----

// An alternative-less mpir.alt: what a use no branch fits becomes.
mpir.pattern {
// CHECK-LABEL:   mpir.pattern {
  %none = mpir.alt <result_name = "r"> : !mpir.sort<Instruction> loc("pattern-roundtrip.mlir":279:1)
// CHECK:           %[[ALT_0:.*]] = mpir.alt  <result_name = "r"> : <Instruction>
  %bare = mpir.alt : !mpir.sort<Instruction> loc("pattern-roundtrip.mlir":281:1)
// CHECK:           %[[ALT_1:.*]] = mpir.alt  : <Instruction>
} loc("pattern-roundtrip.mlir":283:1)
// CHECK:         }
