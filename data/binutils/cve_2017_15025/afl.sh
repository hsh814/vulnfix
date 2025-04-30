#!/bin/bash

rm -rf afl-source
git clone https://github.com/bminor/binutils-gdb.git afl-source
pushd afl-source/
  git checkout 515f23e63c0074ab531bc954f84ca40c6281a724
  cp ../dwarf2.evocatio.c ./bfd/dwarf2.c
popd

export AFL_DIR=/home/yuntong/vulnfix/thirdparty/AFL
export AFL_USE_ASAN=1
export ASAN_OPTIONS=detect_leaks=0
rm -rf afl-build && mkdir afl-build
pushd afl-build
  mkdir temp
  TMP_DIR=$PWD/temp
  mkdir aflrun_tmp
  export AFLRUN_TMP=$PWD/aflrun_tmp
  echo "dwarf2.c:2441" > $TMP_DIR/BBtargets.txt
  export AFLRUN_BB_TARGETS=$TMP_DIR/BBtargets.txt
  export AFLRUN_TARGETS="nm-new"
  # export ADDITIONAL_FLAGS="-flto -fuse-ld=gold -Wl,-plugin-opt=save-temps"
  CC=$AFL_DIR/afl-clang-fast CXX=$AFL_DIR/afl-clang-fast++ ASAN_OPTIONS=detect_leaks=0  ../afl-source/configure --disable-shared --disable-gdb --disable-libdecnumber --disable-readline --disable-sim LIBS='-ldl -lutil'
  CC=$AFL_DIR/afl-clang-fast CXX=$AFL_DIR/afl-clang-fast++ ASAN_OPTIONS=detect_leaks=0   make CFLAGS="-ldl -lutil -fsanitize=address -ggdb -Wno-error" CXXFLAGS="-fsanitize=address -ldl -lutil -ggdb -Wno-error" LDFLAGS=" -ldl -lutil -fsanitize=address" -j 10
popd

rm -rf afl-runtime && mkdir -p afl-runtime/in
cp exploit ./afl-runtime/in
cp ./afl-build/binutils/nm-new afl-runtime/nm-new
