#!/usr/bin/env bash
script_name="my_cvt_img.sh"

if [ -n "$(grep sudo my_cvt_img.sh)" ]; then
	echo "sudo not allowed in script!"
	exit 1
fi
tar xpvf test.tar
cd test
./test_cvt_img.sh
