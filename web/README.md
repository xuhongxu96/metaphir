# MetaphIR on the web

A static site that matches MetaphIR patterns against a published corpus in
the browser: MetaphIR runs as WebAssembly, and the corpus is read by byte
ranges over HTTP, only where a query needs it. GitHub Pages serves the site;
a public Hugging Face bucket serves the corpus. The page is React, in
resizable panes: the pattern (in Monaco) above its matches, and beside them
the IR of the selected match, its bindings listed and the instructions they
bind highlighted (the arrow keys move through the matches). A progress bar
follows each stage's reads and then the matching; Share copies a link that
carries the pattern (`#pattern=<encoded text>`); the theme follows the
system unless chosen.

## Building

```sh
scripts/prepare_llvm.sh --source-only   # or a full native build
scripts/build_wasm.sh                   # build-wasm/, then web/public/wasm/
cd web && npm ci && npm run build       # web/dist/
```

`build_wasm.sh` fetches the Emscripten SDK into `build-wasm/emsdk` (unless
`EMSDK` is set), builds LLVM's libraries for WebAssembly from `llvm-project`
into `build-wasm/llvm`, and MetaphIR into `build-wasm/metaphir`. Compiles go
through ccache when it is installed (`CACHE_DIR` as for `prepare_llvm.sh`).
The native tools and the site must be built from the same `llvm-project`:
a published corpus records the LLVM revision it was made with.

## Deploying the site

This repository is private, so the site is deployed from a separate public
one, which holds the built site and `site/`'s workflow, deploying it to
GitHub Pages as it is:

```sh
web/scripts/deploy_site.sh ../metaphir-site --data <corpus URL> --commit
git -C ../metaphir-site push
```

The script builds the site (after `scripts/build_wasm.sh`), replaces the
site repository's contents with it (creating the repository if needed),
points its `config.json` at the corpus, and commits.

## Publishing a corpus

```sh
metaphir-index build -j 32 corpus -o corpus.mpidx
metaphir-index publish -j 32 corpus.mpidx -o published
web/scripts/publish.py published <owner>/<bucket>
```

`publish` writes, next to the posting keys and lists of the index, each
function's features and a pack of the function alone (with stubs for the
globals it uses and how the module uses its constants), compressed with zstd
and trained dictionaries; see `metaphir/Web/WebIndex.h`. `publish.py`
uploads them to `builds/<build>/` in the bucket, the manifest last, and
prints the corpus URL for `deploy_site.sh --data` (or, with `--config`,
writes it to `web/public/config.json`).

The same files can be matched from the command line:

```sh
hf buckets sync hf://buckets/<owner>/<bucket>/builds/<build> published
metaphir-match --matches-only --packs published pattern.mpir
```

## How a query runs

1. The page reads `manifest.json` and the header (the module directory, a
   sparse table of the posting keys, and the dictionaries), once.
2. Each stage of `WebQuery` names the byte ranges the next reads: the blocks
   of the pattern's posting keys, the shortest lists, the index entries and
   features of the functions on all of them, and the packs of those whose
   features may match (`src/pipeline.ts`).
3. Workers, each with its own WebAssembly instance, match the packs as they
   arrive (`src/pool.ts`).

The fetcher (`src/fetcher.ts`) resolves each file's bucket URL once and reads
ranges from the signed CDN URL it redirects to, so only a few requests count
toward the Hub's rate limit, and it merges nearby ranges into one request.
Every block it reads is kept (`src/blocks.ts`): in IndexedDB, one database
per build, with recently used blocks in memory. No byte is read twice while
the build is current; a build's files never change, so its blocks expire
only when `manifest.json` names another build, whose first visit drops them.

## Developing

```sh
METAPHIR_DATA=/path/to/published npm run dev
```

serves a published directory at `/data` and points the site at it. The
development server can also match local `.ll`/`.bc` files, with their index
if given, with `metaphir-match` built for WebAssembly; the deployed site
cannot. `npm test` (and `ctest`, once `build_wasm.sh` has run) checks that
the WebAssembly builds find what the native tools find.
