# The evaluated folds as a pass plugin for the pinned opt:
#
#   cmake -S eval/fold-plugin -B eval/fold-plugin/build \
#         -DLLVM_DIR=llvm-project/build/lib/cmake/llvm
#   cmake --build eval/fold-plugin/build
cmake_minimum_required(VERSION 3.20)
project(MetaphIRFolds LANGUAGES CXX)

find_package(LLVM REQUIRED CONFIG)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_BUILD_TYPE Release)

add_library(MetaphIRFolds MODULE MetaphIRFolds.cpp)
target_include_directories(MetaphIRFolds SYSTEM PRIVATE ${LLVM_INCLUDE_DIRS})
target_compile_definitions(MetaphIRFolds PRIVATE ${LLVM_DEFINITIONS})
target_compile_options(MetaphIRFolds PRIVATE -fno-rtti)
set_target_properties(MetaphIRFolds PROPERTIES PREFIX "")
