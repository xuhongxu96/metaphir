// RUN: not %metaphir-opt %s 2>&1 | FileCheck %s

// The mpir dialect is registered, so an operation it does not have is
// rejected as its own.
// CHECK: 'mpir.none' found in dialect ('mpir') that does not allow unknown operations
"mpir.none"() : () -> ()
