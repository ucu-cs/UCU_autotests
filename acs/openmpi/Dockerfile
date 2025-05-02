FROM debian:stable

RUN apt update && apt install -y \
    openssh-server \
    openmpi-bin \
    openmpi-common \
    libopenmpi-dev \
    libboost-all-dev \
    libpng++-dev \
    libpng-dev \
    cmake \
    make \
    clang \
    build-essential \
    nfs-kernel-server \
    nfs-common

RUN mkdir /var/run/sshd
RUN echo 'root:root' | chpasswd
RUN sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
RUN sed -i 's/#StrictHostKeyChecking ask/StrictHostKeyChecking no/' /etc/ssh/ssh_config

RUN useradd -m -s /bin/bash mpiuser
RUN echo 'mpiuser:mpipass' | chpasswd

RUN mkdir -p /app
WORKDIR /app

EXPOSE 22

CMD ["/usr/sbin/sshd", "-D"]
