# UCU_autotests
The project that should collect all tests for UCU robotics lab's subjects and provide one common interface, and all related documentation in one place.

# Available scripts:
For every script --help option is available with the complete description, possible options and usage explanation.

```
test_compilation

test_integral 
test_words_count
```

# Installation
"One script to install it all"
```
./setup.sh
```
It creates symlinks to `/home/$USER/.local/bin` folder, such that all instruments are available from any folder in the system.

# Description 

## Usage
### Step-by-step guide
```{bash}
git clone git@github.com:Myralllka/UCU_autotests.git ~/Downloads    # clone the repo to any suitable location
cd UCU_autotests                                                    # 
./system_check.sh                                                   # check if all necessary programs are installed on your local machine
./setup.sh                                                          # install all programs (make symlinks so they are executable from anywhere)
```
After the setup, `test_compilation`, `test_words_count` and `test_integral` can be used from any folder.

So when a new student's lab is received, what should be done:
- check the `CMakeLists.txt`. Right now `test_compilation` works only if the `CMakeLists.txt` is consistent with the [template](https://github.com/ucu-cs/template_cpp) one.
- run the `test_compilation` in a main lab's folder. It will create multiple executables in `./bin` folder. In case of warnings, consider relaunching the script with `-w` option (see `test_compilation --help` for more details).
- read the output carefully - if there is PVS output, it will be in those logs.
- run the student's program with `./bin/run_with...` executable files, to check it with sanitizers.
- after that, if the lab is **words count** or **integral** - test it with correspondent `test_words_count` or `test_integral` (again, see `--help` for more details)
- test the program with valgrind: `valgrind --tool=helgrind ./bin/releases [options/config]` and `valgrind --tool=memcheck --leak-check=full ./bin/release [options/config]`
- then analyze the code and give the feedback

**optional**
- To check with profiler: test the program with perf - `perf record --call-graph dwarf ./bin/release [options/config]`. Then the `hotspot` program can be used to visualize perf results: `hotspot perf.data`

## ACS words count default test cases description

### Test 0
- structure: 
```bash
├── archive
│   ├── file_to_ignore.html
│   └── file.txt
```
- words_count_testcases/test_0 contains 0 folders, 0 words. `file.txt` is empty, `file_to_ignore.html` has some text that should be ignored. Just the primitive test case to justify if the program even works. 

### Test 1
- structure:
```bash
├── archive
│   └── 11
│       └── 1
│           ├── 1.txt
│           ├── to_ignore.bin
│           └── to_ignore.html
```

- words_count_testcases/test_1 contains 1 word. A little bit better test case to test if the program can work with subdirectories and doesn't count the same file more than once.

### Test 70
- structure:
```bash
archive
│   ├── 1
│   │   ├── 10.txt
│   │   ├── 1.txt
│   │   ├── 2.txt
│   │   ├── 3.txt
│   │   ├── 4.txt
│   │   ├── 5.txt
│   │   ├── 6.txt
│   │   ├── 7.txt
│   │   ├── 8.txt
│   │   └── 9.txt
│   └── 2
│       ├── 10.txt
│       ├── 1.txt
│       ├── 2.txt
│       ├── 3.txt
│       ├── 4.txt
│       ├── 5.txt
│       ├── 6.txt
│       ├── 7.txt
│       ├── 8.txt
│       └── 9.txt
```

- words_count_testcases/test_70 contains in total 70 words. Multiple directories, multiple files. 

### How to add more test cases?
- create a folder `words_count_testcases/test_[something]`, with only one file `archive.zip`.
- create a file `words_count_results/test_[something]`, with the correctly counted words, see existing files. 
- create a template for a configuration files, `words_count_testcases/test_[something].m4`, see existing examples.

# IMPORTANT
**ALL Additional parameters, needed for your lab, should be specified as environmental variable `ADDITIONAL_OPTIONS`**
For example:
for a proper work, the additional parameters `max_live_tokens` and `max_queue_size` should be set.
**Before** launching the `test_words_count`, set a variable, for example:
```
export ADDITIONAL_OPTIONS="max_live_tokens = 16\nmax_queue_size = 1000"
```

# WIP: Digital Ocean server setup for GitHub CI

``` {bash}
#!/bin/bash

sudo apt install -y tmux zsh git curl wget libboost-all-dev clang g++ cmake

groupadd wheel
useradd -G wheel -s /bin/bash -m apps
echo "%wheel ALL=(ALL) NOPASSWD: /usr/bin/apt" >> /etc/sudoers

su apps
cd
mkdir GitHubCI
cd !:$
# as written here https://github.com/organizations/ucu-cs/settings/actions/runners/new
mkdir actions-runner && cd actions-runner
curl -o actions-runner-linux-x64-2.287.1.tar.gz -L https://github.com/actions/runner/releases/download/v2.287.1/actions-runner-linux-x64-2.287.1.tar.gz
tar xzf ./actions-runner-linux-x64-2.287.1.tar.gz

echo "CONFIGURE THE SELF-HOSTED RUNNER ACCORDING TO GITHUB CONFIGURE RECOMMENDATIONS."
```
