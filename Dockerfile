FROM nvidia/cuda:10.0-devel-ubuntu18.04
LABEL maintainer="zhongbo2@illinois.edu"

ENV TZ=US \
    DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
        apt-get install -y --no-install-recommends \
        software-properties-common && \
    add-apt-repository ppa:deadsnakes/ppa && apt-get update && \
    apt-get install -y --no-install-recommends \
        build-essential \
        wget \
        unzip \
        apt-transport-https \
        ca-certificates \
        git && \
    apt-get install -y --no-install-recommends \
        openjdk-8-jdk \
        maven 

RUN \
    apt-get install -y --no-install-recommends \
        python3.9 \
        python3-pip \
        python3.9-dev \
        libpython3.9-dev

ENV CFLAGS="-I/usr/include/python3.9"

# Setup JAVA_HOME -- useful for docker commandline
ENV JAVA_HOME /usr/lib/jvm/java-8-openjdk-amd64/
RUN export JAVA_HOME

RUN \
    pip3 install pybind11 && \
    pip3 install setuptools && \
    pip3 install duckdb==0.7.1

RUN rm -rf /var/lib/apt/lists/*


ADD https://github.com/Kitware/CMake/releases/download/v3.19.2/cmake-3.19.2-Linux-x86_64.sh /tmp
RUN sh /tmp/cmake-3.19.2-Linux-x86_64.sh --prefix=/usr/local --exclude-subdir

WORKDIR /cuda-graph-analytics
RUN git clone https://github.com/tomzzy1/ldbc_graphalytics_platforms_graphblas.git
RUN git clone https://github.com/ldbc/ldbc_graphalytics.git
RUN mkdir /cuda-graph-analytics/example-data-sets
RUN cp -r ldbc_graphalytics_platforms_graphblas/example-data-sets/graphs /cuda-graph-analytics/example-data-sets
COPY ./device_tests /cuda-graph-analytics/device_tests

# configure the repository just downloaded
# install sudo for the following commands
RUN apt-get update && apt-get install -y sudo
RUN cd ldbc_graphalytics && scripts/install-local.sh
RUN cd ldbc_graphalytics_platforms_graphblas && bin/sh/install-graphblas.sh 
RUN cd ldbc_graphalytics_platforms_graphblas && bin/sh/install-lagraph.sh

RUN cd ldbc_graphalytics_platforms_graphblas && \
    scripts/init.sh /cuda-graph-analytics/example-data-sets/graphs /cuda-graph-analytics/example-data-sets/matrices



# Step1: docker build -t ece508-cuda-graph-analytics .
# before docker run, please make sure you have installed cuda inside wsl2
# then docker for cuda will automatically work
# try compile and run ECE508 in wsl2 to verify the cuda installation
# Step2: docker run --gpus all -it ece508-cuda-graph-analytics