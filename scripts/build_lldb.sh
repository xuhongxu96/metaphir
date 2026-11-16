#!/bin/bash
# Build LLDB and its DAP adapter from llvm-project's source, for the debugger
# settings in .vscode/, under build-lldb/ in the repository:
#
#   build-lldb/swig      SWIG 4, from PyPI, unless a SWIG 4 is installed
#   build-lldb/build     the build tree (Ninja)
#   build-lldb/install   the install: bin/lldb, bin/lldb-dap, bin/lldb-server,
#                        and LLDB's Python package in lib/python3/site-packages
#   build-lldb/formatters  LLVM's and MLIR's LLDB data formatters, patched (see below)
#
# The release build is installed into build-lldb/install, which VS Code reads
# through ${workspaceFolder}. Needs a C++ compiler, CMake, Ninja, and Python 3
# development headers; SWIG is only needed to build LLDB's Python scripting.
#
# Usage: scripts/build_lldb.sh [--force]
#   --force   reconfigure even when build-lldb/build exists
#
# Environment:
#   JOBS      parallel build jobs (nproc)
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO"

SOURCE="$REPO/llvm-project/llvm"
BUILD_DIR="$REPO/build-lldb"
JOBS="${JOBS:-$(nproc)}"
FORCE=0
[[ "${1:-}" == "--force" ]] && FORCE=1

if [[ ! -f "$SOURCE/CMakeLists.txt" || ! -d "$REPO/llvm-project/lldb" ]]; then
    echo "llvm-project is missing: run scripts/prepare_llvm.sh --source-only first" >&2
    exit 1
fi

# SWIG 4: the system one if it is new enough, else the PyPI wheel's.
find_swig() {
    local candidate
    if candidate="$(command -v swig 2>/dev/null)" &&
        [[ "$("$candidate" -version 2>&1 | sed -n 's/.*Version \([0-9]*\).*/\1/p' | head -1)" -ge 4 ]]; then
        echo "$candidate"
        return
    fi
    local prefix="$BUILD_DIR/swig"
    # The wheel's binary is under data/bin; its bin/swig is a Python wrapper.
    if [[ -z "$(find "$prefix" -path '*/data/bin/swig' -type f 2>/dev/null | head -1)" ]]; then
        echo "building SWIG 4 from PyPI into $prefix" >&2
        python3 -m pip install --quiet --target "$prefix" swig >&2
    fi
    find "$prefix" -path '*/data/bin/swig' -type f | head -1
}

SWIG="$(find_swig)"
if [[ -z "$SWIG" ]]; then
    echo "no SWIG 4 found" >&2
    exit 1
fi
# SWIG's library files: the system's, or the ones beside the wheel's binary.
SWIG_LIB="$("$SWIG" -swiglib 2>/dev/null || true)"
if [[ ! -f "$SWIG_LIB/swig.swg" ]]; then
    SWIG_LIB="$(dirname "$(find "$BUILD_DIR/swig" -name swig.swg | head -1)")"
fi
export SWIG_LIB

if [[ $FORCE -eq 1 || ! -f "$BUILD_DIR/build/build.ninja" ]]; then
    cmake -S "$SOURCE" -B "$BUILD_DIR/build" -G Ninja \
        -DCMAKE_BUILD_TYPE=Release \
        -DCMAKE_INSTALL_PREFIX="$BUILD_DIR/install" \
        -DLLVM_ENABLE_PROJECTS="clang;lldb" \
        -DLLVM_TARGETS_TO_BUILD=Native \
        -DLLVM_ENABLE_ASSERTIONS=OFF \
        -DLLVM_ENABLE_RTTI=ON \
        -DLLVM_INCLUDE_TESTS=OFF \
        -DLLVM_BUILD_TOOLS=OFF \
        -DCLANG_BUILD_TOOLS=OFF \
        -DLLVM_ENABLE_ZLIB=ON \
        -DLLDB_ENABLE_PYTHON=ON \
        -DLLDB_PYTHON_RELATIVE_PATH=lib/python3/site-packages \
        -DSWIG_EXECUTABLE="$SWIG" \
        -DSWIG_DIR="$SWIG_LIB" \
        -DLLDB_ENABLE_LUA=OFF \
        -DLLDB_ENABLE_LIBEDIT=OFF \
        -DLLDB_ENABLE_CURSES=OFF \
        -DLLDB_INCLUDE_TESTS=OFF
fi

ninja -C "$BUILD_DIR/build" -j "$JOBS" lldb lldb-dap lldb-server
ninja -C "$BUILD_DIR/build" install-lldb install-lldb-dap install-lldb-server install-liblldb

# MLIR's formatters crash LLDB on a null mlir::Value (a default one, such as an
# unset capture): its children recurse until the stack overflows. The copy
# here returns no children and a <null> summary for a null value. Upstream
# llvm-project is left as it is.
FORMATTERS="$BUILD_DIR/formatters"
mkdir -p "$FORMATTERS"
python3 - "$REPO/llvm-project/mlir/utils/lldb-scripts/mlirDataFormatters.py" \
    "$FORMATTERS/mlirDataFormatters.py" <<'PY'
import sys

source, target = sys.argv[1:3]
text = open(source).read()


def replace_once(text, old, new):
    assert text.count(old) == 1, f"not unique: {old[:60]!r}"
    return text.replace(old, new)


# A helper before the value's synthetic provider.
text = replace_once(
    text,
    "class ValueSynthProvider:",
    '''def _is_null_value(valobj):
    """A default-constructed mlir::Value has a null implementation pointer."""
    # Summaries get the synthetic value, which has no impl child of its own.
    if valobj.IsSynthetic():
        valobj = valobj.GetNonSyntheticValue()
    impl = valobj.GetChildMemberWithName("impl")
    return impl.IsValid() and impl.GetValueAsUnsigned(0) == 0


class ValueSynthProvider:''',
)
# Values have no children, and their summary is a plain name: reading them
# calls functions in the stopped program (getOwner, debug_getType, ...), and
# that crashes LLDB while the parser is stopped on a value (a breakpoint at
# setDefaultContext, for one). Null values still print as <null>.
text = replace_once(
    text,
    "    def num_children(self):\n        # 7: BlockArgument:",
    "    def num_children(self):\n        return 0\n\n"
    "        # 7: BlockArgument:",
)
text = replace_once(
    text,
    '    """Define an LLDB summary provider for Values."""\n\n',
    '    """Define an LLDB summary provider for Values."""\n\n'
    '    if _is_null_value(valobj):\n'
    '        return "<null>"\n'
    '    return "mlir::Value"\n\n',
)
open(target, "w").write(text)
print("patched", target)
PY
# LLVM's data formatters show every SmallVector as empty: its size is in
# SmallVectorBase, whose members the debug info does not describe. The copy
# here reads the layout directly: BeginX (a pointer) at offset 0, and Size (an
# unsigned 32-bit) at offset 8. Children are built from their addresses, so no
# function runs in the program.
python3 - "$REPO/llvm-project/llvm/utils/lldbDataFormatters.py" \
    "$FORMATTERS/lldbDataFormatters.py" <<'PY'
import sys

source, target = sys.argv[1:3]
text = open(source).read()

NEW_PROVIDER = '''class SmallVectorSynthProvider:
    """Provider for llvm::SmallVector, read from memory (see the patch in build_lldb.sh)."""

    def __init__(self, valobj, internal_dict) -> None:
        self.valobj = valobj
        self.update()

    def num_children(self) -> int:
        return self.count

    def get_child_index(self, name):
        try:
            return int(name.lstrip("[").rstrip("]"))
        except:
            return -1

    def get_child_at_index(self, index):
        if index < 0 or index >= self.count:
            return None
        return self.valobj.CreateValueFromAddress(
            "[" + str(index) + "]",
            self.begin_address + index * self.type_size,
            self.data_type,
        )

    def update(self):
        the_type = self.valobj.GetType()
        if the_type.IsReferenceType():
            the_type = the_type.GetDereferencedType()
        if the_type.IsPointerType():
            the_type = the_type.GetPointeeType()
        self.data_type = the_type.GetTemplateArgumentType(0)
        self.type_size = self.data_type.GetByteSize()
        assert self.type_size != 0
        process = self.valobj.GetProcess()
        address = self.valobj.GetLoadAddress()
        error = lldb.SBError()
        self.begin_address = process.ReadPointerFromMemory(address, error)
        self.count = 0
        if error.Success():
            count = process.ReadUnsignedFromMemory(address + 8, 4, error)
            if error.Success():
                self.count = count


'''
start = text.index("class SmallVectorSynthProvider:")
end = text.index("class ArrayRefSynthProvider:")
text = text[:start] + NEW_PROVIDER + text[end:]
open(target, "w").write(text)
print("patched", target)
PY
echo
echo "LLDB installed in $BUILD_DIR/install:"
echo "  adapter:  $BUILD_DIR/install/bin/lldb-dap"
echo "  Python:   $BUILD_DIR/install/lib/python3/site-packages"
