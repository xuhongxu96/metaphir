; RUN: split-file %s %t
; RUN: %metaphir-match %t/one.mpir %t/input.ll | FileCheck %s --check-prefix=ONE
; RUN: %metaphir-match %t/two.mpir %t/input.ll | FileCheck %s --check-prefix=TWO
; RUN: %metaphir-match %t/two-or-more.mpir %t/input.ll | FileCheck %s --check-prefix=TWOPLUS

; hasNUses and hasNUsesOrMore are Value's: they count uses, not users.

;--- one.mpir
%a = add:?anch i32 ?x, 1
;; hasNUses(?anch, 1)

;--- two.mpir
%a = add:?anch i32 ?x, 1
;; hasNUses(?anch, 2)

;--- two-or-more.mpir
%a = add:?anch i32 ?x, 1
;; hasNUsesOrMore(?anch, 2)

;--- input.ll
declare void @use(i32)
declare void @use2(i32, i32)

define void @once(i32 %x) {
  %a = add i32 %x, 1
  call void @use(i32 %a)
  ret void
}
; ONE: target 0: @once
; ONE-NEXT:   match 0:
; ONE-NEXT:     {?anch = %a, ?x = %x}

; TWO: target 0: @once
; TWO-NEXT:   no match
; TWO-NEXT:   constraint not satisfied: (hasNUses ?anch 2)

; TWOPLUS: target 0: @once
; TWOPLUS-NEXT:   no match
; TWOPLUS-NEXT:   constraint not satisfied: (hasNUsesOrMore ?anch 2)

define void @twice(i32 %x) {
  %a = add i32 %x, 1
  call void @use(i32 %a)
  call void @use(i32 %a)
  ret void
}
; ONE-NEXT: target 1: @twice
; ONE-NEXT:   no match
; ONE-NEXT:   constraint not satisfied: (hasNUses ?anch 1)

; TWO-NEXT: target 1: @twice
; TWO-NEXT:   match 0:
; TWO-NEXT:     {?anch = %a, ?x = %x}

; TWOPLUS-NEXT: target 1: @twice
; TWOPLUS-NEXT:   match 0:
; TWOPLUS-NEXT:     {?anch = %a, ?x = %x}

; One user, two uses.
define void @one_user_twice(i32 %x) {
  %a = add i32 %x, 1
  call void @use2(i32 %a, i32 %a)
  ret void
}
; ONE-NEXT: target 2: @one_user_twice
; ONE-NEXT:   no match
; ONE-NEXT:   constraint not satisfied: (hasNUses ?anch 1)

; TWO-NEXT: target 2: @one_user_twice
; TWO-NEXT:   match 0:
; TWO-NEXT:     {?anch = %a, ?x = %x}

; TWOPLUS-NEXT: target 2: @one_user_twice
; TWOPLUS-NEXT:   match 0:
; TWOPLUS-NEXT:     {?anch = %a, ?x = %x}

define void @thrice(i32 %x) {
  %a = add i32 %x, 1
  call void @use(i32 %a)
  call void @use(i32 %a)
  call void @use(i32 %a)
  ret void
}
; ONE-NEXT: target 3: @thrice
; ONE-NEXT:   no match
; ONE-NEXT:   constraint not satisfied: (hasNUses ?anch 1)
; ONE-NOT: {{.}}

; TWO-NEXT: target 3: @thrice
; TWO-NEXT:   no match
; TWO-NEXT:   constraint not satisfied: (hasNUses ?anch 2)
; TWO-NOT: {{.}}

; TWOPLUS-NEXT: target 3: @thrice
; TWOPLUS-NEXT:   match 0:
; TWOPLUS-NEXT:     {?anch = %a, ?x = %x}
; TWOPLUS-NOT: {{.}}
