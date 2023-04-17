FROM nvidia/cuda:10.0-devel-ubuntu18.04
LABEL maintainer="zhongbo2@illinois.edu"

ENV TZ=US \
    DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
        apt-get install -y --no-install-recommends \
        software-properties-common \
        sudo && \
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
        python3.8 \
        python3.8-dev \
        libpython3.8-dev \
        python3.8-distutils \
        python3-pip 

# make python3.8 the default python3
RUN ln -sf /usr/bin/python3.8 /usr/bin/python3

ENV CFLAGS="-I/usr/include/python3.8 -lpython3.8"

# Setup JAVA_HOME -- useful for docker commandline
ENV JAVA_HOME /usr/lib/jvm/java-8-openjdk-amd64/
RUN export JAVA_HOME

RUN python3.8 -m pip install --upgrade pip setuptools distlib wheel
RUN python3.8 -m pip install pybind11 
RUN python3.8 -m pip install setuptools 
RUN python3.8 -m pip install duckdb==0.7.1

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
RUN cd ldbc_graphalytics && scripts/install-local.sh
RUN cd ldbc_graphalytics_platforms_graphblas && bin/sh/install-graphblas.sh 
RUN cd ldbc_graphalytics_platforms_graphblas && bin/sh/install-lagraph.sh



# Step1: docker build -t ece508-cuda-graph-analytics .
# before docker run, please make sure you have installed cuda inside wsl2
# then docker for cuda will automatically work
# try compile and run ECE508 in wsl2 to verify the cuda installation
# Step2: docker run --gpus all -it ece508-cuda-graph-analytics