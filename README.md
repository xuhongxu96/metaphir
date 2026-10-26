# MetaphIR

MetaphIR is a domain-specific language and toolset for matching LLVM IR
patterns. It is designed to describe the preconditions of InstCombine folds.
See the [language guide](https://github.com/xuhongxu96/metaphir/wiki) for the
pattern syntax.

```llvm
; (X u/ 2) + (X u% 2), in either order
%div = udiv i?n ?x, 2
%rem = urem i?n ?x, 2
%sum = add:c i?n %div, %rem
;; ugt(?n, 1) && isKnownNonZero(?x)
```

![MetaphIR matching demo](metaphir.png)

## Build

MetaphIR builds against a pinned, patched LLVM checkout in `llvm-project/`.

```sh
scripts/prepare_llvm.sh release
cmake -G Ninja -S . -B build -DCMAKE_BUILD_TYPE=Debug
cmake --build build
```

See [Development](docs/development.md) for prerequisites, build options, and
tests.

## Try it

Save this pattern as `pattern.mpir`. It matches `(x << 1) + 1`:

```llvm
%twice = shl i32 ?x, 1
%sum = add i32 %twice, ?c
;; ?c == 1
```

Save this module as `module.ll`:

```llvm
define i32 @odd(i32 %x) {
  %t = shl i32 %x, 1
  %s = add i32 %t, 1
  ret i32 %s
}
```

After building, run the matcher from the repository root:

```sh
build/tools/metaphir-match --matches-only pattern.mpir module.ll
```

It reports the function and the values bound to the pattern variables:

```
module.ll	@odd	{?c = 1, ?x = %x}
```

The [quick start](docs/quickstart.md) walks through a complete example,
including parsing patterns, matching files, and indexing a corpus.

## More

- [Tool reference](docs/tools.md): command options, output, and corpus indexing.
- [Website guide](docs/website.md): browse a published corpus and publish your own.
- [Development](docs/development.md): build, test, and repository layout.
- [Evaluation](docs/evaluation.md): methodology, corpora, and results.
- [License](LICENSE).

## License

MetaphIR is under the Apache License v2.0 (see [LICENSE](LICENSE)).
Redistributions must keep its copyright and license, and pass on
[NOTICE](NOTICE). To cite MetaphIR, see [CITATION.cff](CITATION.cff).

`eval/patches` change LLVM's own code. They are under LLVM's license, the
Apache License v2.0 with LLVM Exceptions.
