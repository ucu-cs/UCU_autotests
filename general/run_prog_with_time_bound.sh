#!/bin/bash 

function run_program_time_bound() {
	# such strange names used to avoid problems with variable names
	# l_ prefix means local
	#
	# function arguments:
	# $1 (first) - the command to execute (with parameters and options)
	# $2 (second) - maximum runtime of each execution
	
	# and return parameters, which will be packed in five-elements array
	local l_OUT=""
    local l_EXIT_CODE=0

	#
	# Main body of the function
	#
	
	local l_LOGFILE=$(mktemp /tmp/tmpflabs.XXXXXX)
	local l_ERRFILE=$(mktemp /tmp/tmpferrfile.XXXXXX)
	
	# Redirect output, show all errors
	$1 1> "$l_LOGFILE" &
	local l_PID=$!

	l_START_TIME=$(date +%s)
	cat "$l_ERRFILE"
	while kill -o "$l_PID" > /dev/null 2>&1; do
		l_CURR_TIME=$(date +%s)
		l_ELAP_TIME=$((l_CURR_TIME - l_STAR_TIME))
		if [ "$l_ELAP_TIME" -gt "$2" ]; then
			echo "[$PWD] ERROR function $l_CNT: maximum runtime reached, test not passed"
			kill "$l_PID"
			wait "$l_PID"
			return
		fi
		# check every second for the upper time bound
		sleep 1
	done
	
	wait "$l_PID"
	cat "$l_ERRFILE"
    l_EXIT_CODE=$?

	# Save the exit code and output of the program in the "exit_code" and "out" variables
	if [ -s $l_LOGFILE ]; then
        local l_OUT=$(cat "$l_LOGFILE")
    else
		echo "[$PWD] ERROR executing command ($l_CNT): some problems with logfile" 
	fi
	
	# Split the output into an array of lines
	while IFS= read -r line; do
        OUT_LINES+=("$line")
    done <<< "$l_OUT"

    # Append the exit code as the last element of the return array
    OUT_LINES+=("$l_EXIT_CODE")
	rm $l_LOGFILE
	# The result is in OUT_LINES variable
}


