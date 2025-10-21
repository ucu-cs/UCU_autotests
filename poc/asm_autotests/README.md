# UCU fasm lab work functions

##### with array always give it's size! There is no way to find size of C array. If few arrays are of the same size, only one coefficient can be passed.

#### [tasks description](https://github.com/ucu-cs/template_asm/blob/master/task.md)

## THIS REPO for:
1) test cases
2) scripts for generating test cases (can be python or C/C++/Rust)
3) test scripts (in C language)

## Building and running tests
Each folder in this repository contains tests for one or more tasks. Refer to [this](https://github.com/ucu-cs/template_asm/blob/master/task.md) document for more information about each task.

All tests should be compiled and linked with an object file `func.o`, which contains the function `func`. This is the function being tested.
In order to do all this, a `makefile` in root directory is provided.
### Makefile

The build process consists of three steps

1. Assemble source code for `func.o` into an object file in an external directory specified in `FUNC_PATH`. This relies on the `makefule` in external directory
2. Symlink this object file into a local `obj` dir, which itself is in `TEST_DIR`
3. Compile the test program in `TEST_DIR` into a binary and link it with the object file `func.o`

Therefore, variables `FUNC_PATH` and `TEST_DIR` **must** be set with each `make` command.

Note: make assumes that the external directory `FUNC_PATH` contains a valid makefile that creates a `func.o` object in `obj` dir when run with target `all`.

Example
```shell
make FUNC_PATH=abs/path/to/func_1 TEST_DIR=5_axb_32_int all 
```
It is possible to use targets other than `all` if you want only some of build steps to run. You may also want to change other variables, such as path to assmebler, c compiler, etc. Refer to `makefile` for more info.

Note: to get an absolute path from a relative path, set `FUNC_PATH` like this
```
make FUNC_PATH=$(realpath ../relative/path/to/func) ...
```

Simple way to make it work:

1. Compile func_x (student`s function)
2. Type command: make FUNC_PATH="path to dir func_x" TEST_DIR="path to dir of the test" all
3. If there is a python script: cd test_arrays/scripts -> python3 "script" -> move to 4.
4. If there is not a python script: cd "test dir path"/bin/ -> ./test

## HOW TO CONTRIBUTE
1) check what is done
2) create an issue about WHAT TO ADD
3) assign to yourself
4) contribute =)

# THE BEST - to add your implementation in `asm` =)) but not necessary
