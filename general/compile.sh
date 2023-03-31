#!/bin/bash 
# Use to print each step: #!/bin/bash -x
#
# Example script -- boilerplate to automate compilation (and, possibly, execution) the lab project.
#

set -o errexit
set -o nounset
set -o pipefail

######
RED='\033[0;31m'
NC='\033[0m' # No Color
#####
#
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

mkdir -p ./cmake-build-release
(
    pushd ./cmake-build-release > /dev/null || exit 1
    echo -e "${RED}Compiling Release...${NC}\n"
    cmake -DPROJECT_NAME="release" -DWARNINGS_AS_ERRORS=$WERR -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX="${install_prefix}" .. || exit 1
    cmake --build . || exit 1
    cmake --install . || exit 1
    popd
)

if [[ "$machine" -eq 0 ]]; then
	# Linux
	mkdir -p ./cmake-build-asan-ubsan-pvs
	(
	    pushd ./cmake-build-asan-ubsan-pvs > /dev/null || exit 1
	    echo -e "${RED}Compiling with ASAN, UBSan and PVS...${NC}\n"
	    cmake -DPROJECT_NAME="run_with_asan_ubsan" -DWARNINGS_AS_ERRORS=$WERR -DENABLE_PVS_STUDIO=ON -DCMAKE_BUILD_TYPE=Debug -DENABLE_ASAN=ON -DENABLE_UBSan=ON -DCMAKE_INSTALL_PREFIX="${install_prefix}" .. || exit 1
	    cmake --build . || exit 1
	    cmake --install . || exit 1
	    popd
	)
	mkdir -p ./cmake-build-tsan
	(
	    pushd ./cmake-build-tsan > /dev/null || exit 1
	    echo -e "${RED}Compiling TSan...${NC}"
	    cmake -DPROJECT_NAME="run_with_tsan" -DCMAKE_BUILD_TYPE=Debug -DENABLE_TSan=ON -DCMAKE_INSTALL_PREFIX="${install_prefix}" .. || exit 1
	    cmake --build . || exit 1
	    cmake --install . || exit 1
	    popd
	)
elif [[ "$machine" -eq 1 ]]; then
	# MacOS
	mkdir -p ./cmake-build-msan
	(
	    pushd ./cmake-build-msan > /dev/null || exit 1
	    echo "${RED}Compiling MSAN...${NC}"
	    cmake -DPROJECT_NAME="run_with_msan" -DWARNINGS_AS_ERRORS=$WERR -DENABLE_PVS_STUDIO -DCMAKE_BUILD_TYPE=Debug -DENABLE_MSAN=ON -DCMAKE_INSTALL_PREFIX="${install_prefix}" .. || exit 1
	    cmake --build . || exit 1
	    cmake --install . || exit 1
	    popd
	)
fi

if [ ! $KEEP ]; then
	rm -rf cmake-build-tsan cmake-build-asan-ubsan-pvs cmake-build-release cmake-build-msan
fi
