# MetaphIR for the browser, built with Emscripten against LLVM built for
# WebAssembly from the same llvm-project checkout (see scripts/
# build_wasm.sh):
#
#   metaphir.js/.wasm        matches published corpora (see Bindings.cpp)
#   metaphir-match.js/.wasm  the metaphir-match tool, which matches the IR
#                            written in the page (web/src/yourIR.ts)
cmake_minimum_required(VERSION 3.20)

project(MetaphIRWeb LANGUAGES C CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

find_package(LLVM REQUIRED CONFIG)

set(METAPHIR_ROOT ${PROJECT_SOURCE_DIR}/../..)

add_compile_options(-fno-rtti
                    "SHELL:-include ${PROJECT_SOURCE_DIR}/NoAllocaMacro.h")
include_directories(${METAPHIR_ROOT})
include_directories(SYSTEM ${LLVM_INCLUDE_DIRS})
add_subdirectory(${METAPHIR_ROOT}/metaphir metaphir)

set(METAPHIR_WASM_LINK_OPTIONS
    -sMODULARIZE=1
    -sEXPORT_ES6=1
    -sALLOW_MEMORY_GROWTH=1
    -sMAXIMUM_MEMORY=4GB
    -sENVIRONMENT=web,worker,node
    -sSTACK_SIZE=4MB)

add_executable(metaphir Bindings.cpp)
# Built without RTTI, as LLVM is.
target_compile_definitions(metaphir PRIVATE EMSCRIPTEN_HAS_UNBOUND_TYPE_NAMES=0)
target_link_libraries(metaphir PRIVATE metaphir-web)
target_link_options(metaphir PRIVATE ${METAPHIR_WASM_LINK_OPTIONS} -lembind -fno-rtti
                    -sEXPORT_NAME=createMetaphIR -sFILESYSTEM=0)

add_executable(metaphir-match ${METAPHIR_ROOT}/tools/metaphir-match.cpp)
target_link_libraries(metaphir-match PRIVATE metaphir-index-lib metaphir-web
                                             LLVMAsmParser LLVMIRReader)
target_compile_definitions(metaphir-match
                           PRIVATE METAPHIR_VERSION="${PROJECT_VERSION}")
target_link_options(
  metaphir-match PRIVATE ${METAPHIR_WASM_LINK_OPTIONS}
  -sEXPORT_NAME=createMetaphIRMatch -sINVOKE_RUN=0 -sEXIT_RUNTIME=0
  -sEXPORTED_RUNTIME_METHODS=callMain,FS)
