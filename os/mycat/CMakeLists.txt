cmake_minimum_required(VERSION 3.14)
project(runner C CXX)

set(CMAKE_C_STANDARD 99)
#  -fsanitize=pointer-compare -fsanitize=pointer-subtract
# set (CMAKE_CXX_FLAGS_DEBUG "${CMAKE_CXX_FLAGS_DEBUG} -fno-omit-frame-pointer -fsanitize=address -fsanitize=leak -fsanitize=undefined")
# set (CMAKE_LINKER_FLAGS_DEBUG "${CMAKE_LINKER_FLAGS_DEBUG} -fno-omit-frame-pointer -fsanitize=address -fsanitize=leak -fsanitize=undefined")

add_executable(runner runner_adv_main.cpp)
