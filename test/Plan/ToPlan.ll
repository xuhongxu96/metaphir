; CHECK-LABEL:   mpir.matcher @addLike <commutative, supported_flags = [0, 1], syntax = 1, arity = 2, param_names = ["ty", "x", "y"], param_is_type = [true, false, false]> {
; CHECK:           %[[VAR_0:.*]] = mpir.var "ty" : <Type>
; CHECK:           mpir.signature %[[VAR_0]] : !mpir.sort<Type>
; CHECK:           mpir.branch <param_args = [0, 1, 2], fixed_flags = [], fixed_flag_values = []> {
; CHECK:           ^bb0(%[[VAL_0:.*]]: !mpir.sort<Type>, %[[VAL_1:.*]]: !mpir.sort<Operand>, %[[VAL_2:.*]]: !mpir.sort<Operand>):
; CHECK:             %[[VAR_1:.*]] = mpir.var "nsw" : <Boolean>
; CHECK:             %[[VAR_2:.*]] = mpir.var "nuw" : <Boolean>
; CHECK:             %[[INST_0:.*]] = mpir.inst <add> flags(%[[VAR_1]], %[[VAR_2]]) (%[[VAL_0]], %[[VAL_1]], %[[VAL_0]], %[[VAL_2]]) <result_name = "ret", flags = [0, 1], flag_modes = [2, 2], operand_kinds = [0, 0]> : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
; CHECK:             mpir.yield %[[INST_0]] : <Instruction>
; CHECK:           }
; CHECK:           mpir.branch <param_args = [0, 1, 2], fixed_flags = [0, 1], fixed_flag_values = [true, true]> {
; CHECK:           ^bb0(%[[VAL_3:.*]]: !mpir.sort<Type>, %[[VAL_4:.*]]: !mpir.sort<Operand>, %[[VAL_5:.*]]: !mpir.sort<Operand>):
; CHECK:             %[[INST_1:.*]] = mpir.inst <or> (%[[VAL_3]], %[[VAL_4]], %[[VAL_3]], %[[VAL_5]]) <result_name = "ret", flags = [3], flag_modes = [0], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
; CHECK:             mpir.yield %[[INST_1]] : <Instruction>
; CHECK:           }
; CHECK:         }
; CHECK-LABEL:   mpir.matcher @shr <supported_flags = [2], syntax = 1, arity = 2, param_names = ["ty", "x", "y"], param_is_type = [true, false, false]> {
; CHECK:           %[[VAR_0:.*]] = mpir.var "ty" : <Type>
; CHECK:           mpir.signature %[[VAR_0]] : !mpir.sort<Type>
; CHECK:           mpir.branch <param_args = [0, 1, 2], fixed_flags = [], fixed_flag_values = []> {
; CHECK:           ^bb0(%[[VAL_0:.*]]: !mpir.sort<Type>, %[[VAL_1:.*]]: !mpir.sort<Operand>, %[[VAL_2:.*]]: !mpir.sort<Operand>):
; CHECK:             %[[VAR_1:.*]] = mpir.var "exact" : <Boolean>
; CHECK:             %[[INST_0:.*]] = mpir.inst <lshr> flags(%[[VAR_1]]) (%[[VAL_0]], %[[VAL_1]], %[[VAL_0]], %[[VAL_2]]) <result_name = "ret", flags = [2], flag_modes = [2], operand_kinds = [0, 0]> : (!mpir.sort<Boolean>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
; CHECK:             mpir.yield %[[INST_0]] : <Instruction>
; CHECK:           }
; CHECK:           mpir.branch <param_args = [0, 1, 2], fixed_flags = [], fixed_flag_values = []> {
; CHECK:           ^bb0(%[[VAL_3:.*]]: !mpir.sort<Type>, %[[VAL_4:.*]]: !mpir.sort<Operand>, %[[VAL_5:.*]]: !mpir.sort<Operand>):
; CHECK:             %[[VAR_2:.*]] = mpir.var "exact" : <Boolean>
; CHECK:             %[[INST_1:.*]] = mpir.inst <ashr> flags(%[[VAR_2]]) (%[[VAL_3]], %[[VAL_4]], %[[VAL_3]], %[[VAL_5]]) <result_name = "ret", flags = [2], flag_modes = [2], operand_kinds = [0, 0]> : (!mpir.sort<Boolean>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
; CHECK:             mpir.yield %[[INST_1]] : <Instruction>
; CHECK:           }
; CHECK:         }
; CHECK-LABEL:   mpir.matcher @bitwiseLogic <commutative, supported_flags = [], syntax = 1, arity = 2, param_names = ["ty", "x", "y"], param_is_type = [true, false, false]> {
; CHECK:           %[[VAR_0:.*]] = mpir.var "ty" : <Type>
; CHECK:           mpir.signature %[[VAR_0]] : !mpir.sort<Type>
; CHECK:           mpir.branch <param_args = [0, 1, 2], fixed_flags = [], fixed_flag_values = []> {
; CHECK:           ^bb0(%[[VAL_0:.*]]: !mpir.sort<Type>, %[[VAL_1:.*]]: !mpir.sort<Operand>, %[[VAL_2:.*]]: !mpir.sort<Operand>):
; CHECK:             %[[INST_0:.*]] = mpir.inst <and> (%[[VAL_0]], %[[VAL_1]], %[[VAL_0]], %[[VAL_2]]) <result_name = "ret", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
; CHECK:             mpir.yield %[[INST_0]] : <Instruction>
; CHECK:           }
; CHECK:           mpir.branch <param_args = [0, 1, 2], fixed_flags = [], fixed_flag_values = []> {
; CHECK:           ^bb0(%[[VAL_3:.*]]: !mpir.sort<Type>, %[[VAL_4:.*]]: !mpir.sort<Operand>, %[[VAL_5:.*]]: !mpir.sort<Operand>):
; CHECK:             %[[INST_1:.*]] = mpir.inst <or> (%[[VAL_3]], %[[VAL_4]], %[[VAL_3]], %[[VAL_5]]) <result_name = "ret", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
; CHECK:             mpir.yield %[[INST_1]] : <Instruction>
; CHECK:           }
; CHECK:           mpir.branch <param_args = [0, 1, 2], fixed_flags = [], fixed_flag_values = []> {
; CHECK:           ^bb0(%[[VAL_6:.*]]: !mpir.sort<Type>, %[[VAL_7:.*]]: !mpir.sort<Operand>, %[[VAL_8:.*]]: !mpir.sort<Operand>):
; CHECK:             %[[INST_2:.*]] = mpir.inst <xor> (%[[VAL_6]], %[[VAL_7]], %[[VAL_6]], %[[VAL_8]]) <result_name = "ret", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
; CHECK:             mpir.yield %[[INST_2]] : <Instruction>
; CHECK:           }
; CHECK:         }
; CHECK-LABEL:   mpir.matcher @zextOrSext <supported_flags = [], syntax = 2, arity = 1, param_names = ["ty1", "x", "ty2"], param_is_type = [true, false, true]> {
; CHECK:           %[[VAR_0:.*]] = mpir.var "ty1" : <Type>
; CHECK:           %[[VAR_1:.*]] = mpir.var "ty2" : <Type>
; CHECK:           mpir.signature %[[VAR_0]], %[[VAR_1]] : !mpir.sort<Type>, !mpir.sort<Type>
; CHECK:           mpir.branch <param_args = [0, 1, 2], fixed_flags = [], fixed_flag_values = []> {
; CHECK:           ^bb0(%[[VAL_0:.*]]: !mpir.sort<Type>, %[[VAL_1:.*]]: !mpir.sort<Operand>, %[[VAL_2:.*]]: !mpir.sort<Type>):
; CHECK:             %[[INST_0:.*]] = mpir.inst <zext> (%[[VAL_0]], %[[VAL_1]], %[[VAL_2]]) <result_name = "ret", flags = [], flag_modes = [], operand_kinds = [0, 2]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>) -> !mpir.sort<Instruction>
; CHECK:             mpir.yield %[[INST_0]] : <Instruction>
; CHECK:           }
; CHECK:           mpir.branch <param_args = [0, 1, 2], fixed_flags = [], fixed_flag_values = []> {
; CHECK:           ^bb0(%[[VAL_3:.*]]: !mpir.sort<Type>, %[[VAL_4:.*]]: !mpir.sort<Operand>, %[[VAL_5:.*]]: !mpir.sort<Type>):
; CHECK:             %[[INST_1:.*]] = mpir.inst <sext> (%[[VAL_3]], %[[VAL_4]], %[[VAL_5]]) <result_name = "ret", flags = [], flag_modes = [], operand_kinds = [0, 2]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>) -> !mpir.sort<Instruction>
; CHECK:             mpir.yield %[[INST_1]] : <Instruction>
; CHECK:           }
; CHECK:         }
; CHECK-LABEL:   mpir.constraint_def @isConstantInt <param_names = ["v"]> {
; CHECK:         ^bb0(%[[VAL_0:.*]]: !mpir.sort<Unknown>):
; CHECK:           %[[READ_0:.*]] = mpir_expr.read %[[VAL_0]] : (!mpir.sort<Unknown>) -> !mpir.sort<Unknown>
; CHECK:           %[[STR_0:.*]] = mpir_expr.str "ConstantInt" : <String>
; CHECK:           %[[CALL_0:.*]] = mpir_expr.call call "isa"(%[[READ_0]], %[[STR_0]]) : (!mpir.sort<Unknown>, !mpir.sort<String>) -> !mpir.sort<Boolean>
; CHECK:           mpir.yield %[[CALL_0]] : <Boolean>
; CHECK:         }
; CHECK-LABEL:   mpir.metaflag_def @constantInt <param_names = ["v"], placement = 2> {
; CHECK:         ^bb0(%[[VAL_0:.*]]: !mpir.sort<Unknown>):
; CHECK:           %[[READ_0:.*]] = mpir_expr.read %[[VAL_0]] : (!mpir.sort<Unknown>) -> !mpir.sort<Unknown>
; CHECK:           %[[APPLY_0:.*]] = mpir_expr.apply @isConstantInt(%[[READ_0]]) : (!mpir.sort<Unknown>) -> !mpir.sort<Boolean>
; CHECK:           mpir.yield %[[APPLY_0]] : <Boolean>
; CHECK:         }
; CHECK-LABEL:   mpir.metaflag_def @power2 <param_names = ["v"], placement = 2> {
; CHECK:         ^bb0(%[[VAL_0:.*]]: !mpir.sort<Unknown>):
; CHECK:           %[[READ_0:.*]] = mpir_expr.read %[[VAL_0]] : (!mpir.sort<Unknown>) -> !mpir.sort<Unknown>
; CHECK:           %[[CALL_0:.*]] = mpir_expr.call call "isPower2"(%[[READ_0]]) : (!mpir.sort<Unknown>) -> !mpir.sort<Boolean>
; CHECK:           mpir.yield %[[CALL_0]] : <Boolean>
; CHECK:         }
; CHECK-LABEL:   mpir.metaflag_def @zero <param_names = ["v"], placement = 2> {
; CHECK:         ^bb0(%[[VAL_0:.*]]: !mpir.sort<Unknown>):
; CHECK:           %[[READ_0:.*]] = mpir_expr.read %[[VAL_0]] : (!mpir.sort<Unknown>) -> !mpir.sort<Unknown>
; CHECK:           %[[CALL_0:.*]] = mpir_expr.call call "isZero"(%[[READ_0]]) : (!mpir.sort<Unknown>) -> !mpir.sort<Boolean>
; CHECK:           mpir.yield %[[CALL_0]] : <Boolean>
; CHECK:         }
; CHECK-LABEL:   mpir.metaflag_def @allOnes <param_names = ["v"], placement = 2> {
; CHECK:         ^bb0(%[[VAL_0:.*]]: !mpir.sort<Unknown>):
; CHECK:           %[[READ_0:.*]] = mpir_expr.read %[[VAL_0]] : (!mpir.sort<Unknown>) -> !mpir.sort<Unknown>
; CHECK:           %[[CALL_0:.*]] = mpir_expr.call call "isAllOnes"(%[[READ_0]]) : (!mpir.sort<Unknown>) -> !mpir.sort<Boolean>
; CHECK:           mpir.yield %[[CALL_0]] : <Boolean>
; CHECK:         }
; CHECK-LABEL:   mpir.metaflag_def @lowBitMask <param_names = ["v"], placement = 2> {
; CHECK:         ^bb0(%[[VAL_0:.*]]: !mpir.sort<Unknown>):
; CHECK:           %[[READ_0:.*]] = mpir_expr.read %[[VAL_0]] : (!mpir.sort<Unknown>) -> !mpir.sort<Unknown>
; CHECK:           %[[CALL_0:.*]] = mpir_expr.call call "isLowBitMask"(%[[READ_0]]) : (!mpir.sort<Unknown>) -> !mpir.sort<Boolean>
; CHECK:           mpir.yield %[[CALL_0]] : <Boolean>
; CHECK:         }
; CHECK-LABEL:   mpir.metaflag_def @poison <param_names = ["v"], placement = 2> {
; CHECK:         ^bb0(%[[VAL_0:.*]]: !mpir.sort<Unknown>):
; CHECK:           %[[READ_0:.*]] = mpir_expr.read %[[VAL_0]] : (!mpir.sort<Unknown>) -> !mpir.sort<Unknown>
; CHECK:           %[[CALL_0:.*]] = mpir_expr.call call "isPoison"(%[[READ_0]]) : (!mpir.sort<Unknown>) -> !mpir.sort<Boolean>
; CHECK:           mpir.yield %[[CALL_0]] : <Boolean>
; CHECK:         }
; CHECK-LABEL:   mpir.metaflag_def @forbidPoison <param_names = ["v"], placement = 2> {
; CHECK:         ^bb0(%[[VAL_0:.*]]: !mpir.sort<Unknown>):
; CHECK:           %[[READ_0:.*]] = mpir_expr.read %[[VAL_0]] : (!mpir.sort<Unknown>) -> !mpir.sort<Unknown>
; CHECK:           %[[CALL_0:.*]] = mpir_expr.call call "isForbidPoison"(%[[READ_0]]) : (!mpir.sort<Unknown>) -> !mpir.sort<Boolean>
; CHECK:           mpir.yield %[[CALL_0]] : <Boolean>
; CHECK:         }
; CHECK-LABEL:   mpir.metaflag_def @anyIntegralConstant <param_names = ["v"], placement = 2> {
; CHECK:         ^bb0(%[[VAL_0:.*]]: !mpir.sort<Unknown>):
; CHECK:           %[[READ_0:.*]] = mpir_expr.read %[[VAL_0]] : (!mpir.sort<Unknown>) -> !mpir.sort<Unknown>
; CHECK:           %[[CALL_0:.*]] = mpir_expr.call call "isAnyIntegralConstant"(%[[READ_0]]) : (!mpir.sort<Unknown>) -> !mpir.sort<Boolean>
; CHECK:           mpir.yield %[[CALL_0]] : <Boolean>
; CHECK:         }
; CHECK-LABEL:   mpir.constraint_def @isAPIntAllowPoison <param_names = ["v"]> {
; CHECK:         ^bb0(%[[VAL_0:.*]]: !mpir.sort<Unknown>):
; CHECK:           %[[READ_0:.*]] = mpir_expr.read %[[VAL_0]] : (!mpir.sort<Unknown>) -> !mpir.sort<Unknown>
; CHECK:           %[[APPLY_0:.*]] = mpir_expr.apply @isConstantInt(%[[READ_0]]) : (!mpir.sort<Unknown>) -> !mpir.sort<Boolean>
; CHECK:           %[[READ_1:.*]] = mpir_expr.read %[[VAL_0]] : (!mpir.sort<Unknown>) -> !mpir.sort<Unknown>
; CHECK:           %[[CALL_0:.*]] = mpir_expr.call call "isConstantSplat"(%[[READ_1]]) : (!mpir.sort<Unknown>) -> !mpir.sort<Boolean>
; CHECK:           %[[CALL_1:.*]] = mpir_expr.call binary "||"(%[[APPLY_0]], %[[CALL_0]]) : (!mpir.sort<Boolean>, !mpir.sort<Boolean>) -> !mpir.sort<Boolean>
; CHECK:           %[[READ_2:.*]] = mpir_expr.read %[[VAL_0]] : (!mpir.sort<Unknown>) -> !mpir.sort<Unknown>
; CHECK:           %[[CALL_2:.*]] = mpir_expr.call call "isAnyIntegralConstant"(%[[READ_2]]) : (!mpir.sort<Unknown>) -> !mpir.sort<Boolean>
; CHECK:           %[[CALL_3:.*]] = mpir_expr.call binary "&&"(%[[CALL_1]], %[[CALL_2]]) : (!mpir.sort<Boolean>, !mpir.sort<Boolean>) -> !mpir.sort<Boolean>
; CHECK:           mpir.yield %[[CALL_3]] : <Boolean>
; CHECK:         }
; CHECK-LABEL:   mpir.metaflag_def @apIntAllowPoison <param_names = ["v"], placement = 2> {
; CHECK:         ^bb0(%[[VAL_0:.*]]: !mpir.sort<Unknown>):
; CHECK:           %[[READ_0:.*]] = mpir_expr.read %[[VAL_0]] : (!mpir.sort<Unknown>) -> !mpir.sort<Unknown>
; CHECK:           %[[APPLY_0:.*]] = mpir_expr.apply @isAPIntAllowPoison(%[[READ_0]]) : (!mpir.sort<Unknown>) -> !mpir.sort<Boolean>
; CHECK:           mpir.yield %[[APPLY_0]] : <Boolean>
; CHECK:         }
; CHECK-LABEL:   mpir.constraint_def @isAPInt <param_names = ["v"]> {
; CHECK:         ^bb0(%[[VAL_0:.*]]: !mpir.sort<Unknown>):
; CHECK:           %[[READ_0:.*]] = mpir_expr.read %[[VAL_0]] : (!mpir.sort<Unknown>) -> !mpir.sort<Unknown>
; CHECK:           %[[APPLY_0:.*]] = mpir_expr.apply @isAPIntAllowPoison(%[[READ_0]]) : (!mpir.sort<Unknown>) -> !mpir.sort<Boolean>
; CHECK:           %[[READ_1:.*]] = mpir_expr.read %[[VAL_0]] : (!mpir.sort<Unknown>) -> !mpir.sort<Unknown>
; CHECK:           %[[CALL_0:.*]] = mpir_expr.call call "isForbidPoison"(%[[READ_1]]) : (!mpir.sort<Unknown>) -> !mpir.sort<Boolean>
; CHECK:           %[[CALL_1:.*]] = mpir_expr.call binary "&&"(%[[APPLY_0]], %[[CALL_0]]) : (!mpir.sort<Boolean>, !mpir.sort<Boolean>) -> !mpir.sort<Boolean>
; CHECK:           mpir.yield %[[CALL_1]] : <Boolean>
; CHECK:         }
; CHECK-LABEL:   mpir.metaflag_def @apInt <param_names = ["v"], placement = 2> {
; CHECK:         ^bb0(%[[VAL_0:.*]]: !mpir.sort<Unknown>):
; CHECK:           %[[READ_0:.*]] = mpir_expr.read %[[VAL_0]] : (!mpir.sort<Unknown>) -> !mpir.sort<Unknown>
; CHECK:           %[[APPLY_0:.*]] = mpir_expr.apply @isAPInt(%[[READ_0]]) : (!mpir.sort<Unknown>) -> !mpir.sort<Boolean>
; CHECK:           mpir.yield %[[APPLY_0]] : <Boolean>
; CHECK:         }
; CHECK-LABEL:   mpir.metaflag_def @anyZeroFP <param_names = ["v"], placement = 2> {
; CHECK:         ^bb0(%[[VAL_0:.*]]: !mpir.sort<Unknown>):
; CHECK:           %[[READ_0:.*]] = mpir_expr.read %[[VAL_0]] : (!mpir.sort<Unknown>) -> !mpir.sort<Unknown>
; CHECK:           %[[CALL_0:.*]] = mpir_expr.call call "isAnyZeroFP"(%[[READ_0]]) : (!mpir.sort<Unknown>) -> !mpir.sort<Boolean>
; CHECK:           mpir.yield %[[CALL_0]] : <Boolean>
; CHECK:         }
; CHECK-LABEL:   mpir.metaflag_def @scalar <param_names = ["v"], placement = 2> {
; CHECK:         ^bb0(%[[VAL_0:.*]]: !mpir.sort<Unknown>):
; CHECK:           %[[READ_0:.*]] = mpir_expr.read %[[VAL_0]] : (!mpir.sort<Unknown>) -> !mpir.sort<Unknown>
; CHECK:           %[[CALL_0:.*]] = mpir_expr.call call "isScalar"(%[[READ_0]]) : (!mpir.sort<Unknown>) -> !mpir.sort<Boolean>
; CHECK:           mpir.yield %[[CALL_0]] : <Boolean>
; CHECK:         }
; CHECK-LABEL:   mpir.metaflag_def @constantSplat <param_names = ["v"], placement = 2> {
; CHECK:         ^bb0(%[[VAL_0:.*]]: !mpir.sort<Unknown>):
; CHECK:           %[[READ_0:.*]] = mpir_expr.read %[[VAL_0]] : (!mpir.sort<Unknown>) -> !mpir.sort<Unknown>
; CHECK:           %[[CALL_0:.*]] = mpir_expr.call call "isConstantSplat"(%[[READ_0]]) : (!mpir.sort<Unknown>) -> !mpir.sort<Boolean>
; CHECK:           mpir.yield %[[CALL_0]] : <Boolean>
; CHECK:         }
; CHECK-LABEL:   mpir.metaflag_def @immConstant <param_names = ["v"], placement = 2> {
; CHECK:         ^bb0(%[[VAL_0:.*]]: !mpir.sort<Unknown>):
; CHECK:           %[[READ_0:.*]] = mpir_expr.read %[[VAL_0]] : (!mpir.sort<Unknown>) -> !mpir.sort<Unknown>
; CHECK:           %[[CALL_0:.*]] = mpir_expr.call call "isImmConstant"(%[[READ_0]]) : (!mpir.sort<Unknown>) -> !mpir.sort<Boolean>
; CHECK:           mpir.yield %[[CALL_0]] : <Boolean>
; CHECK:         }
; CHECK-LABEL:   mpir.metaflag_def @signMask <param_names = ["v"], placement = 2> {
; CHECK:         ^bb0(%[[VAL_0:.*]]: !mpir.sort<Unknown>):
; CHECK:           %[[READ_0:.*]] = mpir_expr.read %[[VAL_0]] : (!mpir.sort<Unknown>) -> !mpir.sort<Unknown>
; CHECK:           %[[CALL_0:.*]] = mpir_expr.call call "isSignMask"(%[[READ_0]]) : (!mpir.sort<Unknown>) -> !mpir.sort<Boolean>
; CHECK:           mpir.yield %[[CALL_0]] : <Boolean>
; CHECK:         }
; CHECK-LABEL:   mpir.metaflag_def @maxSignedValue <param_names = ["v"], placement = 2> {
; CHECK:         ^bb0(%[[VAL_0:.*]]: !mpir.sort<Unknown>):
; CHECK:           %[[READ_0:.*]] = mpir_expr.read %[[VAL_0]] : (!mpir.sort<Unknown>) -> !mpir.sort<Unknown>
; CHECK:           %[[CALL_0:.*]] = mpir_expr.call call "isMaxSignedValue"(%[[READ_0]]) : (!mpir.sort<Unknown>) -> !mpir.sort<Boolean>
; CHECK:           mpir.yield %[[CALL_0]] : <Boolean>
; CHECK:         }
; CHECK-LABEL:   mpir.metaflag_def @negatedPower2 <param_names = ["v"], placement = 2> {
; CHECK:         ^bb0(%[[VAL_0:.*]]: !mpir.sort<Unknown>):
; CHECK:           %[[READ_0:.*]] = mpir_expr.read %[[VAL_0]] : (!mpir.sort<Unknown>) -> !mpir.sort<Unknown>
; CHECK:           %[[CALL_0:.*]] = mpir_expr.call call "isNegatedPower2"(%[[READ_0]]) : (!mpir.sort<Unknown>) -> !mpir.sort<Boolean>
; CHECK:           mpir.yield %[[CALL_0]] : <Boolean>
; CHECK:         }
; CHECK-LABEL:   mpir.metaflag_def @negatedPower2OrZero <param_names = ["v"], placement = 2> {
; CHECK:         ^bb0(%[[VAL_0:.*]]: !mpir.sort<Unknown>):
; CHECK:           %[[READ_0:.*]] = mpir_expr.read %[[VAL_0]] : (!mpir.sort<Unknown>) -> !mpir.sort<Unknown>
; CHECK:           %[[CALL_0:.*]] = mpir_expr.call call "isNegatedPower2OrZero"(%[[READ_0]]) : (!mpir.sort<Unknown>) -> !mpir.sort<Boolean>
; CHECK:           mpir.yield %[[CALL_0]] : <Boolean>
; CHECK:         }
; CHECK-LABEL:   mpir.metaflag_def @power2OrZero <param_names = ["v"], placement = 2> {
; CHECK:         ^bb0(%[[VAL_0:.*]]: !mpir.sort<Unknown>):
; CHECK:           %[[READ_0:.*]] = mpir_expr.read %[[VAL_0]] : (!mpir.sort<Unknown>) -> !mpir.sort<Unknown>
; CHECK:           %[[CALL_0:.*]] = mpir_expr.call call "isPower2OrZero"(%[[READ_0]]) : (!mpir.sort<Unknown>) -> !mpir.sort<Boolean>
; CHECK:           mpir.yield %[[CALL_0]] : <Boolean>
; CHECK:         }
; CHECK-LABEL:   mpir.metaflag_def @lowBitMaskOrZero <param_names = ["v"], placement = 2> {
; CHECK:         ^bb0(%[[VAL_0:.*]]: !mpir.sort<Unknown>):
; CHECK:           %[[READ_0:.*]] = mpir_expr.read %[[VAL_0]] : (!mpir.sort<Unknown>) -> !mpir.sort<Unknown>
; CHECK:           %[[CALL_0:.*]] = mpir_expr.call call "isLowBitMaskOrZero"(%[[READ_0]]) : (!mpir.sort<Unknown>) -> !mpir.sort<Boolean>
; CHECK:           mpir.yield %[[CALL_0]] : <Boolean>
; CHECK:         }
; CHECK-LABEL:   mpir.metaflag_def @shiftedMask <param_names = ["v"], placement = 2> {
; CHECK:         ^bb0(%[[VAL_0:.*]]: !mpir.sort<Unknown>):
; CHECK:           %[[READ_0:.*]] = mpir_expr.read %[[VAL_0]] : (!mpir.sort<Unknown>) -> !mpir.sort<Unknown>
; CHECK:           %[[CALL_0:.*]] = mpir_expr.call call "isShiftedMask"(%[[READ_0]]) : (!mpir.sort<Unknown>) -> !mpir.sort<Boolean>
; CHECK:           mpir.yield %[[CALL_0]] : <Boolean>
; CHECK:         }
; CHECK-LABEL:   mpir.metaflag_def @negative <param_names = ["v"], placement = 2> {
; CHECK:         ^bb0(%[[VAL_0:.*]]: !mpir.sort<Unknown>):
; CHECK:           %[[READ_0:.*]] = mpir_expr.read %[[VAL_0]] : (!mpir.sort<Unknown>) -> !mpir.sort<Unknown>
; CHECK:           %[[CALL_0:.*]] = mpir_expr.call call "isNegative"(%[[READ_0]]) : (!mpir.sort<Unknown>) -> !mpir.sort<Boolean>
; CHECK:           mpir.yield %[[CALL_0]] : <Boolean>
; CHECK:         }
; CHECK-LABEL:   mpir.metaflag_def @nonNegative <param_names = ["v"], placement = 2> {
; CHECK:         ^bb0(%[[VAL_0:.*]]: !mpir.sort<Unknown>):
; CHECK:           %[[READ_0:.*]] = mpir_expr.read %[[VAL_0]] : (!mpir.sort<Unknown>) -> !mpir.sort<Unknown>
; CHECK:           %[[CALL_0:.*]] = mpir_expr.call call "isNonNegative"(%[[READ_0]]) : (!mpir.sort<Unknown>) -> !mpir.sort<Boolean>
; CHECK:           mpir.yield %[[CALL_0]] : <Boolean>
; CHECK:         }
; CHECK-LABEL:   mpir.metaflag_def @strictlyPositive <param_names = ["v"], placement = 2> {
; CHECK:         ^bb0(%[[VAL_0:.*]]: !mpir.sort<Unknown>):
; CHECK:           %[[READ_0:.*]] = mpir_expr.read %[[VAL_0]] : (!mpir.sort<Unknown>) -> !mpir.sort<Unknown>
; CHECK:           %[[CALL_0:.*]] = mpir_expr.call call "isStrictlyPositive"(%[[READ_0]]) : (!mpir.sort<Unknown>) -> !mpir.sort<Boolean>
; CHECK:           mpir.yield %[[CALL_0]] : <Boolean>
; CHECK:         }
; CHECK-LABEL:   mpir.metaflag_def @nonPositive <param_names = ["v"], placement = 2> {
; CHECK:         ^bb0(%[[VAL_0:.*]]: !mpir.sort<Unknown>):
; CHECK:           %[[READ_0:.*]] = mpir_expr.read %[[VAL_0]] : (!mpir.sort<Unknown>) -> !mpir.sort<Unknown>
; CHECK:           %[[CALL_0:.*]] = mpir_expr.call call "isNonPositive"(%[[READ_0]]) : (!mpir.sort<Unknown>) -> !mpir.sort<Boolean>
; CHECK:           mpir.yield %[[CALL_0]] : <Boolean>
; CHECK:         }
; CHECK-LABEL:   mpir.metaflag_def @nonZeroInt <param_names = ["v"], placement = 2> {
; CHECK:         ^bb0(%[[VAL_0:.*]]: !mpir.sort<Unknown>):
; CHECK:           %[[READ_0:.*]] = mpir_expr.read %[[VAL_0]] : (!mpir.sort<Unknown>) -> !mpir.sort<Unknown>
; CHECK:           %[[CALL_0:.*]] = mpir_expr.call call "isNonZeroInt"(%[[READ_0]]) : (!mpir.sort<Unknown>) -> !mpir.sort<Boolean>
; CHECK:           mpir.yield %[[CALL_0]] : <Boolean>
; CHECK:         }
; CHECK-LABEL:   mpir.metaflag_def @undef <param_names = ["v"], placement = 2> {
; CHECK:         ^bb0(%[[VAL_0:.*]]: !mpir.sort<Unknown>):
; CHECK:           %[[READ_0:.*]] = mpir_expr.read %[[VAL_0]] : (!mpir.sort<Unknown>) -> !mpir.sort<Unknown>
; CHECK:           %[[CALL_0:.*]] = mpir_expr.call call "isUndef"(%[[READ_0]]) : (!mpir.sort<Unknown>) -> !mpir.sort<Boolean>
; CHECK:           mpir.yield %[[CALL_0]] : <Boolean>
; CHECK:         }
; CHECK-LABEL:   mpir.metaflag_def @posZeroFP <param_names = ["v"], placement = 2> {
; CHECK:         ^bb0(%[[VAL_0:.*]]: !mpir.sort<Unknown>):
; CHECK:           %[[READ_0:.*]] = mpir_expr.read %[[VAL_0]] : (!mpir.sort<Unknown>) -> !mpir.sort<Unknown>
; CHECK:           %[[CALL_0:.*]] = mpir_expr.call call "isPosZeroFP"(%[[READ_0]]) : (!mpir.sort<Unknown>) -> !mpir.sort<Boolean>
; CHECK:           mpir.yield %[[CALL_0]] : <Boolean>
; CHECK:         }
; CHECK-LABEL:   mpir.metaflag_def @negZeroFP <param_names = ["v"], placement = 2> {
; CHECK:         ^bb0(%[[VAL_0:.*]]: !mpir.sort<Unknown>):
; CHECK:           %[[READ_0:.*]] = mpir_expr.read %[[VAL_0]] : (!mpir.sort<Unknown>) -> !mpir.sort<Unknown>
; CHECK:           %[[CALL_0:.*]] = mpir_expr.call call "isNegZeroFP"(%[[READ_0]]) : (!mpir.sort<Unknown>) -> !mpir.sort<Boolean>
; CHECK:           mpir.yield %[[CALL_0]] : <Boolean>
; CHECK:         }
; CHECK-LABEL:   mpir.metaflag_def @inf <param_names = ["v"], placement = 2> {
; CHECK:         ^bb0(%[[VAL_0:.*]]: !mpir.sort<Unknown>):
; CHECK:           %[[READ_0:.*]] = mpir_expr.read %[[VAL_0]] : (!mpir.sort<Unknown>) -> !mpir.sort<Unknown>
; CHECK:           %[[CALL_0:.*]] = mpir_expr.call call "isInf"(%[[READ_0]]) : (!mpir.sort<Unknown>) -> !mpir.sort<Boolean>
; CHECK:           mpir.yield %[[CALL_0]] : <Boolean>
; CHECK:         }
; CHECK-LABEL:   mpir.metaflag_def @nan <param_names = ["v"], placement = 2> {
; CHECK:         ^bb0(%[[VAL_0:.*]]: !mpir.sort<Unknown>):
; CHECK:           %[[READ_0:.*]] = mpir_expr.read %[[VAL_0]] : (!mpir.sort<Unknown>) -> !mpir.sort<Unknown>
; CHECK:           %[[CALL_0:.*]] = mpir_expr.call call "isNaN"(%[[READ_0]]) : (!mpir.sort<Unknown>) -> !mpir.sort<Boolean>
; CHECK:           mpir.yield %[[CALL_0]] : <Boolean>
; CHECK:         }
; CHECK-LABEL:   mpir.constraint_def @isZeroOrPoison <param_names = ["v"]> {
; CHECK:         ^bb0(%[[VAL_0:.*]]: !mpir.sort<Unknown>):
; CHECK:           %[[READ_0:.*]] = mpir_expr.read %[[VAL_0]] : (!mpir.sort<Unknown>) -> !mpir.sort<Unknown>
; CHECK:           %[[CALL_0:.*]] = mpir_expr.call call "isZero"(%[[READ_0]]) : (!mpir.sort<Unknown>) -> !mpir.sort<Boolean>
; CHECK:           %[[READ_1:.*]] = mpir_expr.read %[[VAL_0]] : (!mpir.sort<Unknown>) -> !mpir.sort<Unknown>
; CHECK:           %[[CALL_1:.*]] = mpir_expr.call call "isPoison"(%[[READ_1]]) : (!mpir.sort<Unknown>) -> !mpir.sort<Boolean>
; CHECK:           %[[CALL_2:.*]] = mpir_expr.call binary "||"(%[[CALL_0]], %[[CALL_1]]) : (!mpir.sort<Boolean>, !mpir.sort<Boolean>) -> !mpir.sort<Boolean>
; CHECK:           mpir.yield %[[CALL_2]] : <Boolean>
; CHECK:         }
; CHECK-LABEL:   mpir.metaflag_def @zeroOrPoison <param_names = ["v"], placement = 2> {
; CHECK:         ^bb0(%[[VAL_0:.*]]: !mpir.sort<Unknown>):
; CHECK:           %[[READ_0:.*]] = mpir_expr.read %[[VAL_0]] : (!mpir.sort<Unknown>) -> !mpir.sort<Unknown>
; CHECK:           %[[APPLY_0:.*]] = mpir_expr.apply @isZeroOrPoison(%[[READ_0]]) : (!mpir.sort<Unknown>) -> !mpir.sort<Boolean>
; CHECK:           mpir.yield %[[APPLY_0]] : <Boolean>
; CHECK:         }
; CHECK-LABEL:   mpir.constraint_def @isAllOnesOrPoison <param_names = ["v"]> {
; CHECK:         ^bb0(%[[VAL_0:.*]]: !mpir.sort<Unknown>):
; CHECK:           %[[READ_0:.*]] = mpir_expr.read %[[VAL_0]] : (!mpir.sort<Unknown>) -> !mpir.sort<Unknown>
; CHECK:           %[[CALL_0:.*]] = mpir_expr.call call "isAllOnes"(%[[READ_0]]) : (!mpir.sort<Unknown>) -> !mpir.sort<Boolean>
; CHECK:           %[[READ_1:.*]] = mpir_expr.read %[[VAL_0]] : (!mpir.sort<Unknown>) -> !mpir.sort<Unknown>
; CHECK:           %[[CALL_1:.*]] = mpir_expr.call call "isPoison"(%[[READ_1]]) : (!mpir.sort<Unknown>) -> !mpir.sort<Boolean>
; CHECK:           %[[CALL_2:.*]] = mpir_expr.call binary "||"(%[[CALL_0]], %[[CALL_1]]) : (!mpir.sort<Boolean>, !mpir.sort<Boolean>) -> !mpir.sort<Boolean>
; CHECK:           mpir.yield %[[CALL_2]] : <Boolean>
; CHECK:         }
; CHECK-LABEL:   mpir.metaflag_def @allOnesOrPoison <param_names = ["v"], placement = 2> {
; CHECK:         ^bb0(%[[VAL_0:.*]]: !mpir.sort<Unknown>):
; CHECK:           %[[READ_0:.*]] = mpir_expr.read %[[VAL_0]] : (!mpir.sort<Unknown>) -> !mpir.sort<Unknown>
; CHECK:           %[[APPLY_0:.*]] = mpir_expr.apply @isAllOnesOrPoison(%[[READ_0]]) : (!mpir.sort<Unknown>) -> !mpir.sort<Boolean>
; CHECK:           mpir.yield %[[APPLY_0]] : <Boolean>
; CHECK:         }
; CHECK-LABEL:   mpir.matcher @neg <supported_flags = [0], syntax = 0, arity = 1, param_names = ["ty", "x"], param_is_type = [true, false]> {
; CHECK:           %[[VAR_0:.*]] = mpir.var "ty" : <Type>
; CHECK:           mpir.signature %[[VAR_0]] : !mpir.sort<Type>
; CHECK:           mpir.branch <param_args = [0, 1], fixed_flags = [], fixed_flag_values = []> {
; CHECK:           ^bb0(%[[VAL_0:.*]]: !mpir.sort<Type>, %[[VAL_1:.*]]: !mpir.sort<Operand>):
; CHECK:             %[[VAR_1:.*]] = mpir.var "nsw" : <Boolean>
; CHECK:             %[[VAR_2:.*]] = mpir.var "_zero" : <Operand>
; CHECK:             %[[INST_0:.*]] = mpir.inst <sub> flags(%[[VAR_1]]) (%[[VAL_0]], %[[VAR_2]], %[[VAL_0]], %[[VAL_1]]) <result_name = "ret", flags = [0], flag_modes = [2], operand_kinds = [0, 0]> : (!mpir.sort<Boolean>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
; CHECK:             %[[READ_0:.*]] = mpir_expr.read %[[VAR_2]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
; CHECK:             %[[CALL_0:.*]] = mpir_expr.call call "isZero"(%[[READ_0]]) anchor %[[INST_0]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
; CHECK:             mpir.require %[[CALL_0]] {from_metaflag} : <Boolean>
; CHECK:             mpir.yield %[[INST_0]] : <Instruction>
; CHECK:           }
; CHECK:         }
; CHECK-LABEL:   mpir.matcher @signum <supported_flags = [], syntax = 0, arity = 1, param_names = ["bits", "x"], param_is_type = [true, false]> {
; CHECK:           %[[VAR_0:.*]] = mpir.var "bits" : <Nat>
; CHECK:           %[[TYPE_0:.*]] = mpir.type.meta_int %[[VAR_0]] : (!mpir.sort<Nat>) -> !mpir.sort<Type>
; CHECK:           mpir.signature %[[TYPE_0]] : !mpir.sort<Type>
; CHECK:           mpir.branch <param_args = [0, 1], fixed_flags = [], fixed_flag_values = []> {
; CHECK:           ^bb0(%[[VAL_0:.*]]: !mpir.sort<Nat>, %[[VAL_1:.*]]: !mpir.sort<Operand>):
; CHECK:             %[[TYPE_1:.*]] = mpir.type.meta_int %[[VAL_0]] : (!mpir.sort<Nat>) -> !mpir.sort<Type>
; CHECK:             %[[USE_0:.*]] = mpir.use @neg (%[[TYPE_1]], %[[VAL_1]]) <result_name = "neg", flags = [], flag_modes = [], operand_kinds = [0], treat_int_as_vec = true> : (!mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
; CHECK:             %[[TYPE_2:.*]] = mpir.type.meta_int %[[VAL_0]] : (!mpir.sort<Nat>) -> !mpir.sort<Type>
; CHECK:             %[[VAR_1:.*]] = mpir.var "_ls" : <Operand>
; CHECK:             %[[INST_0:.*]] = mpir.inst <ashr> (%[[TYPE_2]], %[[VAL_1]], %[[TYPE_2]], %[[VAR_1]]) <result_name = "lhs", flags = [], flag_modes = [], operand_kinds = [0, 0], treat_int_as_vec = true> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
; CHECK:             %[[TYPE_3:.*]] = mpir.type.meta_int %[[VAL_0]] : (!mpir.sort<Nat>) -> !mpir.sort<Type>
; CHECK:             %[[VAR_2:.*]] = mpir.var "_rs" : <Operand>
; CHECK:             %[[INST_1:.*]] = mpir.inst <lshr> (%[[TYPE_3]], %[[USE_0]], %[[TYPE_3]], %[[VAR_2]]) <result_name = "rhs", flags = [], flag_modes = [], operand_kinds = [0, 0], treat_int_as_vec = true> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
; CHECK:             %[[TYPE_4:.*]] = mpir.type.meta_int %[[VAL_0]] : (!mpir.sort<Nat>) -> !mpir.sort<Type>
; CHECK:             %[[INST_2:.*]] = mpir.inst <or> (%[[TYPE_4]], %[[INST_0]], %[[TYPE_4]], %[[INST_1]]) <result_name = "ret", flags = [], flag_modes = [], operand_kinds = [0, 0], metaflags = [#mpir.metaflag<"c", [], {{.*}}>], treat_int_as_vec = true> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Instruction>) -> !mpir.sort<Instruction>
; CHECK:             %[[READ_0:.*]] = mpir_expr.read %[[VAR_1]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
; CHECK:             %[[READ_1:.*]] = mpir_expr.read %[[VAL_0]] : (!mpir.sort<Nat>) -> !mpir.sort<Integer>
; CHECK:             %[[INT_0:.*]] = mpir_expr.int 1 : ui64 : <Integer>
; CHECK:             %[[CALL_0:.*]] = mpir_expr.call binary "-"(%[[READ_1]], %[[INT_0]]) anchor %[[INST_2]] : (!mpir.sort<Integer>, !mpir.sort<Integer>, !mpir.sort<Instruction>) -> !mpir.sort<Integer>
; CHECK:             %[[CALL_1:.*]] = mpir_expr.call binary "=="(%[[READ_0]], %[[CALL_0]]) anchor %[[INST_2]] : (!mpir.sort<Value>, !mpir.sort<Integer>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
; CHECK:             %[[READ_2:.*]] = mpir_expr.read %[[VAR_2]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
; CHECK:             %[[READ_3:.*]] = mpir_expr.read %[[VAL_0]] : (!mpir.sort<Nat>) -> !mpir.sort<Integer>
; CHECK:             %[[INT_1:.*]] = mpir_expr.int 1 : ui64 : <Integer>
; CHECK:             %[[CALL_2:.*]] = mpir_expr.call binary "-"(%[[READ_3]], %[[INT_1]]) anchor %[[INST_2]] : (!mpir.sort<Integer>, !mpir.sort<Integer>, !mpir.sort<Instruction>) -> !mpir.sort<Integer>
; CHECK:             %[[CALL_3:.*]] = mpir_expr.call binary "=="(%[[READ_2]], %[[CALL_2]]) anchor %[[INST_2]] : (!mpir.sort<Value>, !mpir.sort<Integer>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
; CHECK:             %[[CALL_4:.*]] = mpir_expr.call binary "&&"(%[[CALL_1]], %[[CALL_3]]) anchor %[[INST_2]] : (!mpir.sort<Boolean>, !mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
; CHECK:             %[[READ_4:.*]] = mpir_expr.read %[[VAR_1]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
; CHECK:             %[[APPLY_0:.*]] = mpir_expr.apply @isAPInt(%[[READ_4]]) : (!mpir.sort<Value>) -> !mpir.sort<Boolean>
; CHECK:             mpir.require %[[APPLY_0]] {from_metaflag} : <Boolean>
; CHECK:             %[[READ_5:.*]] = mpir_expr.read %[[VAR_2]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
; CHECK:             %[[APPLY_1:.*]] = mpir_expr.apply @isAPInt(%[[READ_5]]) : (!mpir.sort<Value>) -> !mpir.sort<Boolean>
; CHECK:             mpir.require %[[APPLY_1]] {from_metaflag} : <Boolean>
; CHECK:             mpir.require %[[CALL_4]] : <Boolean>
; CHECK:             mpir.yield %[[INST_2]] : <Instruction>
; CHECK:           }
; CHECK:         }
; CHECK-LABEL:   mpir.matcher @logicalAnd <commutative, supported_flags = [], syntax = 1, arity = 2, param_names = ["ty", "x", "y"], param_is_type = [true, false, false]> {
; CHECK:           %[[VAR_0:.*]] = mpir.var "ty" : <Type>
; CHECK:           mpir.signature %[[VAR_0]] : !mpir.sort<Type>
; CHECK:           mpir.branch <param_args = [0, 1, 2], fixed_flags = [], fixed_flag_values = []> {
; CHECK:           ^bb0(%[[VAL_0:.*]]: !mpir.sort<Type>, %[[VAL_1:.*]]: !mpir.sort<Operand>, %[[VAL_2:.*]]: !mpir.sort<Operand>):
; CHECK:             %[[INST_0:.*]] = mpir.inst <and> (%[[VAL_0]], %[[VAL_1]], %[[VAL_0]], %[[VAL_2]]) <result_name = "ret", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
; CHECK:             mpir.yield %[[INST_0]] : <Instruction>
; CHECK:           }
; CHECK:           mpir.branch <param_args = [0, 1, 2], fixed_flags = [], fixed_flag_values = []> {
; CHECK:           ^bb0(%[[VAL_3:.*]]: !mpir.sort<Type>, %[[VAL_4:.*]]: !mpir.sort<Operand>, %[[VAL_5:.*]]: !mpir.sort<Operand>):
; CHECK:             %[[VAR_1:.*]] = mpir.var "_false" : <Operand>
; CHECK:             %[[INST_1:.*]] = mpir.inst <select> (%[[VAL_3]], %[[VAL_4]], %[[VAL_3]], %[[VAL_5]], %[[VAL_3]], %[[VAR_1]]) <result_name = "ret", flags = [], flag_modes = [], operand_kinds = [0, 0, 0]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
; CHECK:             %[[READ_0:.*]] = mpir_expr.read %[[VAR_1]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
; CHECK:             %[[CALL_0:.*]] = mpir_expr.call call "isZero"(%[[READ_0]]) anchor %[[INST_1]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
; CHECK:             mpir.require %[[CALL_0]] {from_metaflag} : <Boolean>
; CHECK:             mpir.yield %[[INST_1]] : <Instruction>
; CHECK:           }
; CHECK:         }
; CHECK-LABEL:   mpir.matcher @logicalOr <commutative, supported_flags = [], syntax = 1, arity = 2, param_names = ["ty", "x", "y"], param_is_type = [true, false, false]> {
; CHECK:           %[[VAR_0:.*]] = mpir.var "ty" : <Type>
; CHECK:           mpir.signature %[[VAR_0]] : !mpir.sort<Type>
; CHECK:           mpir.branch <param_args = [0, 1, 2], fixed_flags = [], fixed_flag_values = []> {
; CHECK:           ^bb0(%[[VAL_0:.*]]: !mpir.sort<Type>, %[[VAL_1:.*]]: !mpir.sort<Operand>, %[[VAL_2:.*]]: !mpir.sort<Operand>):
; CHECK:             %[[INST_0:.*]] = mpir.inst <or> (%[[VAL_0]], %[[VAL_1]], %[[VAL_0]], %[[VAL_2]]) <result_name = "ret", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
; CHECK:             mpir.yield %[[INST_0]] : <Instruction>
; CHECK:           }
; CHECK:           mpir.branch <param_args = [0, 1, 2], fixed_flags = [], fixed_flag_values = []> {
; CHECK:           ^bb0(%[[VAL_3:.*]]: !mpir.sort<Type>, %[[VAL_4:.*]]: !mpir.sort<Operand>, %[[VAL_5:.*]]: !mpir.sort<Operand>):
; CHECK:             %[[VAR_1:.*]] = mpir.var "_true" : <Operand>
; CHECK:             %[[INST_1:.*]] = mpir.inst <select> (%[[VAL_3]], %[[VAL_4]], %[[VAL_3]], %[[VAR_1]], %[[VAL_3]], %[[VAL_5]]) <result_name = "ret", flags = [], flag_modes = [], operand_kinds = [0, 0, 0]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
; CHECK:             %[[READ_0:.*]] = mpir_expr.read %[[VAR_1]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
; CHECK:             %[[CALL_0:.*]] = mpir_expr.call call "isAllOnes"(%[[READ_0]]) anchor %[[INST_1]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
; CHECK:             mpir.require %[[CALL_0]] {from_metaflag} : <Boolean>
; CHECK:             mpir.yield %[[INST_1]] : <Instruction>
; CHECK:           }
; CHECK:         }
; CHECK-LABEL:   mpir.matcher @logicalOp <commutative, supported_flags = [], syntax = 1, arity = 2, param_names = ["ty", "x", "y"], param_is_type = [true, false, false]> {
; CHECK:           %[[VAR_0:.*]] = mpir.var "ty" : <Type>
; CHECK:           mpir.signature %[[VAR_0]] : !mpir.sort<Type>
; CHECK:           mpir.branch <param_args = [0, 1, 2], fixed_flags = [], fixed_flag_values = []> {
; CHECK:           ^bb0(%[[VAL_0:.*]]: !mpir.sort<Type>, %[[VAL_1:.*]]: !mpir.sort<Operand>, %[[VAL_2:.*]]: !mpir.sort<Operand>):
; CHECK:             %[[INST_0:.*]] = mpir.inst <and> (%[[VAL_0]], %[[VAL_1]], %[[VAL_0]], %[[VAL_2]]) <result_name = "ret", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
; CHECK:             mpir.yield %[[INST_0]] : <Instruction>
; CHECK:           }
; CHECK:           mpir.branch <param_args = [0, 1, 2], fixed_flags = [], fixed_flag_values = []> {
; CHECK:           ^bb0(%[[VAL_3:.*]]: !mpir.sort<Type>, %[[VAL_4:.*]]: !mpir.sort<Operand>, %[[VAL_5:.*]]: !mpir.sort<Operand>):
; CHECK:             %[[VAR_1:.*]] = mpir.var "_false" : <Operand>
; CHECK:             %[[INST_1:.*]] = mpir.inst <select> (%[[VAL_3]], %[[VAL_4]], %[[VAL_3]], %[[VAL_5]], %[[VAL_3]], %[[VAR_1]]) <result_name = "ret", flags = [], flag_modes = [], operand_kinds = [0, 0, 0]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
; CHECK:             %[[READ_0:.*]] = mpir_expr.read %[[VAR_1]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
; CHECK:             %[[CALL_0:.*]] = mpir_expr.call call "isZero"(%[[READ_0]]) anchor %[[INST_1]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
; CHECK:             mpir.require %[[CALL_0]] {from_metaflag} : <Boolean>
; CHECK:             mpir.yield %[[INST_1]] : <Instruction>
; CHECK:           }
; CHECK:           mpir.branch <param_args = [0, 1, 2], fixed_flags = [], fixed_flag_values = []> {
; CHECK:           ^bb0(%[[VAL_6:.*]]: !mpir.sort<Type>, %[[VAL_7:.*]]: !mpir.sort<Operand>, %[[VAL_8:.*]]: !mpir.sort<Operand>):
; CHECK:             %[[INST_2:.*]] = mpir.inst <or> (%[[VAL_6]], %[[VAL_7]], %[[VAL_6]], %[[VAL_8]]) <result_name = "ret", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
; CHECK:             mpir.yield %[[INST_2]] : <Instruction>
; CHECK:           }
; CHECK:           mpir.branch <param_args = [0, 1, 2], fixed_flags = [], fixed_flag_values = []> {
; CHECK:           ^bb0(%[[VAL_9:.*]]: !mpir.sort<Type>, %[[VAL_10:.*]]: !mpir.sort<Operand>, %[[VAL_11:.*]]: !mpir.sort<Operand>):
; CHECK:             %[[VAR_2:.*]] = mpir.var "_true" : <Operand>
; CHECK:             %[[INST_3:.*]] = mpir.inst <select> (%[[VAL_9]], %[[VAL_10]], %[[VAL_9]], %[[VAR_2]], %[[VAL_9]], %[[VAL_11]]) <result_name = "ret", flags = [], flag_modes = [], operand_kinds = [0, 0, 0]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
; CHECK:             %[[READ_1:.*]] = mpir_expr.read %[[VAR_2]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
; CHECK:             %[[CALL_1:.*]] = mpir_expr.call call "isAllOnes"(%[[READ_1]]) anchor %[[INST_3]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
; CHECK:             mpir.require %[[CALL_1]] {from_metaflag} : <Boolean>
; CHECK:             mpir.yield %[[INST_3]] : <Instruction>
; CHECK:           }
; CHECK:         }
; CHECK-LABEL:   mpir.matcher @shift <supported_flags = [2], syntax = 1, arity = 2, param_names = ["ty", "x", "y"], param_is_type = [true, false, false]> {
; CHECK:           %[[VAR_0:.*]] = mpir.var "ty" : <Type>
; CHECK:           mpir.signature %[[VAR_0]] : !mpir.sort<Type>
; CHECK:           mpir.branch <param_args = [0, 1, 2], fixed_flags = [], fixed_flag_values = []> {
; CHECK:           ^bb0(%[[VAL_0:.*]]: !mpir.sort<Type>, %[[VAL_1:.*]]: !mpir.sort<Operand>, %[[VAL_2:.*]]: !mpir.sort<Operand>):
; CHECK:             %[[VAR_1:.*]] = mpir.var "exact" : <Boolean>
; CHECK:             %[[INST_0:.*]] = mpir.inst <lshr> flags(%[[VAR_1]]) (%[[VAL_0]], %[[VAL_1]], %[[VAL_0]], %[[VAL_2]]) <result_name = "ret", flags = [2], flag_modes = [2], operand_kinds = [0, 0]> : (!mpir.sort<Boolean>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
; CHECK:             mpir.yield %[[INST_0]] : <Instruction>
; CHECK:           }
; CHECK:           mpir.branch <param_args = [0, 1, 2], fixed_flags = [], fixed_flag_values = []> {
; CHECK:           ^bb0(%[[VAL_3:.*]]: !mpir.sort<Type>, %[[VAL_4:.*]]: !mpir.sort<Operand>, %[[VAL_5:.*]]: !mpir.sort<Operand>):
; CHECK:             %[[VAR_2:.*]] = mpir.var "exact" : <Boolean>
; CHECK:             %[[INST_1:.*]] = mpir.inst <ashr> flags(%[[VAR_2]]) (%[[VAL_3]], %[[VAL_4]], %[[VAL_3]], %[[VAL_5]]) <result_name = "ret", flags = [2], flag_modes = [2], operand_kinds = [0, 0]> : (!mpir.sort<Boolean>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
; CHECK:             mpir.yield %[[INST_1]] : <Instruction>
; CHECK:           }
; CHECK:           mpir.branch <param_args = [0, 1, 2], fixed_flags = [2], fixed_flag_values = [false]> {
; CHECK:           ^bb0(%[[VAL_6:.*]]: !mpir.sort<Type>, %[[VAL_7:.*]]: !mpir.sort<Operand>, %[[VAL_8:.*]]: !mpir.sort<Operand>):
; CHECK:             %[[INST_2:.*]] = mpir.inst <shl> (%[[VAL_6]], %[[VAL_7]], %[[VAL_6]], %[[VAL_8]]) <result_name = "ret", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
; CHECK:             mpir.yield %[[INST_2]] : <Instruction>
; CHECK:           }
; CHECK:         }
; CHECK-LABEL:   mpir.matcher @logicalShift <supported_flags = [2], syntax = 1, arity = 2, param_names = ["ty", "x", "y"], param_is_type = [true, false, false]> {
; CHECK:           %[[VAR_0:.*]] = mpir.var "ty" : <Type>
; CHECK:           mpir.signature %[[VAR_0]] : !mpir.sort<Type>
; CHECK:           mpir.branch <param_args = [0, 1, 2], fixed_flags = [], fixed_flag_values = []> {
; CHECK:           ^bb0(%[[VAL_0:.*]]: !mpir.sort<Type>, %[[VAL_1:.*]]: !mpir.sort<Operand>, %[[VAL_2:.*]]: !mpir.sort<Operand>):
; CHECK:             %[[VAR_1:.*]] = mpir.var "exact" : <Boolean>
; CHECK:             %[[INST_0:.*]] = mpir.inst <lshr> flags(%[[VAR_1]]) (%[[VAL_0]], %[[VAL_1]], %[[VAL_0]], %[[VAL_2]]) <result_name = "ret", flags = [2], flag_modes = [2], operand_kinds = [0, 0]> : (!mpir.sort<Boolean>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
; CHECK:             mpir.yield %[[INST_0]] : <Instruction>
; CHECK:           }
; CHECK:           mpir.branch <param_args = [0, 1, 2], fixed_flags = [2], fixed_flag_values = [false]> {
; CHECK:           ^bb0(%[[VAL_3:.*]]: !mpir.sort<Type>, %[[VAL_4:.*]]: !mpir.sort<Operand>, %[[VAL_5:.*]]: !mpir.sort<Operand>):
; CHECK:             %[[INST_1:.*]] = mpir.inst <shl> (%[[VAL_3]], %[[VAL_4]], %[[VAL_3]], %[[VAL_5]]) <result_name = "ret", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
; CHECK:             mpir.yield %[[INST_1]] : <Instruction>
; CHECK:           }
; CHECK:         }
; CHECK-LABEL:   mpir.matcher @idiv <supported_flags = [2], syntax = 1, arity = 2, param_names = ["ty", "x", "y"], param_is_type = [true, false, false]> {
; CHECK:           %[[VAR_0:.*]] = mpir.var "ty" : <Type>
; CHECK:           mpir.signature %[[VAR_0]] : !mpir.sort<Type>
; CHECK:           mpir.branch <param_args = [0, 1, 2], fixed_flags = [], fixed_flag_values = []> {
; CHECK:           ^bb0(%[[VAL_0:.*]]: !mpir.sort<Type>, %[[VAL_1:.*]]: !mpir.sort<Operand>, %[[VAL_2:.*]]: !mpir.sort<Operand>):
; CHECK:             %[[VAR_1:.*]] = mpir.var "exact" : <Boolean>
; CHECK:             %[[INST_0:.*]] = mpir.inst <udiv> flags(%[[VAR_1]]) (%[[VAL_0]], %[[VAL_1]], %[[VAL_0]], %[[VAL_2]]) <result_name = "ret", flags = [2], flag_modes = [2], operand_kinds = [0, 0]> : (!mpir.sort<Boolean>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
; CHECK:             mpir.yield %[[INST_0]] : <Instruction>
; CHECK:           }
; CHECK:           mpir.branch <param_args = [0, 1, 2], fixed_flags = [], fixed_flag_values = []> {
; CHECK:           ^bb0(%[[VAL_3:.*]]: !mpir.sort<Type>, %[[VAL_4:.*]]: !mpir.sort<Operand>, %[[VAL_5:.*]]: !mpir.sort<Operand>):
; CHECK:             %[[VAR_2:.*]] = mpir.var "exact" : <Boolean>
; CHECK:             %[[INST_1:.*]] = mpir.inst <sdiv> flags(%[[VAR_2]]) (%[[VAL_3]], %[[VAL_4]], %[[VAL_3]], %[[VAL_5]]) <result_name = "ret", flags = [2], flag_modes = [2], operand_kinds = [0, 0]> : (!mpir.sort<Boolean>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
; CHECK:             mpir.yield %[[INST_1]] : <Instruction>
; CHECK:           }
; CHECK:         }
; CHECK-LABEL:   mpir.matcher @irem <supported_flags = [], syntax = 1, arity = 2, param_names = ["ty", "x", "y"], param_is_type = [true, false, false]> {
; CHECK:           %[[VAR_0:.*]] = mpir.var "ty" : <Type>
; CHECK:           mpir.signature %[[VAR_0]] : !mpir.sort<Type>
; CHECK:           mpir.branch <param_args = [0, 1, 2], fixed_flags = [], fixed_flag_values = []> {
; CHECK:           ^bb0(%[[VAL_0:.*]]: !mpir.sort<Type>, %[[VAL_1:.*]]: !mpir.sort<Operand>, %[[VAL_2:.*]]: !mpir.sort<Operand>):
; CHECK:             %[[INST_0:.*]] = mpir.inst <urem> (%[[VAL_0]], %[[VAL_1]], %[[VAL_0]], %[[VAL_2]]) <result_name = "ret", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
; CHECK:             mpir.yield %[[INST_0]] : <Instruction>
; CHECK:           }
; CHECK:           mpir.branch <param_args = [0, 1, 2], fixed_flags = [], fixed_flag_values = []> {
; CHECK:           ^bb0(%[[VAL_3:.*]]: !mpir.sort<Type>, %[[VAL_4:.*]]: !mpir.sort<Operand>, %[[VAL_5:.*]]: !mpir.sort<Operand>):
; CHECK:             %[[INST_1:.*]] = mpir.inst <srem> (%[[VAL_3]], %[[VAL_4]], %[[VAL_3]], %[[VAL_5]]) <result_name = "ret", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
; CHECK:             mpir.yield %[[INST_1]] : <Instruction>
; CHECK:           }
; CHECK:         }
; CHECK-LABEL:   mpir.matcher @sextLike <supported_flags = [], syntax = 2, arity = 1, param_names = ["ty1", "x", "ty2"], param_is_type = [true, false, true]> {
; CHECK:           %[[VAR_0:.*]] = mpir.var "ty1" : <Type>
; CHECK:           %[[VAR_1:.*]] = mpir.var "ty2" : <Type>
; CHECK:           mpir.signature %[[VAR_0]], %[[VAR_1]] : !mpir.sort<Type>, !mpir.sort<Type>
; CHECK:           mpir.branch <param_args = [0, 1, 2], fixed_flags = [], fixed_flag_values = []> {
; CHECK:           ^bb0(%[[VAL_0:.*]]: !mpir.sort<Type>, %[[VAL_1:.*]]: !mpir.sort<Operand>, %[[VAL_2:.*]]: !mpir.sort<Type>):
; CHECK:             %[[INST_0:.*]] = mpir.inst <sext> (%[[VAL_0]], %[[VAL_1]], %[[VAL_2]]) <result_name = "ret", flags = [], flag_modes = [], operand_kinds = [0, 2]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>) -> !mpir.sort<Instruction>
; CHECK:             mpir.yield %[[INST_0]] : <Instruction>
; CHECK:           }
; CHECK:           mpir.branch <param_args = [0, 1, 2], fixed_flags = [], fixed_flag_values = []> {
; CHECK:           ^bb0(%[[VAL_3:.*]]: !mpir.sort<Type>, %[[VAL_4:.*]]: !mpir.sort<Operand>, %[[VAL_5:.*]]: !mpir.sort<Type>):
; CHECK:             %[[INST_1:.*]] = mpir.inst <zext> (%[[VAL_3]], %[[VAL_4]], %[[VAL_5]]) <result_name = "ret", flags = [8], flag_modes = [0], operand_kinds = [0, 2]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>) -> !mpir.sort<Instruction>
; CHECK:             mpir.yield %[[INST_1]] : <Instruction>
; CHECK:           }
; CHECK:         }
; CHECK-LABEL:   mpir.matcher @itofp <supported_flags = [], syntax = 2, arity = 1, param_names = ["ty1", "x", "ty2"], param_is_type = [true, false, true]> {
; CHECK:           %[[VAR_0:.*]] = mpir.var "ty1" : <Type>
; CHECK:           %[[VAR_1:.*]] = mpir.var "ty2" : <Type>
; CHECK:           mpir.signature %[[VAR_0]], %[[VAR_1]] : !mpir.sort<Type>, !mpir.sort<Type>
; CHECK:           mpir.branch <param_args = [0, 1, 2], fixed_flags = [], fixed_flag_values = []> {
; CHECK:           ^bb0(%[[VAL_0:.*]]: !mpir.sort<Type>, %[[VAL_1:.*]]: !mpir.sort<Operand>, %[[VAL_2:.*]]: !mpir.sort<Type>):
; CHECK:             %[[INST_0:.*]] = mpir.inst <uitofp> (%[[VAL_0]], %[[VAL_1]], %[[VAL_2]]) <result_name = "ret", flags = [], flag_modes = [], operand_kinds = [0, 2]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>) -> !mpir.sort<Instruction>
; CHECK:             mpir.yield %[[INST_0]] : <Instruction>
; CHECK:           }
; CHECK:           mpir.branch <param_args = [0, 1, 2], fixed_flags = [], fixed_flag_values = []> {
; CHECK:           ^bb0(%[[VAL_3:.*]]: !mpir.sort<Type>, %[[VAL_4:.*]]: !mpir.sort<Operand>, %[[VAL_5:.*]]: !mpir.sort<Type>):
; CHECK:             %[[INST_1:.*]] = mpir.inst <sitofp> (%[[VAL_3]], %[[VAL_4]], %[[VAL_5]]) <result_name = "ret", flags = [], flag_modes = [], operand_kinds = [0, 2]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>) -> !mpir.sort<Instruction>
; CHECK:             mpir.yield %[[INST_1]] : <Instruction>
; CHECK:           }
; CHECK:         }
; CHECK-LABEL:   mpir.matcher @fptoi <supported_flags = [], syntax = 2, arity = 1, param_names = ["ty1", "x", "ty2"], param_is_type = [true, false, true]> {
; CHECK:           %[[VAR_0:.*]] = mpir.var "ty1" : <Type>
; CHECK:           %[[VAR_1:.*]] = mpir.var "ty2" : <Type>
; CHECK:           mpir.signature %[[VAR_0]], %[[VAR_1]] : !mpir.sort<Type>, !mpir.sort<Type>
; CHECK:           mpir.branch <param_args = [0, 1, 2], fixed_flags = [], fixed_flag_values = []> {
; CHECK:           ^bb0(%[[VAL_0:.*]]: !mpir.sort<Type>, %[[VAL_1:.*]]: !mpir.sort<Operand>, %[[VAL_2:.*]]: !mpir.sort<Type>):
; CHECK:             %[[INST_0:.*]] = mpir.inst <fptoui> (%[[VAL_0]], %[[VAL_1]], %[[VAL_2]]) <result_name = "ret", flags = [], flag_modes = [], operand_kinds = [0, 2]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>) -> !mpir.sort<Instruction>
; CHECK:             mpir.yield %[[INST_0]] : <Instruction>
; CHECK:           }
; CHECK:           mpir.branch <param_args = [0, 1, 2], fixed_flags = [], fixed_flag_values = []> {
; CHECK:           ^bb0(%[[VAL_3:.*]]: !mpir.sort<Type>, %[[VAL_4:.*]]: !mpir.sort<Operand>, %[[VAL_5:.*]]: !mpir.sort<Type>):
; CHECK:             %[[INST_1:.*]] = mpir.inst <fptosi> (%[[VAL_3]], %[[VAL_4]], %[[VAL_5]]) <result_name = "ret", flags = [], flag_modes = [], operand_kinds = [0, 2]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>) -> !mpir.sort<Instruction>
; CHECK:             mpir.yield %[[INST_1]] : <Instruction>
; CHECK:           }
; CHECK:         }
; CHECK-LABEL:   mpir.matcher @maxOrMin <commutative, supported_flags = [], syntax = 1, arity = 2, param_names = ["ty", "x", "y"], param_is_type = [true, false, false]> {
; CHECK:           %[[VAR_0:.*]] = mpir.var "ty" : <Type>
; CHECK:           mpir.signature %[[VAR_0]] : !mpir.sort<Type>
; CHECK:           mpir.branch <param_args = [0, 1, 2], fixed_flags = [], fixed_flag_values = []> {
; CHECK:           ^bb0(%[[VAL_0:.*]]: !mpir.sort<Type>, %[[VAL_1:.*]]: !mpir.sort<Operand>, %[[VAL_2:.*]]: !mpir.sort<Operand>):
; CHECK:             %[[GLOBAL_0:.*]] = mpir.global "llvm.smax" : <Value>
; CHECK:             %[[INST_0:.*]] = mpir.inst <call> (%[[VAL_0]], %[[GLOBAL_0]], %[[VAL_0]], %[[VAL_1]], %[[VAL_0]], %[[VAL_2]]) <result_name = "ret", flags = [], flag_modes = [], operand_kinds = [2, 1, 0, 0]> : (!mpir.sort<Type>, !mpir.sort<Value>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
; CHECK:             mpir.yield %[[INST_0]] : <Instruction>
; CHECK:           }
; CHECK:           mpir.branch <param_args = [0, 1, 2], fixed_flags = [], fixed_flag_values = []> {
; CHECK:           ^bb0(%[[VAL_3:.*]]: !mpir.sort<Type>, %[[VAL_4:.*]]: !mpir.sort<Operand>, %[[VAL_5:.*]]: !mpir.sort<Operand>):
; CHECK:             %[[GLOBAL_1:.*]] = mpir.global "llvm.smin" : <Value>
; CHECK:             %[[INST_1:.*]] = mpir.inst <call> (%[[VAL_3]], %[[GLOBAL_1]], %[[VAL_3]], %[[VAL_4]], %[[VAL_3]], %[[VAL_5]]) <result_name = "ret", flags = [], flag_modes = [], operand_kinds = [2, 1, 0, 0]> : (!mpir.sort<Type>, !mpir.sort<Value>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
; CHECK:             mpir.yield %[[INST_1]] : <Instruction>
; CHECK:           }
; CHECK:           mpir.branch <param_args = [0, 1, 2], fixed_flags = [], fixed_flag_values = []> {
; CHECK:           ^bb0(%[[VAL_6:.*]]: !mpir.sort<Type>, %[[VAL_7:.*]]: !mpir.sort<Operand>, %[[VAL_8:.*]]: !mpir.sort<Operand>):
; CHECK:             %[[GLOBAL_2:.*]] = mpir.global "llvm.umax" : <Value>
; CHECK:             %[[INST_2:.*]] = mpir.inst <call> (%[[VAL_6]], %[[GLOBAL_2]], %[[VAL_6]], %[[VAL_7]], %[[VAL_6]], %[[VAL_8]]) <result_name = "ret", flags = [], flag_modes = [], operand_kinds = [2, 1, 0, 0]> : (!mpir.sort<Type>, !mpir.sort<Value>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
; CHECK:             mpir.yield %[[INST_2]] : <Instruction>
; CHECK:           }
; CHECK:           mpir.branch <param_args = [0, 1, 2], fixed_flags = [], fixed_flag_values = []> {
; CHECK:           ^bb0(%[[VAL_9:.*]]: !mpir.sort<Type>, %[[VAL_10:.*]]: !mpir.sort<Operand>, %[[VAL_11:.*]]: !mpir.sort<Operand>):
; CHECK:             %[[GLOBAL_3:.*]] = mpir.global "llvm.umin" : <Value>
; CHECK:             %[[INST_3:.*]] = mpir.inst <call> (%[[VAL_9]], %[[GLOBAL_3]], %[[VAL_9]], %[[VAL_10]], %[[VAL_9]], %[[VAL_11]]) <result_name = "ret", flags = [], flag_modes = [], operand_kinds = [2, 1, 0, 0]> : (!mpir.sort<Type>, !mpir.sort<Value>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
; CHECK:             mpir.yield %[[INST_3]] : <Instruction>
; CHECK:           }
; CHECK:         }
; CHECK-LABEL:   mpir.matcher @selectMinMax <commutative, supported_flags = [], syntax = 1, arity = 2, param_names = ["ty", "x", "y"], param_is_type = [true, false, false]> {
; CHECK:           %[[VAR_0:.*]] = mpir.var "ty" : <Type>
; CHECK:           mpir.signature %[[VAR_0]] : !mpir.sort<Type>
; CHECK:           mpir.branch <param_args = [0, 1, 2], fixed_flags = [], fixed_flag_values = []> {
; CHECK:           ^bb0(%[[VAL_0:.*]]: !mpir.sort<Type>, %[[VAL_1:.*]]: !mpir.sort<Operand>, %[[VAL_2:.*]]: !mpir.sort<Operand>):
; CHECK:             %[[VAR_1:.*]] = mpir.var "_pred" : <CmpPredicate>
; CHECK:             %[[INST_0:.*]] = mpir.inst <icmp> (%[[VAR_1]], %[[VAL_0]], %[[VAL_1]], %[[VAL_0]], %[[VAL_2]]) <result_name = "_cmp", flags = [], flag_modes = [], operand_kinds = [5, 0, 0], metaflags = [#mpir.metaflag<"c", [], {{.*}}>]> : (!mpir.sort<CmpPredicate>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
; CHECK:             %[[VAR_2:.*]] = mpir.var "_cty" : <Type>
; CHECK:             %[[INST_1:.*]] = mpir.inst <select> (%[[VAR_2]], %[[INST_0]], %[[VAL_0]], %[[VAL_1]], %[[VAL_0]], %[[VAL_2]]) <result_name = "ret", flags = [], flag_modes = [], operand_kinds = [0, 0, 0]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
; CHECK:             %[[READ_0:.*]] = mpir_expr.read %[[VAR_1]] : (!mpir.sort<CmpPredicate>) -> !mpir.sort<String>
; CHECK:             %[[CALL_0:.*]] = mpir_expr.call call "isEquality"(%[[READ_0]]) anchor %[[INST_1]] : (!mpir.sort<String>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
; CHECK:             %[[CALL_1:.*]] = mpir_expr.call unary "!"(%[[CALL_0]]) anchor %[[INST_1]] : (!mpir.sort<Boolean>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
; CHECK:             mpir.require %[[CALL_1]] : <Boolean>
; CHECK:             mpir.yield %[[INST_1]] : <Instruction>
; CHECK:           }
; CHECK:         }
; CHECK-LABEL:   mpir.matcher @signBitCheck <supported_flags = [], syntax = 0, arity = 1, param_names = ["ty", "x"], param_is_type = [true, false]> {
; CHECK:           %[[VAR_0:.*]] = mpir.var "ty" : <Type>
; CHECK:           mpir.signature %[[VAR_0]] : !mpir.sort<Type>
; CHECK:           mpir.branch <param_args = [0, 1], fixed_flags = [], fixed_flag_values = []> {
; CHECK:           ^bb0(%[[VAL_0:.*]]: !mpir.sort<Type>, %[[VAL_1:.*]]: !mpir.sort<Operand>):
; CHECK:             %[[KEYWORD_0:.*]] = mpir.keyword slt : <Value>
; CHECK:             %[[VAR_1:.*]] = mpir.var "_c" : <Operand>
; CHECK:             %[[INST_0:.*]] = mpir.inst <icmp> (%[[KEYWORD_0]], %[[VAL_0]], %[[VAL_1]], %[[VAL_0]], %[[VAR_1]]) <result_name = "ret", flags = [], flag_modes = [], operand_kinds = [5, 0, 0]> : (!mpir.sort<Value>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
; CHECK:             %[[READ_0:.*]] = mpir_expr.read %[[VAR_1]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
; CHECK:             %[[CALL_0:.*]] = mpir_expr.call call "isZero"(%[[READ_0]]) anchor %[[INST_0]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
; CHECK:             mpir.require %[[CALL_0]] {from_metaflag} : <Boolean>
; CHECK:             %[[READ_1:.*]] = mpir_expr.read %[[VAR_1]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
; CHECK:             %[[APPLY_0:.*]] = mpir_expr.apply @isAPInt(%[[READ_1]]) : (!mpir.sort<Value>) -> !mpir.sort<Boolean>
; CHECK:             mpir.require %[[APPLY_0]] {from_metaflag} : <Boolean>
; CHECK:             mpir.yield %[[INST_0]] : <Instruction>
; CHECK:           }
; CHECK:           mpir.branch <param_args = [0, 1], fixed_flags = [], fixed_flag_values = []> {
; CHECK:           ^bb0(%[[VAL_2:.*]]: !mpir.sort<Type>, %[[VAL_3:.*]]: !mpir.sort<Operand>):
; CHECK:             %[[KEYWORD_1:.*]] = mpir.keyword sle : <Value>
; CHECK:             %[[VAR_2:.*]] = mpir.var "_c" : <Operand>
; CHECK:             %[[INST_1:.*]] = mpir.inst <icmp> (%[[KEYWORD_1]], %[[VAL_2]], %[[VAL_3]], %[[VAL_2]], %[[VAR_2]]) <result_name = "ret", flags = [], flag_modes = [], operand_kinds = [5, 0, 0]> : (!mpir.sort<Value>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
; CHECK:             %[[READ_2:.*]] = mpir_expr.read %[[VAR_2]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
; CHECK:             %[[CALL_1:.*]] = mpir_expr.call call "isAllOnes"(%[[READ_2]]) anchor %[[INST_1]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
; CHECK:             mpir.require %[[CALL_1]] {from_metaflag} : <Boolean>
; CHECK:             %[[READ_3:.*]] = mpir_expr.read %[[VAR_2]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
; CHECK:             %[[APPLY_1:.*]] = mpir_expr.apply @isAPInt(%[[READ_3]]) : (!mpir.sort<Value>) -> !mpir.sort<Boolean>
; CHECK:             mpir.require %[[APPLY_1]] {from_metaflag} : <Boolean>
; CHECK:             mpir.yield %[[INST_1]] : <Instruction>
; CHECK:           }
; CHECK:           mpir.branch <param_args = [0, 1], fixed_flags = [], fixed_flag_values = []> {
; CHECK:           ^bb0(%[[VAL_4:.*]]: !mpir.sort<Type>, %[[VAL_5:.*]]: !mpir.sort<Operand>):
; CHECK:             %[[KEYWORD_2:.*]] = mpir.keyword sgt : <Value>
; CHECK:             %[[VAR_3:.*]] = mpir.var "_c" : <Operand>
; CHECK:             %[[INST_2:.*]] = mpir.inst <icmp> (%[[KEYWORD_2]], %[[VAL_4]], %[[VAL_5]], %[[VAL_4]], %[[VAR_3]]) <result_name = "ret", flags = [], flag_modes = [], operand_kinds = [5, 0, 0]> : (!mpir.sort<Value>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
; CHECK:             %[[READ_4:.*]] = mpir_expr.read %[[VAR_3]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
; CHECK:             %[[CALL_2:.*]] = mpir_expr.call call "isAllOnes"(%[[READ_4]]) anchor %[[INST_2]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
; CHECK:             mpir.require %[[CALL_2]] {from_metaflag} : <Boolean>
; CHECK:             %[[READ_5:.*]] = mpir_expr.read %[[VAR_3]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
; CHECK:             %[[APPLY_2:.*]] = mpir_expr.apply @isAPInt(%[[READ_5]]) : (!mpir.sort<Value>) -> !mpir.sort<Boolean>
; CHECK:             mpir.require %[[APPLY_2]] {from_metaflag} : <Boolean>
; CHECK:             mpir.yield %[[INST_2]] : <Instruction>
; CHECK:           }
; CHECK:           mpir.branch <param_args = [0, 1], fixed_flags = [], fixed_flag_values = []> {
; CHECK:           ^bb0(%[[VAL_6:.*]]: !mpir.sort<Type>, %[[VAL_7:.*]]: !mpir.sort<Operand>):
; CHECK:             %[[KEYWORD_3:.*]] = mpir.keyword sge : <Value>
; CHECK:             %[[VAR_4:.*]] = mpir.var "_c" : <Operand>
; CHECK:             %[[INST_3:.*]] = mpir.inst <icmp> (%[[KEYWORD_3]], %[[VAL_6]], %[[VAL_7]], %[[VAL_6]], %[[VAR_4]]) <result_name = "ret", flags = [], flag_modes = [], operand_kinds = [5, 0, 0]> : (!mpir.sort<Value>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
; CHECK:             %[[READ_6:.*]] = mpir_expr.read %[[VAR_4]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
; CHECK:             %[[CALL_3:.*]] = mpir_expr.call call "isZero"(%[[READ_6]]) anchor %[[INST_3]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
; CHECK:             mpir.require %[[CALL_3]] {from_metaflag} : <Boolean>
; CHECK:             %[[READ_7:.*]] = mpir_expr.read %[[VAR_4]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
; CHECK:             %[[APPLY_3:.*]] = mpir_expr.apply @isAPInt(%[[READ_7]]) : (!mpir.sort<Value>) -> !mpir.sort<Boolean>
; CHECK:             mpir.require %[[APPLY_3]] {from_metaflag} : <Boolean>
; CHECK:             mpir.yield %[[INST_3]] : <Instruction>
; CHECK:           }
; CHECK:           mpir.branch <param_args = [0, 1], fixed_flags = [], fixed_flag_values = []> {
; CHECK:           ^bb0(%[[VAL_8:.*]]: !mpir.sort<Type>, %[[VAL_9:.*]]: !mpir.sort<Operand>):
; CHECK:             %[[KEYWORD_4:.*]] = mpir.keyword ugt : <Value>
; CHECK:             %[[VAR_5:.*]] = mpir.var "_c" : <Operand>
; CHECK:             %[[INST_4:.*]] = mpir.inst <icmp> (%[[KEYWORD_4]], %[[VAL_8]], %[[VAL_9]], %[[VAL_8]], %[[VAR_5]]) <result_name = "ret", flags = [], flag_modes = [], operand_kinds = [5, 0, 0]> : (!mpir.sort<Value>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
; CHECK:             %[[READ_8:.*]] = mpir_expr.read %[[VAR_5]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
; CHECK:             %[[CALL_4:.*]] = mpir_expr.call call "isMaxSignedValue"(%[[READ_8]]) anchor %[[INST_4]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
; CHECK:             mpir.require %[[CALL_4]] {from_metaflag} : <Boolean>
; CHECK:             %[[READ_9:.*]] = mpir_expr.read %[[VAR_5]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
; CHECK:             %[[APPLY_4:.*]] = mpir_expr.apply @isAPInt(%[[READ_9]]) : (!mpir.sort<Value>) -> !mpir.sort<Boolean>
; CHECK:             mpir.require %[[APPLY_4]] {from_metaflag} : <Boolean>
; CHECK:             mpir.yield %[[INST_4]] : <Instruction>
; CHECK:           }
; CHECK:           mpir.branch <param_args = [0, 1], fixed_flags = [], fixed_flag_values = []> {
; CHECK:           ^bb0(%[[VAL_10:.*]]: !mpir.sort<Type>, %[[VAL_11:.*]]: !mpir.sort<Operand>):
; CHECK:             %[[KEYWORD_5:.*]] = mpir.keyword uge : <Value>
; CHECK:             %[[VAR_6:.*]] = mpir.var "_c" : <Operand>
; CHECK:             %[[INST_5:.*]] = mpir.inst <icmp> (%[[KEYWORD_5]], %[[VAL_10]], %[[VAL_11]], %[[VAL_10]], %[[VAR_6]]) <result_name = "ret", flags = [], flag_modes = [], operand_kinds = [5, 0, 0]> : (!mpir.sort<Value>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
; CHECK:             %[[READ_10:.*]] = mpir_expr.read %[[VAR_6]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
; CHECK:             %[[CALL_5:.*]] = mpir_expr.call call "isSignMask"(%[[READ_10]]) anchor %[[INST_5]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
; CHECK:             mpir.require %[[CALL_5]] {from_metaflag} : <Boolean>
; CHECK:             %[[READ_11:.*]] = mpir_expr.read %[[VAR_6]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
; CHECK:             %[[APPLY_5:.*]] = mpir_expr.apply @isAPInt(%[[READ_11]]) : (!mpir.sort<Value>) -> !mpir.sort<Boolean>
; CHECK:             mpir.require %[[APPLY_5]] {from_metaflag} : <Boolean>
; CHECK:             mpir.yield %[[INST_5]] : <Instruction>
; CHECK:           }
; CHECK:           mpir.branch <param_args = [0, 1], fixed_flags = [], fixed_flag_values = []> {
; CHECK:           ^bb0(%[[VAL_12:.*]]: !mpir.sort<Type>, %[[VAL_13:.*]]: !mpir.sort<Operand>):
; CHECK:             %[[KEYWORD_6:.*]] = mpir.keyword ult : <Value>
; CHECK:             %[[VAR_7:.*]] = mpir.var "_c" : <Operand>
; CHECK:             %[[INST_6:.*]] = mpir.inst <icmp> (%[[KEYWORD_6]], %[[VAL_12]], %[[VAL_13]], %[[VAL_12]], %[[VAR_7]]) <result_name = "ret", flags = [], flag_modes = [], operand_kinds = [5, 0, 0]> : (!mpir.sort<Value>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
; CHECK:             %[[READ_12:.*]] = mpir_expr.read %[[VAR_7]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
; CHECK:             %[[CALL_6:.*]] = mpir_expr.call call "isSignMask"(%[[READ_12]]) anchor %[[INST_6]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
; CHECK:             mpir.require %[[CALL_6]] {from_metaflag} : <Boolean>
; CHECK:             %[[READ_13:.*]] = mpir_expr.read %[[VAR_7]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
; CHECK:             %[[APPLY_6:.*]] = mpir_expr.apply @isAPInt(%[[READ_13]]) : (!mpir.sort<Value>) -> !mpir.sort<Boolean>
; CHECK:             mpir.require %[[APPLY_6]] {from_metaflag} : <Boolean>
; CHECK:             mpir.yield %[[INST_6]] : <Instruction>
; CHECK:           }
; CHECK:           mpir.branch <param_args = [0, 1], fixed_flags = [], fixed_flag_values = []> {
; CHECK:           ^bb0(%[[VAL_14:.*]]: !mpir.sort<Type>, %[[VAL_15:.*]]: !mpir.sort<Operand>):
; CHECK:             %[[KEYWORD_7:.*]] = mpir.keyword ule : <Value>
; CHECK:             %[[VAR_8:.*]] = mpir.var "_c" : <Operand>
; CHECK:             %[[INST_7:.*]] = mpir.inst <icmp> (%[[KEYWORD_7]], %[[VAL_14]], %[[VAL_15]], %[[VAL_14]], %[[VAR_8]]) <result_name = "ret", flags = [], flag_modes = [], operand_kinds = [5, 0, 0]> : (!mpir.sort<Value>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
; CHECK:             %[[READ_14:.*]] = mpir_expr.read %[[VAR_8]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
; CHECK:             %[[CALL_7:.*]] = mpir_expr.call call "isMaxSignedValue"(%[[READ_14]]) anchor %[[INST_7]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
; CHECK:             mpir.require %[[CALL_7]] {from_metaflag} : <Boolean>
; CHECK:             %[[READ_15:.*]] = mpir_expr.read %[[VAR_8]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
; CHECK:             %[[APPLY_7:.*]] = mpir_expr.apply @isAPInt(%[[READ_15]]) : (!mpir.sort<Value>) -> !mpir.sort<Boolean>
; CHECK:             mpir.require %[[APPLY_7]] {from_metaflag} : <Boolean>
; CHECK:             mpir.yield %[[INST_7]] : <Instruction>
; CHECK:           }
; CHECK:         }
; CHECK-LABEL:   mpir.constraint_def @trueIfSigned <param_names = ["cmp"]> {
; CHECK:         ^bb0(%[[VAL_0:.*]]: !mpir.sort<Unknown>):
; CHECK:           %[[READ_0:.*]] = mpir_expr.read %[[VAL_0]] : (!mpir.sort<Unknown>) -> !mpir.sort<Unknown>
; CHECK:           %[[CALL_0:.*]] = mpir_expr.call call "predicate"(%[[READ_0]]) : (!mpir.sort<Unknown>) -> !mpir.sort<String>
; CHECK:           %[[STR_0:.*]] = mpir_expr.str "slt" : <String>
; CHECK:           %[[CALL_1:.*]] = mpir_expr.call binary "=="(%[[CALL_0]], %[[STR_0]]) : (!mpir.sort<String>, !mpir.sort<String>) -> !mpir.sort<Boolean>
; CHECK:           %[[READ_1:.*]] = mpir_expr.read %[[VAL_0]] : (!mpir.sort<Unknown>) -> !mpir.sort<Unknown>
; CHECK:           %[[CALL_2:.*]] = mpir_expr.call call "predicate"(%[[READ_1]]) : (!mpir.sort<Unknown>) -> !mpir.sort<String>
; CHECK:           %[[STR_1:.*]] = mpir_expr.str "sle" : <String>
; CHECK:           %[[CALL_3:.*]] = mpir_expr.call binary "=="(%[[CALL_2]], %[[STR_1]]) : (!mpir.sort<String>, !mpir.sort<String>) -> !mpir.sort<Boolean>
; CHECK:           %[[CALL_4:.*]] = mpir_expr.call binary "||"(%[[CALL_1]], %[[CALL_3]]) : (!mpir.sort<Boolean>, !mpir.sort<Boolean>) -> !mpir.sort<Boolean>
; CHECK:           %[[READ_2:.*]] = mpir_expr.read %[[VAL_0]] : (!mpir.sort<Unknown>) -> !mpir.sort<Unknown>
; CHECK:           %[[CALL_5:.*]] = mpir_expr.call call "predicate"(%[[READ_2]]) : (!mpir.sort<Unknown>) -> !mpir.sort<String>
; CHECK:           %[[STR_2:.*]] = mpir_expr.str "ugt" : <String>
; CHECK:           %[[CALL_6:.*]] = mpir_expr.call binary "=="(%[[CALL_5]], %[[STR_2]]) : (!mpir.sort<String>, !mpir.sort<String>) -> !mpir.sort<Boolean>
; CHECK:           %[[CALL_7:.*]] = mpir_expr.call binary "||"(%[[CALL_4]], %[[CALL_6]]) : (!mpir.sort<Boolean>, !mpir.sort<Boolean>) -> !mpir.sort<Boolean>
; CHECK:           %[[READ_3:.*]] = mpir_expr.read %[[VAL_0]] : (!mpir.sort<Unknown>) -> !mpir.sort<Unknown>
; CHECK:           %[[CALL_8:.*]] = mpir_expr.call call "predicate"(%[[READ_3]]) : (!mpir.sort<Unknown>) -> !mpir.sort<String>
; CHECK:           %[[STR_3:.*]] = mpir_expr.str "uge" : <String>
; CHECK:           %[[CALL_9:.*]] = mpir_expr.call binary "=="(%[[CALL_8]], %[[STR_3]]) : (!mpir.sort<String>, !mpir.sort<String>) -> !mpir.sort<Boolean>
; CHECK:           %[[CALL_10:.*]] = mpir_expr.call binary "||"(%[[CALL_7]], %[[CALL_9]]) : (!mpir.sort<Boolean>, !mpir.sort<Boolean>) -> !mpir.sort<Boolean>
; CHECK:           mpir.yield %[[CALL_10]] : <Boolean>
; CHECK:         }
; CHECK-LABEL:   mpir.matcher @fnegLike <supported_flags = [], syntax = 0, arity = 1, param_names = ["ty", "x"], param_is_type = [true, false]> {
; CHECK:           %[[VAR_0:.*]] = mpir.var "ty" : <Type>
; CHECK:           mpir.signature %[[VAR_0]] : !mpir.sort<Type>
; CHECK:           mpir.branch <param_args = [0, 1], fixed_flags = [], fixed_flag_values = []> {
; CHECK:           ^bb0(%[[VAL_0:.*]]: !mpir.sort<Type>, %[[VAL_1:.*]]: !mpir.sort<Operand>):
; CHECK:             %[[INST_0:.*]] = mpir.inst <fneg> (%[[VAL_0]], %[[VAL_1]]) <result_name = "ret", flags = [], flag_modes = [], operand_kinds = [0]> : (!mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
; CHECK:             mpir.yield %[[INST_0]] : <Instruction>
; CHECK:           }
; CHECK:           mpir.branch <param_args = [0, 1], fixed_flags = [], fixed_flag_values = []> {
; CHECK:           ^bb0(%[[VAL_2:.*]]: !mpir.sort<Type>, %[[VAL_3:.*]]: !mpir.sort<Operand>):
; CHECK:             %[[VAR_1:.*]] = mpir.var "_zero" : <Operand>
; CHECK:             %[[INST_1:.*]] = mpir.inst <fsub> (%[[VAL_2]], %[[VAR_1]], %[[VAL_2]], %[[VAL_3]]) <result_name = "ret", flags = [13], flag_modes = [1], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
; CHECK:             %[[READ_0:.*]] = mpir_expr.read %[[VAR_1]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
; CHECK:             %[[CALL_0:.*]] = mpir_expr.call call "isNegZeroFP"(%[[READ_0]]) anchor %[[INST_1]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
; CHECK:             mpir.require %[[CALL_0]] {from_metaflag} : <Boolean>
; CHECK:             mpir.yield %[[INST_1]] : <Instruction>
; CHECK:           }
; CHECK:           mpir.branch <param_args = [0, 1], fixed_flags = [], fixed_flag_values = []> {
; CHECK:           ^bb0(%[[VAL_4:.*]]: !mpir.sort<Type>, %[[VAL_5:.*]]: !mpir.sort<Operand>):
; CHECK:             %[[VAR_2:.*]] = mpir.var "_zero" : <Operand>
; CHECK:             %[[INST_2:.*]] = mpir.inst <fsub> (%[[VAL_4]], %[[VAR_2]], %[[VAL_4]], %[[VAL_5]]) <result_name = "ret", flags = [13], flag_modes = [0], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
; CHECK:             %[[READ_1:.*]] = mpir_expr.read %[[VAR_2]] : (!mpir.sort<Operand>) -> !mpir.sort<Value>
; CHECK:             %[[CALL_1:.*]] = mpir_expr.call call "isAnyZeroFP"(%[[READ_1]]) anchor %[[INST_2]] : (!mpir.sort<Value>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
; CHECK:             mpir.require %[[CALL_1]] {from_metaflag} : <Boolean>
; CHECK:             mpir.yield %[[INST_2]] : <Instruction>
; CHECK:           }
; CHECK:         }
; CHECK-LABEL:   mpir.matcher @ptrToIntOrAddr <supported_flags = [], syntax = 2, arity = 1, param_names = ["ty1", "x", "ty2"], param_is_type = [true, false, true]> {
; CHECK:           %[[VAR_0:.*]] = mpir.var "ty1" : <Type>
; CHECK:           %[[VAR_1:.*]] = mpir.var "ty2" : <Type>
; CHECK:           mpir.signature %[[VAR_0]], %[[VAR_1]] : !mpir.sort<Type>, !mpir.sort<Type>
; CHECK:           mpir.branch <param_args = [0, 1, 2], fixed_flags = [], fixed_flag_values = []> {
; CHECK:           ^bb0(%[[VAL_0:.*]]: !mpir.sort<Type>, %[[VAL_1:.*]]: !mpir.sort<Operand>, %[[VAL_2:.*]]: !mpir.sort<Type>):
; CHECK:             %[[INST_0:.*]] = mpir.inst <ptrtoint> (%[[VAL_0]], %[[VAL_1]], %[[VAL_2]]) <result_name = "ret", flags = [], flag_modes = [], operand_kinds = [0, 2]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>) -> !mpir.sort<Instruction>
; CHECK:             mpir.yield %[[INST_0]] : <Instruction>
; CHECK:           }
; CHECK:           mpir.branch <param_args = [0, 1, 2], fixed_flags = [], fixed_flag_values = []> {
; CHECK:           ^bb0(%[[VAL_3:.*]]: !mpir.sort<Type>, %[[VAL_4:.*]]: !mpir.sort<Operand>, %[[VAL_5:.*]]: !mpir.sort<Type>):
; CHECK:             %[[INST_1:.*]] = mpir.inst <ptrtoaddr> (%[[VAL_3]], %[[VAL_4]], %[[VAL_5]]) <result_name = "ret", flags = [], flag_modes = [], operand_kinds = [0, 2]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>) -> !mpir.sort<Instruction>
; CHECK:             mpir.yield %[[INST_1]] : <Instruction>
; CHECK:           }
; CHECK:         }
; CHECK-LABEL:   mpir.metaflag_def @s <param_names = ["v"], placement = 3> {
; CHECK:         ^bb0(%[[VAL_0:.*]]: !mpir.sort<Unknown>):
; CHECK:           %[[READ_0:.*]] = mpir_expr.read %[[VAL_0]] : (!mpir.sort<Unknown>) -> !mpir.sort<Unknown>
; CHECK:           %[[CALL_0:.*]] = mpir_expr.call call "hasOneUse"(%[[READ_0]]) : (!mpir.sort<Unknown>) -> !mpir.sort<Boolean>
; CHECK:           mpir.yield %[[CALL_0]] : <Boolean>
; CHECK:         }
; CHECK-LABEL:   mpir.metaflag_def @su <param_names = ["v"], placement = 3> {
; CHECK:         ^bb0(%[[VAL_0:.*]]: !mpir.sort<Unknown>):
; CHECK:           %[[READ_0:.*]] = mpir_expr.read %[[VAL_0]] : (!mpir.sort<Unknown>) -> !mpir.sort<Unknown>
; CHECK:           %[[CALL_0:.*]] = mpir_expr.call call "hasOneUser"(%[[READ_0]]) : (!mpir.sort<Unknown>) -> !mpir.sort<Boolean>
; CHECK:           mpir.yield %[[CALL_0]] : <Boolean>
; CHECK:         }
; CHECK-LABEL:   mpir.metaflag_def @knownNegative <param_names = ["v"], placement = 2> {
; CHECK:         ^bb0(%[[VAL_0:.*]]: !mpir.sort<Unknown>):
; CHECK:           %[[READ_0:.*]] = mpir_expr.read %[[VAL_0]] : (!mpir.sort<Unknown>) -> !mpir.sort<Unknown>
; CHECK:           %[[CALL_0:.*]] = mpir_expr.call call "isKnownNegative"(%[[READ_0]]) : (!mpir.sort<Unknown>) -> !mpir.sort<Boolean>
; CHECK:           mpir.yield %[[CALL_0]] : <Boolean>
; CHECK:         }
; CHECK-LABEL:   mpir.metaflag_def @notUndef <param_names = ["v"], placement = 2> {
; CHECK:         ^bb0(%[[VAL_0:.*]]: !mpir.sort<Unknown>):
; CHECK:           %[[READ_0:.*]] = mpir_expr.read %[[VAL_0]] : (!mpir.sort<Unknown>) -> !mpir.sort<Unknown>
; CHECK:           %[[CALL_0:.*]] = mpir_expr.call call "isGuaranteedNotToBeUndef"(%[[READ_0]]) : (!mpir.sort<Unknown>) -> !mpir.sort<Boolean>
; CHECK:           mpir.yield %[[CALL_0]] : <Boolean>
; CHECK:         }
; CHECK-LABEL:   mpir.metaflag_def @knownPowerOfTwo <param_names = ["v"], placement = 2> {
; CHECK:         ^bb0(%[[VAL_0:.*]]: !mpir.sort<Unknown>):
; CHECK:           %[[READ_0:.*]] = mpir_expr.read %[[VAL_0]] : (!mpir.sort<Unknown>) -> !mpir.sort<Unknown>
; CHECK:           %[[CALL_0:.*]] = mpir_expr.call call "isKnownPowerOfTwo"(%[[READ_0]]) : (!mpir.sort<Unknown>) -> !mpir.sort<Boolean>
; CHECK:           mpir.yield %[[CALL_0]] : <Boolean>
; CHECK:         }
; CHECK-LABEL:   mpir.metaflag_def @knownPowerOfTwoOrZero <param_names = ["v"], placement = 2> {
; CHECK:         ^bb0(%[[VAL_0:.*]]: !mpir.sort<Unknown>):
; CHECK:           %[[READ_0:.*]] = mpir_expr.read %[[VAL_0]] : (!mpir.sort<Unknown>) -> !mpir.sort<Unknown>
; CHECK:           %[[CALL_0:.*]] = mpir_expr.call call "isKnownPowerOfTwoOrZero"(%[[READ_0]]) : (!mpir.sort<Unknown>) -> !mpir.sort<Boolean>
; CHECK:           mpir.yield %[[CALL_0]] : <Boolean>
; CHECK:         }
; CHECK-LABEL:   mpir.metaflag_def @notPoison <param_names = ["v"], placement = 2> {
; CHECK:         ^bb0(%[[VAL_0:.*]]: !mpir.sort<Unknown>):
; CHECK:           %[[READ_0:.*]] = mpir_expr.read %[[VAL_0]] : (!mpir.sort<Unknown>) -> !mpir.sort<Unknown>
; CHECK:           %[[CALL_0:.*]] = mpir_expr.call call "isGuaranteedNotToBePoison"(%[[READ_0]]) : (!mpir.sort<Unknown>) -> !mpir.sort<Boolean>
; CHECK:           mpir.yield %[[CALL_0]] : <Boolean>
; CHECK:         }
; CHECK-LABEL:   mpir.metaflag_def @notUndefOrPoison <param_names = ["v"], placement = 2> {
; CHECK:         ^bb0(%[[VAL_0:.*]]: !mpir.sort<Unknown>):
; CHECK:           %[[READ_0:.*]] = mpir_expr.read %[[VAL_0]] : (!mpir.sort<Unknown>) -> !mpir.sort<Unknown>
; CHECK:           %[[CALL_0:.*]] = mpir_expr.call call "isGuaranteedNotToBeUndefOrPoison"(%[[READ_0]]) : (!mpir.sort<Unknown>) -> !mpir.sort<Boolean>
; CHECK:           mpir.yield %[[CALL_0]] : <Boolean>
; CHECK:         }
; CHECK-LABEL:   mpir.constraint_def @isOdd <param_names = ["v"]> {
; CHECK:         ^bb0(%[[VAL_0:.*]]: !mpir.sort<Unknown>):
; CHECK:           %[[READ_0:.*]] = mpir_expr.read %[[VAL_0]] : (!mpir.sort<Unknown>) -> !mpir.sort<Unknown>
; CHECK:           %[[INT_0:.*]] = mpir_expr.int 1 : ui64 : <Integer>
; CHECK:           %[[CALL_0:.*]] = mpir_expr.call call "and"(%[[READ_0]], %[[INT_0]]) : (!mpir.sort<Unknown>, !mpir.sort<Integer>) -> !mpir.sort<Integer>
; CHECK:           %[[INT_1:.*]] = mpir_expr.int 1 : ui64 : <Integer>
; CHECK:           %[[CALL_1:.*]] = mpir_expr.call binary "=="(%[[CALL_0]], %[[INT_1]]) : (!mpir.sort<Integer>, !mpir.sort<Integer>) -> !mpir.sort<Boolean>
; CHECK:           mpir.yield %[[CALL_1]] : <Boolean>
; CHECK:         }
; CHECK-LABEL:   mpir.metaflag_def @odd <param_names = ["v"], placement = 2> {
; CHECK:         ^bb0(%[[VAL_0:.*]]: !mpir.sort<Unknown>):
; CHECK:           %[[READ_0:.*]] = mpir_expr.read %[[VAL_0]] : (!mpir.sort<Unknown>) -> !mpir.sort<Unknown>
; CHECK:           %[[APPLY_0:.*]] = mpir_expr.apply @isOdd(%[[READ_0]]) : (!mpir.sort<Unknown>) -> !mpir.sort<Boolean>
; CHECK:           mpir.yield %[[APPLY_0]] : <Boolean>
; CHECK:         }
; CHECK-LABEL:   mpir.matcher @selectEq <supported_flags = [], syntax = 0, arity = 4, param_names = ["cond_ty", "x", "cond_ty", "y", "val_ty", "a", "val_ty", "b"], param_is_type = [true, false, true, false, true, false, true, false]> {
; CHECK:           %[[VAR_0:.*]] = mpir.var "cond_ty" : <Type>
; CHECK:           %[[VAR_1:.*]] = mpir.var "val_ty" : <Type>
; CHECK:           mpir.signature %[[VAR_0]], %[[VAR_0]], %[[VAR_1]], %[[VAR_1]] : !mpir.sort<Type>, !mpir.sort<Type>, !mpir.sort<Type>, !mpir.sort<Type>
; CHECK:           mpir.branch <param_args = [0, 1, 0, 2, 3, 4, 3, 5], fixed_flags = [], fixed_flag_values = []> {
; CHECK:           ^bb0(%[[VAL_0:.*]]: !mpir.sort<Type>, %[[VAL_1:.*]]: !mpir.sort<Operand>, %[[VAL_2:.*]]: !mpir.sort<Operand>, %[[VAL_3:.*]]: !mpir.sort<Type>, %[[VAL_4:.*]]: !mpir.sort<Operand>, %[[VAL_5:.*]]: !mpir.sort<Operand>):
; CHECK:             %[[KEYWORD_0:.*]] = mpir.keyword eq : <Value>
; CHECK:             %[[INST_0:.*]] = mpir.inst <icmp> (%[[KEYWORD_0]], %[[VAL_0]], %[[VAL_1]], %[[VAL_0]], %[[VAL_2]]) <result_name = "cmp", flags = [], flag_modes = [], operand_kinds = [5, 0, 0]> : (!mpir.sort<Value>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
; CHECK:             %[[TYPE_0:.*]] = mpir.type.int 1 : <Type>
; CHECK:             %[[INST_1:.*]] = mpir.inst <select> (%[[TYPE_0]], %[[INST_0]], %[[VAL_3]], %[[VAL_4]], %[[VAL_3]], %[[VAL_5]]) <result_name = "ret", flags = [], flag_modes = [], operand_kinds = [0, 0, 0]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
; CHECK:             mpir.yield %[[INST_1]] : <Instruction>
; CHECK:           }
; CHECK:           mpir.branch <param_args = [0, 1, 0, 2, 3, 4, 3, 5], fixed_flags = [], fixed_flag_values = []> {
; CHECK:           ^bb0(%[[VAL_6:.*]]: !mpir.sort<Type>, %[[VAL_7:.*]]: !mpir.sort<Operand>, %[[VAL_8:.*]]: !mpir.sort<Operand>, %[[VAL_9:.*]]: !mpir.sort<Type>, %[[VAL_10:.*]]: !mpir.sort<Operand>, %[[VAL_11:.*]]: !mpir.sort<Operand>):
; CHECK:             %[[KEYWORD_1:.*]] = mpir.keyword ne : <Value>
; CHECK:             %[[INST_2:.*]] = mpir.inst <icmp> (%[[KEYWORD_1]], %[[VAL_6]], %[[VAL_7]], %[[VAL_6]], %[[VAL_8]]) <result_name = "cmp", flags = [], flag_modes = [], operand_kinds = [5, 0, 0]> : (!mpir.sort<Value>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
; CHECK:             %[[TYPE_1:.*]] = mpir.type.int 1 : <Type>
; CHECK:             %[[INST_3:.*]] = mpir.inst <select> (%[[TYPE_1]], %[[INST_2]], %[[VAL_9]], %[[VAL_11]], %[[VAL_9]], %[[VAL_10]]) <result_name = "ret", flags = [], flag_modes = [], operand_kinds = [0, 0, 0]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
; CHECK:             mpir.yield %[[INST_3]] : <Instruction>
; CHECK:           }
; CHECK:         }
; CHECK-LABEL:   mpir.matcher @selectEqZero <supported_flags = [], syntax = 0, arity = 3, param_names = ["cond_ty", "x", "val_ty", "a", "val_ty", "b"], param_is_type = [true, false, true, false, true, false]> {
; CHECK:           %[[VAR_0:.*]] = mpir.var "cond_ty" : <Type>
; CHECK:           %[[VAR_1:.*]] = mpir.var "val_ty" : <Type>
; CHECK:           mpir.signature %[[VAR_0]], %[[VAR_1]], %[[VAR_1]] : !mpir.sort<Type>, !mpir.sort<Type>, !mpir.sort<Type>
; CHECK:           mpir.branch <param_args = [0, 1, 2, 3, 2, 4], fixed_flags = [], fixed_flag_values = []> {
; CHECK:           ^bb0(%[[VAL_0:.*]]: !mpir.sort<Type>, %[[VAL_1:.*]]: !mpir.sort<Operand>, %[[VAL_2:.*]]: !mpir.sort<Type>, %[[VAL_3:.*]]: !mpir.sort<Operand>, %[[VAL_4:.*]]: !mpir.sort<Operand>):
; CHECK:             %[[KEYWORD_0:.*]] = mpir.keyword eq : <Value>
; CHECK:             %[[INT_0:.*]] = mpir.int 0 : ui1 : <Value>
; CHECK:             %[[INST_0:.*]] = mpir.inst <icmp> (%[[KEYWORD_0]], %[[VAL_0]], %[[VAL_1]], %[[VAL_0]], %[[INT_0]]) <result_name = "cmp", flags = [], flag_modes = [], operand_kinds = [5, 0, 0]> : (!mpir.sort<Value>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
; CHECK:             %[[TYPE_0:.*]] = mpir.type.int 1 : <Type>
; CHECK:             %[[INST_1:.*]] = mpir.inst <select> (%[[TYPE_0]], %[[INST_0]], %[[VAL_2]], %[[VAL_3]], %[[VAL_2]], %[[VAL_4]]) <result_name = "ret", flags = [], flag_modes = [], operand_kinds = [0, 0, 0]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
; CHECK:             mpir.yield %[[INST_1]] : <Instruction>
; CHECK:           }
; CHECK:           mpir.branch <param_args = [0, 1, 2, 3, 2, 4], fixed_flags = [], fixed_flag_values = []> {
; CHECK:           ^bb0(%[[VAL_5:.*]]: !mpir.sort<Type>, %[[VAL_6:.*]]: !mpir.sort<Operand>, %[[VAL_7:.*]]: !mpir.sort<Type>, %[[VAL_8:.*]]: !mpir.sort<Operand>, %[[VAL_9:.*]]: !mpir.sort<Operand>):
; CHECK:             %[[KEYWORD_1:.*]] = mpir.keyword ne : <Value>
; CHECK:             %[[INT_1:.*]] = mpir.int 0 : ui1 : <Value>
; CHECK:             %[[INST_2:.*]] = mpir.inst <icmp> (%[[KEYWORD_1]], %[[VAL_5]], %[[VAL_6]], %[[VAL_5]], %[[INT_1]]) <result_name = "cmp", flags = [], flag_modes = [], operand_kinds = [5, 0, 0]> : (!mpir.sort<Value>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
; CHECK:             %[[TYPE_1:.*]] = mpir.type.int 1 : <Type>
; CHECK:             %[[INST_3:.*]] = mpir.inst <select> (%[[TYPE_1]], %[[INST_2]], %[[VAL_7]], %[[VAL_9]], %[[VAL_7]], %[[VAL_8]]) <result_name = "ret", flags = [], flag_modes = [], operand_kinds = [0, 0, 0]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
; CHECK:             mpir.yield %[[INST_3]] : <Instruction>
; CHECK:           }
; CHECK:         }
; CHECK-LABEL:   mpir.pattern {
; CHECK:           %[[VAR_0:.*]] = mpir.var "n" : <Nat>
; CHECK:           %[[TYPE_0:.*]] = mpir.type.meta_int %[[VAR_0]] : (!mpir.sort<Nat>) -> !mpir.sort<Type>
; CHECK:           %[[VAR_1:.*]] = mpir.var "x" : <Operand>
; CHECK:           %[[INT_0:.*]] = mpir.int 2 : ui2 : <Value>
; CHECK:           %[[INST_0:.*]] = mpir.inst <udiv> (%[[TYPE_0]], %[[VAR_1]], %[[TYPE_0]], %[[INT_0]]) <result_name = "d", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Value>) -> !mpir.sort<Instruction>
; CHECK:           %[[TYPE_1:.*]] = mpir.type.meta_int %[[VAR_0]] : (!mpir.sort<Nat>) -> !mpir.sort<Type>
; CHECK:           %[[VAR_2:.*]] = mpir.var "y" : <Operand>
; CHECK:           %[[ALT_0:.*]] = mpir.alt {
; CHECK:             %[[INST_1:.*]] = mpir.inst <add> (%[[TYPE_1]], %[[INST_0]], %[[TYPE_1]], %[[VAR_2]]) <result_name = "s", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Instruction>, !mpir.sort<Type>, !mpir.sort<Operand>) -> !mpir.sort<Instruction>
; CHECK:             mpir.yield %[[INST_1]] : <Instruction>
; CHECK:           }, {
; CHECK:             %[[INST_2:.*]] = mpir.inst <add> (%[[TYPE_1]], %[[VAR_2]], %[[TYPE_1]], %[[INST_0]]) <result_name = "s", flags = [], flag_modes = [], operand_kinds = [0, 0]> : (!mpir.sort<Type>, !mpir.sort<Operand>, !mpir.sort<Type>, !mpir.sort<Instruction>) -> !mpir.sort<Instruction>
; CHECK:             mpir.yield %[[INST_2]] : <Instruction>
; CHECK:           } attributes {commuted, result_name = "s"} : <Instruction>
; CHECK:           %[[READ_0:.*]] = mpir_expr.read %[[VAR_0]] : (!mpir.sort<Nat>) -> !mpir.sort<Integer>
; CHECK:           %[[INT_1:.*]] = mpir_expr.int 1 : ui64 : <Integer>
; CHECK:           %[[CALL_0:.*]] = mpir_expr.call call "ugt"(%[[READ_0]], %[[INT_1]]) anchor %[[ALT_0]] : (!mpir.sort<Integer>, !mpir.sort<Integer>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
; CHECK:           mpir.require %[[CALL_0]] : <Boolean>
; CHECK:         }
; CHECK-LABEL:   mpir_plan.matcher <slot_names = ["n", "x", "%d", "y", "%s"], slot_kinds = [0, 0, 1, 0, 1], slot_sorts = [6, 2, 3, 2, 3], slot_locs = [{{.*}}, {{.*}}, {{.*}}, {{.*}}, {{.*}}]> {
; CHECK:           %[[FOREACH_INSTRUCTION_0:.*]] = mpir_plan.foreach_instruction
; CHECK:           mpir_plan.either {
; CHECK:             mpir_plan.check_opcode %[[FOREACH_INSTRUCTION_0]], <add>
; CHECK:             mpir_plan.bind %[[FOREACH_INSTRUCTION_0]] -> 4
; CHECK:             mpir_plan.check_operand_count %[[FOREACH_INSTRUCTION_0]], 2
; CHECK:             %[[GET_OPERAND_0:.*]] = mpir_plan.get_operand %[[FOREACH_INSTRUCTION_0]][0]
; CHECK:             %[[GET_TYPE_0:.*]] = mpir_plan.get_type %[[GET_OPERAND_0]]
; CHECK:             mpir_plan.check_type %[[GET_TYPE_0]], [2, 0, 0]
; CHECK:             mpir_plan.check_opcode %[[GET_OPERAND_0]], <udiv>
; CHECK:             mpir_plan.bind %[[GET_OPERAND_0]] -> 2
; CHECK:             mpir_plan.check_operand_count %[[GET_OPERAND_0]], 2
; CHECK:             %[[GET_OPERAND_1:.*]] = mpir_plan.get_operand %[[GET_OPERAND_0]][0]
; CHECK:             %[[GET_TYPE_1:.*]] = mpir_plan.get_type %[[GET_OPERAND_1]]
; CHECK:             mpir_plan.check_type %[[GET_TYPE_1]], [2, 0, 0]
; CHECK:             mpir_plan.bind %[[GET_OPERAND_1]] -> 1 <sort = 2>
; CHECK:             %[[GET_OPERAND_2:.*]] = mpir_plan.get_operand %[[GET_OPERAND_0]][1]
; CHECK:             %[[GET_TYPE_2:.*]] = mpir_plan.get_type %[[GET_OPERAND_2]]
; CHECK:             mpir_plan.check_type %[[GET_TYPE_2]], [2, 0, 0]
; CHECK:             mpir_plan.check_constant %[[GET_OPERAND_2]], 2 : ui2
; CHECK:             %[[GET_OPERAND_3:.*]] = mpir_plan.get_operand %[[FOREACH_INSTRUCTION_0]][1]
; CHECK:             %[[GET_TYPE_3:.*]] = mpir_plan.get_type %[[GET_OPERAND_3]]
; CHECK:             mpir_plan.check_type %[[GET_TYPE_3]], [2, 0, 0]
; CHECK:             mpir_plan.bind %[[GET_OPERAND_3]] -> 3 <sort = 2>
; CHECK:             mpir_plan.yield
; CHECK:           }, {
; CHECK:             mpir_plan.check_opcode %[[FOREACH_INSTRUCTION_0]], <add>
; CHECK:             mpir_plan.bind %[[FOREACH_INSTRUCTION_0]] -> 4
; CHECK:             mpir_plan.check_operand_count %[[FOREACH_INSTRUCTION_0]], 2
; CHECK:             %[[GET_OPERAND_4:.*]] = mpir_plan.get_operand %[[FOREACH_INSTRUCTION_0]][0]
; CHECK:             %[[GET_TYPE_4:.*]] = mpir_plan.get_type %[[GET_OPERAND_4]]
; CHECK:             mpir_plan.check_type %[[GET_TYPE_4]], [2, 0, 0]
; CHECK:             mpir_plan.bind %[[GET_OPERAND_4]] -> 3 <sort = 2>
; CHECK:             %[[GET_OPERAND_5:.*]] = mpir_plan.get_operand %[[FOREACH_INSTRUCTION_0]][1]
; CHECK:             %[[GET_TYPE_5:.*]] = mpir_plan.get_type %[[GET_OPERAND_5]]
; CHECK:             mpir_plan.check_type %[[GET_TYPE_5]], [2, 0, 0]
; CHECK:             mpir_plan.check_opcode %[[GET_OPERAND_5]], <udiv>
; CHECK:             mpir_plan.bind %[[GET_OPERAND_5]] -> 2
; CHECK:             mpir_plan.check_operand_count %[[GET_OPERAND_5]], 2
; CHECK:             %[[GET_OPERAND_6:.*]] = mpir_plan.get_operand %[[GET_OPERAND_5]][0]
; CHECK:             %[[GET_TYPE_6:.*]] = mpir_plan.get_type %[[GET_OPERAND_6]]
; CHECK:             mpir_plan.check_type %[[GET_TYPE_6]], [2, 0, 0]
; CHECK:             mpir_plan.bind %[[GET_OPERAND_6]] -> 1 <sort = 2>
; CHECK:             %[[GET_OPERAND_7:.*]] = mpir_plan.get_operand %[[GET_OPERAND_5]][1]
; CHECK:             %[[GET_TYPE_7:.*]] = mpir_plan.get_type %[[GET_OPERAND_7]]
; CHECK:             mpir_plan.check_type %[[GET_TYPE_7]], [2, 0, 0]
; CHECK:             mpir_plan.check_constant %[[GET_OPERAND_7]], 2 : ui2
; CHECK:             mpir_plan.yield
; CHECK:           }
; CHECK:           %[[SLOT_0:.*]] = mpir_plan.slot 0 {var_name = "n"} : <Nat>
; CHECK:           %[[READ_0:.*]] = mpir_expr.read %[[SLOT_0]] : (!mpir.sort<Nat>) -> !mpir.sort<Integer>
; CHECK:           %[[INT_0:.*]] = mpir_expr.int 1 : ui64 : <Integer>
; CHECK:           %[[SLOT_1:.*]] = mpir_plan.slot 4 {result_name = "s"} : <Instruction>
; CHECK:           %[[CALL_0:.*]] = mpir_expr.call call "ugt"(%[[READ_0]], %[[INT_0]]) anchor %[[SLOT_1]] : (!mpir.sort<Integer>, !mpir.sort<Integer>, !mpir.sort<Instruction>) -> !mpir.sort<Boolean>
; CHECK:           mpir_plan.check %[[CALL_0]] : <Boolean>
; CHECK:           mpir_plan.emit
; CHECK:         }
; mpir-to-plan: a root is matched against every instruction, an instruction
; matcher checks its opcode, binds itself and matches its operands in order,
; and the alternatives of ':c' are alternatives of the plan.
; RUN: %metaphir-parse --emit=mlir %s | %metaphir-opt --mpir-lower --mpir-to-plan | FileCheck %s

%d = udiv i?n ?x, 2
%s = add:c i?n %d, ?y
;; ugt(?n, 1)

