#!/bin/bash

# ChatGPT 3.5 generated modt of it =)

# Check GCC version
gcc_version=$(gcc --version | grep -oP "(?<=gcc \(GCC\)\ )\d+")
if [[ $gcc_version -ge 12 ]]; then
    echo "GCC version is sufficient."
else
    echo "GCC version is below the required minimum."
fi

# Check CMake version
cmake_version=$(cmake --version | grep -oP "(?<=cmake version )\d+\.\d+")
if [[ $cmake_version > 3.15 ]]; then
    echo "CMake version is sufficient."
else
    echo "CMake version is below the required minimum."
fi

# Check Clang version
clang_version=$(clang --version | grep -oP "(?<=clang version )\d+")
if [[ $clang_version -ge 14 ]]; then
    echo "Clang version is sufficient."
else
    echo "Clang version is below the required minimum."
fi

# Check Boost version
boost_version=$(cat /usr/include/boost/version.hpp | grep -oP "(?<=BOOST_VERSION )[0-9]+")
if [[ $boost_version -ge 107400 ]]; then
    echo "Boost version is sufficient."
else
    echo "Boost version is below the required minimum."
fi


