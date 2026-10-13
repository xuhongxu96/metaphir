cmake_minimum_required(VERSION 3.20)

project(MetaphIR VERSION 0.1.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

set(METAPHIR_USE_SANITIZER "" CACHE STRING
    "Build MetaphIR with a sanitizer (e.g. 'address'); LLVM stays uninstrumented")

add_compile_options(-fno-rtti)
if(METAPHIR_USE_SANITIZER)
  add_compile_options(-fsanitize=${METAPHIR_USE_SANITIZER} -fno-omit-frame-pointer)
  add_link_options(-fsanitize=${METAPHIR_USE_SANITIZER})
  # LLVM's BumpPtrAllocator poisons slabs from inline code compiled into
  # MetaphIR but writes into them from the uninstrumented LLVM libraries.
  set(METAPHIR_TEST_ENVIRONMENT "ASAN_OPTIONS=allow_user_poisoning=0")
endif()

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
    gtest_discover_tests(${test_name}
        PROPERTIES ENVIRONMENT "${METAPHIR_TEST_ENVIRONMENT}")
endfunction()

include_directories(${PROJECT_SOURCE_DIR})
include_directories(SYSTEM ${LLVM_INCLUDE_DIRS})

# Project targets (but not the vendored gtest above) build warning-clean.
add_compile_options(-Wall -Wextra -Wno-unused-parameter -Werror)

add_subdirectory(metaphir)
add_subdirectory(test)
add_subdirectory(tools)
