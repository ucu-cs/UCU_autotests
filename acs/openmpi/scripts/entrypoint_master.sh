#!/bin/sh

service ssh start

# Set up ssh

su - mpiuser << 'EOF'
mkdir -p ~/.ssh
chmod 700 ~/.ssh

if [ ! -f ~/.ssh/id_rsa ]; then
    ssh-keygen -t rsa -N "" -f ~/.ssh/id_rsa
fi

# Copy public key to shared volume for other containers
cp ~/.ssh/id_rsa.pub /ssh/$(hostname).pub
EOF

# Try to copy keys from other two containers
while [ ! -f /ssh/mpi-master.pub ] || [ ! -f /ssh/mpi-worker1.pub ] || [ ! -f /ssh/mpi-worker2.pub ]; do
    echo "Waiting for all public keys..."
    sleep 2
done

su - mpiuser << 'EOF'
# Add all hosts to known_hosts
ssh-keyscan -H mpi-master >> ~/.ssh/known_hosts
ssh-keyscan -H mpi-worker1 >> ~/.ssh/known_hosts
ssh-keyscan -H mpi-worker2 >> ~/.ssh/known_hosts

ssh-copy-id mpiuser@mpi-master
ssh-copy-id mpiuser@mpi-worker1
ssh-copy-id mpiuser@mpi-worker2
EOF

su - mpiuser << 'EOF'
cat /ssh/mpi-master.pub /ssh/mpi-worker1.pub /ssh/mpi-worker2.pub > ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
EOF


# NFS setup based on hostname
echo "Setting up NFS server on master node..."

# Configure NFS exports
echo "/app *(rw,sync,no_root_squash,no_subtree_check)" > /etc/exports

# Start NFS server
service rpcbind start
service nfs-kernel-server start
exportfs -a

echo "NFS server is running and /app is shared"

# Compile the application on master
echo "Compiling application on master node..."
cd /app

./compile.sh

echo "SSH setup completed. Keeping container running..."
tail -f /dev/null
