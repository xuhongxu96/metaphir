// RUN: %metaphir-opt --split-input-file %s | %metaphir-opt --split-input-file | FileCheck %s
// The mpir dialect's operations print as they parse.

// Values: meta variables of each sort, literals, keywords, globals and
// aggregates.
mpir.pattern {
  %v = mpir.var "v" : !mpir.sort<Value>
  %o = mpir.var "o" : !mpir.sort<Operand>
  %n = mpir.var "n" : !mpir.sort<Nat>
  %b = mpir.var "b" : !mpir.sort<Boolean>
  %p = mpir.var "p" : !mpir.sort<CmpPredicate>
  %f = mpir.var "f" : !mpir.sort<Function>
  %bb = mpir.var "bb" : !mpir.sort<BasicBlock>
  %ta = mpir.var "ta" : !mpir.sort<TypeArray>
  %va = mpir.var "va" : !mpir.sort<ValueArray>
  %s = mpir.var "s" : !mpir.sort<String>
  %i = mpir.var "i" : !mpir.sort<Instruction>
  %u = mpir.var "u" : !mpir.sort<Unknown>
  %odd = mpir.var "has.dots-and space" : !mpir.sort<Value>
  %one = mpir.int 1 : ui1 : !mpir.sort<Value>
  %neg = mpir.int -5 : si64 : !mpir.sort<Value>
  %half = mpir.float 1.5 : f64 -> !mpir.sort<Value>
  %null = mpir.keyword null : !mpir.sort<Value>
  %poison = mpir.keyword poison : !mpir.sort<Value>
  %eq = mpir.keyword eq : !mpir.sort<CmpPredicate>
  %g = mpir.global "llvm.ctlz" : !mpir.sort<Function>
  %i32 = mpir.type.int 32 : !mpir.sort<Type>
  %arr = mpir.aggregate array(%i32, %one, %i32, %neg) : (!mpir.sort<Type>, !mpir.sort<Value>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Value>
  %st = mpir.aggregate struct(%i32, %one) : (!mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Value>
  %vec = mpir.aggregate vector(%i32, %poison, %i32, %one) : (!mpir.sort<Type>, !mpir.sort<Value>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Value>
  %empty = mpir.aggregate struct() : () -> !mpir.sort<Value>
}
// CHECK-LABEL:   mpir.pattern {
// CHECK:           %[[VAR_0:.*]] = mpir.var "v" : <Value>
// CHECK:           %[[VAR_1:.*]] = mpir.var "o" : <Operand>
// CHECK:           %[[VAR_2:.*]] = mpir.var "n" : <Nat>
// CHECK:           %[[VAR_3:.*]] = mpir.var "b" : <Boolean>
// CHECK:           %[[VAR_4:.*]] = mpir.var "p" : <CmpPredicate>
// CHECK:           %[[VAR_5:.*]] = mpir.var "f" : <Function>
// CHECK:           %[[VAR_6:.*]] = mpir.var "bb" : <BasicBlock>
// CHECK:           %[[VAR_7:.*]] = mpir.var "ta" : <TypeArray>
// CHECK:           %[[VAR_8:.*]] = mpir.var "va" : <ValueArray>
// CHECK:           %[[VAR_9:.*]] = mpir.var "s" : <String>
// CHECK:           %[[VAR_10:.*]] = mpir.var "i" : <Instruction>
// CHECK:           %[[VAR_11:.*]] = mpir.var "u" : <Unknown>
// CHECK:           %[[VAR_12:.*]] = mpir.var "has.dots-and space" : <Value>
// CHECK:           %[[INT_0:.*]] = mpir.int 1 : ui1 : <Value>
// CHECK:           %[[INT_1:.*]] = mpir.int -5 : si64 : <Value>
// CHECK:           %[[FLOAT_0:.*]] = mpir.float 1.500000e+00 : f64 -> <Value>
// CHECK:           %[[KEYWORD_0:.*]] = mpir.keyword null : <Value>
// CHECK:           %[[KEYWORD_1:.*]] = mpir.keyword poison : <Value>
// CHECK:           %[[KEYWORD_2:.*]] = mpir.keyword eq : <CmpPredicate>
// CHECK:           %[[GLOBAL_0:.*]] = mpir.global "llvm.ctlz" : <Function>
// CHECK:           %[[TYPE_0:.*]] = mpir.type.int 32 : <Type>
// CHECK:           %[[AGGREGATE_0:.*]] = mpir.aggregate array(%[[TYPE_0]], %[[INT_0]], %[[TYPE_0]], %[[INT_1]]) : (!mpir.sort<Type>, !mpir.sort<Value>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Value>
// CHECK:           %[[AGGREGATE_1:.*]] = mpir.aggregate struct(%[[TYPE_0]], %[[INT_0]]) : (!mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Value>
// CHECK:           %[[AGGREGATE_2:.*]] = mpir.aggregate vector(%[[TYPE_0]], %[[KEYWORD_1]], %[[TYPE_0]], %[[INT_0]]) : (!mpir.sort<Type>, !mpir.sort<Value>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Value>
// CHECK:           %[[AGGREGATE_3:.*]] = mpir.aggregate struct() : () -> !mpir.sort<Value>
// CHECK:         }

// -----

// Type patterns: integers and bytes, meta widths, primitives, pointers,
// sequences, structs and functions.
mpir.pattern {
  %n = mpir.var "n" : !mpir.sort<Nat>
  %t = mpir.var "t" : !mpir.sort<Type>
  %i1 = mpir.type.int 1 : !mpir.sort<Type>
  %b8 = mpir.type.int 8 byte : !mpir.sort<Type>
  %in = mpir.type.meta_int %n : (!mpir.sort<Nat>) -> !mpir.sort<Type>
  %bn = mpir.type.meta_int %n byte : (!mpir.sort<Nat>) -> !mpir.sort<Type>
  %h = mpir.type.prim half : !mpir.sort<Type>
  %bf = mpir.type.prim bfloat : !mpir.sort<Type>
  %fl = mpir.type.prim float : !mpir.sort<Type>
  %d = mpir.type.prim double : !mpir.sort<Type>
  %q = mpir.type.prim fp128 : !mpir.sort<Type>
  %vd = mpir.type.prim void : !mpir.sort<Type>
  %lb = mpir.type.prim label : !mpir.sort<Type>
  %ptr = mpir.type.ptr : () -> !mpir.sort<Type>
  %ptr3 = mpir.type.ptr addrspace(3) : () -> !mpir.sort<Type>
  %typed = mpir.type.ptr %i1 : (!mpir.sort<Type>) -> !mpir.sort<Type>
  %typed2 = mpir.type.ptr %i1 addrspace(1) : (!mpir.sort<Type>) -> !mpir.sort<Type>
  %a = mpir.type.seq array 4 x %b8 : (!mpir.sort<Type>) -> !mpir.sort<Type>
  %v = mpir.type.seq vector 2 x %in : (!mpir.sort<Type>) -> !mpir.sort<Type>
  %sv = mpir.type.seq scalable 4 x %fl : (!mpir.sort<Type>) -> !mpir.sort<Type>
  %counted = mpir.type.seq array 0 x %t count %n : (!mpir.sort<Type>, !mpir.sort<Nat>) -> !mpir.sort<Type>
  %s = mpir.type.struct {%i1, %h} : (!mpir.sort<Type>, !mpir.sort<Type>) -> !mpir.sort<Type>
  %ps = mpir.type.struct packed {%i1} : (!mpir.sort<Type>) -> !mpir.sort<Type>
  %es = mpir.type.struct {} : () -> !mpir.sort<Type>
  %fn = mpir.type.func %vd(%i1, %ptr) : (!mpir.sort<Type>, !mpir.sort<Type>, !mpir.sort<Type>) -> !mpir.sort<Type>
  %va = mpir.type.func %i1(%i1) vararg : (!mpir.sort<Type>, !mpir.sort<Type>) -> !mpir.sort<Type>
  %nop = mpir.type.func %vd() : (!mpir.sort<Type>) -> !mpir.sort<Type>
}
// CHECK-LABEL:   mpir.pattern {
// CHECK:           %[[VAR_0:.*]] = mpir.var "n" : <Nat>
// CHECK:           %[[VAR_1:.*]] = mpir.var "t" : <Type>
// CHECK:           %[[TYPE_0:.*]] = mpir.type.int 1 : <Type>
// CHECK:           %[[TYPE_1:.*]] = mpir.type.int 8 byte : <Type>
// CHECK:           %[[TYPE_2:.*]] = mpir.type.meta_int %[[VAR_0]] : (!mpir.sort<Nat>) -> !mpir.sort<Type>
// CHECK:           %[[TYPE_3:.*]] = mpir.type.meta_int %[[VAR_0]] byte : (!mpir.sort<Nat>) -> !mpir.sort<Type>
// CHECK:           %[[TYPE_4:.*]] = mpir.type.prim half : <Type>
// CHECK:           %[[TYPE_5:.*]] = mpir.type.prim bfloat : <Type>
// CHECK:           %[[TYPE_6:.*]] = mpir.type.prim float : <Type>
// CHECK:           %[[TYPE_7:.*]] = mpir.type.prim double : <Type>
// CHECK:           %[[TYPE_8:.*]] = mpir.type.prim fp128 : <Type>
// CHECK:           %[[TYPE_9:.*]] = mpir.type.prim void : <Type>
// CHECK:           %[[TYPE_10:.*]] = mpir.type.prim label : <Type>
// CHECK:           %[[TYPE_11:.*]] = mpir.type.ptr : () -> !mpir.sort<Type>
// CHECK:           %[[TYPE_12:.*]] = mpir.type.ptr addrspace(3) : () -> !mpir.sort<Type>
// CHECK:           %[[TYPE_13:.*]] = mpir.type.ptr %[[TYPE_0]] : (!mpir.sort<Type>) -> !mpir.sort<Type>
// CHECK:           %[[TYPE_14:.*]] = mpir.type.ptr %[[TYPE_0]] addrspace(1) : (!mpir.sort<Type>) -> !mpir.sort<Type>
// CHECK:           %[[TYPE_15:.*]] = mpir.type.seq array 4 x %[[TYPE_1]] : (!mpir.sort<Type>) -> !mpir.sort<Type>
// CHECK:           %[[TYPE_16:.*]] = mpir.type.seq vector 2 x %[[TYPE_2]] : (!mpir.sort<Type>) -> !mpir.sort<Type>
// CHECK:           %[[TYPE_17:.*]] = mpir.type.seq scalable 4 x %[[TYPE_6]] : (!mpir.sort<Type>) -> !mpir.sort<Type>
// CHECK:           %[[TYPE_18:.*]] = mpir.type.seq array 0 x %[[VAR_1]] count %[[VAR_0]] : (!mpir.sort<Type>, !mpir.sort<Nat>) -> !mpir.sort<Type>
// CHECK:           %[[TYPE_19:.*]] = mpir.type.struct{%[[TYPE_0]], %[[TYPE_4]]} : (!mpir.sort<Type>, !mpir.sort<Type>) -> !mpir.sort<Type>
// CHECK:           %[[TYPE_20:.*]] = mpir.type.struct packed{%[[TYPE_0]]} : (!mpir.sort<Type>) -> !mpir.sort<Type>
// CHECK:           %[[TYPE_21:.*]] = mpir.type.struct{} : () -> !mpir.sort<Type>
// CHECK:           %[[TYPE_22:.*]] = mpir.type.func %[[TYPE_9]](%[[TYPE_0]], %[[TYPE_11]]) : (!mpir.sort<Type>, !mpir.sort<Type>, !mpir.sort<Type>) -> !mpir.sort<Type>
// CHECK:           %[[TYPE_23:.*]] = mpir.type.func %[[TYPE_0]](%[[TYPE_0]]) vararg : (!mpir.sort<Type>, !mpir.sort<Type>) -> !mpir.sort<Type>
// CHECK:           %[[TYPE_24:.*]] = mpir.type.func %[[TYPE_9]]() : (!mpir.sort<Type>) -> !mpir.sort<Type>
// CHECK:         }

// -----

// Instruction matchers with all they can have: flags (required, absent,
// captured), metaflags on the instruction and on operands, a capture, a
// parent block, keyed and array operands, the settings and the lowered
// form's swapped predicate.
mpir.pattern {
  %i32 = mpir.type.int 32 : !mpir.sort<Type>
  %x = mpir.var "x" : !mpir.sort<Operand>
  %y = mpir.var "y" : !mpir.sort<Operand>
  %nsw = mpir.var "nsw" : !mpir.sort<Boolean>
  %cap = mpir.var "cap" : !mpir.sort<Instruction>
  %blk = mpir.var "blk" : !mpir.sort<BasicBlock>
  %add = mpir.inst <add> capture %cap block %blk flags(%nsw) (%i32, %x, %i32, %y) <result_name = "sum", flags = [0, 1], flag_modes = [2, 0], operand_kinds = [0, 0], metaflags = [#mpir.metaflag<"c", [], loc(unknown)>, #mpir.metaflag<"s", [], loc(unknown)>], operand_metaflags = [[#mpir.metaflag<"or", [#mpir.metaflag<"zero", [], loc(unknown)>, #mpir.metaflag<"one", [], loc(unknown)>], loc(unknown)>], []], treat_int_as_vec = true> : (!mpir.sort<Instruction>, !mpir.sort<BasicBlock>, !mpir.sort<Boolean>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
  %sub = mpir.inst <sub>(%i32, %add, %i32, %x) <result_name = "d", flags = [1], flag_modes = [1], operand_kinds = [0, 0], metaflags = [#mpir.metaflag<"o", [1], loc(unknown)>]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
  %p = mpir.var "p" : !mpir.sort<CmpPredicate>
  %cmp = mpir.inst <icmp>(%p, %i32, %x, %i32, %y) <flags = [], flag_modes = [], operand_kinds = [5, 0, 0], swapped_predicate> : (!mpir.sort<CmpPredicate>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
  %ptr = mpir.type.ptr : () -> !mpir.sort<Type>
  %pp = mpir.var "pp" : !mpir.sort<Operand>
  %al = mpir.var "al" : !mpir.sort<Nat>
  %load = mpir.inst <load>(%i32, %ptr, %pp, %al) <result_name = "ld", flags = [], flag_modes = [], operand_kinds = [2, 0, 6]> : (!mpir.sort<Type>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Nat>) -> !mpir.sort<Instruction>
  %f = mpir.var "f" : !mpir.sort<Function>
  %tys = mpir.var "tys" : !mpir.sort<TypeArray>
  %vals = mpir.var "vals" : !mpir.sort<ValueArray>
  %call = mpir.inst <call>(%i32, %f, %tys, %vals) <flags = [], flag_modes = [], operand_kinds = [2, 1, 4]> : (!mpir.sort<Type>, !mpir.sort<Function>, !mpir.sort<TypeArray>, !mpir.sort<ValueArray>) -> !mpir.sort<Instruction>
  %idx = mpir.inst <extractvalue>(%i32, %x, %vals) <flags = [], flag_modes = [], operand_kinds = [0, 3]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<ValueArray>) -> !mpir.sort<Instruction>
}
// CHECK-LABEL:   mpir.pattern {
// CHECK:           %[[TYPE_0:.*]] = mpir.type.int 32 : <Type>
// CHECK:           %[[VAR_0:.*]] = mpir.var "x" : <Operand>
// CHECK:           %[[VAR_1:.*]] = mpir.var "y" : <Operand>
// CHECK:           %[[VAR_2:.*]] = mpir.var "nsw" : <Boolean>
// CHECK:           %[[VAR_3:.*]] = mpir.var "cap" : <Instruction>
// CHECK:           %[[VAR_4:.*]] = mpir.var "blk" : <BasicBlock>
// CHECK:           %[[INST_0:.*]] = mpir.inst <add> capture %[[VAR_3]] block %[[VAR_4]] flags(%[[VAR_2]]) (%[[TYPE_0]], %[[VAR_0]], %[[TYPE_0]], %[[VAR_1]]) <result_name = "sum", flags = [0, 1], flag_modes = [2, 0], operand_kinds = [0, 0], metaflags = [#mpir.metaflag<"c", [], {{.*}}>, #mpir.metaflag<"s", [], {{.*}}>], operand_metaflags = {{\[\[}}#mpir.metaflag<"or", [#mpir.metaflag<"zero", [], {{.*}}>, #mpir.metaflag<"one", [], {{.*}}>], {{.*}}>], []], treat_int_as_vec = true> : (!mpir.sort<Instruction>, !mpir.sort<BasicBlock>, !mpir.sort<Boolean>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:           %[[INST_1:.*]] = mpir.inst <sub> (%[[TYPE_0]], %[[INST_0]], %[[TYPE_0]], %[[VAR_0]]) <result_name = "d", flags = [1], flag_modes = [1], operand_kinds = [0, 0], metaflags = [#mpir.metaflag<"o", [1], {{.*}}>]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:           %[[VAR_5:.*]] = mpir.var "p" : <CmpPredicate>
// CHECK:           %[[INST_2:.*]] = mpir.inst <icmp> (%[[VAR_5]], %[[TYPE_0]], %[[VAR_0]], %[[TYPE_0]], %[[VAR_1]]) <flags = [], flag_modes = [], operand_kinds = [5, 0, 0], swapped_predicate> : (!mpir.sort<CmpPredicate>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:           %[[TYPE_1:.*]] = mpir.type.ptr : () -> !mpir.sort<Type>
// CHECK:           %[[VAR_6:.*]] = mpir.var "pp" : <Operand>
// CHECK:           %[[VAR_7:.*]] = mpir.var "al" : <Nat>
// CHECK:           %[[INST_3:.*]] = mpir.inst <load> (%[[TYPE_0]], %[[TYPE_1]], %[[VAR_6]], %[[VAR_7]]) <result_name = "ld", flags = [], flag_modes = [], operand_kinds = [2, 0, 6]> : (!mpir.sort<Type>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Nat>) -> !mpir.sort<Instruction>
// CHECK:           %[[VAR_8:.*]] = mpir.var "f" : <Function>
// CHECK:           %[[VAR_9:.*]] = mpir.var "tys" : <TypeArray>
// CHECK:           %[[VAR_10:.*]] = mpir.var "vals" : <ValueArray>
// CHECK:           %[[INST_4:.*]] = mpir.inst <call> (%[[TYPE_0]], %[[VAR_8]], %[[VAR_9]], %[[VAR_10]]) <flags = [], flag_modes = [], operand_kinds = [2, 1, 4]> : (!mpir.sort<Type>, !mpir.sort<Function>, !mpir.sort<TypeArray>, !mpir.sort<ValueArray>) -> !mpir.sort<Instruction>
// CHECK:           %[[INST_5:.*]] = mpir.inst <extractvalue> (%[[TYPE_0]], %[[VAR_0]], %[[VAR_10]]) <flags = [], flag_modes = [], operand_kinds = [0, 3]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<ValueArray>) -> !mpir.sort<Instruction>
// CHECK:         }

// -----

// Definitions: a matcher with branches and fixed flags, used; a constraint
// and a metaflag definition, called; alternatives, bindings and
// requirements of the lowered form.
mpir.matcher @addLike <commutative, supported_flags = [0, 1], syntax = 1, arity = 2, param_names = ["ty", "x", "y"], param_is_type = [true, false, false]> {
  %ty = mpir.var "ty" : !mpir.sort<Type>
  mpir.signature %ty : !mpir.sort<Type>
  mpir.branch <param_args = [0, 1, 2], fixed_flags = [], fixed_flag_values = []> {
  ^bb0(%t: !mpir.sort<Type>, %a: !mpir.sort<Operand>, %b: !mpir.sort<Operand>):
    %r = mpir.inst <add>(%t, %a, %t, %b) <result_name = "ret", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
    mpir.yield %r : !mpir.sort<Instruction>
  }
  mpir.branch <param_args = [0, 1, 2], fixed_flags = [0, 1], fixed_flag_values = [true, false]> {
  ^bb0(%t: !mpir.sort<Type>, %a: !mpir.sort<Operand>, %b: !mpir.sort<Operand>):
    %r = mpir.inst <or>(%t, %a, %t, %b) <result_name = "ret", flags = [3], flag_modes = [0], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
    mpir.yield %r : !mpir.sort<Instruction>
  }
}
mpir.matcher @private_one <sym_visibility = "private", supported_flags = [], syntax = 0, arity = 1, param_names = [""], param_is_type = [false]> {
  mpir.signature
}
mpir.constraint_def @same <param_names = ["a", "b"]> {
^bb0(%a: !mpir.sort<Unknown>, %b: !mpir.sort<Unknown>):
  %ra = mpir_expr.read %a : (!mpir.sort<Unknown>) -> !mpir.sort<Unknown>
  %rb = mpir_expr.read %b : (!mpir.sort<Unknown>) -> !mpir.sort<Unknown>
  %eq = mpir_expr.call binary "=="(%ra, %rb) : (!mpir.sort<Unknown>, !mpir.sort<Unknown>) -> !mpir.sort<Boolean>
  mpir.yield %eq : !mpir.sort<Boolean>
}
mpir.metaflag_def @small <param_names = ["v", "lim"], placement = 2> {
^bb0(%v: !mpir.sort<Value>, %lim: !mpir.sort<Integer>):
  %rv = mpir_expr.read %v : (!mpir.sort<Value>) -> !mpir.sort<Integer>
  %rl = mpir_expr.read %lim : (!mpir.sort<Integer>) -> !mpir.sort<Integer>
  %lt = mpir_expr.call call "ult"(%rv, %rl) : (!mpir.sort<Integer>, !mpir.sort<Integer>) -> !mpir.sort<Boolean>
  mpir.yield %lt : !mpir.sort<Boolean>
}
mpir.pattern {
  %i32 = mpir.type.int 32 : !mpir.sort<Type>
  %x = mpir.var "x" : !mpir.sort<Operand>
  %y = mpir.var "y" : !mpir.sort<Operand>
  %use = mpir.use @addLike(%i32, %x, %i32, %y) <result_name = "u", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
  %s = mpir.var "s" : !mpir.sort<Instruction>
  %alt = mpir.alt {
    mpir.bind %s, %use : !mpir.sort<Instruction>, !mpir.sort<Instruction>
    mpir.yield %use : !mpir.sort<Instruction>
  }, {
    mpir.yield %x : !mpir.sort<Operand>
  } attributes {or_self_of = "add"} : !mpir.sort<Instruction>
  %rx = mpir_expr.read %x : (!mpir.sort<Operand>) -> !mpir.sort<Value>
  %ry = mpir_expr.read %y : (!mpir.sort<Operand>) -> !mpir.sort<Value>
  %same = mpir_expr.apply @same(%rx, %ry) : (!mpir.sort<Value>, !mpir.sort<Value>) -> !mpir.sort<Boolean>
  mpir.require %same {from_metaflag} : !mpir.sort<Boolean>
}
// CHECK-LABEL:   mpir.matcher @addLike <commutative, supported_flags = [0, 1], syntax = 1, arity = 2, param_names = ["ty", "x", "y"], param_is_type = [true, false, false]> {
// CHECK:           %[[VAR_0:.*]] = mpir.var "ty" : <Type>
// CHECK:           mpir.signature %[[VAR_0]] : !mpir.sort<Type>
// CHECK:           mpir.branch <param_args = [0, 1, 2], fixed_flags = [], fixed_flag_values = []> {
// CHECK:           ^bb0(%[[VAL_0:.*]]: !mpir.sort<Type>, %[[VAL_1:.*]]: !mpir.sort<Operand>, %[[VAL_2:.*]]: !mpir.sort<Operand>):
// CHECK:             %[[INST_0:.*]] = mpir.inst <add> (%[[VAL_0]], %[[VAL_1]], %[[VAL_0]], %[[VAL_2]]) <result_name = "ret", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:             mpir.yield %[[INST_0]] : <Instruction>
// CHECK:           }
// CHECK:           mpir.branch <param_args = [0, 1, 2], fixed_flags = [0, 1], fixed_flag_values = [true, false]> {
// CHECK:           ^bb0(%[[VAL_3:.*]]: !mpir.sort<Type>, %[[VAL_4:.*]]: !mpir.sort<Operand>, %[[VAL_5:.*]]: !mpir.sort<Operand>):
// CHECK:             %[[INST_1:.*]] = mpir.inst <or> (%[[VAL_3]], %[[VAL_4]], %[[VAL_3]], %[[VAL_5]]) <result_name = "ret", flags = [3], flag_modes = [0], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:             mpir.yield %[[INST_1]] : <Instruction>
// CHECK:           }
// CHECK:         }
// CHECK-LABEL:   mpir.matcher @private_one <sym_visibility = "private", supported_flags = [], syntax = 0, arity = 1, param_names = [""], param_is_type = [false]> {
// CHECK:           mpir.signature
// CHECK:         }
// CHECK-LABEL:   mpir.constraint_def @same <param_names = ["a", "b"]> {
// CHECK:         ^bb0(%[[VAL_0:.*]]: !mpir.sort<Unknown>, %[[VAL_1:.*]]: !mpir.sort<Unknown>):
// CHECK:           %[[READ_0:.*]] = mpir_expr.read %[[VAL_0]] : (!mpir.sort<Unknown>) -> !mpir.sort<Unknown>
// CHECK:           %[[READ_1:.*]] = mpir_expr.read %[[VAL_1]] : (!mpir.sort<Unknown>) -> !mpir.sort<Unknown>
// CHECK:           %[[CALL_0:.*]] = mpir_expr.call binary "=="(%[[READ_0]], %[[READ_1]]) : (!mpir.sort<Unknown>, !mpir.sort<Unknown>) -> !mpir.sort<Boolean>
// CHECK:           mpir.yield %[[CALL_0]] : <Boolean>
// CHECK:         }
// CHECK-LABEL:   mpir.metaflag_def @small <param_names = ["v", "lim"], placement = 2> {
// CHECK:         ^bb0(%[[VAL_0:.*]]: !mpir.sort<Value>, %[[VAL_1:.*]]: !mpir.sort<Integer>):
// CHECK:           %[[READ_0:.*]] = mpir_expr.read %[[VAL_0]] : (!mpir.sort<Value>) -> !mpir.sort<Integer>
// CHECK:           %[[READ_1:.*]] = mpir_expr.read %[[VAL_1]] : (!mpir.sort<Integer>) -> !mpir.sort<Integer>
// CHECK:           %[[CALL_0:.*]] = mpir_expr.call call "ult"(%[[READ_0]], %[[READ_1]]) : (!mpir.sort<Integer>, !mpir.sort<Integer>) -> !mpir.sort<Boolean>
// CHECK:           mpir.yield %[[CALL_0]] : <Boolean>
// CHECK:         }
// CHECK-LABEL:   mpir.pattern {
// CHECK:           %[[TYPE_0:.*]] = mpir.type.int 32 : <Type>
// CHECK:           %[[VAR_0:.*]] = mpir.var "x" : <Operand>
// CHECK:           %[[VAR_1:.*]] = mpir.var "y" : <Operand>
// CHECK:           %[[USE_0:.*]] = mpir.use @addLike (%[[TYPE_0]], %[[VAR_0]], %[[TYPE_0]], %[[VAR_1]]) <result_name = "u", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
// CHECK:           %[[VAR_2:.*]] = mpir.var "s" : <Instruction>
// CHECK:           %[[ALT_0:.*]] = mpir.alt {
// CHECK:             mpir.bind %[[VAR_2]], %[[USE_0]] : <Instruction>, <Instruction>
// CHECK:             mpir.yield %[[USE_0]] : <Instruction>
// CHECK:           }, {
// CHECK:             mpir.yield %[[VAR_0]] : <Operand>
// CHECK:           } attributes {or_self_of = "add"} : <Instruction>
// CHECK:           %[[READ_0:.*]] = mpir_expr.read %[[VAR_0]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
// CHECK:           %[[READ_1:.*]] = mpir_expr.read %[[VAR_1]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
// CHECK:           %[[APPLY_0:.*]] = mpir_expr.apply @same(%[[READ_0]], %[[READ_1]]) : (!mpir.sort<Value>, !mpir.sort<Value>) -> !mpir.sort<Boolean>
// CHECK:           mpir.require %[[APPLY_0]] {from_metaflag} : <Boolean>
// CHECK:         }

// -----

// An alternative-less mpir.alt: what a use no branch fits becomes.
mpir.pattern {
  %none = mpir.alt attributes {result_name = "r"} : !mpir.sort<Instruction>
  %bare = mpir.alt : !mpir.sort<Instruction>
}
// CHECK-LABEL:   mpir.pattern {
// CHECK:           %[[ALT_0:.*]] = mpir.alt  attributes {result_name = "r"} : <Instruction>
// CHECK:           %[[ALT_1:.*]] = mpir.alt  : <Instruction>
// CHECK:         }
