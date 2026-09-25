; RUN: split-file %s %t
; RUN: %metaphir-match %t/literal.mpir %t/input.ll | FileCheck %s --check-prefix=LIT
; RUN: %metaphir-match %t/meta.mpir %t/input.ll | FileCheck %s --check-prefix=META

; Under treatIntAsVec, a literal integer constant matches a vector splat that
; has poison lanes (like LLVM's m_One/m_Zero). A meta variable bound from a
; splat still requires every lane to be defined.

;--- literal.mpir
;; treatIntAsVec(true)
%shl = shl:?anch i?bits 1, ?y

;--- meta.mpir
;; treatIntAsVec(true)
%shl = shl:?anch i?bits ?c:constantInt, ?y

;--- input.ll
define <2 x i8> @poison_lane(<2 x i8> %y) {
  %r = shl <2 x i8> <i8 1, i8 poison>, %y
  ret <2 x i8> %r
}
; LIT: target 0: @poison_lane
; LIT-NEXT:   match 0:
; LIT-NEXT:     {?anch = %r, ?bits = 8, ?y = %y}

; META: target 0: @poison_lane
; META-NEXT:   no match
; META-NEXT:   constraint not satisfied: (isConstantInt ?c)
