// RUN: not %metaphir-opt --split-input-file --mpir-desugar-metaflags %s 2>&1 | FileCheck %s
// What mpir-desugar-metaflags rejects. The parser reports these itself for
// what it parses; the pass does for modules made otherwise, at the location
// of the metaflag (here, the name of its case).

mpir.pattern {
  %i8 = mpir.type.int 8 : !mpir.sort<Type>
  %i32 = mpir.type.int 32 : !mpir.sort<Type>
  %x = mpir.var "x" : !mpir.sort<Operand>
  // A type-only operand has no value.
  // CHECK: no-subject:1:1: error: metaflag ':zero' has no value to use as its subject
  %a = mpir.inst <zext>(%i8, %x, %i32) <flags = [], flag_modes = [], operand_kinds = [0, 2], operand_metaflags = [[], [#mpir.metaflag<"zero", [], loc("no-subject":1:1)>]]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>) -> !mpir.sort<Instruction>
}

// -----

mpir.pattern {
  %x = mpir.var "x" : !mpir.sort<Operand>
  // CHECK: unknown:1:1: error: unknown metaflag ':nope'
  %a = mpir.inst <freeze>(%x) <flags = [], flag_modes = [], operand_kinds = [1], operand_metaflags = [[#mpir.metaflag<"nope", [], loc("unknown":1:1)>]]> : (!mpir.sort<Operand>) -> !mpir.sort<Instruction>
}

// -----

mpir.pattern {
  %x = mpir.var "x" : !mpir.sort<Operand>
  // On the instruction.
  // CHECK: on-instruction:1:1: error: unknown metaflag ':nope'
  %a = mpir.inst <freeze>(%x) <flags = [], flag_modes = [], operand_kinds = [1], metaflags = [#mpir.metaflag<"nope", [], loc("on-instruction":1:1)>]> : (!mpir.sort<Operand>) -> !mpir.sort<Instruction>
}

// -----

mpir.pattern {
  %x = mpir.var "x" : !mpir.sort<Operand>
  // Inside ':not'.
  // CHECK: in-not:1:1: error: unknown metaflag ':nope'
  %a = mpir.inst <freeze>(%x) <flags = [], flag_modes = [], operand_kinds = [1], operand_metaflags = [[#mpir.metaflag<"not", [#mpir.metaflag<"nope", [], loc("in-not":1:1)>], loc("in-not":1:1)>]]> : (!mpir.sort<Operand>) -> !mpir.sort<Instruction>
}

// -----

mpir.pattern {
  %x = mpir.var "x" : !mpir.sort<Operand>
  // Inside ':or'.
  // CHECK: in-or:1:1: error: unknown metaflag ':nope'
  %a = mpir.inst <freeze>(%x) <flags = [], flag_modes = [], operand_kinds = [1], operand_metaflags = [[#mpir.metaflag<"or", [#mpir.metaflag<"nope", [], loc("in-or":1:1)>], loc("in-or":1:1)>]]> : (!mpir.sort<Operand>) -> !mpir.sort<Instruction>
}

// -----

mpir.metaflag_def @two <param_names = ["v", "n"], placement = 2> {
^bb0(%v: !mpir.sort<Unknown>, %n: !mpir.sort<Unknown>):
  %t = mpir_expr.bool true : !mpir.sort<Boolean>
  mpir.yield %t : !mpir.sort<Boolean>
}
mpir.pattern {
  %x = mpir.var "x" : !mpir.sort<Operand>
  // CHECK: count:1:1: error: metaflag ':two' expects 1 arguments, got 0
  %a = mpir.inst <freeze>(%x) <flags = [], flag_modes = [], operand_kinds = [1], operand_metaflags = [[#mpir.metaflag<"two", [], loc("count":1:1)>]]> : (!mpir.sort<Operand>) -> !mpir.sort<Instruction>
}

// -----

mpir.metaflag_def @two <param_names = ["v", "n"], placement = 2> {
^bb0(%v: !mpir.sort<Unknown>, %n: !mpir.sort<Unknown>):
  %t = mpir_expr.bool true : !mpir.sort<Boolean>
  mpir.yield %t : !mpir.sort<Boolean>
}
mpir.pattern {
  %x = mpir.var "x" : !mpir.sort<Operand>
  // CHECK: argument:1:1: error: metaflag ':two' expects integer arguments
  %a = mpir.inst <freeze>(%x) <flags = [], flag_modes = [], operand_kinds = [1], operand_metaflags = [[#mpir.metaflag<"two", [#mpir.metaflag<"two", [], loc("argument":1:1)>], loc("argument":1:1)>]]> : (!mpir.sort<Operand>) -> !mpir.sort<Instruction>
}

// -----

mpir.metaflag_def @zero <param_names = ["v"], placement = 2> {
^bb0(%v: !mpir.sort<Unknown>):
  // CHECK: error: '?v' is bound to 'poison', which a constraint cannot refer to
  %r = mpir_expr.read %v : (!mpir.sort<Unknown>) -> !mpir.sort<Unknown>
  %z = mpir_expr.call call "isZero"(%r) : (!mpir.sort<Unknown>) -> !mpir.sort<Boolean>
  mpir.yield %z : !mpir.sort<Boolean>
}
mpir.pattern {
  %p = mpir.keyword poison : !mpir.sort<Value>
  %a = mpir.inst <freeze>(%p) <flags = [], flag_modes = [], operand_kinds = [1], operand_metaflags = [[#mpir.metaflag<"zero", [], loc(unknown)>]]> : (!mpir.sort<Value>) -> !mpir.sort<Instruction>
}
