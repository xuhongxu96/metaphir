; RUN: not %metaphir-parse %s 2>&1 | FileCheck %s

; bitwiseLogic is m_BitwiseLogic, which takes no flags; an 'or disjoint' is
; written as such.
%l = bitwiseLogic disjoint i8 ?x, ?y
; CHECK: flag 'disjoint' is not valid for 'bitwiseLogic'
