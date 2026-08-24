cmake_minimum_required(VERSION 3.20)

project(MetaphIR VERSION 0.1.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

add_compile_options(-fno-rtti)

set(LLVM_DIR
    ${PROJECT_SOURCE_DIR}/llvm-project/build/install/lib/cmake/llvm
    CACHE PATH "Directory containing LLVMConfig.cmake")
find_package(LLVM 24.0.0 REQUIRED CONFIG)

enable_testing()
include(GoogleTest)

set(GTEST_ROOT ${PROJECT_SOURCE_DIR}/llvm-project/third-party/unittest/googletest)
add_library(metaphir-gtest STATIC ${GTEST_ROOT}/src/gtest-all.cc)
target_include_directories(metaphir-gtest
    PUBLIC
        ${GTEST_ROOT}/include
        ${LLVM_INCLUDE_DIRS}
    PRIVATE
        ${GTEST_ROOT}
)
target_link_libraries(metaphir-gtest PUBLIC LLVMSupport)
target_compile_definitions(metaphir-gtest PUBLIC GTEST_HAS_RTTI=0)

add_library(metaphir-gtest-main STATIC ${GTEST_ROOT}/src/gtest_main.cc)
target_link_libraries(metaphir-gtest-main PUBLIC metaphir-gtest)

function(add_metaphir_test test_name)
    add_executable(${test_name} ${ARGN})
    target_link_libraries(${test_name} PRIVATE metaphir-gtest-main)
    gtest_discover_tests(${test_name})
endfunction()

include_directories(${CMAKE_SOURCE_DIR} ${LLVM_INCLUDE_DIRS})

add_subdirectory(metaphir)
add_subdirectory(test)
add_subdirectory(tools)
