; Constants wider than 64 bits round-trip; under a sanitizer build
; (METAPHIR_USE_SANITIZER=address) this also checks their storage is freed.
; RUN: %metaphir-parse %s | FileCheck %s

add i128 ?x, 340282366920938463463374607431768211455
; CHECK: add i128 ?x, 340282366920938463463374607431768211455
