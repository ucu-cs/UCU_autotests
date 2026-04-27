#!/bin/sh

service ssh start

su - mpiuser << EOF
mkdir -p ~/.ssh
chmod 700 ~/.ssh

if [ ! -f ~/.ssh/id_rsa ]; then
    ssh-keygen -t rsa -N "" -f ~/.ssh/id_rsa
fi

cp ~/.ssh/id_rsa.pub /ssh/$(hostname).pub
touch /ssh/$(hostname).ready
EOF

while [ ! -f /ssh/mpi-master.ready ] || \
      [ ! -f /ssh/mpi-worker1.ready ] || \
      [ ! -f /ssh/mpi-worker2.ready ]; do
    sleep 1
done

su - mpiuser << 'EOF'
mkdir -p ~/.ssh

echo "Host *" > ~/.ssh/config
echo "    StrictHostKeyChecking no" >> ~/.ssh/config
echo "    UserKnownHostsFile=/dev/null" >> ~/.ssh/config
chmod 600 ~/.ssh/config

cat /ssh/*.pub > ~/.ssh/authorized_keys
chmod 600 ~/.ssh/authorized_keys

for host in mpi-master mpi-worker1 mpi-worker2; do
    until ssh-keyscan -H $host >> ~/.ssh/known_hosts 2>/dev/null; do
        sleep 1
    done
done
EOF

echo "Compiling application on master node..."
cd /app
./compile.sh -o
chmod -R 755 /app/bin/

echo "SSH setup completed. Keeping container running..."
tail -f /dev/null
