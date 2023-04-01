#!/bin/bash
# Use to print each step: #!/bin/bash -x
#
# Example script -- boilerplate to automate compilation (and, possibly, execution) the lab project.
#

set -o errexit
set -o nounset
set -o pipefail

######
# Color variables
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color
#####
#
PROJECT_NAME_INIT=$(cat CMakeLists.txt | grep "set(PROJECT_NAME")
PREFIX="$MAGENTA[APPS testing compilation]: ${NC}"
install_prefix=".."
WERR="ON"
KEEP=false

while [[ $# -gt 0 ]]; do
  case $1 in
  -h | --help)
    echo "Usage: ./compile.sh [options] 

The script to compile a project. Produces multiple executables:
1) (./bin/release) 			It compiles the Release version of a project to test it\'s performance 
2) (./bin/run_with_asan_ubsan)		LINUX_ONLY: It compiles the Debug version of a project with ASAN and UBSan and PVS
3) (./bin/run_with_tsan)		LINUX_ONLY: It compiles the Debug version of a project with TSan 
4) (./bin/run_with_msan)		MACOS_ONLY: It compiles the Debug version of a project with MSAN and PVS
Options:
	-h		--help 	Show help message.
	-k		--keep-build 	keep build directories.
	-w		--werr 	OFF warnings_as_errors. Switched ON as default for release build, ASAN and MSAN."

    exit 0
    ;;
  -w | --werr)
	WERR="OFF"
	shift
	;;
  -k | --keep-build)
	KEEP=true
	shift
	;;
  \?)
    echo "Invalid option: -$OPTARG" >&2
    exit 1
    ;;
  *)
    break
    ;;
  esac
done

UNAME="$(uname -s)"
case "${UNAME}" in 
	Linux*)		machine=0;;
	Darwin*)	machine=1;;
	*)			echo "Unknown machine; only MacOS and Linux are supported;";;
esac

###############################################
######### Useful functions declaration ########
###############################################


function f_set_pvs() {
	sed -i '/ENABLE_PVS_STUDIO/d' CMakeLists.txt
	sed -i "15i set(ENABLE_PVS_STUDIO ${1})" CMakeLists.txt
}

function f_set_proj_name() {
	sed -i "s/^set(PROJECT_NAME.*/set(PROJECT_NAME ${1})/" ./CMakeLists.txt
}

function f_set_werr() {
	sed -i '/WARNINGS_AS_ERRORS/d' CMakeLists.txt
	sed -i "15i set(WARNINGS_AS_ERRORS ${1})" CMakeLists.txt
}

function f_set_ubsan() {
	sed -i '/ENABLE_UBSan/d' CMakeLists.txt
	sed -i "15i set(ENABLE_UBSan ${1})" CMakeLists.txt
}

function f_set_asan() {
	sed -i '/ENABLE_ASAN/d' CMakeLists.txt
	sed -i "15i set(ENABLE_ASAN ${1})" CMakeLists.txt
}

function f_set_tsan() {
	sed -i '/ENABLE_TSAN/d' CMakeLists.txt
	sed -i "15i set(ENABLE_TSAN ${1})" CMakeLists.txt
}

function f_set_msan() {
	sed -i '/ENABLE_MSAN/d' CMakeLists.txt
	sed -i "15i set(ENABLE_MSAN ${1})" CMakeLists.txt
}

f_set_werr "$WERR"
###############################################
############ Main compilation part ############
###############################################
f_set_proj_name "release"
mkdir -p ./cmake-build-release
(
    pushd ./cmake-build-release > /dev/null || exit 1
    echo -e "$PREFIX${RED}Compiling Release...${NC}\n"
    cmake -DPROJECT_NAME="release" -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX="${install_prefix}" .. || exit 1
    cmake --build . || exit 1
    cmake --install . || exit 1
    popd
)

if [[ "$machine" -eq 0 ]]; then
	# Linux
	# change the CMakeLists.txt because there are problems...
	f_set_pvs "ON"
	f_set_asan "ON"
	f_set_ubsan "ON"
	mkdir -p ./cmake-build-asan-ubsan-pvs
	(
	    pushd ./cmake-build-asan-ubsan-pvs > /dev/null || exit 1
	    echo -e "$PREFIX${RED}Compiling with ASAN, UBSan and PVS...${NC}\n"
	    cmake -DPROJECT_NAME="run_with_asan_ubsan" -DCMAKE_BUILD_TYPE=Debug -DCMAKE_INSTALL_PREFIX="${install_prefix}" .. || exit 1
	    cmake --build . || exit 1
	    cmake --install . || exit 1
	    popd
	)
	f_set_pvs "OFF"
	f_set_asan "OFF"
	f_set_ubsan "OFF"
	f_set_tsan "ON"
	mkdir -p ./cmake-build-tsan
	(
	    pushd ./cmake-build-tsan > /dev/null || exit 1
	    echo -e "$PREFIX${RED}Compiling TSan...${NC}"
	    cmake -DPROJECT_NAME="run_with_tsan" -DCMAKE_BUILD_TYPE=Debug -DCMAKE_INSTALL_PREFIX="${install_prefix}" .. || exit 1
	    cmake --build . || exit 1
	    cmake --install . || exit 1
	    popd
	)
	f_set_tsan "OFF"
elif [[ "$machine" -eq 1 ]]; then
	# MacOS
	f_set_pvs "ON"
	f_set_msan "ON"
	mkdir -p ./cmake-build-msan
	(
	    pushd ./cmake-build-msan > /dev/null || exit 1
	    echo "$PREFIX${RED}Compiling MSAN...${NC}"
	    cmake -DPROJECT_NAME="run_with_msan" -DCMAKE_BUILD_TYPE=Debug -DCMAKE_INSTALL_PREFIX="${install_prefix}" .. || exit 1
	    cmake --build . || exit 1
	    cmake --install . || exit 1
	    popd
	)
	f_set_pvs "OFF"
	f_set_msan "OFF"
fi

if [ "$KEEP" == false ]; then
	rm -rf cmake-build-tsan cmake-build-asan-ubsan-pvs cmake-build-release cmake-build-msan
fi
