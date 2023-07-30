# UCU_autotests
The project that should unify all tests in UCU PoCO, ACS, OS courses and provide one common interface and all related documentation.

# Available instruments:
```
test_compilation

test_integral 
test_words_count
```

# Installation
One script to install it all
```
./setup.sh
```
It requires password, because it uses `sudo` program to create symlinks to `/usr/local/bin` folder.

# Description 
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
