; NOTE: CHECK lines are written by hand; update_test_check.py skips this file.
; mpir-to-plan: a root is matched against every instruction, an instruction
; matcher checks its opcode, binds itself and matches its operands in order,
; and the alternatives of ':c' are alternatives of the plan.
; RUN: %metaphir-parse --engine=mlir --emit=mlir %s | %metaphir-opt --mpir-lower --mpir-to-plan | FileCheck %s

%d = udiv i?n ?x, 2
%s = add:c i?n %d, ?y
;; ugt(?n, 1)

; CHECK:      mpir_plan.matcher <slot_names = ["n", "x", "%d", "y", "%s"]
; CHECK-NEXT:   %[[ROOT:.*]] = mpir_plan.foreach_instruction
; CHECK-NEXT:   mpir_plan.either {
; CHECK-NEXT:     mpir_plan.check_opcode %[[ROOT]], <add>
; CHECK-NEXT:     mpir_plan.bind %[[ROOT]] -> 4
; CHECK-NEXT:     mpir_plan.check_operand_count %[[ROOT]], 2
; CHECK-NEXT:     %[[LHS:.*]] = mpir_plan.get_operand %[[ROOT]][0]
; CHECK-NEXT:     %[[LHSTY:.*]] = mpir_plan.get_type %[[LHS]]
; CHECK-NEXT:     mpir_plan.check_type %[[LHSTY]], [2, 0, 0]
; CHECK-NEXT:     mpir_plan.check_opcode %[[LHS]], <udiv>
; CHECK:          mpir_plan.yield
; CHECK-NEXT:   }, {
; CHECK-NEXT:     mpir_plan.check_opcode %[[ROOT]], <add>
; CHECK:          %[[RHS:.*]] = mpir_plan.get_operand %[[ROOT]][1]
; CHECK:          mpir_plan.check_opcode %[[RHS]], <udiv>
; CHECK:          mpir_plan.yield
; CHECK-NEXT:   }
; CHECK:        mpir_plan.check %{{.*}} : <Boolean>
; CHECK-NEXT:   mpir_plan.emit
