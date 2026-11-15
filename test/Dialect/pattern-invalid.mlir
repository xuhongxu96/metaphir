// RUN: %metaphir-opt --split-input-file --verify-diagnostics %s
// What the mpir and mpir_expr dialects reject: their verifiers, and the
// names their syntax spells enumerations with.

mpir.pattern {
  %x = mpir.var "x" : !mpir.sort<Value>
  // expected-error @+1 {{operand kinds need 2 operand values, but it has 1}}
  %a = mpir.inst <freeze>(%x) <flags = [], flag_modes = [], operand_kinds = [0]> : (!mpir.sort<Value>) -> !mpir.sort<Instruction>
}

// -----

mpir.pattern {
  %x = mpir.var "x" : !mpir.sort<Value>
  // expected-error @+1 {{has an invalid operand kind 42}}
  %a = mpir.inst <freeze>(%x) <flags = [], flag_modes = [], operand_kinds = [42]> : (!mpir.sort<Value>) -> !mpir.sort<Instruction>
}

// -----

mpir.pattern {
  %x = mpir.var "x" : !mpir.sort<Value>
  // expected-error @+1 {{has an invalid operand kind -1}}
  %a = mpir.inst <freeze>(%x) <flags = [], flag_modes = [], operand_kinds = [-1]> : (!mpir.sort<Value>) -> !mpir.sort<Instruction>
}

// -----

mpir.pattern {
  %x = mpir.var "x" : !mpir.sort<Value>
  // expected-error @+1 {{needs one mode per flag}}
  %a = mpir.inst <add>(%x, %x) <flags = [0], flag_modes = [], operand_kinds = [1, 1]> : (!mpir.sort<Value>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
}

// -----

mpir.pattern {
  %x = mpir.var "x" : !mpir.sort<Value>
  // expected-error @+1 {{has an invalid flag mode 7}}
  %a = mpir.inst <add>(%x, %x) <flags = [0], flag_modes = [7], operand_kinds = [1, 1]> : (!mpir.sort<Value>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
}

// -----

mpir.pattern {
  %x = mpir.var "x" : !mpir.sort<Value>
  // expected-error @+1 {{has an invalid flag mode -1}}
  %a = mpir.inst <add>(%x, %x) <flags = [0], flag_modes = [-1], operand_kinds = [1, 1]> : (!mpir.sort<Value>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
}

// -----

mpir.pattern {
  %x = mpir.var "x" : !mpir.sort<Value>
  // expected-error @+1 {{needs one capture per captured flag}}
  %a = mpir.inst <add>(%x, %x) <flags = [0], flag_modes = [2], operand_kinds = [1, 1]> : (!mpir.sort<Value>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
}

// -----

mpir.pattern {
  %x = mpir.var "x" : !mpir.sort<Value>
  // expected-error @+1 {{needs one metaflag list per operand}}
  %a = mpir.inst <add>(%x, %x) <flags = [], flag_modes = [], operand_kinds = [1, 1], operand_metaflags = [[]]> : (!mpir.sort<Value>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
}

// -----

mpir.pattern {
  %x = mpir.var "x" : !mpir.sort<Value>
  // expected-error @+1 {{flag 2 is not valid for 'add'}}
  %a = mpir.inst <add>(%x, %x) <flags = [2], flag_modes = [0], operand_kinds = [1, 1]> : (!mpir.sort<Value>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
}

// -----

mpir.pattern {
  %x = mpir.var "x" : !mpir.sort<Value>
  // expected-error @+1 {{flag 99 is not valid for 'add'}}
  %a = mpir.inst <add>(%x, %x) <flags = [99], flag_modes = [0], operand_kinds = [1, 1]> : (!mpir.sort<Value>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
}

// -----

mpir.pattern {
  %x = mpir.var "x" : !mpir.sort<Value>
  // expected-error @+1 {{flag -1 is not valid for 'add'}}
  %a = mpir.inst <add>(%x, %x) <flags = [-1], flag_modes = [0], operand_kinds = [1, 1]> : (!mpir.sort<Value>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
}

// -----

mpir.pattern {
  %x = mpir.var "x" : !mpir.sort<Value>
  // expected-error @+1 {{'sub' is not commutative}}
  %a = mpir.inst <sub>(%x, %x) <flags = [], flag_modes = [], operand_kinds = [1, 1], metaflags = [#mpir.metaflag<"s", [], loc(unknown)>, #mpir.metaflag<"c", [], loc(unknown)>]> : (!mpir.sort<Value>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
}

// -----

mpir.pattern {
  %x = mpir.var "x" : !mpir.sort<Value>
  // expected-error @+1 {{operand kinds need 2 operand values, but it has 1}}
  %a = mpir.use @m(%x) <flags = [], flag_modes = [], operand_kinds = [0]> : (!mpir.sort<Value>) -> !mpir.sort<Instruction>
}

// -----

mpir.pattern {
  %x = mpir.var "x" : !mpir.sort<Value>
  // expected-error @+1 {{uses unknown matcher 'nowhere'}}
  %a = mpir.use @nowhere(%x) <flags = [], flag_modes = [], operand_kinds = [1]> : (!mpir.sort<Value>) -> !mpir.sort<Instruction>
}

// -----

mpir.pattern {
  %x = mpir.var "x" : !mpir.sort<Value>
  // expected-error @+1 {{calls unknown constraint 'nowhere'}}
  %a = mpir_expr.apply @nowhere(%x) : (!mpir.sort<Value>) -> !mpir.sort<Boolean>
}

// -----

mpir.pattern {
  %x = mpir.var "x" : !mpir.sort<Value>
  // expected-error @+1 {{'isZero' takes 1 to 1 arguments}}
  %a = mpir_expr.call call "isZero"(%x, %x) : (!mpir.sort<Value>, !mpir.sort<Value>) -> !mpir.sort<Boolean>
}

// -----

mpir.pattern {
  %x = mpir.var "x" : !mpir.sort<Value>
  // expected-error @+1 {{has an unknown operator 9999}}
  %a = "mpir_expr.call"(%x) <{op = 9999 : i32, kind = 2 : i32, operandSegmentSizes = array<i32: 1, 0>}> : (!mpir.sort<Value>) -> !mpir.sort<Boolean>
}

// -----

mpir.pattern {
  %x = mpir.var "x" : !mpir.sort<Value>
  // expected-error @+1 {{unknown call operator 'isNothing'}}
  %a = mpir_expr.call call "isNothing"(%x) : (!mpir.sort<Value>) -> !mpir.sort<Boolean>
}

// -----

mpir.pattern {
  %x = mpir.var "x" : !mpir.sort<Value>
  // expected-error @+1 {{expected unary, binary or call}}
  %a = mpir_expr.call ternary "?"(%x) : (!mpir.sort<Value>) -> !mpir.sort<Boolean>
}

// -----

mpir.pattern {
  // expected-error @+1 {{unknown sort 'Bogus'}}
  %x = mpir.var "x" : !mpir.sort<Bogus>
}

// -----

mpir.pattern {
  %x = mpir.var "x" : !mpir.sort<Value>
  // expected-error @+1 {{unknown instruction matcher 'bogus'}}
  %a = mpir.inst <bogus>(%x) <flags = [], flag_modes = [], operand_kinds = [1]> : (!mpir.sort<Value>) -> !mpir.sort<Instruction>
}

// -----

mpir.pattern {
  // expected-error @+1 {{unknown keyword constant 'nothing'}}
  %k = mpir.keyword nothing : !mpir.sort<Value>
}

// -----

mpir.pattern {
  // expected-error @+1 {{unknown primitive type 'quad'}}
  %t = mpir.type.prim quad : !mpir.sort<Type>
}

// -----

mpir.pattern {
  // expected-error @+1 {{unknown aggregate kind 'list'}}
  %a = mpir.aggregate list() : () -> !mpir.sort<Value>
}

// -----

mpir.pattern {
  %t = mpir.type.int 8 : !mpir.sort<Type>
  // expected-error @+1 {{unknown sequence kind 'matrix'}}
  %s = mpir.type.seq matrix 4 x %t : (!mpir.sort<Type>) -> !mpir.sort<Type>
}

// -----

mpir.pattern {
  // expected-error @+1 {{expected valid keyword}}
  %k = mpir.keyword 5 : !mpir.sort<Value>
}

// -----

mpir.pattern {
  %x = mpir.var "x" : !mpir.sort<Value>
  // expected-error @+1 {{expected string}}
  %a = mpir_expr.call call isZero(%x) : (!mpir.sort<Value>) -> !mpir.sort<Boolean>
}

// -----

mpir.pattern {
  // expected-error @+1 {{expected '<'}}
  %x = mpir.var "x" : !mpir.sort
}

// -----

mpir.pattern {
  %x = mpir.var "x" : !mpir.sort<Value>
  // expected-error @+1 {{expected '>'}}
  %a = "mpir.inst"(%x) <{opcode = #mpir.opcode<add x>, flags = array<i32>, flag_modes = array<i32>, operand_kinds = array<i32: 1>, operandSegmentSizes = array<i32: 0, 0, 0, 1>}> : (!mpir.sort<Value>) -> !mpir.sort<Instruction>
}
