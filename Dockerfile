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

ENV OUT=/out
ENV SRC=/src
ENV WORK=/work
ENV PATH="$PATH:/out"
RUN mkdir -p $OUT $SRC $WORK

# install a newer version of cmake, since it is required by z3
RUN DEBIAN_FRONTEND=noninteractive apt-get install --yes --no-install-recommends wget
RUN wget -O - https://apt.kitware.com/keys/kitware-archive-latest.asc 2>/dev/null | gpg --dearmor - | tee /etc/apt/trusted.gpg.d/kitware.gpg >/dev/null
RUN DEBIAN_FRONTEND=noninteractive apt purge --yes --auto-remove cmake && \
    apt-add-repository "deb https://apt.kitware.com/ubuntu/ $(lsb_release -cs) main"  && \
    apt update && \
    apt-get install --yes --no-install-recommends cmake

COPY checkout_build_install_llvm.sh /root/
RUN /root/checkout_build_install_llvm.sh
RUN rm /root/checkout_build_install_llvm.sh

# install python3.8, for driver scripts of the project
RUN DEBIAN_FRONTEND=noninteractive apt install -y python3.8

# install other libraries
RUN DEBIAN_FRONTEND=noninteractive apt install -y git vim python3-pip gdb \
    default-jdk m4 xxd clang flex bison autopoint gperf texinfo libjpeg-dev \
    nasm libass-dev libmp3lame-dev dh-autoreconf unzip libopus-dev \
    libtheora-dev libvorbis-dev rsync python3-dev python-dev opam

RUN DEBIAN_FRONTEND=noninteractive apt install -y clang-12

RUN DEBIAN_FRONTEND=noninteractive apt-get install -y llvm-12 llvm-12-dev libllvm12 llvm-12-runtime opam \
    libclang-cpp12-dev libgmp-dev libclang-12-dev llvm-12-dev libmpfr-dev ncurses-dev 
RUN sed -i '/opam install -j \$NCPU sparrow --deps-only/s/$/ --assume-depexts/'
    
RUN update-alternatives --install /usr/bin/llvm-config llvm-config /usr/bin/llvm-config-12 10
RUN update-alternatives --install /usr/bin/clang clang /usr/bin/clang-12 40
RUN update-alternatives --install /usr/bin/clang++ clang++ /usr/bin/clang++-12 40

# install elfutils
RUN DEBIAN_FRONTEND=noninteractive apt install -y unzip pkg-config zlib1g zlib1g-dev autoconf libtool cmake
WORKDIR /root
RUN curl -o elfutils-0.185.tar.bz2 https://sourceware.org/elfutils/ftp/0.185/elfutils-0.185.tar.bz2
RUN tar -xf elfutils-0.185.tar.bz2
WORKDIR /root/elfutils-0.185/
RUN ./configure --disable-debuginfod --disable-libdebuginfod
RUN make
RUN make install

# build the project
COPY . /home/yuntong/vulnfix/
WORKDIR /home/yuntong/vulnfix/
RUN git submodule init
RUN git submodule update

# build DAFL
WORKDIR /home/yuntong/vulnfix/thirdparty/DAFL
RUN make && cd llvm_mode && make

# build sparrow
WORKDIR /home/yuntong/vulnfix/thirdparty/sparrow
RUN ./build.sh

WORKDIR /home/yuntong/vulnfix/
RUN python3.8 -m pip install -r requirements.txt
# required for building cvc5 (default python3 is 3.6)
RUN python3 -m pip install toml pyparsing
# NOTE: this might be slow
RUN ./build.sh

ENV PATH="/home/yuntong/vulnfix/bin:${PATH}"

ENTRYPOINT /bin/bash
