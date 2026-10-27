# Website

https://xuhongxu.com/metaphir

A static site that matches MetaphIR patterns against a published corpus in
the browser, chosen from the corpora `config.json` lists.

| Part | Where it runs |
|---|---|
| the site | GitHub Pages, deployed from a separate public repository |
| the corpus | a public Hugging Face bucket, read by byte ranges over HTTP, only where a query needs it |
| MetaphIR | WebAssembly, in the browser |

### The page

The page is React, in resizable panes:

| Pane | Shows |
|---|---|
| pattern | the pattern, in Monaco; a second tab shows `stdlib.mpir`, read-only |
| matches | matches below the pattern; use the arrow keys to move through them. The **Rejected** tab lists constraints that rejected structural matches, with counts and up to 10 examples. For your IR, it also lists each unmatched function and why. |
| IR | the selected match's function, with its bindings listed and the instructions it matched highlighted (as `metaphir-match --print-instructions` reports them) |

- **Corpus** or **Your IR** chooses what Match searches. When more than one
  corpus is configured, a picker beside it chooses which one; the choice is
  kept in `?corpus=<id>` and in share links. Your IR opens an
  editor for LLVM IR, stored in the browser and matched by the WebAssembly
  `metaphir-match` tool. Results include bindings and, for unmatched
  functions, the failed constraints or missing instructions. Selecting a
  failed constraint opens its rejected structural match with instructions
  highlighted. IR errors are marked in the editor. Corpus and Your IR keep
  separate results.
- Ctrl/⌘+clicking the name of a composite matcher, metaflag or constraint,
  in the pattern or in `stdlib.mpir`, goes to its definition: in the pattern
  if it defines one, or else in the `stdlib.mpir` tab.
- Each constraint the status panel lists as rejecting structural matches
  links to the Rejected tab, at the functions it rejected.
- In the tables, dragging the right edge of a column's header resizes the
  column (double-click to reset; the widths are kept in the browser), and a
  hovered cell shows a button that copies its full text.
- In the editors a name is one word with its sigil (`?x`, `%.x`,
  `@llvm.ctpop.i32`): the cursor in it highlights its occurrences,
  double-clicking selects it, and Ctrl/⌘+F2 changes them all.
- Hovering a matched instruction in either editor highlights its counterpart
  in the other.
- The search above the matches keeps those with every word of it in their
  module, function or bindings. A binding in it, `?a = %x` or `?a=%x`, must be
  one of the match's, the variable bound to that value; quote a value with
  spaces: `?v = "<2 x i32> <i32 1, i32 2>"`.
- A pattern's errors are marked in the editor, and listed in the status
  panel with their source line and caret. The panel also lists the pattern's
  warnings, and the constraints that rejected the structural matches of the
  functions matched, with how many functions each rejected; those that could
  not be evaluated are marked in the editor as warnings.
- A progress bar follows each stage's reads, then the matching. A query with
  very many candidates asks before reading their features.
- **Help** opens the pattern guide: the syntax by example, a reference of
  every meta flag, constraint operator and matcher, and PatternMatch.h's
  idioms beside patterns. It opens with the page until you ask it not to.
- The **example** picker loads a pattern of the evaluation, named by what it
  folds, with a link to its LLVM pull request.
- The theme follows the system unless one is chosen.

**Share** copies a link that carries the pattern. Links of either kind open
in any browser:

| Link | Pattern encoding | When |
|---|---|---|
| `#patternz=` | its tokens as bytes, deflated, in base64url (as instcombine-instrumentor's links carry IR); see `web/src/share/` | by default |
| `#pattern=` | plain text | where the browser cannot compress |

### Building the site

```sh
scripts/prepare_llvm.sh --source-only   # or a full native build
scripts/build_wasm.sh                   # build-wasm/, then web/public/wasm/
cd web && npm ci && npm run build       # web/dist/
```

`scripts/build_wasm.sh` builds under `build-wasm/`, then copies the modules
into `web/public/wasm/`:

| Directory | Contents |
|---|---|
| `build-wasm/emsdk` | the Emscripten SDK, unless `EMSDK` is set |
| `build-wasm/host` | `llvm-tblgen`, when `llvm-project` has no native build |
| `build-wasm/llvm` | LLVM's libraries, built for WebAssembly from `llvm-project`; built again only when `llvm-project` (its commit, patches or edits) or their options change, and kept without their object files |
| `build-wasm/metaphir` | `metaphir.{js,wasm}` and `metaphir-match.{js,wasm}` |

| Environment variable | Default | |
|---|---|---|
| `EMSDK` | `build-wasm/emsdk` | an activated Emscripten SDK to use instead |
| `CACHE_DIR` | ccache's default | ccache directory; compiles use ccache when it is installed |
| `JOBS` | `nproc` | parallel build jobs |

> [!IMPORTANT]
> Build the native tools and the site from the same `llvm-project`: a
> published corpus records the LLVM revision it was made with.

### Publishing a corpus

```sh
metaphir-index build -j 32 eval/corpus-o2-final -o eval/corpus-o2-final.mpidx
metaphir-index publish -j 32 eval/corpus-o2-final.mpidx -o published
web/scripts/publish.py published --corpus o2-final --label "O2 final"
```

Publish each corpus the same way (`--corpus original`, `--corpus
thinlto-prelink`); each keeps its own builds and config entry.

`metaphir-index publish` writes (see `metaphir/Web/WebIndex.h`):

- the posting keys and lists of the index, as they are;
- each function's features, compressed with zstd and a trained dictionary;
- one pack per function, with stubs for its globals and module-level constant
  uses. Up to eight consecutive packs share a zstd frame and trained
  dictionary. `functions.idx` maps each pack to its frame and slot.

`web/scripts/publish.py` uploads them to **`builds/<corpus>/<build>/`** in the
bucket, uploading `manifest.json` last, and upserts that corpus in
`web/public/config.json`:

```json
{
  "default": "o2-final",
  "corpora": [
    {"id": "o2-final", "label": "O2 final", "data": "https://…/builds/o2-final/<build>"},
    {"id": "original", "label": "Original IR", "data": "https://…/builds/original/<build>"}
  ]
}
```

```
web/scripts/publish.py <published> --corpus <id> [<owner>/<bucket>]
    [--label <label>] [--description <text>] [--default]
    [--keep <n>] [--config <file> | --no-config]
```

| Argument | Default | |
|---|---|---|
| `<published>` | | the directory `metaphir-index publish` wrote |
| `--corpus <id>` | | the corpus id; required, and used in the bucket path and config |
| `<owner>/<bucket>` | `xuhongxu96/llvm-opt-benchmark-index` | the bucket to upload to |
| `--label <label>` | the id | the display label in the config |
| `--description <text>` | existing | the description in the config |
| `--default` | | make this corpus the site's default |
| `--keep <n>` | `3` | how many builds **of this corpus** the bucket keeps; other corpora are untouched |
| `--config <file>` | `web/public/config.json` | the site's config to upsert |
| `--no-config` | | leave the site's config as it is |

Other corpus entries and the `default` are preserved. Uploading one corpus
never prunes another corpus's builds.

> [!WARNING]
> The site's config names a build per corpus. Publish with `--keep` large
> enough for the deployed config, and deploy again after republishing a
> corpus, or a referenced build can be pruned.

The same files can be matched from the command line, as the site does,
without the corpus. For the corpus from
[Indexing a corpus](tools.md#indexing-a-corpus):

```
$ metaphir-index publish corpus.mpidx -o published
...
published 3 files (4 functions) to published

$ ls published
features.bin  functions.idx  header.bin.zst  keys.bin  lists.bin  manifest.json  packs.bin

$ metaphir-match --matches-only --summary --packs published pattern.mpir
matched 2 of 4 functions (2 on the posting lists)
a.ll	@f	{?n = 32, ?x = %x}
b.ll	@h	{?n = 32, ?x = %x}
```

For a published build:

```sh
hf buckets sync hf://buckets/xuhongxu96/llvm-opt-benchmark-index/builds/<build> published
metaphir-match --matches-only --packs published pattern.mpir
```

### Deploying the site

On a push to `main`, CI builds and tests the site, then deploys it directly
from this repository to GitHub Pages. The project site is available at
<https://xuhongxu.com/metaphir/> through the custom domain configured for the
account's user site. The old MetaphIR project site redirects there. You can
also run the deploy workflow manually from the Actions tab on `main`.

### How a query runs

1. The page reads `manifest.json` and the header once: the module directory,
   a sparse table of the posting keys, and the dictionaries.
2. Each stage of `WebQuery` names the byte ranges the next one reads
   (`web/src/pipeline.ts`):

   | Stage | Reads |
   |---|---|
   | 1 | the blocks holding the pattern's posting keys |
   | 2 | the shortest posting lists |
   | 3 | the `functions.idx` entries of the functions on all of them |
   | 4 | those functions' features |
   | 5 | the frames holding the packs of the functions whose features may match |

3. Workers, each with its own WebAssembly instance, match the packs as their
   frames arrive (`web/src/pool.ts`).

#### Reading and caching

| | How | Why |
|---|---|---|
| fetching (`web/src/fetcher.ts`) | resolves each file's bucket URL once, then reads ranges from the signed CDN URL it redirects to | only a few requests count toward the Hub's rate limit |
| | merges nearby ranges into one request | fewer requests |
| caching (`web/src/blocks.ts`) | keeps every block it reads in IndexedDB, one database per `<corpus>:<build>`, with recently used blocks in memory | no byte is read twice while the build is current |
| expiry | a build's files never change, so a corpus's older builds expire when its `manifest.json` names another build; another corpus's cache is kept | switching corpora does not reread the one switched back to |

### Developing

```sh
cd web && METAPHIR_DATA=/path/to/published npm run dev
```

| | |
|---|---|
| `METAPHIR_DATA` | a directory from `metaphir-index publish`; the development server serves it at `/data` and emits a one-corpus config naming it (`METAPHIR_CORPUS` sets its id, default `local`) |
