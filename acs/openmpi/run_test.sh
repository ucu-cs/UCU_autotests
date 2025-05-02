#!/bin/bash

RESET="\017"
NORMAL="\033[0m"
GREEN="\033[1;32m"
RED="\033[1;31m"

LAB_DIR=$1

if [ ! -d "$LAB_DIR" ]; then
    echo "Could not find directory $LAB_DIR" > /dev/stderr
    echo "Usage: ./run_test.sh <path_to_lab>" > /dev/stderr
    exit 1
fi

# Setup for tests

rm -rf ./results
rm -rf ./container_scripts
mkdir -p ./results

cp -r ./scripts ./container_scripts
cp -r ./config_files/* ./container_scripts/

rm -rf ./app
cp -r $LAB_DIR ./app

# Execution
#
echo "+ Starting docker mpi containers"
docker compose up --build -d

echo "+ Executing mpi script for the first time"
docker exec mpi-master bash /ssh/exec_app.sh

cp -r ./app/result ./results/result1

echo "+ Executing mpi script for the second time"
docker exec mpi-master bash /ssh/exec_app.sh

cp -r ./app/result ./results/result2

echo "+ Closing containers"
docker compose down

echo "+ Checking results"

# Test comparison

if cmp -s ./results/result1 ./results/result2; then
    printf "$GREEN Test Passed!$NORMAL\n"
else
    printf "$RED Test Failed: Files Differ!$NORMAL\n"
fi
