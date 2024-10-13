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
    dir_path=${3:-$PWD}
    out_path=${4:-$(realpath $(dirname $dir_path))}
    echo "Executing command: $command"
    bash $command

    cwd=$(basename "$dir_path")
    echo ar_file=find $PWD -regextype posix-extended -regex "$out_path/$cwd-[0-9]{4}(-[0-9]{2}){5}.*"
    ar_file=`find $PWD -regextype posix-extended -regex "$out_path/$cwd-[0-9]{4}(-[0-9]{2}){5}.*"`

    if [[ $out_path && $out_path == $(realpath $(dirname $ar_file)) ]]; then
        >&2 echo -e "${RED}Test failed - out directory is not right$RESET"
        return
    fi

    if [[ -n $file ]]; then
        >&2 echo -e "${RED}Test failed - no archive$RESET"
        return
    fi

    mkdir -p tmp
    cd tmp

    echo "Extracting archive: $unarchive_cmd $ar_file"
    $unarchive_cmd $ar_file
    files_found=`find $PWD -type f -printf '%f '`

    echo -e "\n\nFiles found: $files_found"
    echo -e "\n\nFiles to find: $files_to_find"

    file_diff=`diff <(echo $files_to_find) <(echo $files_found)`
    if [[ $file_diff ]]; then
        cd ..
        rm $ar_file
        >&2 echo -e "${RED}Test failed - files differ. Check tmp$RESET"
        >&2 echo "Diff: $file_diff"
        return
    fi

    echo -e "${GREEN}Test passed$RESET"
    rm $ar_file
    cd ..
    rm -rf tmp
}

function test_clear() {
    files_to_find=$1
    command=$2
    dir_path=$3
    file_paths=$4
    out_path=$(realpath $(dirname $dir_path))
    echo "Executing command: $command"
    bash $command

    cwd=$(basename "$dir_path")
    ar_file=`find $PWD -regextype posix-extended -regex "$(realpath $dir_path)/$cwd-[0-9]{4}(-[0-9]{2}){5}.*"`

    if [[ $out_path && $out_path == $(realpath $(dirname $ar_file)) ]]; then
        >&2 echo -e "${RED}Test failed - out directory is not right$RESET"
        return
    fi

    if [[ -n $file ]]; then
        >&2 echo -e "${RED}Test failed - no archive$RESET"
        return
    fi

    mkdir -p tmp
    cd tmp

    echo "Extracting archive: $unarchive_cmd $ar_file"
    $unarchive_cmd $ar_file
    files_found=`find $PWD -type f -printf '%f '`

    echo -e "\n\nFiles found: $files_found"
    echo -e "\n\nFiles to find: $files_to_find"

    file_diff=`diff <(echo $files_to_find) <(echo $files_found)`
    if [[ $file_diff ]]; then
        cd ..
        rm $ar_file
        >&2 echo -e "${RED}Test failed - files differ. Check tmp$RESET"
        >&2 echo "Diff: $file_diff"
        return
    fi

    rm $ar_file
    cd ..
    rm -rf tmp

    if [`ls -1 .bashrc Projects/dotfiles/instal 2> /dev/null |  wc -l` -gt 0]; then
        >&2 echo -e "${RED}Test failed - clear does not work$RESET"
        >&2 echo "Diff: $file_diff"
        return
    fi

    echo -e "${GREEN}Test passed$RESET"
}

setup

echo -e "\n\nTest 0: basic usage.\n"
test_usage "`find "$PWD" -type f -mtime +1 -printf '%f '`" "$script_path"

echo -e "\n\nTest: files only in subdir.\n"
test_usage "`find "$PWD/dir/subdir" -type f -mtime +2 -printf '%f '`" "$script_path -p dir/subdir -d 2" 'dir/subdir'

echo -e "\n\nTest: files only in subdir.\n"
test_usage "`find "$PWD/dir/subdir" -type f -mtime +3 -printf '%f '`" "$script_path --path='dir/subdir' --days=3 -t ." 'dir/subdir'

echo -e "\n\nTest: files only in subdir.\n"
test_usage "`find "$PWD/dir/subdir" -type f -mtime +3 -printf '%f '`" "$script_path --path='dir/subdir' --days=3 --dest=dir" 'dir/subdir' 'dir'

setup
echo -e "\n\nTest: files with clear.\n"
test_usage "`find "$PWD/dir/subdir" -type f -mtime +3 -printf '%f '`" "$script_path --path=dir/subdir --days=3 -c" 'dir/subdir' "`find "$PWD/dir/subdir" -type f -mtime +3`"

setup
echo -e "\n\nTest: files with -c.\n"
test_usage "`find "$PWD/dir/subdir" -type f -mtime +3 -printf '%f '`" "$script_path --path=dir/subdir --days=3 --clear" 'dir/subdir' "`find "$PWD/dir/subdir" -type f -mtime +3`"
