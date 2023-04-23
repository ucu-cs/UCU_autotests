#!/bin/bash

set -o errexit
set -o pipefail

# Set the default maximum run time for the program in seconds
MAX_RUNTIME=20
# And some other important variables
ADDITIONAL=""
progname=""

# Create configure files
declare -a CONFS
CONFS[0]=$(mktemp /tmp/conf1.XXXXXX)
CONFS[1]=$(mktemp /tmp/conf2.XXXXXX)
CONFS[2]=$(mktemp /tmp/conf3.XXXXXX)
export LC_NUMERIC="en_US.UTF-8"
{
    printf '%s\n' 'abs_err     = 0.0005'
    printf '%s\n' 'rel_err     = 0.00000002'
    printf '%s\n' 'x_start     = -50'
    printf '%s\n' 'x_end       = 50'
    printf '%s\n' 'y_start     = -50'
    printf '%s\n' 'y_end       = 50'
    printf '%s\n' 'init_steps_x  = 100'
    printf '%s\n' 'init_steps_y  = 100'
    printf '%s\n' 'max_iter    = 30'
} >> "${CONFS[0]}"
{
    printf '%s\n' 'abs_err     = 0.0005'
    printf '%s\n' 'rel_err     = 0.00000002'
    printf '%s\n' 'x_start     = -100'
    printf '%s\n' 'x_end       = 100'
    printf '%s\n' 'y_start     = -100'
    printf '%s\n' 'y_end       = 100'
    printf '%s\n' 'init_steps_x  = 100'
    printf '%s\n' 'init_steps_y  = 100'
    printf '%s\n' 'max_iter    = 30'
} >> "${CONFS[1]}"
{
    printf '%s\n' 'abs_err     = 0.000001'
    printf '%s\n' 'rel_err     = 0.00002'
    printf '%s\n' 'x_start     = -10'
    printf '%s\n' 'x_end       = 10'
    printf '%s\n' 'y_start     = -10'
    printf '%s\n' 'y_end       = 10'
    printf '%s\n' 'init_steps_x  = 100'
    printf '%s\n' 'init_steps_y  = 100'
    printf '%s\n' 'max_iter    = 30'
} >> "${CONFS[2]}"

# And program options
POSITIONAL_ARGS=()

while [[ $# -gt 0 ]]; do
  case $1 in
  -h | --help)
    echo "Usage: test_integral [program name] [options]
	-h	--help		Show help message.
	-a	--additional	Some additional arguments to the exec file. String, in quotes.
	-m	--max-runtime	Maximum runtime for one iteration, in [s]. Default - 20
Details:
	Example of additional arguments:
	test_integral ./bin/integrate conf_file \"n_threads, n_points\""
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
  echo "$1 exists. Continuing:"
  progname=$1
  shift
else
  echo "ERROR: program $1 does not exist or not found."
  exit 1
fi


# Declare correct answers for each function and epsilons for each function
declare -a CORRECT_ANSWERS_FUNCTIONS 
CORRECT_ANSWERS_FUNCTIONS[0]=$(echo "4.545447652e6" | sed 's/e/*10^/g;s/ /*/' | bc)
CORRECT_ANSWERS_FUNCTIONS[1]=$(echo "8.572082414e5" | sed 's/e/*10^/g;s/ /*/' | bc)
CORRECT_ANSWERS_FUNCTIONS[2]=$(bc <<< -1.604646665)
EPSILONS=(20 20 0.0001)

# Load the main function
source run_prog_with_time_bound
# For each function (without additional)
for ((counter = 1; counter <= 3; counter++)); do
	# return values will be stored in OUT_LINES array
	OUT_LINES=()
	command="$progname $counter ${CONFS[$((counter - 1))]} $ADDITIONAL"

	run_program_time_bound "$command" "$MAX_RUNTIME"

    RESULT=$(printf "%.11f"'\n' ${OUT_LINES[0]} )
    ABS_ERROR=${OUT_LINES[1]}
    REL_ERROR=${OUT_LINES[2]}
    TOTAL_TIME=${OUT_LINES[3]}
	EXITCODE=${OUT_LINES[4]}
  
    difference=$(echo "scale=10; ${CORRECT_ANSWERS_FUNCTIONS[$((counter - 1))]} - $RESULT" | bc -l | tr -d '-')
    if (( $(echo "$difference <= ${EPSILONS[$((counter - 1))]}" | bc -l) )); then
      echo "The values for integral ${counter} are equal (within epsilon). 
  Expected value: ${CORRECT_ANSWERS_FUNCTIONS[$((counter - 1))]};
  Received value: ${RESULT}."
    else
      echo "The values for integral ${counter} are NOT EQUAL (outside epsilon).
  Expected value: ${CORRECT_ANSWERS_FUNCTIONS[$((counter - 1))]};
  Received value: ${RESULT}."
    fi
  
done
