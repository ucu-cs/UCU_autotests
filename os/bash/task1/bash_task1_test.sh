#!/bin/bash

EXEC="my_rsz_img.sh"
FILE_PATH="/tmp"
ARCHIVE="images.tar.gz"
DEST="$PWD"

SUCCESS=0
FAILED=0

usage() {
  echo "Usage: bash_task1_test.sh"
  echo "Must be run in the directory with the $EXEC and $ARCHIVE files"
}

clear_files() {
  rm "$PWD"/dog*.png "$PWD"/cat*.jpg >& /dev/null
  rm "$FILE_PATH"/dog*.png "$FILE_PATH"/cat*.jpg >& /dev/null
  rm "$DEST"/dog*.png "$DEST"/cat*.jpg >& /dev/null
}

prepare() {
  clear_files
  tar xf "$ARCHIVE" -C "$PWD"
  tar xf "$ARCHIVE" -C "$FILE_PATH"
}

test_clear_dest() {
  prepare
  if ! ./"$EXEC" --clear --width=150 --dest="$FILE_PATH"; then
    >&2 echo "ERROR Program exited with error code $?. Exiting the test..."
    ((FAILED++))
    return
  fi
  echo "$EXEC --clear --width=150 --dest=$FILE_PATH executed successfully"
  if [[ "$( find "$PWD" -maxdepth 1 -type f \( -name 'dog.png' -o -name 'cat.jpg' \))" == "" ]]; then
    echo "SUCCESS: files were successfully cleared with --clear flag"
    ((SUCCESS++))
  else
    >&2 echo "ERROR: files were not removed from source folder with --clear flag"
    ((FAILED++))
  fi
  if [[ "$( find "$FILE_PATH" -maxdepth 1 -type f \( -name 'dog-*.png' -o -name 'cat-.jpg' \))" != "" ]]; then
    echo "SUCCESS: destination folder is correctly working."
    ((SUCCESS++))
  else
    >&2 echo "ERROR: files are not present in destination folder"
    ((FAILED++))
  fi
  clear_files
}

test_width() {
  WIDTH=(150 450) # original images have width 300. 
  # testing for width parameter smaller and greater than original
  if ! ./"$EXEC" >& /dev/null; then
    echo "SUCCESS: program exited with non-zero exit code without set width"
    ((SUCCESS++))
  else
    >&2 echo "ERROR: program exited with exit code 0 without required parameter width"
    ((FAILED++))
  fi
  prepare
  for w in "${WIDTH[@]}"; do
    if ! ./"$EXEC" -w "$w" >/dev/null; then
      >&2 echo "ERROR Program exited with error code $?. Exiting the test..."
      ((FAILED++))
      return
    fi
    echo "$EXEC -w $w executed successfully"
  if [[ "$( find "$PWD" -maxdepth 1 -type f \( -name "dog-$w-*.png" -o -name "cat-$w-*.jpg" \))" != "" ]]; then
    echo "SUCCESS: files were successfully found with $w width at the destination folder"
    ((SUCCESS++))
  else
    >&2 echo "ERROR: images with width $w were not created in the destination folder or have wrong name"
    ((FAILED++))
  fi 
  done
  clear_files
}

#an instance of the test with short arguments
test_path_set_short() {
  prepare
  if ! ./"$EXEC" -p "$FILE_PATH" dog.png -w 150 -t "$PWD" >& /dev/null; then
    >&2 echo "ERROR Program exited with error code $?. Exiting the test..."
    ((FAILED++))
    return
  fi
  echo "$EXEC -p $FILE_PATH dog.png -w 150 -t $PWD executed successfully"
  if [[ "$(find "$PWD" -name "dog-150-*.png")" != "" && "$(find "$PWD" -name "cat-*.jpg")" == "" ]]; then
    echo "SUCCESS: files not specified were not resized"
    ((SUCCESS++))
  else
    >&2 echo "ERROR: files not specified in command line were converted"
    ((FAILED++))
  fi
  clear_files
}

#an instance of the test with long arguments
#let's have two to troubleshoot things quicker
test_path_set_long() {
  prepare
  if ! ./"$EXEC" --path="$FILE_PATH" dog.png --width=150 --dest="$PWD" >& /dev/null; then
    >&2 echo "ERROR Program exited with error code $?. Exiting the test..."
    ((FAILED++))
    return
  fi
  echo "$EXEC -p $FILE_PATH dog.png -w 150 -t $PWD executed successfully"
  if [[ "$(find "$PWD" -name "dog-150-*.png")" != "" && "$(find "$PWD" -name "cat-*.jpg")" == "" ]]; then
    echo "SUCCESS: files not specified were not resized"
    ((SUCCESS++))
  else
    >&2 echo "ERROR: files not specified in command line were converted"
    ((FAILED++))
  fi
  clear_files
}


if [[ "$(find . -name "$EXEC" )" == "" ]]; then
  usage
  exit 1
else
  echo "Testing file clearing and destination check..."
  test_clear_dest
  echo "Testing width parameters..."
  test_width
  echo "Testing files selection..."
  test_path_set_short
  test_path_set_long
  echo "Tests are completed: Passed: $SUCCESS, failed: $FAILED"
fi
