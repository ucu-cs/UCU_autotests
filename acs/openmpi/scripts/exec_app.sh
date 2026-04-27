#!/bin/bash
# This script should be run on the master node

echo "Creating hostfile..."
cat > /app/hostfile << EOF
mpi-master
mpi-worker1
mpi-worker2
EOF

cd /app
./compile.sh -o

su - mpiuser << EOF

cd /app

echo "Running MPI program for the first time"
mpirun --hostfile /app/hostfile -np 3 /app/cmake-build-release/openmpi /config_files/config.cfg

EOF
