#!/bin/sh

service ssh start

# Set up ssh

su - mpiuser << 'EOF'
# Create SSH directory and set permissions
mkdir -p ~/.ssh
chmod 700 ~/.ssh

# Generate SSH key if it doesn't exist
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

# Need known hosts)
su - mpiuser << 'EOF'
cat /ssh/mpi-master.pub /ssh/mpi-worker1.pub /ssh/mpi-worker2.pub > ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys
EOF


# NFS setup based on hostname
echo "Setting up NFS client on worker node $(hostname)..."

service rpcbind start

echo "Waiting for NFS server to be ready..."
while ! rpcinfo -p mpi-master ; do
    echo "NFS server not ready yet, waiting... (attempt $RETRY of $MAX_RETRY)"
    RETRY=$((RETRY+1))
    sleep 5
done

if mountpoint -q /app; then
    umount /app
fi

mount -t nfs mpi-master:/app /app
echo "NFS mount completed"

echo "SSH setup completed. Keeping container running..."
tail -f /dev/null
