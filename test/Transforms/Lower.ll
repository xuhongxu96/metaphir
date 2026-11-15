; NOTE: CHECK lines are written by hand; update_test_check.py skips this file.
; The lowering passes: metaflags become constraints, and ':c', ':o' and the
; branches of a 'match' matcher become mpir.alt.
; RUN: split-file %s %t
; RUN: %metaphir-parse --engine=mlir --emit=mlir %t/commutative.mpir | %metaphir-opt --mpir-lower | FileCheck %s --check-prefix=COMMUTATIVE
; RUN: %metaphir-parse --engine=mlir --emit=mlir %t/or-self.mpir | %metaphir-opt --mpir-lower | FileCheck %s --check-prefix=OR-SELF
; RUN: %metaphir-parse --engine=mlir --emit=mlir %t/matcher.mpir | %metaphir-opt --mpir-lower | FileCheck %s --check-prefix=MATCHER

;--- commutative.mpir
%a = add:c i32 ?x:zero, ?y
; Both operand orders, and ':zero' on ?x as a constraint anchored at %a.
; COMMUTATIVE:      %[[ALT:.*]] = mpir.alt {
; COMMUTATIVE-NEXT:   %i_a = "mpir.inst"(%{{.*}}, %x, %{{.*}}, %y)
; COMMUTATIVE-NEXT:   mpir.yield %i_a
; COMMUTATIVE-NEXT: }, {
; COMMUTATIVE-NEXT:   %i_a = "mpir.inst"(%{{.*}}, %y, %{{.*}}, %x)
; COMMUTATIVE-NEXT:   mpir.yield %i_a
; COMMUTATIVE-NEXT: } {commuted, result_name = "a"}
; COMMUTATIVE:      %[[READ:.*]] = mpir_expr.read %x
; COMMUTATIVE-NEXT: %[[ZERO:.*]] = "mpir_expr.call"(%[[READ]], %[[ALT]])
; COMMUTATIVE-NEXT: mpir.require %[[ZERO]]
; COMMUTATIVE-NOT:  #mpir.metaflag

;--- or-self.mpir
%d = sub i32 ?x, ?y
%s = add:?s:o i32 %d, 1
; The add's first operand in its place, which then binds its capture, or
; the add.
; OR-SELF:      mpir.alt {
; OR-SELF-NEXT:   mpir.bind %s, %i_d
; OR-SELF-NEXT:   mpir.yield %i_d
; OR-SELF-NEXT: }, {
; OR-SELF-NEXT:   %i_s = "mpir.inst"
; OR-SELF-NEXT:   mpir.yield %i_s
; OR-SELF-NEXT: } {or_self_of = "add", or_self_region = 0 : i32, result_name = "s"}

;--- matcher.mpir
%r = shr exact:?e i32 ?x, ?y
; One alternative per branch, the root renamed after the use and its flag
; capture the use's.
; MATCHER:      mpir.alt {
; MATCHER-NEXT:   %i_r = "mpir.inst"(%e, %{{.*}}, %x, %{{.*}}, %y) <{{{.*}}opcode = #mpir.opcode<lshr>
; MATCHER-NEXT:   mpir.yield %i_r
; MATCHER-NEXT: }, {
; MATCHER-NEXT:   %i_r = "mpir.inst"(%e, %{{.*}}, %x, %{{.*}}, %y) <{{{.*}}opcode = #mpir.opcode<ashr>
; MATCHER-NEXT:   mpir.yield %i_r
; MATCHER-NEXT: } {result_name = "r"}
; MATCHER-NOT:  mpir.use
