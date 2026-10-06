; RUN: split-file %s %t
; RUN: %metaphir-match %t/sext-like.mpir %t/input.ll | FileCheck %s --check-prefix=SEXT
; RUN: %metaphir-match %t/itofp.mpir %t/input.ll | FileCheck %s --check-prefix=ITOFP
; RUN: %metaphir-match %t/fptoi.mpir %t/input.ll | FileCheck %s --check-prefix=FPTOI
; RUN: %metaphir-match %t/ptr-to-int-or-addr.mpir %t/input.ll | FileCheck %s --check-prefix=PTR

; 'sextLike' is m_SExtLike (sext, or zext nneg), 'itofp' m_IToFP, 'fptoi'
; m_FPToI and 'ptrToIntOrAddr' m_PtrToIntOrAddr.

;--- sext-like.mpir
%r = sextLike:?anch i8 ?x to i32

;--- itofp.mpir
%r = itofp:?anch i32 ?x to float

;--- fptoi.mpir
%r = fptoi:?anch float ?x to i32

;--- ptr-to-int-or-addr.mpir
%r = ptrToIntOrAddr:?anch ptr ?x to i64

;--- input.ll

define i32 @sext(i8 %a) {
  %r = sext i8 %a to i32
  ret i32 %r
}
; SEXT: target 0: @sext
; SEXT-NEXT:   match 0:
; SEXT-NEXT:     {?anch = %r, ?x = %a}

; ITOFP: target 0: @sext
; ITOFP-NEXT:   no match

; FPTOI: target 0: @sext
; FPTOI-NEXT:   no match

; PTR: target 0: @sext
; PTR-NEXT:   no match

define i32 @zext_nneg(i8 %a) {
  %r = zext nneg i8 %a to i32
  ret i32 %r
}
; SEXT-NEXT: target 1: @zext_nneg
; SEXT-NEXT:   match 0:
; SEXT-NEXT:     {?anch = %r, ?x = %a}

; ITOFP-NEXT: target 1: @zext_nneg
; ITOFP-NEXT:   no match

; FPTOI-NEXT: target 1: @zext_nneg
; FPTOI-NEXT:   no match

; PTR-NEXT: target 1: @zext_nneg
; PTR-NEXT:   no match

define i32 @zext(i8 %a) {
  %r = zext i8 %a to i32
  ret i32 %r
}
; SEXT-NEXT: target 2: @zext
; SEXT-NEXT:   no match

; ITOFP-NEXT: target 2: @zext
; ITOFP-NEXT:   no match

; FPTOI-NEXT: target 2: @zext
; FPTOI-NEXT:   no match

; PTR-NEXT: target 2: @zext
; PTR-NEXT:   no match

define float @uitofp(i32 %a) {
  %r = uitofp nneg i32 %a to float
  ret float %r
}
; SEXT-NEXT: target 3: @uitofp
; SEXT-NEXT:   no match

; ITOFP-NEXT: target 3: @uitofp
; ITOFP-NEXT:   match 0:
; ITOFP-NEXT:     {?anch = %r, ?x = %a}

; FPTOI-NEXT: target 3: @uitofp
; FPTOI-NEXT:   no match

; PTR-NEXT: target 3: @uitofp
; PTR-NEXT:   no match

define float @sitofp(i32 %a) {
  %r = sitofp i32 %a to float
  ret float %r
}
; SEXT-NEXT: target 4: @sitofp
; SEXT-NEXT:   no match

; ITOFP-NEXT: target 4: @sitofp
; ITOFP-NEXT:   match 0:
; ITOFP-NEXT:     {?anch = %r, ?x = %a}

; FPTOI-NEXT: target 4: @sitofp
; FPTOI-NEXT:   no match

; PTR-NEXT: target 4: @sitofp
; PTR-NEXT:   no match

define i32 @fptoui(float %a) {
  %r = fptoui float %a to i32
  ret i32 %r
}
; SEXT-NEXT: target 5: @fptoui
; SEXT-NEXT:   no match

; ITOFP-NEXT: target 5: @fptoui
; ITOFP-NEXT:   no match

; FPTOI-NEXT: target 5: @fptoui
; FPTOI-NEXT:   match 0:
; FPTOI-NEXT:     {?anch = %r, ?x = %a}

; PTR-NEXT: target 5: @fptoui
; PTR-NEXT:   no match

define i32 @fptosi(float %a) {
  %r = fptosi float %a to i32
  ret i32 %r
}
; SEXT-NEXT: target 6: @fptosi
; SEXT-NEXT:   no match

; ITOFP-NEXT: target 6: @fptosi
; ITOFP-NEXT:   no match

; FPTOI-NEXT: target 6: @fptosi
; FPTOI-NEXT:   match 0:
; FPTOI-NEXT:     {?anch = %r, ?x = %a}

; PTR-NEXT: target 6: @fptosi
; PTR-NEXT:   no match

define i64 @ptrtoint(ptr %a) {
  %r = ptrtoint ptr %a to i64
  ret i64 %r
}
; SEXT-NEXT: target 7: @ptrtoint
; SEXT-NEXT:   no match

; ITOFP-NEXT: target 7: @ptrtoint
; ITOFP-NEXT:   no match

; FPTOI-NEXT: target 7: @ptrtoint
; FPTOI-NEXT:   no match

; PTR-NEXT: target 7: @ptrtoint
; PTR-NEXT:   match 0:
; PTR-NEXT:     {?anch = %r, ?x = %a}

define i64 @ptrtoaddr(ptr %a) {
  %r = ptrtoaddr ptr %a to i64
  ret i64 %r
}
; SEXT-NEXT: target 8: @ptrtoaddr
; SEXT-NEXT:   no match

; ITOFP-NEXT: target 8: @ptrtoaddr
; ITOFP-NEXT:   no match

; FPTOI-NEXT: target 8: @ptrtoaddr
; FPTOI-NEXT:   no match

; PTR-NEXT: target 8: @ptrtoaddr
; PTR-NEXT:   match 0:
; PTR-NEXT:     {?anch = %r, ?x = %a}
