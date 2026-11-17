# metaphir-tblgen built for this machine, for cross builds (scripts/
# build_wasm.sh): a build for another platform cannot run the tool it builds.
# It needs only LLVM's TableGen library, from a native build of LLVM.
cmake_minimum_required(VERSION 3.20)
project(MetaphIRTableGenHost LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
find_package(LLVM REQUIRED CONFIG)
add_compile_options(-fno-rtti)
include_directories(SYSTEM ${LLVM_INCLUDE_DIRS})
add_subdirectory(${PROJECT_SOURCE_DIR}/../../tools/metaphir-tblgen metaphir-tblgen)
