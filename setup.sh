#!/bin/bash -x

# Script for setting up everything necessary.
# Requires password
# Mostly creating symlinks to ensure the access from all possible directories
#
# yet :TODO

echo "Password needed to create correct symlinks and make it possible to run test scripts from any directory"
sudo ln -sf $PWD/general/run_prog_with_time_bound.sh /usr/local/bin/run_prog_with_time_bound
sudo chmod +x /usr/local/bin/run_prog_with_time_bound

sudo ln -sf $PWD/general/compile.sh /usr/local/bin/test_compilation
sudo chmod +x /usr/local/bin/test_compilation
sudo ln -sf $PWD/acs/integral/integral.sh /usr/local/bin/test_integral
sudo chmod +x /usr/local/bin/test_integral
sudo ln -sf $PWD/acs/words_count/words.sh /usr/local/bin/test_words_count
sudo chmod +x /usr/local/bin/test_words_count

echo "Now do \"source ~/.bashrc\" or \"source ~/.zshrc\" and use 'test_integral' from any location"

# while true; do
# 	[[ -t 0 ]] && {read -t 10 -n 2 -p $'\e[1;32mSet up for? [y/n] (default: y)\e[0m\n' resp || resp=y;}
# 	response=`echo $resp | sed -r 's/(.*)$/\1=/'`
#
# 	if [[ $response =~ ^(y|Y)=$ ]]
# 	then
# 		# executing
# 		break
# 	fi
# done
