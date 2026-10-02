# Builds the Dart FFI wrapper around a pinned whisper.cpp checkout.
# scripts/build_whisper.sh clones whisper.cpp next to this file; upstream files are never edited.
cmake_minimum_required(VERSION 3.14)
project(whisper_ffi C CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

set(BUILD_SHARED_LIBS ON CACHE BOOL "" FORCE)
set(WHISPER_BUILD_TESTS OFF CACHE BOOL "" FORCE)
set(WHISPER_BUILD_EXAMPLES OFF CACHE BOOL "" FORCE)
set(WHISPER_BUILD_SERVER OFF CACHE BOOL "" FORCE)

add_subdirectory(whisper.cpp)

add_library(whisper_ffi SHARED whisper_wrapper.cpp)
target_link_libraries(whisper_ffi PRIVATE whisper)
