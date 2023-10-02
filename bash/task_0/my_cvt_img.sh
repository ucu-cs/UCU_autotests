#!/bin/bash

input_dir=$(pwd)
output_dir=$(pwd)
od_set_explicitly=false
extensions_regex=".*\.\(jpg\|jpeg\|png\|gif\|bmp\)"
init_id=0
id_size=8
clear_dir=false


prev_arg=$0
for arg in "$@"; do
	shift

	if [[ "$arg" =~ ^--dest=.*$ ]]; then
		output_dir=${arg:7}
		od_set_explicitly=true
	fi
	if [[ "$arg" =~ ^--init=.*$ ]]; then
		init_id=${arg:7}
	fi
	if [[ "$arg" =~ ^--digits=.*$ ]]; then
		id_size=${arg:9}
	fi
	if [[ "$arg" == --clear ]]; then
		clear_dir=true
	fi
	if [ "$prev_arg" != "-t" ] && [ -d $arg ]; then
		input_dir=$arg
	fi

	case $prev_arg in
		"-t")
			output_dir=$arg
			od_set_explicitly=true
			;;
		"-i")
			init_id=$arg
			;;
		"-d")
			id_size=$arg
			;;
	esac

	if [ "$arg" = "-c" ]; then
		clear_dir=true
	fi

	prev_arg=$arg
done

if [ "$od_set_explicitly" = false ]; then
	output_dir=$input_dir
fi

current_id=$init_id
for file in $(find $input_dir -regex $extensions_regex); do
	date_edited=$(stat -c %y "$file")
	year=$(echo $date_edited | cut -d' ' -f1 | cut -d'-' -f1)
	month=$(echo $date_edited | cut -d' ' -f1 | cut -d'-' -f2)
	day=$(echo $date_edited | cut -d' ' -f1 | cut -d'-' -f3)
	hour=$(echo $date_edited | cut -d' ' -f2 | cut -d':' -f1)
	minute=$(echo $date_edited | cut -d' ' -f2 | cut -d':' -f2)
	second=$(echo $date_edited | cut -d' ' -f2 | cut -d':' -f3 | cut -d'.' -f1)

	formatted_id="$(printf "%0${id_size}d" $current_id)"

	convert "$file" -set filename:f "$year-$month-$day-$hour-$minute-$second-$formatted_id" "$output_dir/%[filename:f].jpg"

	current_id=$((current_id+1))

	if [ "$clear_dir" = true ]; then
		rm "$file"
	fi
done
