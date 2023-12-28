FROM ubuntu:18.04

RUN apt clean
RUN apt update
RUN DEBIAN_FRONTEND=noninteractive apt install -y build-essential curl wget software-properties-common llvm git
# add this for installing latest version of python3.8
RUN add-apt-repository ppa:deadsnakes/ppa
RUN add-apt-repository ppa:avsm/ppa
RUN printf "deb http://apt.llvm.org/xenial/ llvm-toolchain-xenial-12 main" | tee /etc/apt/sources.list.d/llvm-toolchain-xenial-12.list
RUN wget -O - https://apt.llvm.org/llvm-snapshot.gpg.key | apt-key add
RUN apt update

# install other libraries
RUN DEBIAN_FRONTEND=noninteractive apt install -y git vim python3-pip gdb \
    default-jdk m4 xxd clang flex bison autopoint gperf texinfo libjpeg-dev \
    nasm libass-dev libmp3lame-dev dh-autoreconf unzip libopus-dev \
    libtheora-dev libvorbis-dev rsync python3-dev python-dev \
    libgcc-9-dev

RUN DEBIAN_FRONTEND=noninteractive apt install -y clang-10
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y llvm-12 liblldb-12 python3-lldb-12 lldb-12 llvm-12-dev libllvm12 llvm-12-runtime
RUN update-alternatives --install /usr/bin/llvm-config llvm-config /usr/bin/llvm-config-12 10

# install DAFL
RUN git clone https://github.com/pslhy/DAFL.git --recursive
RUN git clone https://github.com/prosyslab/smake.git
RUN git clone https://github.com/prosyslab/sparrow.git

# build DAFL
WORKDIR /DAFL
RUN make && cd llvm_mode && make

# build sparrow
WORKDIR /sparrow
RUN ./build.sh

# install elfutils
RUN DEBIAN_FRONTEND=noninteractive apt install -y unzip pkg-config zlib1g zlib1g-dev autoconf libtool cmake
WORKDIR /root
RUN curl -o elfutils-0.185.tar.bz2 https://sourceware.org/elfutils/ftp/0.185/elfutils-0.185.tar.bz2
RUN tar -xf elfutils-0.185.tar.bz2
WORKDIR /root/elfutils-0.185/
RUN ./configure --disable-debuginfod --disable-libdebuginfod
RUN make
RUN make install

# install python3.8 and the libraries we need
RUN DEBIAN_FRONTEND=noninteractive apt install -y python3.8
RUN python3.8 -m pip install toml pyparsing z3-solver libclang
RUN python3 -m pip install toml pyparsing

# build the project
COPY . /home/yuntong/vulnfix/
WORKDIR /home/yuntong/vulnfix/
RUN git submodule init
RUN git submodule update
# build is slow within docker build, so just build inside container
RUN ./build.sh

ENV PATH="/home/yuntong/vulnfix/bin:${PATH}"

ENTRYPOINT /bin/bash
