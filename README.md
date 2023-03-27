# UCU_autotests
The project that should unify all tests in UCU PoCO, ACS, OS courses and provide one common interface and all related documentation.

# Available instruments:
test_integral

# Installation
One script to install it all
```
./setup.sh
```
It requires password, because it uses `sudo` program to create symlinks to `/usr/local/bin` folder.


# Digital Ocean server setup for GitHub CI

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
