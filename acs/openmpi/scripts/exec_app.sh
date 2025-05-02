#!/bin/bash
# This script should be run on the master node

echo "Creating hostfile..."
cat > /app/hostfile << EOF
mpi-master
mpi-worker1
mpi-worker2
EOF

su - mpiuser << EOF

cd /app

cp -r /ssh/config_file /app/config_file

echo "Running MPI program for the first time"
mpirun --hostfile /app/hostfile -np 3 /app/bin/openmpi /config_files/config.cfg

EOF
