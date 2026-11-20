# Passes

<!-- Generated from metaphir/Transforms/*/Passes.td: do not edit. Update with METAPHIR_UPDATE_GOLDEN=1 ctest -R MetaphIR.pass-docs. -->

The passes over the mpir dialects run in three stages, a directory of `metaphir/Transforms` each, and declared in its `Passes.td`:

```
metaphir-parse ──► mpir (surface)
  Lowering   mpir-desugar-metaflags → mpir-expand-matchers
             → mpir-lower-alternatives → mpir-check-bindings
mpir (lowered)
  ToPlan     mpir-to-plan                  adds an mpir_plan.matcher
  ToIndex    mpir-to-index                 adds an mpir_index.query
             → mpir-index-structuralize → mpir-index-retrieval
             → mpir-index-factor
```

`mpir-to-plan` and `mpir-to-index` add their op after each `mpir.pattern`, which stays.

## Lowering (`metaphir/Transforms/Lowering`)

### `-mpir-check-bindings`

_Check that every alternative binds the named meta variables_

- Reads: lowered `mpir`.
- Writes: nothing; fails on a named meta variable some `mpir.alt`
  alternatives leave unbound.

### `-mpir-desugar-metaflags`

_Turn metaflags into constraints_

- Reads: surface `mpir`, with metaflags.
- Writes: `mpir` without metaflags; each becomes an `mpir.require` of an
  `mpir_expr` constraint.

### `-mpir-expand-matchers`

_Inline the uses of 'match' matchers_

- Reads: `mpir` with `mpir.use`s of `mpir.matcher`s.
- Writes: `mpir` without `mpir.use`; each becomes an `mpir.alt` with an
  alternative per branch (and per operand order, with `:c`), and one that
  matches the operand, with `:o`.

### `-mpir-lower-alternatives`

_Turn ':c' and ':o' on instruction matchers into mpir.alt_

- Reads: `mpir` with `:c` and `:o` on `mpir.inst`s.
- Writes: lowered `mpir`, in which every choice a match makes is an
  `mpir.alt`. A commuted compare's predicate is swapped by a keyword, or by
  an `mpir.let` of an `mpir_expr` call.

## ToPlan (`metaphir/Transforms/ToPlan`)

### `-mpir-to-plan`

_Compile lowered patterns into match plans_

- Reads: lowered `mpir`.
- Writes: an `mpir_plan.matcher` after each `mpir.pattern`, the plan that
  matches it; its constraints are `mpir_expr`.

## ToIndex (`metaphir/Transforms/ToIndex`)

### `-mpir-index-factor`

_Factor the posting lists every variant reads_

- Reads and writes: `mpir_index`. A list every variant of an
  `mpir_index.retrieve` reads is factored out of its union.

### `-mpir-index-retrieval`

_Add the posting-list lookup of index queries_

- Reads and writes: `mpir_index`. Each query gets an `mpir_index.retrieve`:
  the union over its variants of the intersection of their lists.

### `-mpir-index-structuralize`

_Require what constraints say of instructions as features_

- Reads and writes: `mpir_index`. What a variant's constraints say of the
  kind of an instruction, or of the intrinsic a call calls, becomes
  features it requires, which the corpus index has posting lists of.

### `-mpir-to-index`

_Compile lowered patterns into index queries_

- Reads: lowered `mpir`.
- Writes: an `mpir_index.query` after each `mpir.pattern`: a variant per
  choice of matcher branches, with the features a function needs for it.
