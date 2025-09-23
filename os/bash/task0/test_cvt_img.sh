#!/usr/bin/env bash
# Script for testing my_cvt_img.sh
# To be run in the test/ directory.
#
indir="input"
outdir="output"
tmpdir="temp"
cmd="../my_cvt_img.sh"
default_digits=8
expected_format="JPEG"
extensions_regex=".*\.\(jpg\|png\|gif\|bmp\)"

check_image_format() {
	# Args:
	# $1 = outdir
	# $2 = file format, as displayed by magick (e.g JPEG)
	for file in $(find $1/*); do
		if [[ $(identify -format "%m" $file) != $2 ]]; then
			echo "Error: $file is not a $2 file"
			exit 1
		fi
	done

	echo "All files are $2"
}

check_image_count() {
	# Args:
	# $1 = outdir
	# $2 = number of files expected
	if [ $(ls $1 | wc -l) -ne $2 ]; then
		echo "Error: $1 has $(ls $1 | wc -l) files, expected $2"
		exit 1
	fi

	echo "Directory $1 has $2 files as expected"
}

check_filenames() {
	# Args:
	# $1 = outdir
	for file in $(ls $1); do
		if [[ ! $file =~ ^[0-9]{4}-([0-9]{2}-){5}[0-9]{$2}\.jpg$ ]]; then
			echo "Error: $file does not match the correct filename"
			exit 1
		fi
	done

	echo "All files have the correct filename"
}

check_modified_date() {
	# Args:
	# $1 = indir
	# $2 = outdir
	for infile in $(find $1 -regex $extensions_regex); do
		date_edited=$(stat -c %y "$infile")
		year=$(echo $date_edited | cut -d' ' -f1 | cut -d'-' -f1)
		month=$(echo $date_edited | cut -d' ' -f1 | cut -d'-' -f2)
		day=$(echo $date_edited | cut -d' ' -f1 | cut -d'-' -f3)
		hour=$(echo $date_edited | cut -d' ' -f2 | cut -d':' -f1)
		minute=$(echo $date_edited | cut -d' ' -f2 | cut -d':' -f2)
		second=$(echo $date_edited | cut -d' ' -f2 | cut -d':' -f3 | cut -d'.' -f1)

		found_file=false
		for outfile in $(ls $2); do
			#echo "found file $outfile"
			if [[ "$outfile" =~ ^$year-$month-$day-$hour-$minute-$second.*$ ]]; then
				found_file=true
				#echo "found file with the filename $outfile"
				break
			fi
		done

		if [[ $found_file != true ]]; then
			echo "Couldn't found a file with the modification date $date_edited"
			exit 1
		fi
		
	done
	echo "All files have the correct modification date in the name."
}

check_clear() {
	# Args:
	# $1 = indir
	# $2 = tmpdir
	# $3 = outdir
	# $4 = command, e.g. "../my_cvt_img.sh"
	if ! [ -d $2 ]; then
		mkdir $2
	fi

	cp -r $1/* $2

	$4 $2 -t $3 -c

	if [ -n "$(find $2 -regex $extensions_regex)" ]; then
		echo "Input directory $1 not cleared with -c"
		exit 1
	fi
	echo "Input directory cleared successfully with -c"

	$4 $2 -t $3 --clear

	if [ -n "$(find $2 -regex $extensions_regex)" ]; then
		echo "Input directory $1 not cleared with --clear"
		exit 1
	fi
	echo "Input directory cleared successfully with --clear"

	rm -rf $3/*
}

basic_checks() {
	# Args:
	# $1 = number of digits specified
	check_image_format "$outdir" "$expected_format"
	check_image_count "$outdir" $(find $indir -regex $extensions_regex | wc -l)
	check_filenames "$outdir" $1
	check_modified_date "$indir" "$outdir"
}

no_args_test() {
	# No args
	$cmd "$indir"

	if ! [ -d $tmpdir ]; then
		mkdir $tmpdir
	fi

	for file in $(ls $indir); do
		if [[ ! $file =~ ^[0-9]{4}-([0-9]{2}-){5}[0-9]{$default_digits}\.jpg$ ]]; then
			mv $indir/$file $tmpdir
		fi
	done

	check_image_format "$indir" "$expected_format"
	check_image_count "$indir" $(find $tmpdir -regex $extensions_regex | wc -l)
	check_filenames "$indir" $default_digits
	check_modified_date "$tmpdir" "$indir"
	echo "Simple test completed."

	rm -rf $indir/*
	mv $tmpdir/* $indir
}

test_short_args() {
	# No args
	echo "Testing short args 1"
	$cmd "$indir" -i 0 -d 4 -t "$outdir"
	basic_checks 4

	rm -rf $outdir/*

	echo "Testing short args 2"
	$cmd -i 5 "$indir" -d 6 -t "$outdir"
	basic_checks 6

	rm -rf $outdir/*
}

test_long_args() {
	# No args
	echo "Testing long args 1"
	$cmd --init=0 --digits=2 "$indir" --dest="$outdir"
	basic_checks 2

	rm -rf $outdir/*

	echo "Testing long args 2"
	$cmd --init=5 --digits=8 --dest="$outdir" "$indir" 
	basic_checks 8

	rm -rf $outdir/*
}

test_mixed_args() {
	# No args
	echo "Testing mixed args 1"
	$cmd --digits=3 "$indir" -t "$outdir"
	basic_checks 3

	rm -rf $outdir/*

	echo "Testing mixed args 2"
	$cmd --init=5 -d 5 --dest="$outdir" "$indir" 
	basic_checks 5

	rm -rf $outdir/*
}


rm -rf $outdir/*
rm -rf $tmpdir/*
no_args_test
check_clear $indir $tmpdir $outdir $cmd
test_long_args
test_short_args
test_mixed_args
echo "All tests passed successfully."
