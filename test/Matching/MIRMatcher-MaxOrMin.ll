; RUN: split-file %s %t
; RUN: %metaphir-match %t/signed-min-max.mpir %t/input.ll | FileCheck %s --check-prefix=SIGNED
; RUN: %metaphir-match %t/any-min-max.mpir %t/input.ll | FileCheck %s --check-prefix=ANY
; RUN: %metaphir-match %t/id.mpir %t/input.ll | FileCheck %s --check-prefix=ID

; 'intrinsic' reads the intrinsic a captured call calls, as '@llvm.?id'
; would bind it; it lets a composite tell which of its branches matched.

;--- signed-min-max.mpir
%m = maxOrMin:?mm:c i32 ?a, ?b
;; intrinsic(?mm) == "llvm.smax" || intrinsic(?mm) == "llvm.smin"

;--- any-min-max.mpir
%m = maxOrMin:?mm i32 ?a, ?b

;--- id.mpir
%m = call:?mm i32 @llvm.?id(i32 ?a, i32 ?b)
;; intrinsic(?mm) == ?id

;--- input.ll

define i32 @smax(i32 %a, i32 %b) {
  %m = call i32 @llvm.smax.i32(i32 %a, i32 %b)
  ret i32 %m
}
; SIGNED: target 0: @smax
; SIGNED-NEXT:   match 0:
; SIGNED-NEXT:     {?a = %a, ?b = %b, ?mm = %m}
; SIGNED-NEXT:   match 1:
; SIGNED-NEXT:     {?a = %b, ?b = %a, ?mm = %m}

; ANY: target 0: @smax
; ANY-NEXT:   match 0:
; ANY-NEXT:     {?a = %a, ?b = %b, ?mm = %m}

; ID: target 0: @smax
; ID-NEXT:   match 0:
; ID-NEXT:     {?a = %a, ?b = %b, ?id = llvm.smax, ?mm = %m}

define i32 @smin(i32 %a, i32 %b) {
  %m = call i32 @llvm.smin.i32(i32 %a, i32 %b)
  ret i32 %m
}
; SIGNED-NEXT: target 1: @smin
; SIGNED-NEXT:   match 0:
; SIGNED-NEXT:     {?a = %a, ?b = %b, ?mm = %m}
; SIGNED-NEXT:   match 1:
; SIGNED-NEXT:     {?a = %b, ?b = %a, ?mm = %m}

; ANY-NEXT: target 1: @smin
; ANY-NEXT:   match 0:
; ANY-NEXT:     {?a = %a, ?b = %b, ?mm = %m}

; ID-NEXT: target 1: @smin
; ID-NEXT:   match 0:
; ID-NEXT:     {?a = %a, ?b = %b, ?id = llvm.smin, ?mm = %m}

define i32 @umax(i32 %a, i32 %b) {
  %m = call i32 @llvm.umax.i32(i32 %a, i32 %b)
  ret i32 %m
}
; SIGNED-NEXT: target 2: @umax
; SIGNED-NEXT:   no match
; SIGNED-NEXT:   constraint not satisfied: (|| (== (intrinsic ?mm) "llvm.smax") (== (intrinsic ?mm) "llvm.smin"))
; SIGNED-NEXT:   constraint not satisfied: (|| (== (intrinsic ?mm) "llvm.smax") (== (intrinsic ?mm) "llvm.smin"))

; ANY-NEXT: target 2: @umax
; ANY-NEXT:   match 0:
; ANY-NEXT:     {?a = %a, ?b = %b, ?mm = %m}

; ID-NEXT: target 2: @umax
; ID-NEXT:   match 0:
; ID-NEXT:     {?a = %a, ?b = %b, ?id = llvm.umax, ?mm = %m}

define i32 @umin(i32 %a, i32 %b) {
  %m = call i32 @llvm.umin.i32(i32 %a, i32 %b)
  ret i32 %m
}
; SIGNED-NEXT: target 3: @umin
; SIGNED-NEXT:   no match
; SIGNED-NEXT:   constraint not satisfied: (|| (== (intrinsic ?mm) "llvm.smax") (== (intrinsic ?mm) "llvm.smin"))
; SIGNED-NEXT:   constraint not satisfied: (|| (== (intrinsic ?mm) "llvm.smax") (== (intrinsic ?mm) "llvm.smin"))

; ANY-NEXT: target 3: @umin
; ANY-NEXT:   match 0:
; ANY-NEXT:     {?a = %a, ?b = %b, ?mm = %m}

; ID-NEXT: target 3: @umin
; ID-NEXT:   match 0:
; ID-NEXT:     {?a = %a, ?b = %b, ?id = llvm.umin, ?mm = %m}

; Not a min or max.
define i32 @uadd_sat(i32 %a, i32 %b) {
  %m = call i32 @llvm.uadd.sat.i32(i32 %a, i32 %b)
  ret i32 %m
}
; SIGNED-NEXT: target 4: @uadd_sat
; SIGNED-NEXT:   no match

; ANY-NEXT: target 4: @uadd_sat
; ANY-NEXT:   no match

; ID-NEXT: target 4: @uadd_sat
; ID-NEXT:   match 0:
; ID-NEXT:     {?a = %a, ?b = %b, ?id = llvm.uadd.sat, ?mm = %m}
