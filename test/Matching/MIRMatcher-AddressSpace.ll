; 'ptr' matches a pointer in any address space; 'ptr addrspace(N)' only one
; in address space N.
; RUN: split-file %s %t
; RUN: %metaphir-parse %t/specific.mpir | FileCheck %s --check-prefix=PRINT
; RUN: %metaphir-match %t/any.mpir %t/input.ll | FileCheck %s --check-prefix=ANY
; RUN: %metaphir-match %t/specific.mpir %t/input.ll | FileCheck %s --check-prefix=SPECIFIC

;--- any.mpir
%r = load:?anch i32, ptr ?p

;--- specific.mpir
%r = load:?anch i32, ptr addrspace(1) ?p
; PRINT: pattern instructions=1 constraints=0
; PRINT-NEXT: %r = load:?anch i32, ptr addrspace(1) ?p
; PRINT-NEXT: meta ?anch type=Instruction
; PRINT-NEXT: meta ?p type=Value

;--- input.ll
define i32 @generic(ptr %p) {
  %r = load i32, ptr %p
  ret i32 %r
}
; ANY: target 0: @generic
; ANY-NEXT:   match 0:
; ANY-NEXT:     {?anch = %r, ?p = %p}

; SPECIFIC: target 0: @generic
; SPECIFIC-NEXT:   no match

define i32 @global(ptr addrspace(1) %p) {
  %r = load i32, ptr addrspace(1) %p
  ret i32 %r
}
; ANY-NEXT: target 1: @global
; ANY-NEXT:   match 0:
; ANY-NEXT:     {?anch = %r, ?p = %p}

; SPECIFIC-NEXT: target 1: @global
; SPECIFIC-NEXT:   match 0:
; SPECIFIC-NEXT:     {?anch = %r, ?p = %p}
