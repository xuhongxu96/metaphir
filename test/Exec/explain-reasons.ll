; Why a function has no structural match, as --explain says: each reason a
; pattern's features can lack in a function, in turn.
; RUN: split-file %s %t
; RUN: %metaphir-match --explain %t/no-instruction.mpir %t/ir.ll | FileCheck %s --check-prefix=NOINST
; RUN: %metaphir-match --explain %t/edge.mpir %t/ir.ll | FileCheck %s --check-prefix=EDGE
; RUN: %metaphir-match --explain %t/sibling.mpir %t/ir.ll | FileCheck %s --check-prefix=SIBLING
; RUN: %metaphir-match --explain %t/global.mpir %t/ir.ll | FileCheck %s --check-prefix=GLOBAL
; RUN: %metaphir-match --explain %t/flag.mpir %t/ir.ll | FileCheck %s --check-prefix=FLAG
; RUN: %metaphir-match --explain %t/constant.mpir %t/ir.ll | FileCheck %s --check-prefix=CONST
; RUN: %metaphir-match --explain %t/types.mpir %t/ir.ll | FileCheck %s --check-prefix=TYPES
; RUN: %metaphir-match --explain %t/connected.mpir %t/ir.ll | FileCheck %s --check-prefix=CONNECT

;--- no-instruction.mpir
%r = mul i32 ?x, ?y
;--- edge.mpir
%a = add i32 ?x, ?y
%b = mul i32 ?z, ?w
%c = mul i32 %a, ?z
;--- sibling.mpir
%a = add i32 ?x, ?y
%b = mul i32 ?x, ?z
;--- global.mpir
%c = call i32 @callee(i32 ?x)
;--- flag.mpir
%a = add nsw i32 ?x, ?y
;--- constant.mpir
%a = add i32 ?x, 5
;--- types.mpir
%a = add i32 ?x, ?y
%b = add i64 ?z, ?w
;--- connected.mpir
%a = add i32 ?x, ?y
%b = mul i32 ?z, ?w
%c = sub i32 %a, %b

;--- ir.ll
declare i32 @callee(i32)
declare i32 @other(i32)
; The instructions of each pattern are there; what is missing is named.
define i32 @edge(i32 %p, i32 %q) {
  %a = add i32 %p, %q
  %m = mul i32 %q, %q
  %r = sub i32 %m, %m
  ret i32 %r
}
; NOINST: target 0: @edge
; NOINST-NEXT:   match 0:
; NOINST-NEXT:     {?x = %q, ?y = %q}

; EDGE: target 0: @edge
; EDGE-NEXT:   no match
; EDGE-NEXT:   no structural match: no `mul` in it has an `add` operand

; SIBLING: target 0: @edge
; SIBLING-NEXT:   no match
; SIBLING-NEXT:   no structural match: ?x would be both %p and %q

; GLOBAL: target 0: @edge
; GLOBAL-NEXT:   no match
; GLOBAL-NEXT:   no structural match: it has no `call`

; FLAG: target 0: @edge
; FLAG-NEXT:   no match
; FLAG-NEXT:   no structural match: no `add` in it has nsw and has an i32 result

; CONST: target 0: @edge
; CONST-NEXT:   no match
; CONST-NEXT:   no structural match: no `add` in it has the constant operand the pattern gives it

; TYPES: target 0: @edge
; TYPES-NEXT:   no match
; TYPES-NEXT:   no structural match: no `add` in it has an i64 result

; CONNECT: target 0: @edge
; CONNECT-NEXT:   no match
; CONNECT-NEXT:   no structural match: no `sub` in it has an `add` operand

define i32 @sibling(i32 %p, i32 %q) {
  %a = add i32 %p, 1
  %m = mul i32 %q, 2
  %r = sub i32 %a, %m
  ret i32 %r
}
; NOINST-NEXT: target 1: @sibling
; NOINST-NEXT:   match 0:
; NOINST-NEXT:     {?x = %q, ?y = 2}

; EDGE-NEXT: target 1: @sibling
; EDGE-NEXT:   no match
; EDGE-NEXT:   no structural match: no `mul` in it has an `add` operand

; SIBLING-NEXT: target 1: @sibling
; SIBLING-NEXT:   no match
; SIBLING-NEXT:   no structural match: no value in it is used by both an `add` and a `mul`

; GLOBAL-NEXT: target 1: @sibling
; GLOBAL-NEXT:   no match
; GLOBAL-NEXT:   no structural match: it has no `call`

; FLAG-NEXT: target 1: @sibling
; FLAG-NEXT:   no match
; FLAG-NEXT:   no structural match: no `add` in it has nsw and has an i32 result

; CONST-NEXT: target 1: @sibling
; CONST-NEXT:   no match
; CONST-NEXT:   no structural match: no `add` in it has the constant operand the pattern gives it

; TYPES-NEXT: target 1: @sibling
; TYPES-NEXT:   no match
; TYPES-NEXT:   no structural match: no `add` in it has an i64 result

; CONNECT-NEXT: target 1: @sibling
; CONNECT-NEXT:   match 0:
; CONNECT-NEXT:     {?w = 2, ?x = %p, ?y = 1, ?z = %q}

define i32 @global(i32 %p) {
  %a = add i32 %p, %p
  %m = mul i32 %a, %a
  %c = call i32 @other(i32 %m)
  ret i32 %c
}
; NOINST-NEXT: target 2: @global
; NOINST-NEXT:   match 0:
; NOINST-NEXT:     {?x = %a, ?y = %a}

; EDGE-NEXT: target 2: @global
; EDGE-NEXT:   match 0:
; EDGE-NEXT:     {?w = %a, ?x = %p, ?y = %p, ?z = %a}

; SIBLING-NEXT: target 2: @global
; SIBLING-NEXT:   no match
; SIBLING-NEXT:   no structural match: no value in it is used by both an `add` and a `mul`

; GLOBAL-NEXT: target 2: @global
; GLOBAL-NEXT:   no match
; GLOBAL-NEXT:   no structural match: it uses no `@callee`

; FLAG-NEXT: target 2: @global
; FLAG-NEXT:   no match
; FLAG-NEXT:   no structural match: no `add` in it has nsw and has an i32 result

; CONST-NEXT: target 2: @global
; CONST-NEXT:   no match
; CONST-NEXT:   no structural match: no `add` in it has the constant operand the pattern gives it

; TYPES-NEXT: target 2: @global
; TYPES-NEXT:   no match
; TYPES-NEXT:   no structural match: no `add` in it has an i64 result

; CONNECT-NEXT: target 2: @global
; CONNECT-NEXT:   no match
; CONNECT-NEXT:   no structural match: it has no `sub`

define i32 @connected(i32 %p, i32 %q) {
  %a = add i32 %p, %q
  %m = mul i32 %p, %q
  %r = sub i32 %p, %q
  ret i32 %r
}
; NOINST-NEXT: target 3: @connected
; NOINST-NEXT:   match 0:
; NOINST-NEXT:     {?x = %p, ?y = %q}
; NOINST-NOT: {{.}}

; EDGE-NEXT: target 3: @connected
; EDGE-NEXT:   no match
; EDGE-NEXT:   no structural match: no `mul` in it has an `add` operand
; EDGE-NOT: {{.}}

; SIBLING-NEXT: target 3: @connected
; SIBLING-NEXT:   match 0:
; SIBLING-NEXT:     {?x = %p, ?y = %q, ?z = %q}
; SIBLING-NOT: {{.}}

; GLOBAL-NEXT: target 3: @connected
; GLOBAL-NEXT:   no match
; GLOBAL-NEXT:   no structural match: it has no `call`
; GLOBAL-NOT: {{.}}

; FLAG-NEXT: target 3: @connected
; FLAG-NEXT:   no match
; FLAG-NEXT:   no structural match: no `add` in it has nsw and has an i32 result
; FLAG-NOT: {{.}}

; CONST-NEXT: target 3: @connected
; CONST-NEXT:   no match
; CONST-NEXT:   no structural match: no `add` in it has the constant operand the pattern gives it
; CONST-NOT: {{.}}

; TYPES-NEXT: target 3: @connected
; TYPES-NEXT:   no match
; TYPES-NEXT:   no structural match: no `add` in it has an i64 result
; TYPES-NOT: {{.}}

; CONNECT-NEXT: target 3: @connected
; CONNECT-NEXT:   no match
; CONNECT-NEXT:   no structural match: no `sub` in it has an `add` operand
; CONNECT-NOT: {{.}}
