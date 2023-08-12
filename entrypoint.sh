#!/bin/bash
sed 's/\r$//' dependencies/apt.txt | sed 's/#.*//' | xargs apt install -y

mkdir -p build_gcc
mkdir -p build_clang

export CC=gcc
export CXX=g++
cmake -G'Unix Makefiles' -Bbuild_gcc
cmake --build build_gcc

export CC=clang
export CXX=clang++
cmake -G'Unix Makefiles' -Bbuild_clang
cmake --build build_clang

rm -rf build_gcc
rm -rf build_clang

