#!/bin/bash

set -o errexit
set -o nounset
set -o pipefail

tests_passed=0
working_dir="./temp"
unpacked_arch_dir="./unpacked_archive"

test1() {
  cp ${needed_resources} -r "./"

  echo "------------------------------"
  echo "Starting test 1..."
  echo ""
  eval "bash ./${shmake_path}" >> "./${shmake_output_file}" 2>&1

  if [ ! -e "./${main_o_path}" ]; then
    echo "Fail! First target (${main_o_target}) was not created!"
    return 1
  fi

  echo "Success! First target (${main_o_target}) was created!"
  old_time=$(stat -c %Y "./$main_o_path")

  sleep 1
  touch ./${main_cpp_path}
  eval "bash ./${shmake_path}" >> "./${shmake_output_file}" 2>&1

  new_time=$(stat -c %Y "./$main_o_path")

  if [ "${old_time}" -eq "${new_time}" ]; then
    echo "Fail! First target was not updated after modifying dependency file!"
    return 1
  fi
  echo "Success! First target was updated after modifying dependency file!"

  rm "./${main_o_path}"
  eval "bash ./${shmake_path}" >> "./${shmake_output_file}" 2>&1
  if [ ! -e "./${main_o_path}" ]; then
    echo "Fail! First target was not recreated after deletion!"
    echo ""
    echo "Test 1 finished with failure!"
    echo "------------------------------"
    return 1
  fi
  echo "Success! First target was recreated after deletion!"

  ((tests_passed++))

  echo ""
  echo "Test 1 finished successfully!"
  echo "------------------------------"
  return 0
}

test1_wrapper() {
  shmakefile_path="./shmakefile"
  shmake_path="./shell_make.sh"
  file1_cpp_path="./file1.cpp"
  file2_cpp_path="./file2.cpp"
  main_cpp_path="./main_file.cpp"
  file1_h_path="./file1.h"
  file2_h_path="./file2.h"
  file1_o_path="./file1.o"
  file2_o_path="./file2.o"
  main_o_path="./main_file.o"
  main_o_target="main_file.o"
  needed_resources="../resources/shmakefiles/test1/shmakefile ../resources/main_file.cpp ../resources/file1.h ../resources/file2.h"
  shmake_output_file="../test1_logs.txt"
  test1 || true
  set +o errexit
  rm -f "./${main_o_path}" "./${main_cpp_path}" "./${shmakefile_path}" "./${file1_h_path}" "./${file2_h_path}"
  set -o errexit
}

test2() {
  cp ${needed_resources} -r "./"

  echo "------------------------------"
  echo "Starting test 2..."
  echo ""
  eval "bash ./${shmake_path} ${file1_o_target}" >> "./${shmake_output_file}" 2>&1

  if [ ! -e "./${file1_o_path}" ]; then
    echo "Fail! Requested target (${file1_o_target}) was not created!"
    return 1
  fi

  echo "Success! Requested target (${file1_o_target}) was created!"
  old_time=$(stat -c %Y "./$file1_o_path")

  sleep 1
  touch ./${file1_cpp_path}
  eval "bash ${shmake_path} ${file1_o_target}" >> "./${shmake_output_file}" 2>&1

  new_time=$(stat -c %Y "./$file1_o_path")

  if [ "${old_time}" -eq "${new_time}" ]; then
    echo "Fail! Requested target was not updated after modifying dependency file!"
    return 1
  fi
  echo "Success! Requested target was updated after modifying dependency file!"

  rm "./${file1_o_path}"
  eval "bash ${shmake_path} ${file1_o_target}" >> "./${shmake_output_file}" 2>&1
  if [ ! -e "./${file1_o_path}" ]; then
    echo "Fail! Requested target was not recreated after deletion!"
    echo ""
    echo "Test 2 finished with failure!"
    echo "------------------------------"
    return 1
  fi
  echo "Success! Requested target was recreated after deletion!"

  ((tests_passed++))

  echo ""
  echo "Test 2 finished successfully!"
  echo "------------------------------"
  return 0
}

test2_wrapper() {
  shmakefile_path="./shmakefile"
  shmake_path="./shell_make.sh"
  file1_cpp_path="./file1.cpp"
  file2_cpp_path="./file2.cpp"
  main_cpp_path="./main_file.cpp"
  file1_o_path="./file1.o"
  file1_o_target="file1.o"
  file2_o_path="./file2.o"
  file2_o_target="file2.o"
  main_o_path="./main_file.o"
  main_o_target="main_file.o"
  needed_resources="../resources/shmakefiles/test2/shmakefile ../resources/file1.cpp ../resources/file1.h"
  shmake_output_file="../test2_logs.txt"
  test2 || true
  set +o errexit
  rm -f "./${file1_o_path}" "./${file1_cpp_path}" "./${shmakefile_path}" "./${file1_h_path}"
  set -o errexit
}

test3() {
  result=1
  cp ${needed_resources} -r "./"

  echo "------------------------------"
  echo "Starting test 3..."
  echo ""
  eval "bash ${shmake_path} ${main_o_target} ${file1_o_target} ${file2_o_target}" >> "./${shmake_output_file}" 2>&1

  if [ ! -e "./${main_o_path}" ] || [ ! -e "./${file1_o_path}" ] || [ ! -e "./${file2_o_path}" ]; then
    echo "Fail! At least one of requested targets (${main_o_target}, ${file1_o_target}, ${file2_o_target}) was not created!"
    return 1
  fi

  echo "Success! Requested targets (${main_o_target}, ${file1_o_target}, ${file2_o_target}) were created!"
  old_time1=$(stat -c %Y "./$main_o_path")
  old_time2=$(stat -c %Y "./$file1_o_path")
  old_time3=$(stat -c %Y "./$file2_o_path")

  sleep 1
  touch ./${main_cpp_path}
  touch ./${file1_cpp_path}
  eval "bash ${shmake_path} ${main_o_target} ${file1_o_target} ${file2_o_target}" >> "./${shmake_output_file}" 2>&1

  new_time1=$(stat -c %Y "./$main_o_path")
  new_time2=$(stat -c %Y "./$file1_o_path")
  new_time3=$(stat -c %Y "./$file2_o_path")

  if [ "${old_time3}" -ne "${new_time3}" ]; then
    echo "Fail! Up to date target was updated!"
    result=0
  else
    echo "Success! Up to date target was not touched!"
  fi

  if [ "${old_time1}" -eq "${new_time1}" ]; then
    echo "Fail! Requested target was not updated after modifying dependency file!"
    result=0
  else
    echo "Success! Requested target was updated after modifying dependency file!"
  fi

  if [ "${old_time2}" -eq "${new_time2}" ]; then
    echo "Fail! Requested target was not updated after modifying dependency file!"
    result=0
  else
    echo "Success! Requested target was updated after modifying dependency file!"
  fi

  rm -f "./${main_o_path}" "./${file1_o_path}" "./${file2_o_path}"
  eval "bash ${shmake_path} ${main_o_target} ${file1_o_target} ${file2_o_target}" >> "./${shmake_output_file}" 2>&1
  if [ ! -e "./${file1_o_path}" ] || [ ! -e "./${file2_o_path}" ] || [ ! -e "./${main_o_path}" ]; then
    echo "Fail! One or more of requested targets was not recreated after deletion!"
    echo ""
    echo "Test 3 finished with failure!"
    echo "------------------------------"
    return 1
  fi
  echo "Success! Requested targets were all successfully recreated after deletion!"

  ((tests_passed+=result))

  echo ""
  if [ "${result}" -eq 1 ]; then
    echo "Test 3 finished successfully!"
  else
    echo "Test 3 finished with failure!"
  fi
  echo "------------------------------"
  return 0
}

test3_wrapper() {
  shmakefile_path="./shmakefile"
  shmake_path="./shell_make.sh"
  file1_cpp_path="./file1.cpp"
  file2_cpp_path="./file2.cpp"
  main_cpp_path="./main_file.cpp"
  file1_o_path="./file1.o"
  file1_o_target="file1.o"
  file2_o_path="./file2.o"
  file2_o_target="file2.o"
  main_o_path="./main_file.o"
  main_o_target="main_file.o"
  needed_resources="../resources/shmakefiles/test3/shmakefile ../resources/file1.cpp ../resources/file1.h ../resources/file2.cpp ../resources/file2.h ../resources/main_file.cpp"
  shmake_output_file="../test3_logs.txt"
  test3 || true
  set +o errexit
  rm -f "./${file1_o_path}" "./${file2_o_path}" "./${main_o_path}"
  rm -f "./${file1_cpp_path}" "./${shmakefile_path}" "./${file1_h_path}" "./${file2_cpp_path}" "./${file2_h_path}" "./${main_cpp_path}"
  set -o errexit
}

conduct_testing() {
  test1_wrapper
  test2_wrapper
  test3_wrapper
}

setup() {
  echo "------------------------------"
  echo "Starting initial setup..."
  echo ""
  set +o errexit

  mkdir_error_output=$(mkdir "./$unpacked_arch_dir" 2>&1)

  # Check the exit status of mkdir
  if [ $? -ne 0 ]; then
      echo "Error while creating directory './$unpacked_arch_dir': $mkdir_error_output"
      exit 1
  else
      echo "Directory './$unpacked_arch_dir' created successfully"
  fi

  unzip_error_output=$(unzip -n "./$arch_name" -d "./$unpacked_arch_dir" 2>&1)

  # Check the exit status of unzip
  if [ $? -ne 0 ]; then
      echo "Error while unzipping archive './$arch_name':"
      echo "${unzip_error_output}"
      exit 1
  else
      echo "Unzipped archive './$arch_name' successfully"
  fi

  mkdir_error_output=$(mkdir "./${working_dir}" 2>&1)

  # Check the exit status of mkdir
  if [ $? -ne 0 ]; then
      echo "Error while creating temp directory './$working_dir':"
      echo "$mkdir_error_output"
      exit 1
  else
      echo "Temp directory './$working_dir' created successfully"
  fi

  cp_error_output=$(cp "./${unpacked_arch_path}/shell_make.sh" "./${working_dir}" 2>&1)

  # Check the exit status of cp (copy)
  if [ $? -ne 0 ]; then
      echo "Error while copying './${unpacked_arch_path}/shell_make.sh' to './${working_dir}':"
      echo "$cp_error_output"
      exit 1
  else
      echo "Copied './${unpacked_arch_path}/shell_make.sh' to './${working_dir}' successfully"
  fi

  set -o errexit
  cd "./${working_dir}"
  echo "Changed directory to './${working_dir}' successfully"

  echo ""
  echo "Setup ended successfully!"
  echo "------------------------------"
}

clean_up() {
  echo "Cleaning..."
  cd ../
  rm -rf ./temp
  rm -rf ./"$unpacked_arch_dir"
  echo "Cleaned."
}

# Parse arguments
# ----------------------------------------------------------
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <archive with work>"
    exit 1
fi

arch_name="$1"

# ----------------------------------------------------------
arch_basename=$(basename "$arch_name")
unpacked_arch_path="./${unpacked_arch_dir}/${arch_basename%.*}" # Remove extension and concatenate

setup
conduct_testing || true
clean_up

echo "Tests passed: ${tests_passed}/3"