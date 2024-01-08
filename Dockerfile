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

# install a newer version of cmake, since it is required by z3
RUN DEBIAN_FRONTEND=noninteractive apt-get install --yes --no-install-recommends wget
RUN wget -O - https://apt.kitware.com/keys/kitware-archive-latest.asc 2>/dev/null | gpg --dearmor - | tee /etc/apt/trusted.gpg.d/kitware.gpg >/dev/null
RUN DEBIAN_FRONTEND=noninteractive apt purge --yes --auto-remove cmake && \
    apt-add-repository "deb https://apt.kitware.com/ubuntu/ $(lsb_release -cs) main"  && \
    apt update && \
    apt-get install --yes --no-install-recommends cmake

# install python3.8, for driver scripts of the project
RUN DEBIAN_FRONTEND=noninteractive apt install -y python3.8

# install other libraries
RUN DEBIAN_FRONTEND=noninteractive apt install -y git vim python3-pip gdb \
    default-jdk m4 xxd clang flex bison autopoint gperf texinfo libjpeg-dev \
    nasm libass-dev libmp3lame-dev dh-autoreconf unzip libopus-dev \
    libtheora-dev libvorbis-dev rsync python3-dev python-dev 

RUN DEBIAN_FRONTEND=noninteractive apt install -y clang-12
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y llvm-12 llvm-12-dev libllvm12 llvm-12-runtime opam \
    libclang-12-dev libgmp-dev libmpfr-dev llvm-dev ncurses-dev libclang-dev
RUN update-alternatives --install /usr/bin/llvm-config llvm-config /usr/bin/llvm-config-12 10
RUN update-alternatives --install /usr/bin/clang clang /usr/bin/clang-12 40
RUN update-alternatives --install /usr/bin/clang++ clang++ /usr/bin/clang++-12 40

# install DAFL
RUN git clone https://github.com/prosyslab/DAFL.git --recursive
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
RUN python3.8 -m pip install toml pyparsing z3-solver libclang
RUN python3 -m pip install toml pyparsing

# build the project
COPY . /home/yuntong/vulnfix/
WORKDIR /home/yuntong/vulnfix/
RUN git submodule init
RUN git submodule update
RUN python3.8 -m pip install -r requirements.txt
# required for building cvc5 (default python3 is 3.6)
RUN python3 -m pip install toml pyparsing
# NOTE: this might be slow
RUN ./build.sh

ENV PATH="/home/yuntong/vulnfix/bin:${PATH}"

ENTRYPOINT /bin/bash
