#! /bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
RESET='\033[0m'

unarchive_cmd=${AR_CMD:-${1:-"tar xzf"}}
script_path=${SCRIPT_PATH:-${2:-"./my_inc_bkp.sh"}}


function setup () {
    echo "Creating test files"

    echo "Creating directory dir"
    mkdir -p dir
    echo "Creating directory dir/subdir"
    mkdir -p dir/subdir

    echo "Creating 15 files for each dir - file_\$i.txt = file created i days ago"
    for ((i = 0; i < 15; i++)); do
        echo "File $i" > "dir/file_$i.txt"
        touch -d "$i days ago"  "dir/file_$i.txt"

        echo "File $i" > "dir/subdir/file_$i.txt"
        touch -d "$i days ago"  "dir/subdir/file_$i.txt"
    done
}

# You need to set two variables:
#   files_to_find - a list of file names to be found.
#   command - command to test
function test_usage() {
    files_to_find=$1
    command=$2
    dir_path=$(realpath ${3:-$PWD})
    out_path=$(realpath ${4:-$(realpath $dir_path)}) #sets 'out' to 'in' by default
    test_clear=${5:-false}
    echo "Executing command: $command"
    bash $command

    if [[ "$?" != "0" ]]; then
        >&2 echo -e "${RED}Attention! The script did not exit with '1' code!$RESET"
    fi

    cwd=$(basename "$dir_path")
    echo ar_file=find $PWD -regextype posix-extended -regex "$out_path/$cwd-[0-9]{4}(-[0-9]{2}){5}.*"
    ar_file=`find $PWD -regextype posix-extended -regex "$out_path/$cwd-[0-9]{4}(-[0-9]{2}){5}.*"`

    if [[ -z "$ar_file" ]]; then
        if [[ $files_to_find != "" ]]; then
            >&2 echo -e "${RED}Test failed - could not find the archive!$RESET"
        else #else there are no files to find -> technically success of the test
            echo -e "${GREEN}Test passed$RESET"
        fi

        return
    fi

    mkdir -p tmp && cd tmp || { echo "Failed to create a temporary directory!"; rm ./dir; return; }

    echo "Extracting archive: $unarchive_cmd $ar_file"
    $unarchive_cmd $ar_file
    files_found=`find . -maxdepth 1 -type f -printf '%f '`

    echo -e "\n\nFiles found: $files_found"
    echo -e "\n\nFiles to find: $files_to_find"

    file_diff=`diff <(echo $files_to_find | tr ' ' '\n' | sort) <(echo $files_found | tr ' ' '\n' | sort)`
    if [[ $file_diff ]]; then
        cd ..
        rm $ar_file
        rm -fR ./tmp ./dir
        >&2 echo -e "${RED}Test failed - files differ. Check tmp$RESET"
        >&2 echo "Diff: $file_diff"
        return
    fi

    if [[ $test_clear == true ]]; then
        if [[ $(ls "$dir_path" | wc -l) -ge $(echo "$files_to_find" | wc -w) ]]; then #checks whether files have been removed by comparing numbers of files
            >&2 echo -e "${RED}Test failed - the input directory was not cleared!$RESET"
            cd ..
            rm $ar_file
            rm -fR ./tmp ./dir
            return
        fi
    fi

    echo -e "${GREEN}Test passed$RESET"
    rm $ar_file
    cd ..
    rm -fR ./tmp ./dir
}

#`-maxdepth 1` is used down below to make sure only the files in the target directory are considered.
#under some systems, `find` seems to run recursively by default.

setup
echo -e "\n\nTest 0: basic usage.\n"
test_usage "`find "$PWD" -maxdepth 1 -type f -mtime +1 -printf '%f '`" "$script_path"

setup
echo -e "\n\nTest: files only in subdir.\n"
test_usage "`find "$PWD/dir/subdir" -maxdepth 1 -type f -mtime +2 -printf '%f '`" "$script_path -p dir/subdir -d 2" 'dir/subdir' 'dir/subdir' false

setup
echo -e "\n\nTest: files only in subdir.\n"
test_usage "`find "$PWD/dir/subdir" -maxdepth 1 -type f -mtime +3 -printf '%f '`" "$script_path --path=dir/subdir --days=3 -t ." 'dir/subdir' '.'

setup
echo -e "\n\nTest: files only in subdir.\n"
test_usage "`find "$PWD/dir/subdir" -maxdepth 1 -type f -mtime +3 -printf '%f '`" "$script_path --path=dir/subdir --days=3 --dest=dir" 'dir/subdir' 'dir'

setup
echo -e "\n\nTest: files with clear.\n"
test_usage "`find "$PWD/dir/subdir" -maxdepth 1 -type f -mtime +3 -printf '%f '`" "$script_path --path=dir/subdir --days=3 -c" 'dir/subdir' 'dir/subdir' true

setup
echo -e "\n\nTest: files with -c.\n"
test_usage "`find "$PWD/dir/subdir" -maxdepth 1 -type f -mtime +3 -printf '%f '`" "$script_path --path=dir/subdir --days=3 --clear" 'dir/subdir' 'dir/subdir' true
