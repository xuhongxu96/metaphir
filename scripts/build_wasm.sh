#!/bin/bash
# Build MetaphIR for the browser with Emscripten, under build-wasm/:
#
#   build-wasm/emsdk     the Emscripten SDK (unless EMSDK is set)
#   build-wasm/host      llvm-tblgen, when llvm-project has no native build
#   build-wasm/llvm      LLVM's libraries, built for WebAssembly from
#                        llvm-project (as scripts/prepare_llvm.sh left it)
#   build-wasm/metaphir  metaphir.{js,wasm} and metaphir-match.{js,wasm}
#
# and copies the modules into web/public/wasm/ for the website.
#
# Usage: scripts/build_wasm.sh
#
# Environment:
#   EMSDK      an activated Emscripten SDK to use instead of build-wasm/emsdk
#   CACHE_DIR  ccache directory (ccache default when unset)
#   JOBS       parallel build jobs (nproc)
#
# Compiles go through ccache when it is installed, as in prepare_llvm.sh.
#
# llvm-project must be prepared by scripts/prepare_llvm.sh (--source-only
# suffices): the native tools and these read published corpora alike only if
# built from the same source. LLVM's table generator comes from the native
# build (llvm-project/build/bin) when there is one.
set -euo pipefail

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BUILD_DIR="$BASE_DIR/build-wasm"
EMSDK_VERSION="6.0.10"
JOBS="${JOBS:-$(nproc)}"
NATIVE_BIN="$BASE_DIR/llvm-project/build/bin"

if [ ! -f "$BASE_DIR/llvm-project/llvm/CMakeLists.txt" ]; then
    echo "Error: no llvm-project source; run scripts/prepare_llvm.sh --source-only first." >&2
    exit 1
fi
mkdir -p "$BUILD_DIR"

if [ -z "${EMSDK:-}" ]; then
    EMSDK="$BUILD_DIR/emsdk"
    if [ ! -d "$EMSDK" ]; then
        echo "[$(date)] Fetching the Emscripten SDK..."
        git clone -q --depth 1 https://github.com/emscripten-core/emsdk.git "$EMSDK"
    fi
    "$EMSDK/emsdk" install "$EMSDK_VERSION"
    "$EMSDK/emsdk" activate "$EMSDK_VERSION" >/dev/null
fi
# shellcheck disable=SC1091
source "$EMSDK/emsdk_env.sh" >/dev/null 2>&1
echo "Using $(emcc --version | head -1)"

# ccache takes em++ as it would any compiler.
CCACHE_ARGS=()
if command -v ccache >/dev/null; then
    CCACHE_ARGS=(-DCMAKE_C_COMPILER_LAUNCHER=ccache
                 -DCMAKE_CXX_COMPILER_LAUNCHER=ccache)
    if [ -n "${CACHE_DIR:-}" ]; then
        export CCACHE_DIR="$CACHE_DIR"
    fi
fi

if [ ! -x "$NATIVE_BIN/llvm-tblgen" ]; then
    echo "[$(date)] Building llvm-tblgen for this machine..."
    cmake -G Ninja -S "$BASE_DIR/llvm-project/llvm" -B "$BUILD_DIR/host" \
        -DCMAKE_BUILD_TYPE=Release \
        -DLLVM_TARGETS_TO_BUILD="" \
        -DLLVM_INCLUDE_TESTS=OFF \
        -DLLVM_INCLUDE_BENCHMARKS=OFF \
        -DLLVM_INCLUDE_EXAMPLES=OFF \
        "${CCACHE_ARGS[@]}" >/dev/null
    cmake --build "$BUILD_DIR/host" -- -j"$JOBS" llvm-tblgen llvm-min-tblgen
    NATIVE_BIN="$BUILD_DIR/host/bin"
fi

echo "[$(date)] Building LLVM for WebAssembly..."
emcmake cmake -G Ninja -S "$BASE_DIR/llvm-project/llvm" -B "$BUILD_DIR/llvm" \
    -DCMAKE_BUILD_TYPE=MinSizeRel \
    -DLLVM_TARGETS_TO_BUILD="" \
    -DLLVM_DEFAULT_TARGET_TRIPLE=wasm32-unknown-emscripten \
    -DLLVM_ENABLE_PROJECTS="" \
    -DLLVM_ENABLE_THREADS=OFF \
    -DLLVM_ENABLE_ZLIB=OFF \
    -DLLVM_ENABLE_ZSTD=OFF \
    -DLLVM_ENABLE_LIBXML2=OFF \
    -DLLVM_ENABLE_TERMINFO=OFF \
    -DLLVM_ENABLE_LIBEDIT=OFF \
    -DLLVM_ENABLE_LIBPFM=OFF \
    -DLLVM_ENABLE_RTTI=OFF \
    -DLLVM_ENABLE_EH=OFF \
    -DLLVM_ENABLE_ASSERTIONS=OFF \
    -DLLVM_INCLUDE_TESTS=OFF \
    -DLLVM_INCLUDE_BENCHMARKS=OFF \
    -DLLVM_INCLUDE_EXAMPLES=OFF \
    -DLLVM_INCLUDE_UTILS=OFF \
    -DLLVM_INCLUDE_DOCS=OFF \
    -DLLVM_BUILD_TOOLS=OFF \
    -DLLVM_TABLEGEN="$NATIVE_BIN/llvm-tblgen" \
    -DLLVM_NATIVE_TOOL_DIR="$NATIVE_BIN" \
    "${CCACHE_ARGS[@]}" >/dev/null
cmake --build "$BUILD_DIR/llvm" -- -j"$JOBS" \
    LLVMAnalysis LLVMAsmParser LLVMBitReader LLVMBitWriter LLVMCore \
    LLVMIRReader LLVMSupport LLVMTransformUtils

echo "[$(date)] Building MetaphIR for WebAssembly..."
emcmake cmake -G Ninja -S "$BASE_DIR/web/wasm" -B "$BUILD_DIR/metaphir" \
    -DCMAKE_BUILD_TYPE=MinSizeRel \
    -DLLVM_DIR="$BUILD_DIR/llvm/lib/cmake/llvm" \
    "${CCACHE_ARGS[@]}" >/dev/null
cmake --build "$BUILD_DIR/metaphir" -- -j"$JOBS" metaphir metaphir-match

mkdir -p "$BASE_DIR/web/public/wasm"
cp "$BUILD_DIR"/metaphir/metaphir{,-match}.{js,wasm} "$BASE_DIR/web/public/wasm/"
echo "[$(date)] Built web/public/wasm/metaphir{,-match}.{js,wasm}"
