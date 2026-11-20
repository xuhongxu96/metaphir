; RUN: not %metaphir-parse %s 2>&1 | FileCheck %s

%cmp = icmp eq i32 ?a, ?b
%branch = br i1 %cmp, label %bb, label ?other
add i32 ?bb, ?a
; CHECK: meta variable '?bb' is used with an incompatible type
