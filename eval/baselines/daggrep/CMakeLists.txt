cmake_minimum_required(VERSION 3.20)

project(daggrep CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(LLVM REQUIRED CONFIG)
list(APPEND CMAKE_MODULE_PATH ${LLVM_CMAKE_DIR})
include(AddLLVM)

include_directories(${LLVM_INCLUDE_DIRS})
add_definitions(${LLVM_DEFINITIONS})
add_compile_options(-fno-rtti)

set(LLVM_LINK_COMPONENTS
  core
  support
  irreader
  irprinter
  analysis
  passes
  ipo
  scalaropts
)
add_llvm_executable(daggrep PARTIAL_SOURCES_INTENDED daggrep.cpp)
