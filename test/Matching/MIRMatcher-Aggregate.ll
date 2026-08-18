; RUN: split-file %s %t
; RUN: %metaphir-match %t/pattern.mpir %t/match.ll %t/no-match.ll | FileCheck %s

;--- pattern.mpir
extractvalue {i32, {i8, i16}} ?aggregate, ...?indices
; CHECK: target 0: @aggregate_match
; CHECK-NEXT:   match 0:
; CHECK-NEXT:     {?aggregate = %aggregate, ?indices = [1, 0]}
; CHECK-NEXT: target 1: @aggregate_no_match
; CHECK-NEXT:   no match

;--- match.ll
define i8 @aggregate_match({i32, {i8, i16}} %aggregate) {
  %result = extractvalue {i32, {i8, i16}} %aggregate, 1, 0
  ret i8 %result
}

;--- no-match.ll
define i8 @aggregate_no_match({i64, {i8, i16}} %aggregate) {
  %result = extractvalue {i64, {i8, i16}} %aggregate, 1, 0
  ret i8 %result
}
