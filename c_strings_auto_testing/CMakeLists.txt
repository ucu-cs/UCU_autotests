cmake_minimum_required(VERSION 3.0)

set(CMAKE_CXX_COMPILER /usr/bin/g++)
# CHANGE YOUR PROJECT NAME
set(PROJECT_NAME c_string_tests)
set(CMAKE_CXX_STANDARD 20)

project(${PROJECT_NAME} C CXX)

set(LIBN my_c_string)
#set(CMAKE_C_STANDARD 11)
set(CMAKE_BUILD_TYPE Debug)
# Options
set(WARNINGS_AS_ERRORS OFF)
set(ENABLE_PVS_STUDIO OFF)
#! ENABLE_SANITIZERS is the option for the test builds!
#  Definitely enable it while developing.
#  Disable it for the production builds and before submitting for grading!
set(ENABLE_SANITIZERS OFF)

# Only one of Memory(MSAN), Address(ASAN), or Thread(TSan) sanitizers is applicable at the time
set(ENABLE_UBSan OFF)
#set(ASAN_OPTIONS allocator_may_return_null=1)
#message(${ASAN_OPTIONS})
set(ENABLE_ASAN OFF)
set(ENABLE_TSan OFF)
set(ENABLE_MSAN OFF)

# !Warnings as errors should be imported here.
# !Do not delete this line! switch it 'OFF' in case you don't need it.
include(cmake/defaults/CompilerWarnings.cmake)

#####################################################################################################
# 1) set up gtests. This block of code is taken from https://crascit.com/2015/07/25/cmake-gtest/
# Download and unpack googletest at configure time
configure_file(CMakeLists.txt.in googletest-download/CMakeLists.txt)
execute_process(COMMAND "${CMAKE_COMMAND}" -G "${CMAKE_GENERATOR}" .
        WORKING_DIRECTORY "${CMAKE_BINARY_DIR}/googletest-download"
        )
execute_process(COMMAND "${CMAKE_COMMAND}" --build .
        WORKING_DIRECTORY "${CMAKE_BINARY_DIR}/googletest-download"
        )

# Prevent GoogleTest from overriding our compiler/linker options
# when building with Visual Studio
set(gtest_force_shared_crt ON CACHE BOOL "" FORCE)

# Add googletest directly to our build. This adds the following targets:
# gtest, gtest_main, gmock and gmock_main
add_subdirectory("${CMAKE_BINARY_DIR}/googletest-src"
        "${CMAKE_BINARY_DIR}/googletest-build"
        )

#####################################################################################################

# 2) build my_str library
add_library(
        ${LIBN} SHARED
        ${CMAKE_SOURCE_DIR}/c_str_lib/mystring.hpp
        ${CMAKE_SOURCE_DIR}/c_str_lib/mystring.cpp
)
target_include_directories(${LIBN} PUBLIC ${CMAKE_SOURCE_DIR}/c_str_lib)

#####################################################################################################
# 3) build tests
add_executable(gtester ${CMAKE_SOURCE_DIR}/google_tests/main.cpp ${CMAKE_SOURCE_DIR}/google_tests/Tests/tests.cpp)
target_compile_definitions(gtester PUBLIC FILE_DIR="${CMAKE_SOURCE_DIR}/google_tests/test_files")
target_link_libraries(gtester ${LIBN} gtest gtest_main)

###################################
# set output directory (bin)
set_target_properties(${LIBN} gtester
        PROPERTIES
        RUNTIME_OUTPUT_DIRECTORY ${CMAKE_SOURCE_DIR}/bin)
set_target_properties(${LIBN}
        PROPERTIES
        LIBRARY_OUTPUT_DIRECTORY ${CMAKE_SOURCE_DIR}/lib_bin
        ARCHIVE_OUTPUT_DIRECTORY ${CMAKE_SOURCE_DIR}/lib_bin)

#####################################
# Define ALL_TARGETS variable to use in PVS and Sanitizers
set(ALL_TARGETS gtester)
include(cmake/config.cmake)
