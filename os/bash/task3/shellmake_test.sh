#!/bin/bash

tests_passed=0

test1() {
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
  needed_resources="../resources/shmakefiles/test1/shmakefile ../resources/main_file.cpp ../resources/file1.h ../resources/file2.h"

  cp ${needed_resources} -r "./"

  echo "------------------------------"
  echo "Starting test 1..."
  echo ""
  eval "bash ${shmake_path}"

  if [ ! -e "${main_o_path}" ]; then
    echo "Fail! First target (main_file.o) was not created!"
    return 1
  fi

  echo "Success! First target (main_file.o) was created!"
  old_time=$(stat -c %Y "$main_o_path")

  sleep 1
  touch ${main_cpp_path}
  eval "bash ${shmake_path}"

  new_time=$(stat -c %Y "$main_o_path")

  if [ "${old_time}" -eq "${new_time}" ]; then
    echo "Fail! First target was not updated after modifying dependency file!"
    return 1
  fi
  echo "Success! First target was updated after modifying dependency file!"

  rm "${main_o_path}"
  eval "bash ${shmake_path}"
  if [ ! -e "${main_o_path}" ]; then
    echo "Fail! First target was not recreated after deletion!"
    echo ""
    echo "Test 1 finished with failure!"
    echo "------------------------------"
    return 1
  fi
  echo "Success! First target was recreated after deletion!"

  rm "${main_o_path}"
  rm "${main_cpp_path}" "${shmakefile_path}" "${file1_h_path}" "${file2_h_path}"

  echo ""
  echo "Test 1 finished successfully!"
  echo "------------------------------"
  return 0
}

test2() {
  shmakefile_path="./shmakefile"
  shmake_path="./shell_make.sh"
  file1_cpp_path="./file1.cpp"
  file2_cpp_path="./file2.cpp"
  main_cpp_path="./main_file.cpp"
  file1_o_path="./file1.o"
  file2_o_path="./file2.o"
  main_o_path="./main_file.o"
  needed_resources="../resources/shmakefiles/test2/shmakefile ../resources/file1.cpp ../resources/file1.h"

  cp ${needed_resources} -r "./"

  echo "------------------------------"
  echo "Starting test 2..."
  echo ""
  eval "bash ${shmake_path} file1.o"

  if [ ! -e "${file1_o_path}" ]; then
    echo "Fail! Requested target (file1.o) was not created!"
    return 1
  fi

  echo "Success! Requested target (file1.o) was created!"
  old_time=$(stat -c %Y "$file1_o_path")

  sleep 1
  touch ${file1_cpp_path}
  eval "bash ${shmake_path} file1.o"

  new_time=$(stat -c %Y "$file1_o_path")

  if [ "${old_time}" -eq "${new_time}" ]; then
    echo "Fail! Requested target was not updated after modifying dependency file!"
    return 1
  fi
  echo "Success! Requested target was updated after modifying dependency file!"

  rm "${file1_o_path}"
  eval "bash ${shmake_path} file1.o"
  if [ ! -e "${file1_o_path}" ]; then
    echo "Fail! Requested target was not recreated after deletion!"
    echo ""
    echo "Test 2 finished with failure!"
    echo "------------------------------"
    return 1
  fi
  echo "Success! Requested target was recreated after deletion!"

  rm "${file1_o_path}"
  rm "${file1_cpp_path}" "${shmakefile_path}" "${file1_h_path}"

  echo ""
  echo "Test 2 finished successfully!"
  echo "------------------------------"
  return 0
}

test3() {
  shmakefile_path="./shmakefile"
  shmake_path="./shell_make.sh"
  file1_cpp_path="./file1.cpp"
  file2_cpp_path="./file2.cpp"
  main_cpp_path="./main_file.cpp"
  file1_o_path="./file1.o"
  file2_o_path="./file2.o"
  main_o_path="./main_file.o"
  needed_resources="../resources/shmakefiles/test3/shmakefile ../resources/file1.cpp ../resources/file1.h ../resources/file2.cpp ../resources/file2.h ../resources/main_file.cpp"

  cp ${needed_resources} -r "./"

  echo "------------------------------"
  echo "Starting test 3..."
  echo ""
  eval "bash ${shmake_path} main_file.o file1.o file2.o"

  if [ ! -e "${main_o_path}" ] || [ ! -e "${file1_o_path}" ] || [ ! -e "${file2_o_path}" ]; then
    echo "Fail! Requested targets (main_file.o, file1.o, file2.o) were not created!"
    return 1
  fi

  echo "Success! Requested targets (main_file.o, file1.o, file2.o) were created!"
  old_time1=$(stat -c %Y "$main_o_path")
  old_time2=$(stat -c %Y "$file1_o_path")
  old_time3=$(stat -c %Y "$file2_o_path")

  sleep 1
  touch ${main_cpp_path}
  touch ${file1_cpp_path}
  eval "bash ${shmake_path} main_file.o file1.o file2.o"

  new_time1=$(stat -c %Y "$main_o_path")
  new_time2=$(stat -c %Y "$file1_o_path")
  new_time3=$(stat -c %Y "$file2_o_path")

  if [ "${old_time3}" -ne "${new_time3}" ]; then
    echo "Fail! Up to date target was updated!"
    return 1
  fi
  echo "Success! Up to date target was not touched!"

  if [ "${old_time1}" -eq "${new_time1}" ]; then
      echo "Fail! Requested target was not updated after modifying dependency file!"
      return 1
    fi
  echo "Success! Requested target was updated after modifying dependency file!"

  if [ "${old_time2}" -eq "${new_time2}" ]; then
      echo "Fail! Requested target was not updated after modifying dependency file!"
      return 1
    fi
  echo "Success! Requested target was updated after modifying dependency file!"

  rm "${main_o_path}" "${file1_o_path}" "${file2_o_path}"
  eval "bash ${shmake_path} main_file.o file1.o file2.o"
  if [ ! -e "${file1_o_path}" ] || [ ! -e "${file2_o_path}" ] || [ ! -e "${main_o_path}" ]; then
    echo "Fail! One or more of requested targets was not recreated after deletion!"
    echo ""
    echo "Test 3 finished with failure!"
    echo "------------------------------"
    return 1
  fi
  echo "Success! Requested targets were all successfully recreated after deletion!"

  rm "${file1_o_path}" "${file2_o_path}" "${main_o_path}"
  rm "${file1_cpp_path}" "${shmakefile_path}" "${file1_h_path}" "${file2_cpp_path}" "${file2_h_path}" "${main_cpp_path}"

  echo ""
  echo "Test 3 finished successfully!"
  echo "------------------------------"
  return 0
}

# Parse arguments
# ----------------------------------------------------------
if [ "$#" -ne 1 ]; then
    echo "Usage: $0 <archive with work>"
    exit 1
fi

arch_name="$1"

# ----------------------------------------------------------

# needed_resources="../resources/file1.cpp ../resources/file1.h ../resources/file2.cpp ../resources/file2.h ../resources/main_file.cpp ../resources/shmakefile"
working_dir="./temp"
unpacked_arch_dir="./unpacked_archive"
arch_basename="$(basename "$arch_name")"
unpacked_arch_path="${unpacked_arch_dir}/${arch_basename%.*}" # Remove extension and concatenate

unzip -q "$arch_name" -d "$unpacked_arch_dir" || exit

echo "Unzipped archive successfully!"

mkdir -p ${working_dir}
cp "${unpacked_arch_path}/shell_make.sh" ${working_dir}
cd ${working_dir} || exit
echo "Prepared working directory..."

test1
if [ $? -eq 0 ]; then
  ((tests_passed++))
fi
test2
if [ $? -eq 0 ]; then
  ((tests_passed++))
fi
test3
if [ $? -eq 0 ]; then
  ((tests_passed++))
fi

echo "Cleaning..."
cd ../
rm -rf ./temp
rm -rf "$unpacked_arch_dir"
echo "Cleaned."
echo "Tests passed: ${tests_passed}/3"
