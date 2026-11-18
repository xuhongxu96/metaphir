// RUN: not %metaphir-opt --split-input-file --mpir-check-bindings %s 2>&1 | FileCheck %s
// mpir-check-bindings rejects a named meta variable that is bound only when
// an instruction with ':o' matches itself: a match in which it matches its
// operand would leave the variable without a value.

// A variable only the instruction binds.
// CHECK: error: meta variable '?y' is not bound when ':o' lets 'add' match its operand; name it '?_y' if it need not be bound
mpir.pattern {
  %0 = mpir.type.int 32 : <Type>
  %x = mpir.var "x" : <Operand>
  %y = mpir.var "y" : <Operand>
  %1 = mpir.alt {
    mpir.yield %x : <Operand>
  }, {
    %i_a = mpir.inst <add> (%0, %x, %0, %y) <result_name = "a", flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
    mpir.yield %i_a : <Instruction>
  } <or_self_of = "add", or_self_region = 0, result_name = "a"> : <Instruction>
  %2 = mpir.type.int 32 : <Type>
  %3 = mpir.int 3 : ui2 : <Value>
  %i_b = mpir.inst <mul> (%2, %1, %2, %3) <result_name = "b", flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
}

// -----

// A flag capture, of a use of a matcher.
// CHECK: error: meta variable '?wrap' is not bound when ':o' lets 'addish' match its operand; name it '?_wrap' if it need not be bound
mpir.pattern {
  %wrap = mpir.var "wrap" : <Boolean>
  %0 = mpir.type.int 32 : <Type>
  %x = mpir.var "x" : <Operand>
  %1 = mpir.int 1 : ui1 : <Value>
  %2 = mpir.alt {
    %i_a = mpir.inst <add> flags(%wrap) (%0, %x, %0, %1) <result_name = "a", flags = [nsw], flag_modes = [captured], operand_kinds = [typed_value, typed_value]> : (!mpir.sort<Boolean>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
    mpir.yield %i_a : <Instruction>
  }, {
    mpir.yield %x : <Operand>
  } <or_self_of = "addish", or_self_region = 1, result_name = "a"> : <Instruction>
  %3 = mpir.type.int 32 : <Type>
  %4 = mpir.int 3 : ui2 : <Value>
  %i_b = mpir.inst <mul> (%3, %2, %3, %4) <result_name = "b", flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
}

// -----

// A type variable.
// CHECK: error: meta variable '?wide' is not bound when ':o' lets 'zext' match its operand; name it '?_wide' if it need not be bound
mpir.pattern {
  %0 = mpir.type.int 8 : <Type>
  %x = mpir.var "x" : <Operand>
  %wide = mpir.var "wide" : <Type>
  %1 = mpir.alt {
    mpir.yield %x : <Operand>
  }, {
    %i_a = mpir.inst <zext> (%0, %x, %wide) <result_name = "a", flags = [], flag_modes = [], operand_kinds = [typed_value, type_only]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>) -> !mpir.sort<Instruction>
    mpir.yield %i_a : <Instruction>
  } <or_self_of = "zext", or_self_region = 0, result_name = "a"> : <Instruction>
  %2 = mpir.type.int 8 : <Type>
  %3 = mpir.int 3 : ui2 : <Value>
  %i_b = mpir.inst <mul> (%2, %1, %2, %3) <result_name = "b", flags = [], flag_modes = [], operand_kinds = [typed_value, typed_value]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
}
