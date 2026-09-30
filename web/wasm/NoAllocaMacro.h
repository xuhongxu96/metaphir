// Included before every MetaphIR source of the WebAssembly build. Emscripten's
// libc defines alloca as an object-like macro (glibc's is function-like), which
// would rename the 'alloca' instruction matcher wherever its name is pasted
// into an identifier; the header is read once here, so it does not come back.
#include <alloca.h>
#undef alloca
