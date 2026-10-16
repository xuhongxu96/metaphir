; RUN: split-file %s %t
; RUN: %metaphir-match %t/select-min-max.mpir %t/input.ll | FileCheck %s --check-prefix=MINMAX
; RUN: %metaphir-match %t/commuted.mpir %t/input.ll | FileCheck %s --check-prefix=COMMUTED

; 'selectMinMax' is an integer min or max as matchSelectPattern finds it:
; select (icmp pred A, B), A, B for a relational pred, in any order.

;--- select-min-max.mpir
%a = add i32 ?p, 1
%s = selectMinMax:?anch i32 %a, ?b

;--- commuted.mpir
%a = add i32 ?p, 1
%s = selectMinMax:?anch:c i32 %a, ?b

;--- input.ll

define i32 @smax(i32 %p, i32 %b) {
  %a = add i32 %p, 1
  %c = icmp sgt i32 %a, %b
  %s = select i1 %c, i32 %a, i32 %b
  ret i32 %s
}
; MINMAX: target 0: @smax
; MINMAX-NEXT:   match 0:
; MINMAX-NEXT:     {?anch = %s, ?b = %b, ?p = %p}

; COMMUTED: target 0: @smax
; COMMUTED-NEXT:   match 0:
; COMMUTED-NEXT:     {?anch = %s, ?b = %b, ?p = %p}

; The compare's operands are swapped.
define i32 @umin_swapped_cmp(i32 %p, i32 %b) {
  %a = add i32 %p, 1
  %c = icmp ugt i32 %b, %a
  %s = select i1 %c, i32 %a, i32 %b
  ret i32 %s
}
; MINMAX-NEXT: target 1: @umin_swapped_cmp
; MINMAX-NEXT:   match 0:
; MINMAX-NEXT:     {?anch = %s, ?b = %b, ?p = %p}

; COMMUTED-NEXT: target 1: @umin_swapped_cmp
; COMMUTED-NEXT:   match 0:
; COMMUTED-NEXT:     {?anch = %s, ?b = %b, ?p = %p}

; The select's arms are swapped.
define i32 @smin_swapped_arms(i32 %p, i32 %b) {
  %a = add i32 %p, 1
  %c = icmp sgt i32 %a, %b
  %s = select i1 %c, i32 %b, i32 %a
  ret i32 %s
}
; MINMAX-NEXT: target 2: @smin_swapped_arms
; MINMAX-NEXT:   no match

; COMMUTED-NEXT: target 2: @smin_swapped_arms
; COMMUTED-NEXT:   match 0:
; COMMUTED-NEXT:     {?anch = %s, ?b = %b, ?p = %p}

; Not a min or max.
define i32 @equality(i32 %p, i32 %b) {
  %a = add i32 %p, 1
  %c = icmp eq i32 %a, %b
  %s = select i1 %c, i32 %a, i32 %b
  ret i32 %s
}
; MINMAX-NEXT: target 3: @equality
; MINMAX-NEXT:   no match
; MINMAX-NEXT:   constraint not satisfied: (! (isEquality ?_s$_pred))

; COMMUTED-NEXT: target 3: @equality
; COMMUTED-NEXT:   no match
; COMMUTED-NEXT:   constraint not satisfied: (! (isEquality ?_s$_pred))

define i32 @other_arm(i32 %p, i32 %b) {
  %a = add i32 %p, 1
  %c = icmp sgt i32 %a, %b
  %s = select i1 %c, i32 %a, i32 %p
  ret i32 %s
}
; MINMAX-NEXT: target 4: @other_arm
; MINMAX-NEXT:   no match
; MINMAX-NOT: {{.}}

; COMMUTED-NEXT: target 4: @other_arm
; COMMUTED-NEXT:   no match
; COMMUTED-NOT: {{.}}
