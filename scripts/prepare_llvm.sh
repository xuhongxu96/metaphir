#!/bin/bash
set -e

BASE_DIR=$(pwd)
CACHE_DIR=${CACHE_DIR:-/nvme/h445xu/ccache}
LLVM_COMMIT="53a7028134738d799d8b758a5675873e325dd9e0"
LLVM_DIR="$BASE_DIR/llvm-project"
LLVM_BUILD_DIR="$LLVM_DIR/build"
LLVM_BUILD_TYPE=${LLVM_BUILD_TYPE:-Debug}

echo "Using LLVM commit: $LLVM_COMMIT"

if [ ! -d "$LLVM_DIR" ]; then
    echo "[$(date)] Initializing llvm-project ($LLVM_COMMIT)..."
    git init -q "$LLVM_DIR"
    git -C "$LLVM_DIR" remote add origin https://github.com/llvm/llvm-project.git
fi

CURRENT_COMMIT=$(git -C "$LLVM_DIR" rev-parse HEAD 2>/dev/null || echo "none")
if [ "$CURRENT_COMMIT" != "$LLVM_COMMIT" ]; then
    echo "[$(date)] Syncing to $LLVM_COMMIT (was $CURRENT_COMMIT)..."
    if ! git -C "$LLVM_DIR" fetch --depth 1 origin "$LLVM_COMMIT"; then
        echo "[$(date)] Fetch failed."
        exit 1
    fi
    git -C "$LLVM_DIR" reset --hard FETCH_HEAD
    git -C "$LLVM_DIR" clean -fdx
else
    echo "[$(date)] llvm-project already at correct version, skipping."
fi

# Patch
git -C "$LLVM_DIR" reset --hard FETCH_HEAD
git -C "$LLVM_DIR" apply $BASE_DIR/eval/patches/*.patch

# Configure LLVM
echo "[$(date)] Building LLVM..."
mkdir -p "$LLVM_BUILD_DIR"
cd "$LLVM_BUILD_DIR"
cmake -G Ninja ../llvm \
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
