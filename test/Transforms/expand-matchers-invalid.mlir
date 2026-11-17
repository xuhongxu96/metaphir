// RUN: %metaphir-opt --split-input-file --verify-diagnostics --mpir-expand-matchers %s
// What mpir-expand-matchers rejects: a use that passes a type only a match
// decides where the matcher fixes the type.

mpir.matcher @pick <supported_flags = [], syntax = nary, arity = 2, param_names = ["", "c", "ty", "t"], param_is_type = [true, false, true, false]> {
  %i1 = mpir.type.int 1 : !mpir.sort<Type>
  %ty = mpir.var "ty" : !mpir.sort<Type>
  mpir.signature %i1, %ty : !mpir.sort<Type>, !mpir.sort<Type>
  mpir.branch <param_args = [-1, 0, 1, 2], fixed_flags = [], fixed_flag_values = []> {
  ^bb0(%c: !mpir.sort<Boolean>, %t: !mpir.sort<Type>, %v: !mpir.sort<Operand>):
    %bit = mpir.type.int 1 : !mpir.sort<Type>
    %r = mpir.inst <select>(%bit, %c, %t, %v, %t, %v) <result_name = "ret", flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value, typed_value]> : (!mpir.sort<Type>, !mpir.sort<Boolean>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
    mpir.yield %r : !mpir.sort<Instruction>
  }
}
mpir.pattern {
  %any = mpir.var "any" : !mpir.sort<Type>
  %i32 = mpir.type.int 32 : !mpir.sort<Type>
  %cond = mpir.var "cond" : !mpir.sort<Operand>
  %x = mpir.var "x" : !mpir.sort<Operand>
  // expected-error @+1 {{matcher 'pick' requires type 'i1' for a parameter, but this use passes '?any'}}
  %u = mpir.use @pick(%any, %cond, %i32, %x) <result_name = "r", flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
}
