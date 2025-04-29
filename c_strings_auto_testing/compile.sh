#!/bin/bash -x

# clean up in case compilation process termination
trap ctrl_c INT
function ctrl_c() {
	    rm -rf build
}

set -e
set -o errexit
set -o nounset
set -o pipefail

# just for tests
export ASAN_OPTIONS=allocator_may_return_null=1

cmake -B build -G Ninja || ctrl_c
ninja -C build -j $(grep -c ^processor /proc/cpuinfo) || ctrl_c

rm -rf build
