#!/bin/bash
# Use to print each step: #!/bin/bash -x
#
# Example script -- boilerplate to automate compilation (and, possibly, execution) the lab project.
#
set -e
set -o errexit
set -o nounset
set -o pipefail

on_exit() {
  # avoid printing the last line if there were no backup_CMakeLists file.
  echo -e "$PREFIX: Finishing. Restoring the CMakeLists.txt."
  mv backup_CMakeLists.txt CMakeLists.txt 2>/dev/null
}

# To restore the CMakeLists.txt after compilation
trap 'on_exit' EXIT

####
# Source colours and initialize some global variables
source $(dirname "$(readlink -f /usr/local/bin/test_compilation)")/general_settings.sh
install_prefix=".."
WERR="ON"
KEEP=false
MSAN=false

while [[ $# -gt 0 ]]; do
  case $1 in
  -h | --help)
    echo -e "${GREEN}Usage: ./compile.sh [options] 

The script to compile a project. Produces multiple executables:
1) (./bin/release) 			It compiles the Release version of a project to test it\'s performance 
2) (./bin/run_with_asan_ubsan)		It compiles the Debug version of a project with ASAN and UBSan and PVS
3) (./bin/run_with_tsan)		It compiles the Debug version of a project with TSan 
Options:
	-h		--help 	Show help message.
	-k		--keep-build 	keep build directories.
	-m		--msan 	compile also with MSan (available for Linux only, CLang compiler).
	-w		--no-werr 	OFF warnings_as_errors. Switched ON as default.${NC}"
    exit 0
    ;;
  -w | --no-werr)
    WERR="OFF"
    shift
    ;;
  -k | --keep-build)
    KEEP=true
    shift
    ;;
  -m | --msan)
    MSAN=true
    shift
    ;;
  \?)
    echo "$PREFIX${RED}: Invalid option: -$OPTARG ${NC}" >&2
    exit 1
    ;;
  *)
    break
    ;;
  esac
done

UNAME="$(uname -s)"
case "${UNAME}" in
Linux*) machine=0 ;;
Darwin*) machine=1 ;;
*) echo "$PREFIX${RED}: Unknown machine; only MacOS and Linux are supported;${NC}" ;;
esac

###
# backup a CMakeLists.txt

cp CMakeLists.txt backup_CMakeLists.txt

###############################################
######### Useful functions declaration ########
###############################################

# As far as options for CMake can't be used here because of caching,
# and otherwise it is hard to
function f_set_pvs() {
  sed -i "/ENABLE_PVS_STUDIO/d" CMakeLists.txt
  sed -i "15i set(ENABLE_PVS_STUDIO ${1})" CMakeLists.txt
}

function f_set_proj_name() {
  sed -i "s/^set(PROJECT_NAME.*/set(PROJECT_NAME ${1})/" ./CMakeLists.txt
}

function f_set_werr() {
  sed -i "/WARNINGS_AS_ERRORS/d" CMakeLists.txt
  sed -i "15i set(WARNINGS_AS_ERRORS ${1})" CMakeLists.txt
}

function f_set_ubsan() {
  sed -i "/ENABLE_UBSan/d" CMakeLists.txt
  sed -i "15i set(ENABLE_UBSan ${1})" CMakeLists.txt
}

function f_set_asan() {
  sed -i "/ENABLE_ASAN/d" CMakeLists.txt
  sed -i "15i set(ENABLE_ASAN ${1})" CMakeLists.txt
}

function f_set_tsan() {
  sed -i "/ENABLE_TSAN/d" CMakeLists.txt
  sed -i "15i set(ENABLE_TSAN ${1})" CMakeLists.txt
}

function f_set_msan() {
  sed -i "/ENABLE_MSAN/d" CMakeLists.txt
  sed -i "15i set(ENABLE_MSAN ${1})" CMakeLists.txt
}

f_set_werr "$WERR"
###############################################
############ Main compilation part ############
###############################################
f_set_proj_name "release"
mkdir -p ./apps-cmake-build-release
(
  pushd ./apps-cmake-build-release >/dev/null || exit 1
  echo -e "$PREFIX${GREEN}: Compiling Release...${NC}\n"
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
  f_set_proj_name "run_with_asan_ubsan"
  mkdir -p ./apps-cmake-build-asan-ubsan-pvs
  (
    pushd ./apps-cmake-build-asan-ubsan-pvs >/dev/null || exit 1
    echo -e "$PREFIX${GREEN}: Compiling with ASAN, UBSan and PVS...${NC}\n"
    cmake -DCMAKE_BUILD_TYPE=Debug -DCMAKE_INSTALL_PREFIX="${install_prefix}" .. || exit 1
    cmake --build . || exit 1
    cmake --install . || exit 1
    popd
  )
  f_set_pvs "OFF"
  f_set_asan "OFF"
  f_set_ubsan "OFF"

  f_set_tsan "ON"
  f_set_proj_name "run_with_tsan"
  mkdir -p ./apps-cmake-build-tsan
  (
    pushd ./apps-cmake-build-tsan >/dev/null || exit 1
    echo -e "$PREFIX${GREEN}: Compiling with TSan...${NC}"
    cmake -DCMAKE_BUILD_TYPE=Debug -DCMAKE_INSTALL_PREFIX="${install_prefix}" .. || exit 1
    cmake --build . || exit 1
    cmake --install . || exit 1
    popd
  )
  f_set_tsan "OFF"

  if "$MSAN"; then
    f_set_msan "ON"
    f_set_proj_name "run_with_msan"
    mkdir -p ./apps-cmake-build-msan
    (
      pushd ./apps-cmake-build-msan >/dev/null || exit 1
      echo -e "$PREFIX${GREEN}: Compiling with MSan...${NC}"
      cmake -DCMAKE_BUILD_TYPE=Debug -DCMAKE_INSTALL_PREFIX="${install_prefix}" .. || exit 1
      cmake --build . || exit 1
      cmake --install . || exit 1
      popd
    )
    f_set_msan "OFF"
  fi

elif [[ "$machine" -eq 1 ]]; then
  # MacOS

  f_set_pvs "ON"
  f_set_asan "ON"
  f_set_ubsan "ON"
  f_set_proj_name "run_with_asan_ubsan"
  mkdir -p ./apps-cmake-build-asan-ubsan
  (
    pushd ./apps-cmake-build-msan >/dev/null || exit 1
    echo "$PREFIX${GREEN}: Compiling with ASan UBSan...${NC}"
    cmake -DCMAKE_BUILD_TYPE=Debug -DCMAKE_INSTALL_PREFIX="${install_prefix}" .. || exit 1
    cmake --build . || exit 1
    cmake --install . || exit 1
    popd
  )
  f_set_pvs "OFF"
  f_set_ubsan "OFF"
  f_set_asan "OFF"
fi

if [ "$KEEP" == false ]; then
  rm -rf apps-cmake-build-tsan apps-cmake-build-asan-ubsan-pvs apps-cmake-build-release apps-cmake-build-msan
fi
