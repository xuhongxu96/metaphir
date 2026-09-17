#!/bin/bash
set -e

BASE_DIR=$(pwd)
CACHE_DIR=${CACHE_DIR:-/data/h445xu/ccache}
LLVM_COMMIT="53a7028134738d799d8b758a5675873e325dd9e0"
LLVM_DIR="$BASE_DIR/llvm-project"
# Parse optional build type argument (default: Release)
BUILD_TYPE_ARG="${1:-${LLVM_BUILD_TYPE:-Release}}"
case "${BUILD_TYPE_ARG,,}" in
    release|--release)
        LLVM_BUILD_TYPE="Release"
        DEFAULT_BUILD_DIR="$LLVM_DIR/build-release"
        ;;
    debug|--debug)
        LLVM_BUILD_TYPE="Debug"
        DEFAULT_BUILD_DIR="$LLVM_DIR/build-debug"
        ;;
    -h|--help|help)
        echo "Usage: $0 [debug|release]"
        exit 0
        ;;
    *)
        echo "Error: Invalid build type '$1'. Expected 'debug' or 'release'." >&2
        echo "Usage: $0 [debug|release]" >&2
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

# Reset and patch
echo "[$(date)] Resetting to $LLVM_COMMIT and applying patches..."
git -C "$LLVM_DIR" reset --hard "$LLVM_COMMIT"
git -C "$LLVM_DIR" clean -fd
git -C "$LLVM_DIR" apply $BASE_DIR/eval/patches/*.patch

# Configure LLVM
echo "[$(date)] Building LLVM..."
mkdir -p "$LLVM_BUILD_DIR"
cd "$LLVM_BUILD_DIR"
cmake -G Ninja "$LLVM_DIR/llvm" \
    -DLLVM_ENABLE_PROJECTS="llvm" \
    -DLLVM_TARGETS_TO_BUILD="X86" \
    -DCMAKE_BUILD_TYPE=$LLVM_BUILD_TYPE \
    -DLLVM_INCLUDE_TESTS=ON \
    -DLLVM_INCLUDE_BENCHMARKS=OFF \
    -DLLVM_INCLUDE_EXAMPLES=OFF \
    -DLLVM_ENABLE_RTTI=OFF \
    -DLLVM_CCACHE_BUILD=ON \
    -DLLVM_CCACHE_MAXSIZE=10GB \
    -DLLVM_CCACHE_DIR=$CACHE_DIR

# Build
cmake --build . --target all -- -j8

# Install
cmake --install . --prefix "$LLVM_BUILD_DIR/install"
