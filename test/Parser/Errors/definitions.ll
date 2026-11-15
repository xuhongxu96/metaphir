; NOTE: CHECK lines are written by hand; update_test_check.py skips this file.
; What the parser rejects: definitions. Each case is a pattern file of its own.
; RUN: split-file %s %t
; RUN: not %metaphir-parse %t/constraint-name.mpir 2>&1 | FileCheck %s --check-prefix=CONSTRAINT-NAME
; CONSTRAINT-NAME: constraint-name.mpir:1:12: error: expected constraint name, which must be an identifier and not a keyword
; RUN: not %metaphir-parse %t/constraint-open.mpir 2>&1 | FileCheck %s --check-prefix=CONSTRAINT-OPEN
; CONSTRAINT-OPEN: constraint-open.mpir:1:14: error: expected '(' after constraint name (got '?v')
; RUN: not %metaphir-parse %t/constraint-parameter.mpir 2>&1 | FileCheck %s --check-prefix=CONSTRAINT-PARAMETER
; CONSTRAINT-PARAMETER: constraint-parameter.mpir:1:14: error: expected '?' parameter meta variable
; RUN: not %metaphir-parse %t/constraint-duplicate-parameter.mpir 2>&1 | FileCheck %s --check-prefix=CONSTRAINT-DUPLICATE-PARAMETER
; CONSTRAINT-DUPLICATE-PARAMETER: constraint-duplicate-parameter.mpir:1:18: error: duplicate parameter '?v' in constraint declaration
; RUN: not %metaphir-parse %t/constraint-close.mpir 2>&1 | FileCheck %s --check-prefix=CONSTRAINT-CLOSE
; CONSTRAINT-CLOSE: constraint-close.mpir:1:17: error: expected ')' after parameters (got '{')
; RUN: not %metaphir-parse %t/constraint-brace.mpir 2>&1 | FileCheck %s --check-prefix=CONSTRAINT-BRACE
; CONSTRAINT-BRACE: constraint-brace.mpir:2:3: error: expected '{' before constraint body (got 'true')
; RUN: not %metaphir-parse %t/constraint-body.mpir 2>&1 | FileCheck %s --check-prefix=CONSTRAINT-BODY
; CONSTRAINT-BODY: constraint-body.mpir:2:3: error: expected constraint expression
; RUN: not %metaphir-parse %t/constraint-end.mpir 2>&1 | FileCheck %s --check-prefix=CONSTRAINT-END
; CONSTRAINT-END: constraint-end.mpir:4:1: error: expected '}' after constraint body (got end of file)
; RUN: not %metaphir-parse %t/constraint-extra.mpir 2>&1 | FileCheck %s --check-prefix=CONSTRAINT-EXTRA
; CONSTRAINT-EXTRA: constraint-extra.mpir:2:8: error: expected '}' after constraint body (got 'true')
; RUN: not %metaphir-parse %t/metaflag-name.mpir 2>&1 | FileCheck %s --check-prefix=METAFLAG-NAME
; METAFLAG-NAME: metaflag-name.mpir:1:10: error: expected ':' followed by a metaflag name
; RUN: not %metaphir-parse %t/metaflag-subject.mpir 2>&1 | FileCheck %s --check-prefix=METAFLAG-SUBJECT
; METAFLAG-SUBJECT: metaflag-subject.mpir:1:15: error: a metaflag needs a '?' parameter for its subject
; RUN: not %metaphir-parse %t/metaflag-parameter.mpir 2>&1 | FileCheck %s --check-prefix=METAFLAG-PARAMETER
; METAFLAG-PARAMETER: metaflag-parameter.mpir:1:13: error: expected '?' parameter meta variable
; RUN: not %metaphir-parse %t/metaflag-body.mpir 2>&1 | FileCheck %s --check-prefix=METAFLAG-BODY
; METAFLAG-BODY: metaflag-body.mpir:2:3: error: expected constraint expression
; RUN: not %metaphir-parse %t/metaflag-result.mpir 2>&1 | FileCheck %s --check-prefix=METAFLAG-RESULT
; METAFLAG-RESULT: metaflag-result.mpir:2:5: error: constraint must have a boolean result
; RUN: not %metaphir-parse %t/metaflag-placement.mpir 2>&1 | FileCheck %s --check-prefix=METAFLAG-PLACEMENT
; METAFLAG-PLACEMENT: metaflag-placement.mpir:1:12: error: expected '(' after metaflag name (got ':f')
; RUN: not %metaphir-parse %t/metaflag-end.mpir 2>&1 | FileCheck %s --check-prefix=METAFLAG-END
; METAFLAG-END: metaflag-end.mpir:4:1: error: expected '}' after metaflag body (got end of file)
; RUN: not %metaphir-parse %t/match-commutative-tag.mpir 2>&1 | FileCheck %s --check-prefix=MATCH-COMMUTATIVE-TAG
; MATCH-COMMUTATIVE-TAG: match-commutative-tag.mpir:1:6: error: expected ':c' in match declaration
; RUN: not %metaphir-parse %t/match-name.mpir 2>&1 | FileCheck %s --check-prefix=MATCH-NAME
; MATCH-NAME: match-name.mpir:1:7: error: expected matcher name in match declaration, which must be an identifier and not a keyword
; RUN: not %metaphir-parse %t/match-flags-open.mpir 2>&1 | FileCheck %s --check-prefix=MATCH-FLAGS-OPEN
; MATCH-FLAGS-OPEN: match-flags-open.mpir:1:9: error: expected '[' before supported flags (got 'Binary')
; RUN: not %metaphir-parse %t/match-flag-name.mpir 2>&1 | FileCheck %s --check-prefix=MATCH-FLAG-NAME
; MATCH-FLAG-NAME: match-flag-name.mpir:1:10: error: expected semantic flag name
; RUN: not %metaphir-parse %t/match-flags-close.mpir 2>&1 | FileCheck %s --check-prefix=MATCH-FLAGS-CLOSE
; MATCH-FLAGS-CLOSE: match-flags-close.mpir:1:14: error: expected ']' after supported flags (got 'Binary')
; RUN: not %metaphir-parse %t/match-archetype.mpir 2>&1 | FileCheck %s --check-prefix=MATCH-ARCHETYPE
; MATCH-ARCHETYPE: match-archetype.mpir:1:12: error: expected archetype 'Unary', 'Nary', 'Binary' or 'Cast'
; RUN: not %metaphir-parse %t/match-commutative-unary.mpir 2>&1 | FileCheck %s --check-prefix=MATCH-COMMUTATIVE-UNARY
; MATCH-COMMUTATIVE-UNARY: match-commutative-unary.mpir:1:20: error: only 'Binary' matchers can be declared commutative with ':c'
; RUN: not %metaphir-parse %t/match-parameters-open.mpir 2>&1 | FileCheck %s --check-prefix=MATCH-PARAMETERS-OPEN
; MATCH-PARAMETERS-OPEN: match-parameters-open.mpir:1:19: error: expected '(' before parameter list (got '?ty')
; RUN: not %metaphir-parse %t/match-brace.mpir 2>&1 | FileCheck %s --check-prefix=MATCH-BRACE
; MATCH-BRACE: match-brace.mpir:2:3: error: expected '{' to start match branch (got '%ret')
; RUN: not %metaphir-parse %t/match-body.mpir 2>&1 | FileCheck %s --check-prefix=MATCH-BODY
; MATCH-BODY: match-body.mpir:2:21: error: expected ',' between operands (got '?b')
; RUN: not %metaphir-parse %t/match-empty-branch.mpir 2>&1 | FileCheck %s --check-prefix=MATCH-EMPTY-BRANCH
; MATCH-EMPTY-BRANCH: match-empty-branch.mpir:2:1: error: match branch must contain at least one instruction
; RUN: not %metaphir-parse %t/match-two-rets.mpir 2>&1 | FileCheck %s --check-prefix=MATCH-TWO-RETS
; MATCH-TWO-RETS: match-two-rets.mpir:4:3: error: duplicate instruction result '%ret'
; RUN: not %metaphir-parse %t/match-branch-flag.mpir 2>&1 | FileCheck %s --check-prefix=MATCH-BRANCH-FLAG
; MATCH-BRANCH-FLAG: match-branch-flag.mpir:3:7: error: flag 'exact' is not declared in matcher's supported flags
; RUN: not %metaphir-parse %t/match-branch-flag-value.mpir 2>&1 | FileCheck %s --check-prefix=MATCH-BRANCH-FLAG-VALUE
; MATCH-BRANCH-FLAG-VALUE: match-branch-flag-value.mpir:3:13: error: expected 'true' or 'false' after '='
; RUN: not %metaphir-parse %t/match-branch-close.mpir 2>&1 | FileCheck %s --check-prefix=MATCH-BRANCH-CLOSE
; MATCH-BRANCH-CLOSE: match-branch-close.mpir:3:18: error: expected ']' after branch flags (got '{')
; RUN: not %metaphir-parse %t/match-branch-brace.mpir 2>&1 | FileCheck %s --check-prefix=MATCH-BRANCH-BRACE
; MATCH-BRANCH-BRACE: match-branch-brace.mpir:3:5: error: expected type
; RUN: not %metaphir-parse %t/match-end.mpir 2>&1 | FileCheck %s --check-prefix=MATCH-END
; MATCH-END: match-end.mpir:4:1: error: expected '}' to end match branch (got end of file)
; RUN: not %metaphir-parse %t/match-type-parameter.mpir 2>&1 | FileCheck %s --check-prefix=MATCH-TYPE-PARAMETER
; MATCH-TYPE-PARAMETER: match-type-parameter.mpir:1:20: error: expected type
; RUN: not %metaphir-parse %t/match-parameters-close.mpir 2>&1 | FileCheck %s --check-prefix=MATCH-PARAMETERS-CLOSE
; MATCH-PARAMETERS-CLOSE: match-parameters-close.mpir:1:31: error: expected ')' after parameter list (got '{')
; RUN: not %metaphir-parse %t/match-branch-flag-name.mpir 2>&1 | FileCheck %s --check-prefix=MATCH-BRANCH-FLAG-NAME
; MATCH-BRANCH-FLAG-NAME: match-branch-flag-name.mpir:3:7: error: expected semantic flag name

;--- constraint-name.mpir
constraint (?v) {
  true
}

;--- constraint-open.mpir
constraint f ?v {
  true
}

;--- constraint-parameter.mpir
constraint f(v) {
  true
}

;--- constraint-duplicate-parameter.mpir
constraint f(?v, ?v) {
  true
}

;--- constraint-close.mpir
constraint f(?v {
  true
}

;--- constraint-brace.mpir
constraint f(?v)
  true
}

;--- constraint-body.mpir
constraint f(?v) {
  )
}

;--- constraint-end.mpir
constraint f(?v) {
  true

;--- constraint-extra.mpir
constraint f(?v) {
  true true
}

;--- metaflag-name.mpir
metaflag f(?v) {
  true
}

;--- metaflag-subject.mpir
metaflag :f() {
  true
}

;--- metaflag-parameter.mpir
metaflag :f(v) {
  true
}

;--- metaflag-body.mpir
metaflag :f(?v) {
  )
}

;--- metaflag-result.mpir
metaflag :f(?v) {
  1 + 2
}

;--- metaflag-placement.mpir
metaflag:x :f(?v) {
  true
}

;--- metaflag-end.mpir
metaflag :f(?v) {
  true

;--- match-commutative-tag.mpir
match:x m [] Binary (?ty ?a, ?b) {
  %ret = add ?ty ?a, ?b
}

;--- match-name.mpir
match [] Binary (?ty ?a, ?b) {
  %ret = add ?ty ?a, ?b
}

;--- match-flags-open.mpir
match m Binary (?ty ?a, ?b) {
  %ret = add ?ty ?a, ?b
}

;--- match-flag-name.mpir
match m [1] Binary (?ty ?a, ?b) {
  %ret = add ?ty ?a, ?b
}

;--- match-flags-close.mpir
match m [nsw Binary (?ty ?a, ?b) {
  %ret = add ?ty ?a, ?b
}

;--- match-archetype.mpir
match m [] Ternary (?ty ?a, ?b) {
  %ret = add ?ty ?a, ?b
}

;--- match-commutative-unary.mpir
match:c m [] Unary (?ty ?a) {
  %ret = freeze ?ty ?a
}

;--- match-parameters-open.mpir
match m [] Binary ?ty ?a, ?b {
  %ret = add ?ty ?a, ?b
}

;--- match-brace.mpir
match m [] Binary (?ty ?a, ?b)
  %ret = add ?ty ?a, ?b
}

;--- match-body.mpir
match m [] Binary (?ty ?a, ?b) {
  %ret = add ?ty ?a ?b
}

;--- match-empty-branch.mpir
match m [] Binary (?ty ?a, ?b) {
}

;--- match-two-rets.mpir
match m [] Binary (?ty ?a, ?b) {
  %ret = add ?ty ?a, ?b
  %ret2 = add ?ty %ret, ?b
  %ret = sub ?ty ?a, ?b
}

;--- match-branch-flag.mpir
match m [nsw] Binary (?ty ?a, ?b) {
  %ret = add ?ty ?a, ?b
} or [exact = true] {
  %ret = sub ?ty ?a, ?b
}

;--- match-branch-flag-value.mpir
match m [nsw] Binary (?ty ?a, ?b) {
  %ret = add ?ty ?a, ?b
} or [nsw = 1] {
  %ret = sub ?ty ?a, ?b
}

;--- match-branch-close.mpir
match m [nsw] Binary (?ty ?a, ?b) {
  %ret = add ?ty ?a, ?b
} or [nsw = true {
  %ret = sub ?ty ?a, ?b
}

;--- match-branch-brace.mpir
match m [nsw] Binary (?ty ?a, ?b) {
  %ret = add ?ty ?a, ?b
} or
  %ret = sub ?ty ?a, ?b
}

;--- match-end.mpir
match m [] Binary (?ty ?a, ?b) {
  %ret = add ?ty ?a, ?b

;--- match-type-parameter.mpir
match m [] Binary () ?a, ?b) {
  %ret = add i32 ?a, ?b
}

;--- match-parameters-close.mpir
match m [] Binary (?ty ?a, ?b {
  %ret = add ?ty ?a, ?b
}

;--- match-branch-flag-name.mpir
match m [nsw] Binary (?ty ?a, ?b) {
  %ret = add ?ty ?a, ?b
} or [1 = true] {
  %ret = sub ?ty ?a, ?b
}

