#!/bin/bash 

set -o errexit
set -o pipefail

# Set the default maximum run time for the program in seconds
MAX_RUNTIME=500
N_TIMES=3
N_MAX_THREADS=4
N_MAX_MERGES=4
# And some other important variables
ADDITIONAL=""
progname=""
#CORRECT_RES_FNAMES=($(ls $indir_path))
#ls $(dirname $indir_path)/words_count_results

# https://stackoverflow.com/questions/18884992/how-do-i-assign-ls-to-an-array-in-linux-bash/18887210#18887210
indir_path=$(dirname $(readlink -f /usr/local/bin/test_integral))/words_count_testcases
res_path=$(dirname $(readlink -f /usr/local/bin/test_integral))/words_count_results

shopt -s nullglob
CORRECT_RES_FNAMES=($res_path/*)
indir_array=($indir_path/*/)
shopt -u nullglob

N_TEST_CASES=${#indir_array[@]}
# And program options
POSITIONAL_ARGS=()
STATUS=false

while [[ $# -gt 0 ]]; do
  case $1 in
  -h | --help)
    echo "Usage: test_words_count [program name] [options]
	-h	--help		Show help message.
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
  echo "$1 exists. Continuing:"
  progname=$1
  shift
else
  echo "ERROR: program $1 does not exist or not found."
  exit 1
fi

# Load the main function
source run_prog_with_time_bound

# For each function (without additional)
OUT_DIR=$(mktemp -d /tmp/results.XXXXXX)
for ((counter=0; counter < $N_TEST_CASES; counter++)); do
	echo "Test case $counter ..."
	TOTAL_TIME_N_RUNS=0
	# Create configure files
	CONF_FILE=$(mktemp /tmp/conf.XXXXXX)
	{
	    printf '%s\n' "indir=	\"${indir_array[$counter]}\""
	    printf '%s\n' "out_by_a=	\"$OUT_DIR/out_by_a_$counter-0\""
	    printf '%s\n' "out_by_n=	\"$OUT_DIR/out_by_n_$counter-0\""
	    printf '%s\n' 'archives_extensions=	.zip'
	    printf '%s\n' 'indexing_extensions=	.txt'
	    printf '%s\n' 'max_file_size=		10000000'

	    printf '%s\n' 'indexing_threads=	1'
	    printf '%s\n' 'merging_threads=		1'
		printf '%s\n' 'filenames_queue_size= 10000'
		printf '%s\n' 'raw_files_queue_size= 1000'
		printf '%s\n' 'dictionaries_queue_size= 1000'
	} >> "$CONF_FILE"
	
	# return values will be stored in OUT_LINES array
	OUT_LINES=()
	command="$progname $CONF_FILE"
	run_program_time_bound "$command" "$MAX_RUNTIME"
	if ! diff <(sort "$OUT_DIR/out_by_a_$counter-0") <(sort "$OUT_DIR/out_by_n_$counter-0"); then 
			echo "MISTAKE! Files by a and by n are not equal;"
			STATUS=true
	fi

	if ! diff -w <(sort "$OUT_DIR/out_by_a_$counter-0") <(sort "${CORRECT_RES_FNAMES[$counter]}"); then
			echo "MISTAKE! Output is not correct; expected output: "
			cat ${CORRECT_RES_FNAMES[$counter]}
			STATUS=true
	fi

	for ((n_time=0; n_time < $N_TIMES; n_time++)); do
		echo "Test case: $counter, iteration: $n_time"
		for ((n_threads = 1; n_threads < $N_MAX_THREADS; n_threads++)); do
		for ((n_merge = 1; n_merge < $N_MAX_MERGES; n_merge++)); do
		# echo "Test case: $counter, iteration: $n_time; thread $n_threads; merging threads: $n_merge."

		# Create configure files
		l_name_a="$OUT_DIR/out_by_a_$counter-$n_time-$n_threads-$n_merge"
		l_name_n="$OUT_DIR/out_by_n_$counter-$n_time-$n_threads-$n_merge"
		CONF_FILE=$(mktemp /tmp/conf.XXXXXX)
		{
		    printf '%s\n' "indir=	\"${indir_array[$counter]}\""
		    printf '%s\n' "out_by_a=	\"$l_name_a\""
		    printf '%s\n' "out_by_n=	\"$l_name_n\""
		    printf '%s\n' 'archives_extensions=	.zip'
		    printf '%s\n' 'indexing_extensions=	.txt'
		    printf '%s\n' 'max_file_size=		10000000'
	
		    printf '%s\n' 'indexing_threads=	1'
		    printf '%s\n' 'merging_threads=		1'
			printf '%s\n' 'filenames_queue_size= 10000'
			printf '%s\n' 'raw_files_queue_size= 1000'
			printf '%s\n' 'dictionaries_queue_size= 1000'
		} >> "$CONF_FILE"

		# return values will be stored in OUT_LINES array
		OUT_LINES=()
		command="$progname $CONF_FILE"
		run_program_time_bound "$command" "$MAX_RUNTIME"

		if ! diff "$l_name_a" "$OUT_DIR/out_by_a_$counter-0" ; then 
			echo "MISTAKE! Files sorted by alphabet are not equal;"
			STATUS=true
		fi	
		if ! diff "$l_name_n" "$OUT_DIR/out_by_n_$counter-0" ; then 
			echo "MISTAKE! Files sorted by number of occurrences are not equal;"
			STATUS=true
		fi	
		done
		done
	done

    #TOTAL_TIME=${OUT_LINES[1]}
	#WRITING_TIME=${OUT_LINES[2]}
	#EXITCODE=${OUT_LINES[3]}
  
#    difference=$(echo "scale=10; ${CORRECT_ANSWERS_FUNCTIONS[$((counter - 1))]} - $RESULT" | bc -l | tr -d '-')
#    if (( $(echo "$difference <= ${EPSILONS[$((counter - 1))]}" | bc -l) )); then
#      echo "The values for integral ${counter} are equal (within epsilon). 
#  Expected value: ${CORRECT_ANSWERS_FUNCTIONS[$((counter - 1))]};
#  Received value: ${RESULT}."
#    else
#      echo "The values for integral ${counter} are NOT EQUAL (outside epsilon).
#  Expected value: ${CORRECT_ANSWERS_FUNCTIONS[$((counter - 1))]};
#  Received value: ${RESULT}."
#    fi
  
done

if $STATUS; then
	echo "MISTAKE; At least one test failed."
else
	echo "Good; All tests passed."
fi

