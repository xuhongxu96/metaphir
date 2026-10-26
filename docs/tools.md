# Tool reference


| Command | |
|---|---|
| `metaphir-match <pattern> <.ll/.bc file or directory>...` | matches a pattern against every function |
| `metaphir-index build <directory> -o <index>` | indexes a corpus for `metaphir-match --index` |
| `metaphir-index dump <index>` | prints the features in an index |
| `metaphir-index stats <pattern> <index>` | counts the modules and functions of an index a pattern may match |
| `metaphir-index publish <index> -o <directory>` | publishes an indexed corpus for the web |
| `metaphir-parse <pattern>` | parses and prints a pattern |
| `metaphir-lex [--line-numbers] <file>` | prints the tokens of a file |

### `metaphir-match`

```
metaphir-match [options] <pattern> <.ll/.bc file or directory>...
```

| Option | |
|---|---|
| `--matches-only` | print only the matches, one tab-separated line each (see [Output](#output)) |
| `-j <n>` | match `n` files at once (`0`: one per hardware thread); needs `--matches-only` |
| `--print-instructions` | add which IR instruction each pattern instruction matched (see [Matched instructions](#matched-instructions)); needs `--matches-only` |
| `--index=<file>` | skip the files and functions the index shows cannot match (see [Indexing a corpus](#indexing-a-corpus)); needs `--matches-only` |
| `--trust-index` | match only the indexed candidates; needs `--index` |
| `--packs=<directory>` | match a published corpus instead of files (see [Website](website.md)); needs `--matches-only` |
| `--explain` | explain why a function has no match: rejected constraints and their structural matches, conflicting bindings, or missing instructions; unavailable with `--matches-only` |
| `--summary` | print to stderr how many functions and files were checked |

The examples below use this pattern, `pattern.mpir`:

```llvm
; pattern.mpir: (X u/ 2) + (X u% 2), in either order
%div = udiv i?n ?x, 2
%rem = urem i?n ?x, 2
%sum = add:c i?n %div, %rem
;; ugt(?n, 1)
```

#### Output

| Mode | Prints | For |
|---|---|---|
| default | every function, numbered as a `target`, with each of its matches or `no match`, and why constraints failed | debugging a pattern on a few files |
| `--matches-only` | one line per match: file, `@function`, bindings, separated by tabs; nothing for functions without a match | corpora, scripts, and `-j`, `--index`, `--packs` |

For `%r = add i32 ?x, ?c` with `;; ?c == 2`, over a module whose `@f` is
`add i32 %a, 2` and `@g` is `add i32 %a, 1`:

```
$ metaphir-match pattern.mpir a.ll
target 0: @f
  match 0:
    {?c = 2, ?x = %a}
target 1: @g
  no match
  constraint not satisfied: (== ?c 2)

$ metaphir-match --matches-only pattern.mpir a.ll
a.ll	@f	{?c = 2, ?x = %a}
```

`constraint not satisfied` is printed only when the instructions matched and
a constraint then failed. A function without the instructions prints only
`no match`.

#### Matched instructions

`--print-instructions` adds a last column that maps each pattern instruction
to the IR instruction it matched:

```
%div@2 = #0
│    │   └─ the IR instruction: its position among all the function's
│    │      instructions, from 0, across blocks, terminators included
│    └──── the line of the pattern instruction in the pattern file
└───────── the pattern instruction, by result name (opcode if unnamed)
```

For `pattern.mpir` above:

```llvm
; f.ll
define i32 @f(i32 %x) {
entry:
  %d = udiv i32 %x, 2          ; #0  ← %div@2
  %unrelated = mul i32 %x, 3   ; #1
  br label %next               ; #2
next:
  %r = urem i32 %x, 2          ; #3  ← %rem@3
  %s = add i32 %r, %d          ; #4  ← %sum@4
  ret i32 %s                   ; #5
}
```

```
$ metaphir-match --matches-only --print-instructions pattern.mpir f.ll
f.ll	@f	{?n = 32, ?x = %x}	{%div@2 = #0, %rem@3 = #3, %sum@4 = #4}
```

Positions identify instructions whether or not they are named, and are what
the website highlights.

Instructions expanded from a composite matcher are named
`<use>$<instruction in the composite>`, and have the line of the use, however
deeply the composites nest. `signum` (from the standard library) expands to
`%neg`, `%lhs`, `%rhs` and `%ret`; its `%ret` is the use itself:

```llvm
; composite.mpir
%s = signum i32 ?x
%n = neg i32 %s
```

```llvm
; signum.ll
define i32 @signum(i32 %x) {
  %neg = sub i32 0, %x        ; #0  ← %s$neg@2
  %lhs = ashr i32 %x, 31      ; #1  ← %s$lhs@2
  %rhs = lshr i32 %neg, 31    ; #2  ← %s$rhs@2
  %ret = or i32 %lhs, %rhs    ; #3  ← %s@2
  %n = sub i32 0, %ret        ; #4  ← %n@3
  ret i32 %n
}
```

```
$ metaphir-match --matches-only --print-instructions composite.mpir signum.ll
signum.ll	@signum	{?x = %x}	{%s@2 = #3, %s$lhs@2 = #1, %s$neg@2 = #0, %s$rhs@2 = #2, %n@3 = #4}
```

An or-self matcher (`:o`) that matched its operand alone shares that
operand's position. In `@plain`, which has no `add`, `%sum` is the `sub`:

```llvm
; self.mpir
%diff = sub i32 ?x, ?y
%sum = add:o i32 %diff, 1
ret i32 %sum
```

```llvm
; self.ll
define i32 @plain(i32 %x, i32 %y) {
  %d = sub i32 %x, %y          ; #0  ← %diff@2, %sum@3
  ret i32 %d                   ; #1  ← ret@4
}

define i32 @plus1(i32 %x, i32 %y) {
  %d = sub i32 %x, %y          ; #0  ← %diff@2
  %s = add i32 %d, 1           ; #1  ← %sum@3
  ret i32 %s                   ; #2  ← ret@4
}
```

```
$ metaphir-match --matches-only --print-instructions self.mpir self.ll
self.ll	@plain	{?x = %x, ?y = %y}	{%diff@2 = #0, %sum@3 = #0, ret@4 = #1}
self.ll	@plus1	{?x = %x, ?y = %y}	{%diff@2 = #0, %sum@3 = #1, ret@4 = #2}
```

### `metaphir-index`

| Subcommand | Option | |
|---|---|---|
| `build <directory>` | `-o <file>` | the index file to write |
| | `-j <n>` | index `n` files at once (`0`: one per hardware thread) |
| | `--no-value-facts` | skip value-tracking facts: a faster build that prunes less |
| `dump <index>` | | print each module's and function's features |
| `stats <pattern> <index>` | | count what the pattern may match |
| `publish <index>` | `-o <directory>` | the directory to write the published files to |
| | `-j <n>` | pack `n` modules at once (`0`: one per hardware thread) |

#### Indexing a corpus

A corpus of three files, where only `@f` and `@h` match `pattern.mpir`:

| File | Functions |
|---|---|
| `corpus/a.ll` | `@f` (`udiv`, `urem`, `add`), `@g` (`mul`) |
| `corpus/b.ll` | `@h` (`urem`, `udiv`, `add`, operands swapped) |
| `corpus/c.ll` | `@k` (`fadd`) |

```
$ metaphir-index build corpus -o corpus.mpidx
indexed 3 files

$ metaphir-index stats pattern.mpir corpus.mpidx
modules: 2 of 3 (66.67%)
bytes: 270 of 341 (79.18%)
functions: 2 of 4 (50.00%)

$ metaphir-index dump corpus.mpidx
module a.ll: add mul udiv urem ret; add-udiv add-urem ret-add ret-mul; 0 globals
  0: add udiv urem ret; add-udiv add-urem ret-add; 0 globals
  1: mul ret; ret-mul; 0 globals
module b.ll: add udiv urem ret; add-udiv add-urem ret-add; 0 globals
  0: add udiv urem ret; add-udiv add-urem ret-add; 0 globals
module c.ll: fadd ret; ret-fadd; 0 globals
  0: fadd ret; ret-fadd; 0 globals
```

`dump` lists, per module and then per function, the instruction kinds, the
operand edges (`add-udiv`: an `add` uses a `udiv`) and the number of globals.

Matching with the index checks only the candidates, and `--summary` shows how
many functions and files that is. It counts the functions checked, not the
functions matched:

```
$ metaphir-match --matches-only --summary pattern.mpir corpus
matched 4 of 4 functions (in 3 of 3 files)
corpus/a.ll	@f	{?n = 32, ?x = %x}
corpus/b.ll	@h	{?n = 32, ?x = %x}

$ metaphir-match --matches-only --summary --index corpus.mpidx pattern.mpir corpus
matched 2 of 4 functions (in 2 of 3 files)
corpus/a.ll	@f	{?n = 32, ?x = %x}
corpus/b.ll	@h	{?n = 32, ?x = %x}
```

`c.ll` is not read at all, and `@g` is not materialized.

Files added or changed since indexing are matched in full, with a warning.
`--trust-index` skips that check: it neither lists the input directories nor
looks at the files for changes, so it is faster but misses such files. With a
new `corpus/new.ll` that also matches:

```
$ metaphir-match --matches-only --summary --index corpus.mpidx pattern.mpir corpus
metaphir-match: warning: corpus/new.ll: not indexed; matching it in full
matched 3 of 5 functions (in 3 of 4 files)
...
corpus/new.ll	@n	{?n = 32, ?x = %x}

$ metaphir-match --matches-only --summary --index corpus.mpidx --trust-index pattern.mpir corpus
matched 2 of 3 functions (in 2 of 2 files)
corpus/a.ll	@f	{?n = 32, ?x = %x}
corpus/b.ll	@h	{?n = 32, ?x = %x}
```

For a large corpus:

```sh
metaphir-index build -j 32 corpus -o corpus.mpidx
metaphir-match --matches-only -j 32 --index corpus.mpidx pattern.mpir corpus
```

### `metaphir-parse`, `metaphir-lex`

`metaphir-parse` parses a pattern and prints it with its constraints and the
types of its variables:

```
$ metaphir-parse pattern.mpir
pattern instructions=3 constraints=1
%div = udiv i?n ?x, 2
%rem = urem i?n ?x, 2
%sum = add:c i?n %div, %rem
constraint (ugt ?n 1)
meta ?n type=Nat
meta ?x type=Value
```

`metaphir-lex` prints the tokens of a file; `--line-numbers` prefixes each
with its line:

```
$ metaphir-lex --line-numbers pattern.mpir
2: LocalVar div
2: equal
2: kw_udiv
2: MetaIntVar n
2: MetaVar x
2: comma
2: APSInt 2
...
```

## How matching is narrowed

Before matching a function, `metaphir-match` compares the pattern with the
function's **features**:

| Feature | Example (from `corpus/a.ll` above) |
|---|---|
| instruction signatures: kind, flags and types | `udiv i32`, `add i32` |
| operand edges | `add-udiv`: an `add` uses a `udiv` |
| shared values | `%x`, used by both the `udiv` and the `urem` |
| globals | the globals the function uses (none here) |
| value facts at each instruction kind's operands | the constant `2` at operand 1 of `udiv`; constant classes; use counts; value-tracking facts (when indexing) |

A pattern variant is matched only where the function can have a match. Each
condition below prunes a function of `corpus` (checked with
`metaphir-index stats`):

| Condition | Pattern | Pruned |
|---|---|---|
| its instructions must be there | `pattern.mpir` | `@g` (no `udiv`), `@k` |
| their types must agree on the type variables | `%r = urem i8 ?x, ?c` | every function: their `urem`s are `i32` |
| no constraint may be false on the facts | `%r = urem i?n ?x, ?c` with `;; ?c == 4` | every function: the only `urem` constant is `2` |

Constraints use the same evaluator as they do on IR
(`metaphir/Matching/ConstraintEvaluator.h`). Facts may leave a result unknown;
unknown constraints do not prune candidates.

Each operator's IR, recording, and index semantics are documented together in
`metaphir/Matching/Operators/`.

With an index, matching takes two steps:

1. `metaphir-index build` stores each function's features and builds posting
   lists from coarse features (instruction kinds, edges, sibling pairs, and
   globals) to the functions that contain them.
2. `metaphir-match --index` intersects the pattern's shortest posting lists
   (for example, `udiv`, `urem`, and `add-udiv`) to find candidates, then
   checks only those functions.

Each file of the corpus is then handled by what the index says about it:

| File | Handling | Example |
|---|---|---|
| indexed, no candidates | not read | `c.ll` |
| indexed, with candidates | loaded lazily; only the candidate functions are materialized | `a.ll`: `@f`, not `@g` |
| changed since indexing, or not indexed | matched in full (with a warning), unless `--trust-index` is given | `new.ll` |
