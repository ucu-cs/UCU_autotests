### MYCAT Tests

How-to:

1. The script `test_mycat_2b.sh` is the starting point of all tests. It's purpose is running your `mycat` executable with various combinations of flags and input files.
2. The script supports `-e` flag that instructs it to terminate on the first failure of any test case.
3. It also supports `-l` flag that appends test cases with HUGE input files to the suite.      
3.1 The runtime is also compared to that of the standard `cat`.     
3.2 You have to put the huge input files of the appropriate sizes into the working directory yourself. See the proper filenames in the beginning of the test script.
4. The script can wrap the execution of `mycat` with another parent process... For example, it can be benfeicial to benchmark the `mycat` with `valgrind` or test its resilience to random signals coming in by starting it from within `runner` (which is compiled with the `CMakeLists.txt` included). To tell the script what parent program to use, pass it with `-v` flag like `-v valgrind`.
