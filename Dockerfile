FROM ubuntu:22.04

# baseline
RUN apt-get update
RUN apt-get install -y git wget clang gcc-12 g++-12 make cmake libboost-dev
RUN ln -sf /usr/bin/gcc-12 /usr/bin/gcc
RUN ln -sf /usr/bin/g++-12 /usr/bin/g++
RUN git clone https://github.com/Myralllka/UCU_autotests.git


