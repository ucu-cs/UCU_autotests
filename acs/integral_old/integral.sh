#!/bin/bash

set -o errexit
set -o pipefail

# And some general settings
source $(dirname "$(readlink -f /usr/local/bin/test_compilation)")/general_settings.sh
PREFIX="$MAGENTA==> [APPS testing integral] ${NC}"

# Set the default maximum run time for the program in seconds
MAX_RUNTIME=20
N_TIMES=3
N_MAX_THREADS=$(grep -c ^processor /proc/cpuinfo)
echo -e "${CYAN}The number of cores is $N_MAX_THREADS${NC}"
# And some other important variables
ADDITIONAL=""
progname=""

project_path=$(dirname "$(readlink -f /usr/local/bin/test_integral)")

# Create configure files
declare -a CONFS
CONFS[0]=$(mktemp /tmp/conf1.XXXXXX)
CONFS[1]=$(mktemp /tmp/conf2.XXXXXX)
CONFS[2]=$(mktemp /tmp/conf3.XXXXXX)

export LC_NUMERIC="en_US.UTF-8"
{
  m4 $project_path/func_1.m4 $project_path/general_config.m4
} >>"${CONFS[0]}"
{
  m4 $project_path/func_2.m4 $project_path/general_config.m4
} >>"${CONFS[1]}"
{
  m4 $project_path/func_3.m4 $project_path/general_config.m4
} >>"${CONFS[2]}"

# And program options
POSITIONAL_ARGS=()

while [[ $# -gt 0 ]]; do
  case $1 in
  -h | --help)
    echo "Usage: test_integral [program name] [lab number] [options]
	-h	--help		Show help message.
	-m	--max-runtime	Maximum runtime for one iteration, in [s]. Default - 20
Details:
  [lab number] is a number of the Integral lab, from 1 to 4."

    #	-a	--additional	Some additional arguments to the exec file. String, in quotes.
    #  Unfortunately, right now for the testing it is necessary to use so-called additional arguments.
    #  For the Lab2 it is the number of threads, and for Lab3 it is the number of points.
    #  Syntax of additional arguments:
    #    test_integral ./bin/integrate -a \"n_threads, n_points\""
    exit 0
    ;;
  \?)
    echo "Invalid option: -$OPTARG" >&2
    exit 1
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
    #  -a | --additional)
    #    if [ ! -z "$2" ] 2>/dev/null; then
    #      ADDITIONAL=$2
    #      shift 2
    #    else
    #      echo "Option --additional requires a string argument." >&2
    #      exit 1
    #    fi
    #    ;;
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

LAB_NUMBER=$2
# Check  bounds for positional for positional argument - the number of the lab
if [ -z "$LAB_NUMBER" ]; then
  echo -e "${ERROR}The lab number is not specified. Run test_integral -h for more details."
  exit
fi
if [ "$LAB_NUMBER" -gt "4" ] || [ "$LAB_NUMBER" -le "0" ]; then
  echo -e "${ERROR}The lab number should be from 1 to 4."
  exit
fi
if [ "$LAB_NUMBER" -eq "1" ]; then
  N_MAX_THREADS=1
fi

# Check if the program name is set
if [ -e "$1" ]; then
  echo "$1 exists. Continuing:"
  progname=$1
  shift
else
  echo "${ERROR}Program $1 does not exist or not found."
  exit 1
fi

# Load the main function
source run_prog_with_time_bound

# For each function (without additional tasks)
for ((counter = 1; counter <= 3; counter++)); do
  echo -e "$PREFIX function $counter"
  # return values will be stored in OUT_LINES array
  for ((n_threads = 1; n_threads <= $N_MAX_THREADS; n_threads++)); do
    OUT_LINES=()
    if [ "$LAB_NUMBER" -ge "2" ]; then
      ADDITIONAL="$n_threads"
    fi
    if [ "$LAB_NUMBER" -ge "3" ]; then
      ADDITIONAL+=" 1000"
    fi

    command="$progname $counter ${CONFS[$((counter - 1))]} $ADDITIONAL"
    run_program_time_bound "$command" "$MAX_RUNTIME"

    RESULT=$(printf "%.11f"'\n' ${OUT_LINES[0]})

    # For improvements
    ABS_ERROR=${OUT_LINES[1]}
    REL_ERROR=${OUT_LINES[2]}
    TOTAL_TIME=${OUT_LINES[3]}
    EXITCODE=${OUT_LINES[4]}

    echo -e "${BLUE}---> Testing the integral computation, $n_threads threads.${NC}"
    m4 $project_path/func_$counter.m4 $project_path/compare.sh | bash -c "$(cat)" -- $RESULT

  done
done
