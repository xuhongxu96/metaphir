#!/bin/bash
# Fetch, patch, build and install the pinned llvm-project checkout that
# MetaphIR builds against.
#
# Usage: scripts/prepare_llvm.sh [debug|release] [--force] [--source-only]
#                                [--libraries-only] [--prune]
#
# --source-only     stops once the source is patched, e.g. for
#                   scripts/build_wasm.sh alone.
# --libraries-only  builds LLVM's libraries and only the tools MetaphIR's
#                   tests run (TEST_TOOLS below), not all of LLVM's tools.
# --prune           keeps only the install, llvm-lit and TEST_TOOLS of the
#                   build, e.g.
#                   to cache it (as CI does, .github/workflows/ci.yml).
#
# Environment:
#   LLVM_BUILD_TYPE  default build type when none is given (Release)
#   LLVM_BUILD_DIR   build directory (llvm-project/build-<type>)
#   CACHE_DIR        ccache directory (ccache default when unset); ccache is
#                    used when it is installed
#   JOBS             parallel build jobs (nproc)
#
# The selected build directory is linked as llvm-project/build, which is where
# the MetaphIR CMake build and the eval scripts look for LLVM.
set -euo pipefail

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LLVM_COMMIT="53a7028134738d799d8b758a5675873e325dd9e0"
LLVM_DIR="$BASE_DIR/llvm-project"
JOBS="${JOBS:-$(nproc)}"
# What MetaphIR's build and tests run from the build tree; llvm-lit is
# written when LLVM is configured, the others built.
TEST_TOOLS=(FileCheck not split-file llvm-as llvm-tblgen llvm-min-tblgen)

usage() {
    echo "Usage: $0 [debug|release] [--force] [--source-only] [--libraries-only] [--prune]"
}

BUILD_TYPE_ARG="${LLVM_BUILD_TYPE:-Release}"
FORCE=0
SOURCE_ONLY=0
LIBRARIES_ONLY=0
PRUNE=0
for arg in "$@"; do
    case "${arg,,}" in
        --source-only) SOURCE_ONLY=1 ;;
        --libraries-only) LIBRARIES_ONLY=1 ;;
        --prune) PRUNE=1 ;;
        release|--release|debug|--debug) BUILD_TYPE_ARG="$arg" ;;
        -f|--force) FORCE=1 ;;
        -h|--help|help) usage; exit 0 ;;
        *)
            echo "Error: unknown argument '$arg'." >&2
            usage >&2
            exit 1
            ;;
    esac
done

case "${BUILD_TYPE_ARG,,}" in
    release|--release)
        LLVM_BUILD_TYPE="Release"
        DEFAULT_BUILD_DIR="$LLVM_DIR/build-release"
        ;;
    debug|--debug)
        LLVM_BUILD_TYPE="Debug"
        DEFAULT_BUILD_DIR="$LLVM_DIR/build-debug"
        ;;
    *)
        echo "Error: invalid build type '$BUILD_TYPE_ARG'. Expected 'debug' or 'release'." >&2
        usage >&2
        exit 1
        ;;
esac

LLVM_BUILD_DIR="${LLVM_BUILD_DIR:-$DEFAULT_BUILD_DIR}"

echo "Using LLVM commit: $LLVM_COMMIT"
echo "Using LLVM build type: $LLVM_BUILD_TYPE"
echo "Using LLVM build directory: $LLVM_BUILD_DIR"

if [ ! -d "$LLVM_DIR" ]; then
    echo "[$(date)] Initializing llvm-project ($LLVM_COMMIT)..."
    git init -q "$LLVM_DIR"
    git -C "$LLVM_DIR" remote add origin https://github.com/llvm/llvm-project.git
fi

# Sync LLVM commit if needed
if ! git -C "$LLVM_DIR" cat-file -e "$LLVM_COMMIT^{commit}" 2>/dev/null; then
    echo "[$(date)] Fetching $LLVM_COMMIT..."
    git -C "$LLVM_DIR" fetch --depth 1 origin "$LLVM_COMMIT"
fi

shopt -s nullglob
PATCHES=("$BASE_DIR"/eval/patches/*.patch)
shopt -u nullglob

# Resetting discards local edits. The applied eval patches are expected (they
# are generated with `git -C llvm-project diff HEAD`); any other change, e.g.
# instrumentation work not yet saved to eval/patches, stops the script unless
# --force is given.
if [ "$FORCE" -eq 0 ] && git -C "$LLVM_DIR" rev-parse -q --verify HEAD >/dev/null; then
    EXPECTED_DIFF="$(cat /dev/null "${PATCHES[@]}")"
    if [ "$(git -C "$LLVM_DIR" diff HEAD)" != "$EXPECTED_DIFF" ] ||
        [ -n "$(git -C "$LLVM_DIR" ls-files --others --exclude-standard)" ]; then
        echo "Error: $LLVM_DIR has local changes beyond eval/patches that the reset would discard." >&2
        echo "Save them (git -C llvm-project diff HEAD > eval/patches/<name>.patch) or rerun with --force." >&2
        exit 1
    fi
fi

echo "[$(date)] Resetting to $LLVM_COMMIT and applying patches..."
git -C "$LLVM_DIR" reset --hard "$LLVM_COMMIT"
git -C "$LLVM_DIR" clean -fd
if [ "${#PATCHES[@]}" -gt 0 ]; then
    git -C "$LLVM_DIR" apply "${PATCHES[@]}"
fi
if [ "$SOURCE_ONLY" -eq 1 ]; then
    echo "[$(date)] Done: $LLVM_DIR is at $LLVM_COMMIT with eval/patches."
    exit 0
fi

# Configure LLVM
echo "[$(date)] Building LLVM..."
mkdir -p "$LLVM_BUILD_DIR"
CMAKE_ARGS=(
    -DLLVM_ENABLE_PROJECTS="llvm"
    -DLLVM_TARGETS_TO_BUILD="X86"
    -DCMAKE_BUILD_TYPE="$LLVM_BUILD_TYPE"
    -DLLVM_INCLUDE_TESTS=ON
    -DLLVM_INCLUDE_BENCHMARKS=OFF
    -DLLVM_INCLUDE_EXAMPLES=OFF
    -DLLVM_ENABLE_RTTI=OFF
)
if command -v ccache >/dev/null; then
    CMAKE_ARGS+=(-DLLVM_CCACHE_BUILD=ON -DLLVM_CCACHE_MAXSIZE=10GB)
    if [ -n "${CACHE_DIR:-}" ]; then
        CMAKE_ARGS+=(-DLLVM_CCACHE_DIR="$CACHE_DIR")
    fi
fi
if [ "$LIBRARIES_ONLY" -eq 1 ]; then
    CMAKE_ARGS+=(-DLLVM_BUILD_TOOLS=OFF)
fi
cmake -G Ninja -S "$LLVM_DIR/llvm" -B "$LLVM_BUILD_DIR" "${CMAKE_ARGS[@]}"

# Build
cmake --build "$LLVM_BUILD_DIR" --target all -- -j"$JOBS"
if [ "$LIBRARIES_ONLY" -eq 1 ]; then
    cmake --build "$LLVM_BUILD_DIR" -- -j"$JOBS" "${TEST_TOOLS[@]}"
fi

# Install
cmake --install "$LLVM_BUILD_DIR" --prefix "$LLVM_BUILD_DIR/install"

if [ "$PRUNE" -eq 1 ]; then
    echo "[$(date)] Pruning the build to its install and test tools..."
    KEEP="$(mktemp -d)"
    mv "$LLVM_BUILD_DIR/install" "$KEEP/install"
    mkdir -p "$KEEP/bin"
    for tool in llvm-lit "${TEST_TOOLS[@]}"; do
        mv "$LLVM_BUILD_DIR/bin/$tool" "$KEEP/bin/"
    done
    rm -rf "$LLVM_BUILD_DIR"
    mv "$KEEP" "$LLVM_BUILD_DIR"
fi

# Point llvm-project/build at the selected build.
if [ "$(dirname "$LLVM_BUILD_DIR")" = "$LLVM_DIR" ]; then
    LINK_TARGET="$(basename "$LLVM_BUILD_DIR")"
else
    LINK_TARGET="$LLVM_BUILD_DIR"
fi
if [ "$LINK_TARGET" != "build" ]; then
    ln -sfn "$LINK_TARGET" "$LLVM_DIR/build"
fi
echo "[$(date)] Done. $LLVM_DIR/build -> $LINK_TARGET"
