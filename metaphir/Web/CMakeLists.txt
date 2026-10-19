# Published corpora are compressed with zstd: the system's, which LLVM uses
# too, or, where there is none (as for WebAssembly), a release built here.
if(NOT EMSCRIPTEN)
  find_package(zstd QUIET)
endif()
if(TARGET zstd::libzstd_shared)
  set(METAPHIR_ZSTD zstd::libzstd_shared)
elseif(TARGET zstd::libzstd_static)
  set(METAPHIR_ZSTD zstd::libzstd_static)
else()
  enable_language(C)
  include(FetchContent)
  FetchContent_Declare(
    zstd
    URL https://github.com/facebook/zstd/releases/download/v1.5.7/zstd-1.5.7.tar.gz
    URL_HASH
      SHA256=eb33e51f49a15e023950cd7825ca74a4a2b43db8354825ac24fc1b7ee09e6fa3
    DOWNLOAD_EXTRACT_TIMESTAMP TRUE
    # Its own build is not used.
    SOURCE_SUBDIR none)
  FetchContent_MakeAvailable(zstd)
  file(GLOB ZSTD_SOURCES ${zstd_SOURCE_DIR}/lib/common/*.c
       ${zstd_SOURCE_DIR}/lib/compress/*.c ${zstd_SOURCE_DIR}/lib/decompress/*.c
       ${zstd_SOURCE_DIR}/lib/dictBuilder/*.c)
  add_library(metaphir-zstd STATIC ${ZSTD_SOURCES})
  target_include_directories(metaphir-zstd SYSTEM
                             PUBLIC ${zstd_SOURCE_DIR}/lib)
  target_compile_definitions(metaphir-zstd PRIVATE ZSTD_DISABLE_ASM)
  set(METAPHIR_ZSTD metaphir-zstd)
endif()

# Matching a published corpus, read by byte ranges; the web build uses it
# too.
add_library(metaphir-web WebIndex.cpp WebIndex.h WebQuery.cpp WebQuery.h
                         Zstd.cpp Zstd.h)

target_link_libraries(metaphir-web PUBLIC metaphir-index-core metaphir-parser
                                          ${METAPHIR_ZSTD})

# Publishing a corpus from its index.
add_library(metaphir-web-publish WebPublisher.cpp WebPublisher.h)

target_link_libraries(metaphir-web-publish PUBLIC metaphir-web
                                                  metaphir-index-lib)
