; What the parser rejects: definitions. Each case is a pattern file of its own.
; RUN: split-file %s %t
; RUN: not %metaphir-parse %t/constraint-name.mpir 2>&1 | FileCheck %s --check-prefix=CONSTRAINT-NAME
; RUN: not %metaphir-parse %t/constraint-open.mpir 2>&1 | FileCheck %s --check-prefix=CONSTRAINT-OPEN
; RUN: not %metaphir-parse %t/constraint-parameter.mpir 2>&1 | FileCheck %s --check-prefix=CONSTRAINT-PARAMETER
; RUN: not %metaphir-parse %t/constraint-duplicate-parameter.mpir 2>&1 | FileCheck %s --check-prefix=CONSTRAINT-DUPLICATE-PARAMETER
; RUN: not %metaphir-parse %t/constraint-close.mpir 2>&1 | FileCheck %s --check-prefix=CONSTRAINT-CLOSE
; RUN: not %metaphir-parse %t/constraint-brace.mpir 2>&1 | FileCheck %s --check-prefix=CONSTRAINT-BRACE
; RUN: not %metaphir-parse %t/constraint-body.mpir 2>&1 | FileCheck %s --check-prefix=CONSTRAINT-BODY
; RUN: not %metaphir-parse %t/constraint-end.mpir 2>&1 | FileCheck %s --check-prefix=CONSTRAINT-END
; RUN: not %metaphir-parse %t/constraint-extra.mpir 2>&1 | FileCheck %s --check-prefix=CONSTRAINT-EXTRA
; RUN: not %metaphir-parse %t/metaflag-name.mpir 2>&1 | FileCheck %s --check-prefix=METAFLAG-NAME
; RUN: not %metaphir-parse %t/metaflag-subject.mpir 2>&1 | FileCheck %s --check-prefix=METAFLAG-SUBJECT
; RUN: not %metaphir-parse %t/metaflag-parameter.mpir 2>&1 | FileCheck %s --check-prefix=METAFLAG-PARAMETER
; RUN: not %metaphir-parse %t/metaflag-body.mpir 2>&1 | FileCheck %s --check-prefix=METAFLAG-BODY
; RUN: not %metaphir-parse %t/metaflag-result.mpir 2>&1 | FileCheck %s --check-prefix=METAFLAG-RESULT
; RUN: not %metaphir-parse %t/metaflag-placement.mpir 2>&1 | FileCheck %s --check-prefix=METAFLAG-PLACEMENT
; RUN: not %metaphir-parse %t/metaflag-end.mpir 2>&1 | FileCheck %s --check-prefix=METAFLAG-END
; RUN: not %metaphir-parse %t/match-commutative-tag.mpir 2>&1 | FileCheck %s --check-prefix=MATCH-COMMUTATIVE-TAG
; RUN: not %metaphir-parse %t/match-name.mpir 2>&1 | FileCheck %s --check-prefix=MATCH-NAME
; RUN: not %metaphir-parse %t/match-flags-open.mpir 2>&1 | FileCheck %s --check-prefix=MATCH-FLAGS-OPEN
; RUN: not %metaphir-parse %t/match-flag-name.mpir 2>&1 | FileCheck %s --check-prefix=MATCH-FLAG-NAME
; RUN: not %metaphir-parse %t/match-flags-close.mpir 2>&1 | FileCheck %s --check-prefix=MATCH-FLAGS-CLOSE
; RUN: not %metaphir-parse %t/match-archetype.mpir 2>&1 | FileCheck %s --check-prefix=MATCH-ARCHETYPE
; RUN: not %metaphir-parse %t/match-commutative-unary.mpir 2>&1 | FileCheck %s --check-prefix=MATCH-COMMUTATIVE-UNARY
; RUN: not %metaphir-parse %t/match-parameters-open.mpir 2>&1 | FileCheck %s --check-prefix=MATCH-PARAMETERS-OPEN
; RUN: not %metaphir-parse %t/match-brace.mpir 2>&1 | FileCheck %s --check-prefix=MATCH-BRACE
; RUN: not %metaphir-parse %t/match-body.mpir 2>&1 | FileCheck %s --check-prefix=MATCH-BODY
; RUN: not %metaphir-parse %t/match-empty-branch.mpir 2>&1 | FileCheck %s --check-prefix=MATCH-EMPTY-BRANCH
; RUN: not %metaphir-parse %t/match-two-rets.mpir 2>&1 | FileCheck %s --check-prefix=MATCH-TWO-RETS
; RUN: not %metaphir-parse %t/match-branch-flag.mpir 2>&1 | FileCheck %s --check-prefix=MATCH-BRANCH-FLAG
; RUN: not %metaphir-parse %t/match-branch-flag-value.mpir 2>&1 | FileCheck %s --check-prefix=MATCH-BRANCH-FLAG-VALUE
; RUN: not %metaphir-parse %t/match-branch-close.mpir 2>&1 | FileCheck %s --check-prefix=MATCH-BRANCH-CLOSE
; RUN: not %metaphir-parse %t/match-branch-brace.mpir 2>&1 | FileCheck %s --check-prefix=MATCH-BRANCH-BRACE
; RUN: not %metaphir-parse %t/match-end.mpir 2>&1 | FileCheck %s --check-prefix=MATCH-END
; RUN: not %metaphir-parse %t/match-type-parameter.mpir 2>&1 | FileCheck %s --check-prefix=MATCH-TYPE-PARAMETER
; RUN: not %metaphir-parse %t/match-parameters-close.mpir 2>&1 | FileCheck %s --check-prefix=MATCH-PARAMETERS-CLOSE
; RUN: not %metaphir-parse %t/match-branch-flag-name.mpir 2>&1 | FileCheck %s --check-prefix=MATCH-BRANCH-FLAG-NAME
;--- constraint-name.mpir
constraint (?v) {
; CONSTRAINT-NAME: expected constraint name, which must be an identifier and not a keyword

  true
}

;--- constraint-open.mpir
constraint f ?v {
; CONSTRAINT-OPEN: expected '(' after constraint name (got '?v')

  true
}

;--- constraint-parameter.mpir
constraint f(v) {
; CONSTRAINT-PARAMETER: expected '?' parameter meta variable

  true
}

;--- constraint-duplicate-parameter.mpir
constraint f(?v, ?v) {
; CONSTRAINT-DUPLICATE-PARAMETER: duplicate parameter '?v' in constraint declaration

  true
}

;--- constraint-close.mpir
constraint f(?v {
; CONSTRAINT-CLOSE: expected ')' after parameters (got '{')

  true
}

;--- constraint-brace.mpir
constraint f(?v)
  true
; CONSTRAINT-BRACE: expected '{' before constraint body (got 'true')

}

;--- constraint-body.mpir
constraint f(?v) {
  )
; CONSTRAINT-BODY: expected constraint expression

}

;--- constraint-end.mpir
constraint f(?v) {
  true

;--- constraint-extra.mpir
; CONSTRAINT-END: expected '}' after constraint body (got end of file)

constraint f(?v) {
  true true
; CONSTRAINT-EXTRA: expected '}' after constraint body (got 'true')

}

;--- metaflag-name.mpir
metaflag f(?v) {
; METAFLAG-NAME: expected ':' followed by a metaflag name

  true
}

;--- metaflag-subject.mpir
metaflag :f() {
; METAFLAG-SUBJECT: a metaflag needs a '?' parameter for its subject

  true
}

;--- metaflag-parameter.mpir
metaflag :f(v) {
; METAFLAG-PARAMETER: expected '?' parameter meta variable

  true
}

;--- metaflag-body.mpir
metaflag :f(?v) {
  )
; METAFLAG-BODY: expected constraint expression

}

;--- metaflag-result.mpir
metaflag :f(?v) {
  1 + 2
; METAFLAG-RESULT: constraint must have a boolean result

}

;--- metaflag-placement.mpir
metaflag:x :f(?v) {
; METAFLAG-PLACEMENT: expected '(' after metaflag name (got ':f')

  true
}

;--- metaflag-end.mpir
metaflag :f(?v) {
  true

;--- match-commutative-tag.mpir
; METAFLAG-END: expected '}' after metaflag body (got end of file)

match:x m [] Binary (?ty ?a, ?b) {
; MATCH-COMMUTATIVE-TAG: expected ':c' in match declaration

  %ret = add ?ty ?a, ?b
}

;--- match-name.mpir
match [] Binary (?ty ?a, ?b) {
; MATCH-NAME: expected matcher name in match declaration, which must be an identifier and not a keyword

  %ret = add ?ty ?a, ?b
}

;--- match-flags-open.mpir
match m Binary (?ty ?a, ?b) {
; MATCH-FLAGS-OPEN: expected '[' before supported flags (got 'Binary')

  %ret = add ?ty ?a, ?b
}

;--- match-flag-name.mpir
match m [1] Binary (?ty ?a, ?b) {
; MATCH-FLAG-NAME: expected semantic flag name

  %ret = add ?ty ?a, ?b
}

;--- match-flags-close.mpir
match m [nsw Binary (?ty ?a, ?b) {
; MATCH-FLAGS-CLOSE: expected ']' after supported flags (got 'Binary')

  %ret = add ?ty ?a, ?b
}

;--- match-archetype.mpir
match m [] Ternary (?ty ?a, ?b) {
; MATCH-ARCHETYPE: expected archetype 'Unary', 'Nary', 'Binary' or 'Cast'

  %ret = add ?ty ?a, ?b
}

;--- match-commutative-unary.mpir
match:c m [] Unary (?ty ?a) {
; MATCH-COMMUTATIVE-UNARY: only 'Binary' matchers can be declared commutative with ':c'

  %ret = freeze ?ty ?a
}

;--- match-parameters-open.mpir
match m [] Binary ?ty ?a, ?b {
; MATCH-PARAMETERS-OPEN: expected '(' before parameter list (got '?ty')

  %ret = add ?ty ?a, ?b
}

;--- match-brace.mpir
match m [] Binary (?ty ?a, ?b)
  %ret = add ?ty ?a, ?b
; MATCH-BRACE: expected '{' to start match branch (got '%ret')

}

;--- match-body.mpir
match m [] Binary (?ty ?a, ?b) {
  %ret = add ?ty ?a ?b
; MATCH-BODY: expected ',' between operands (got '?b')

}

;--- match-empty-branch.mpir
match m [] Binary (?ty ?a, ?b) {
}
; MATCH-EMPTY-BRANCH: match branch must contain at least one instruction

;--- match-two-rets.mpir
match m [] Binary (?ty ?a, ?b) {
  %ret = add ?ty ?a, ?b
  %ret2 = add ?ty %ret, ?b
  %ret = sub ?ty ?a, ?b
; MATCH-TWO-RETS: duplicate instruction result '%ret'

}

;--- match-branch-flag.mpir
match m [nsw] Binary (?ty ?a, ?b) {
  %ret = add ?ty ?a, ?b
} or [exact = true] {
; MATCH-BRANCH-FLAG: flag 'exact' is not declared in matcher's supported flags

  %ret = sub ?ty ?a, ?b
}

;--- match-branch-flag-value.mpir
match m [nsw] Binary (?ty ?a, ?b) {
  %ret = add ?ty ?a, ?b
} or [nsw = 1] {
; MATCH-BRANCH-FLAG-VALUE: expected 'true' or 'false' after '='

  %ret = sub ?ty ?a, ?b
}

;--- match-branch-close.mpir
match m [nsw] Binary (?ty ?a, ?b) {
  %ret = add ?ty ?a, ?b
} or [nsw = true {
; MATCH-BRANCH-CLOSE: expected ']' after branch flags (got '{')

  %ret = sub ?ty ?a, ?b
}

;--- match-branch-brace.mpir
match m [nsw] Binary (?ty ?a, ?b) {
  %ret = add ?ty ?a, ?b
} or
; MATCH-BRANCH-BRACE: expected type

  %ret = sub ?ty ?a, ?b
}

;--- match-end.mpir
match m [] Binary (?ty ?a, ?b) {
  %ret = add ?ty ?a, ?b

;--- match-type-parameter.mpir
; MATCH-END: expected '}' to end match branch (got end of file)

match m [] Binary () ?a, ?b) {
; MATCH-TYPE-PARAMETER: expected type

  %ret = add i32 ?a, ?b
}

;--- match-parameters-close.mpir
match m [] Binary (?ty ?a, ?b {
; MATCH-PARAMETERS-CLOSE: expected ')' after parameter list (got '{')

  %ret = add ?ty ?a, ?b
}

;--- match-branch-flag-name.mpir
match m [nsw] Binary (?ty ?a, ?b) {
  %ret = add ?ty ?a, ?b
} or [1 = true] {
; MATCH-BRANCH-FLAG-NAME: expected semantic flag name

  %ret = sub ?ty ?a, ?b
}
