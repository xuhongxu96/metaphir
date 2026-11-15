; Constants wider than 64 bits round-trip; under a sanitizer build
; (METAPHIR_USE_SANITIZER=address) this also checks their storage is freed.
; RUN: %metaphir-parse %s | FileCheck %s
; CHECK: pattern instructions=1 constraints=0
; CHECK-NEXT: add i128 ?x, 340282366920938463463374607431768211455

add i128 ?x, 340282366920938463463374607431768211455
; CHECK: meta ?x type=Value
