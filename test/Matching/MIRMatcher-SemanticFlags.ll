; RUN: split-file %s %t
; RUN: %metaphir-match %t/pattern.mpir %t/flags.ll %t/no-flags.ll | FileCheck %s

;--- pattern.mpir
%add = add nsw:?nsw nuw:?nuw i32 1, 2
%shift = lshr exact:?exact i32 8, 1
%disjoint = or disjoint:?disjoint i32 1, 2
%slot = alloca inalloca:?inalloca i32, i32 1
%loaded = load volatile:?volatile i32, ptr %slot
%gep = getelementptr inbounds:?inbounds nusw:?nusw nuw:?gep_nuw i32, ptr %slot, i32 0
%extended = zext nneg:?nneg i8 1 to i32
%compare = icmp samesign:?samesign eq i32 1, 2
%fp = fadd fast:?fast nnan:?nnan ninf:?ninf nsz:?nsz arcp:?arcp contract:?contract afn:?afn reassoc:?reassoc float 1.0, 2.0
ret void

;--- flags.ll
define void @all_flags() {
  %add = add nsw nuw i32 1, 2
  %shift = lshr exact i32 8, 1
  %disjoint = or disjoint i32 1, 2
  %slot = alloca inalloca i32
  %loaded = load volatile i32, ptr %slot
  %gep = getelementptr inbounds nusw nuw i32, ptr %slot, i32 0
  %extended = zext nneg i8 1 to i32
  %compare = icmp samesign eq i32 1, 2
  %fp = fadd fast float 1.0, 2.0
  ret void
}
; CHECK: target 0: @all_flags
; CHECK-NEXT:   match 0:
; CHECK-NEXT:     {?afn = true, ?arcp = true, ?contract = true, ?disjoint = true, ?exact = true, ?fast = true, ?gep_nuw = true, ?inalloca = true, ?inbounds = true, ?ninf = true, ?nnan = true, ?nneg = true, ?nsw = true, ?nsz = true, ?nusw = true, ?nuw = true, ?reassoc = true, ?samesign = true, ?volatile = true}

;--- no-flags.ll
define void @no_flags() {
  %add = add i32 1, 2
  %shift = lshr i32 8, 1
  %disjoint = or i32 1, 2
  %slot = alloca i32
  %loaded = load i32, ptr %slot
  %gep = getelementptr i32, ptr %slot, i32 0
  %extended = zext i8 1 to i32
  %compare = icmp eq i32 1, 2
  %fp = fadd float 1.0, 2.0
  ret void
}
; CHECK-NEXT: target 1: @no_flags
; CHECK-NEXT:   match 0:
; CHECK-NEXT:     {?afn = false, ?arcp = false, ?contract = false, ?disjoint = false, ?exact = false, ?fast = false, ?gep_nuw = false, ?inalloca = false, ?inbounds = false, ?ninf = false, ?nnan = false, ?nneg = false, ?nsw = false, ?nsz = false, ?nusw = false, ?nuw = false, ?reassoc = false, ?samesign = false, ?volatile = false}
