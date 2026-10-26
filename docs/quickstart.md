# Quick start


This walkthrough uses a small corpus to demonstrate each tool. It takes about
a minute after you build `build/` (see [Building](development.md#building)).

### 1. Set up

From the repository root, put the tools on `PATH` and make a scratch
directory, `/tmp/metaphir-try`, for the files below:

```sh
export PATH="$PWD/build/tools:$PATH"
mkdir -p /tmp/metaphir-try/corpus && cd /tmp/metaphir-try
```

Save this pattern, `(x << 1) + 1`, as `pattern.mpir`. Lines starting with
`;;` are constraints:

```llvm
; pattern.mpir: (x << 1) + 1
%twice = shl i32 ?x, 1
%sum = add i32 %twice, ?c
;; ?c == 1
```

Save this module as `corpus/a.ll`. `@odd` matches, and `@plus2` adds 2
instead of 1:

```llvm
; corpus/a.ll
define i32 @odd(i32 %x) {
  %t = shl i32 %x, 1
  %s = add i32 %t, 1
  ret i32 %s
}

define i32 @plus2(i32 %x) {
  %t = shl i32 %x, 1
  %s = add i32 %t, 2
  ret i32 %s
}
```

Save this module as `corpus/b.ll`. `@triple` has no `shl` at all:

```llvm
; corpus/b.ll
define i32 @triple(i32 %x) {
  %m = mul i32 %x, 3
  ret i32 %m
}
```

### 2. Read the pattern

`metaphir-lex` shows how the pattern is tokenized:

```
$ metaphir-lex --line-numbers pattern.mpir
2: LocalVar twice
2: equal
2: kw_shl
2: Type i32
2: MetaVar x
2: comma
2: APSInt 1
...
4: ConstraintMarker
4: MetaVar c
4: equalequal
4: APSInt 1
5: Eof
```

`metaphir-parse` shows how it is parsed, including its variables' kinds:

```
$ metaphir-parse pattern.mpir
pattern instructions=2 constraints=1
%twice = shl i32 ?x, 1
%sum = add i32 %twice, ?c
constraint (== ?c 1)
meta ?x type=Value
meta ?c type=Value
```

### 3. Match a file

By default, `metaphir-match` reports every function, and why a function whose
instructions matched still failed:

```
$ metaphir-match pattern.mpir corpus/a.ll
target 0: @odd
  match 0:
    {?c = 1, ?x = %x}
target 1: @plus2
  no match
  constraint not satisfied: (== ?c 1)
```

### 4. Match a directory

`--matches-only` prints one line per match (file, function, bindings), which
is what you want for many files. A directory is searched for `.ll` and `.bc`
files:

```
$ metaphir-match --matches-only pattern.mpir corpus
corpus/a.ll	@odd	{?c = 1, ?x = %x}
```

`--print-instructions` adds which IR instruction each pattern instruction
matched (`%twice` on pattern line 2 matched the function's instruction `#0`):

```
$ metaphir-match --matches-only --print-instructions pattern.mpir corpus
corpus/a.ll	@odd	{?c = 1, ?x = %x}	{%twice@2 = #0, %sum@3 = #1}
```

### 5. Index the corpus

An index records each function's features, so matching can skip the
functions that cannot match without reading them:

```
$ metaphir-index build corpus -o corpus.mpidx
indexed 2 files

$ metaphir-index dump corpus.mpidx
module a.ll: add shl ret; add-shl ret-add; 0 globals
  0: add shl ret; add-shl ret-add; 0 globals
  1: add shl ret; add-shl ret-add; 0 globals
module b.ll: mul ret; ret-mul; 0 globals
  0: mul ret; ret-mul; 0 globals
```

`stats` estimates how much of the corpus may match. Here, only `@odd` remains.
The index rules out `@triple` because it has no `shl`, and `@plus2` because it
adds `2` rather than satisfying `;; ?c == 1`.

```
$ metaphir-index stats pattern.mpir corpus.mpidx
modules: 1 of 2 (50.00%)
bytes: 183 of 262 (69.85%)
functions: 1 of 3 (33.33%)
```

Match with the index; `--summary` reports how many functions were checked:

```
$ metaphir-match --matches-only --summary --index corpus.mpidx pattern.mpir corpus
matched 1 of 3 functions (in 1 of 2 files)
corpus/a.ll	@odd	{?c = 1, ?x = %x}
```

### 6. Publish for the website

`publish` writes the files the website matches over HTTP. `--packs` matches
them locally as the website does, without the corpus:

```
$ metaphir-index publish corpus.mpidx -o published
...
published 2 files (3 functions) to published

$ metaphir-match --matches-only --packs published pattern.mpir
a.ll	@odd	{?c = 1, ?x = %x}
```

Each function pack preserves the module's use-list order. This lets
value-tracking constraints, which inspect a bounded number of uses, behave on
the website as they do in `metaphir-match`.

Next: the [Wiki](https://github.com/xuhongxu96/metaphir/wiki) for the
language, and the [tool reference](tools.md) for every option.
