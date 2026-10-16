; RUN: split-file %s %t
; RUN: %metaphir-match %t/pattern.mpir %t/input.ll | FileCheck %s
; RUN: %metaphir-match %t/pattern-anyblock.mpir %t/input.ll | FileCheck %s --check-prefix=ANYBLOCK
; RUN: %metaphir-match %t/pattern-anyblock2.mpir %t/input.ll | FileCheck %s --check-prefix=ANYBLOCK2
; RUN: %metaphir-match %t/pattern-nomatch.mpir %t/input.ll | FileCheck %s --check-prefix=NOMATCH
; RUN: %metaphir-match %t/pattern-explicit.mpir %t/input.ll | FileCheck %s --check-prefix=EXPLICIT

;--- pattern.mpir
%trunc = trunc i?big ?x to i?small
%sub = sub i?small 0, %trunc
%zext = zext:?anch i?small %sub to i?big

;--- pattern-anyblock.mpir
anyblock:
%trunc = trunc i?big ?x to i?small
anyblock:
%sub = sub i?small 0, %trunc
%zext = zext:?anch i?small %sub to i?big

;--- pattern-anyblock2.mpir
entry:
%trunc = trunc i?big ?x to i?small
anyblock:
%sub = sub i?small 0, %trunc
%zext = zext:?anch i?small %sub to i?big

;--- pattern-nomatch.mpir
entry:
%trunc = trunc i?big ?x to i?small
other:
%sub = sub i?small 0, %trunc
%zext = zext:?anch i?small %sub to i?big

;--- pattern-explicit.mpir
entry:
%trunc = trunc i?big ?x to i?small
other:
%sub = sub i?small 0, %trunc
final:
%zext = zext:?anch i?small %sub to i?big

;--- input.ll
define i128 @cross_block(i128 %x) {
entry:
  %t = trunc i128 %x to i64
  %c = icmp slt i128 %x, 0
  br i1 %c, label %neg, label %end
neg:
  %s = sub i64 0, %t
  br label %end
end:
  %z = zext i64 %s to i128
  ret i128 %z
}
; CHECK: target 0: @cross_block
; CHECK-NEXT:   match 0:
; CHECK-NEXT:     {?anch = %z, ?big = 128, ?small = 64, ?x = %x}
; CHECK-NOT: {{.}}

; ANYBLOCK: target 0: @cross_block
; ANYBLOCK-NEXT:   match 0:
; ANYBLOCK-NEXT:     {?anch = %z, ?big = 128, ?small = 64, ?x = %x}
; ANYBLOCK-NOT: {{.}}

; ANYBLOCK2: target 0: @cross_block
; ANYBLOCK2-NEXT:   match 0:
; ANYBLOCK2-NEXT:     {?anch = %z, ?big = 128, ?entry = %entry, ?small = 64, ?x = %x}
; ANYBLOCK2-NOT: {{.}}

; NOMATCH: target 0: @cross_block
; NOMATCH-NEXT:   no match
; NOMATCH-NOT: {{.}}

; EXPLICIT: target 0: @cross_block
; EXPLICIT-NEXT:   match 0:
; EXPLICIT-NEXT:     {?anch = %z, ?big = 128, ?entry = %entry, ?final = %end, ?other = %neg, ?small = 64, ?x = %x}
; EXPLICIT-NOT: {{.}}
