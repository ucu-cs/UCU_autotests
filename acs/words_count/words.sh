#!/bin/bash

set -o errexit
set -o pipefail

# Set the default maximum run time for the program in seconds
MAX_RUNTIME=40
N_TIMES=3
N_MAX_THREADS=4
N_MAX_MERGES=4
# And some other important variables
ADDITIONAL=""
progname=""
#CORRECT_RES_FNAMES=($(ls $indir_path))
#ls $(dirname $indir_path)/words_count_results

# https://stackoverflow.com/questions/18884992/how-do-i-assign-ls-to-an-array-in-linux-bash/18887210#18887210
project_path=$(dirname "$(readlink -f /usr/local/bin/test_words_count)")
indir_path=$project_path/words_count_testcases
res_path=$(dirname "$(readlink -f /usr/local/bin/test_words_count)")/words_count_results

shopt -s nullglob
CORRECT_RES_FNAMES=("$res_path/"*)
indir_array=("$indir_path"/*/)
shopt -u nullglob

N_TEST_CASES=${#indir_array[@]}
# And program options
POSITIONAL_ARGS=()
STATUS=false
VERBOSE=false

while [[ $# -gt 0 ]]; do
  case $1 in
  -h | --help)
    echo "Usage: test_words_count [program name] [options]
	-h	--help		Show help message.
	-v  --verbose Show the output with additional information
	-a	--additional	Some additional arguments to the exec file. String, in quotes.
	-m	--max-runtime	Maximum runtime for one iteration, in [s]. Default - 20.
	-n	--n-times	How many times to repeat the counting for each test file. Default - 3.
Details:
	Example of additional arguments:
	test_integral ./bin/integrate conf_file \"n_threads, n_points\""
    exit 0
    ;;
  \?)
    echo "Invalid option: -$OPTARG" >&2
    exit 1
    ;;
  -v | --verbose)
    VERBOSE=true
    shift 1
    ;;
  -m | --max_runtime)
    if [ "$2" -eq "$2" ] 2>/dev/null; then
      MAX_RUNTIME=$2
      shift 2
    else
      echo "Option --max_runtime requires an numerical argument." >&2
      exit 1
    fi
    ;;
  -n | --n-times)
    if [ "$2" -eq "$2" ] 2>/dev/null; then
      N_TIMES=$2
      shift 2
    else
      echo "Option --n_times requires an numerical argument." >&2
      exit 1
    fi
    ;;
  -a | --additional)
    if [ ! -z "$2" ] 2>/dev/null; then
      ADDITIONAL=$2
      shift 2
    else
      echo "Option --additional requires a string argument." >&2
      exit 1
    fi
    ;;
  :)
    echo "Option -$OPTARG requires an numerical argument." >&2
    exit 1
    ;;
  *)
    POSITIONAL_ARGS+=("$1") # save positional arg
    shift 1
    ;;
  esac
done

set -- "${POSITIONAL_ARGS[@]}" # restore positional parameters

# Check if the program name is set
if [ -e "$1" ]; then
  echo -e "$PREFIX $1 exists. Continuing:"
  progname=$1
  shift
else
  echo -e "$ERROR: program $1 does not exist or not found."
  exit 1
fi

# Load the main function
source run_prog_with_time_bound
# And some general settings
source $(dirname "$(readlink -f /usr/local/bin/test_compilation)")/general_settings.sh
PREFIX="$MAGENTA==> [APPS testing words count] ${NC}"

# For each function (without additional)
OUT_DIR=$(mktemp -d /tmp/results.XXXXXX)
echo -e "${BLUE}-> Running program on $N_TEST_CASES test cases, $N_TIMES times on each case; from 1 to $N_MAX_THREADS count threads for each test case, for 1 to $N_MAX_MERGES merging threads. Maximal runtime for each execution is limited with $MAX_RUNTIME sec."
echo -e "${GREEN}--> Please, run '$ test_words_count --help' to see how to change those numbers.${BLUE}"
echo -e "-> In the very first execution, results are additionally sorted with bash 'sort' program and compared - they should be the same."
echo -e "-> Between each execution, results are compared with the very first run, and in case of mismatch there will be a warning.${NC}"
for ((counter = 0; counter < "$N_TEST_CASES"; counter++)); do
  echo -e "$PREFIX Test case $counter ..."
  TOTAL_TIME_N_RUNS=0
  # Create configure files
  CONF_FILE=$(mktemp /tmp/conf.XXXXXX)
  {
    m4 -DINPUT_DIR="${indir_array[$counter]}" -DOUT_A="$OUT_DIR/out_by_a_$counter-0" -DOUT_N="$OUT_DIR/out_by_n_$counter-0" ${indir_array[$counter]%?}.m4 $project_path/general_config.m4
  } >>"$CONF_FILE"

  # return values will be stored in OUT_LINES array
  OUT_LINES=()
  command="$progname $CONF_FILE"
  run_program_time_bound "$command" "$MAX_RUNTIME"
  if ! diff <(sort "$OUT_DIR/out_by_a_$counter-0") <(sort "$OUT_DIR/out_by_n_$counter-0") 2>/dev/null; then
    echo -e "$WARN MISTAKE! Files sorted by alpabet and by number are not equal;"
    STATUS=true
  fi

  if ! (diff -w <(sort "$OUT_DIR/out_by_a_$counter-0") <(sort "${CORRECT_RES_FNAMES[$counter]}") >/dev/null); then
    echo -e "$WARN MISTAKE! Output is not correct; expected output: "
    cat "${CORRECT_RES_FNAMES[$counter]}"
    echo -e "But received output is: "
    cat "$OUT_DIR/out_by_a_$counter-0"
    STATUS=true
  fi

  for ((n_time = 0; n_time < "$N_TIMES"; n_time++)); do
    echo -e "$PREFIX Test case: $counter, iteration: $n_time"
    for ((n_threads = 1; n_threads <= "$N_MAX_THREADS"; n_threads++)); do
      for ((n_merge = 1; n_merge <= "$N_MAX_MERGES"; n_merge++)); do
        if $VERBOSE; then
          echo -e "$BLUE---> Test case: $counter, iteration: $n_time; thread $n_threads; merging threads: $n_merge.$NC"
        fi

        # Create configure files
        l_name_a="$OUT_DIR/out_by_a_$counter-$n_time-$n_threads-$n_merge"
        l_name_n="$OUT_DIR/out_by_n_$counter-$n_time-$n_threads-$n_merge"
        CONF_FILE=$(mktemp /tmp/conf.XXXXXX)
        {
          m4 -DINPUT_DIR="${indir_array[$counter]}" -DOUT_A="$l_name_a" -DOUT_N="$l_name_n" ${indir_array[$counter]%?}.m4 -DN_THREADS=$n_threads -DN_MTHREADS=$n_merge $project_path/general_config.m4
        } >>"$CONF_FILE"

        # return values will be stored in OUT_LINES array
        OUT_LINES=()
        command="$progname $CONF_FILE"
        run_program_time_bound "$command" "$MAX_RUNTIME"

        if ! diff "$l_name_a" "$OUT_DIR/out_by_a_$counter-0"; then
          echo -e "$WARN MISTAKE! Files sorted by alphabet are not equal;"
          STATUS=true
        fi
        if ! diff "$l_name_n" "$OUT_DIR/out_by_n_$counter-0"; then
          echo -e "$WARN MISTAKE! Files sorted by number of occurrences are not equal;"
          STATUS=true
        fi
      done
    done
  done
done

if $STATUS; then
  echo -e "${RED}=> Bad =(${NC} At least one test failed."
else
  echo -e "${GREEN}=> Good!${NC} All tests passed."
fi
