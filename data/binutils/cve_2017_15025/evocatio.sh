#!/bin/bash

rm -rf evocatio-source
git clone https://github.com/bminor/binutils-gdb.git evocatio-source
pushd evocatio-source/
  git checkout 515f23e63c0074ab531bc954f84ca40c6281a724
  cp ../dwarf2.evocatio.c ./bfd/dwarf2.c
popd

export EVOCATIO=/home/yuntong/vulnfix/thirdparty/Evocatio/bug-severity-AFLplusplus
export AFL_USE_ASAN=1
export ASAN_OPTIONS=detect_leaks=0
rm -rf evocatio-build && mkdir evocatio-build
pushd evocatio-build
  mkdir temp
  TMP_DIR=$PWD/temp
  mkdir aflrun_tmp
  export AFLRUN_TMP=$PWD/aflrun_tmp
  echo "dwarf2.c:2441" > $TMP_DIR/BBtargets.txt
  export AFLRUN_BB_TARGETS=$TMP_DIR/BBtargets.txt
  export AFLRUN_TARGETS="nm-new"
  # export ADDITIONAL_FLAGS="-flto -fuse-ld=gold -Wl,-plugin-opt=save-temps"
  CC=$EVOCATIO/afl-cc CXX=$EVOCATIO/afl-c++ ASAN_OPTIONS=detect_leaks=0  ../evocatio-source/configure --disable-shared --disable-gdb --disable-libdecnumber --disable-readline --disable-sim LIBS='-ldl -lutil'
  CC=$EVOCATIO/afl-cc CXX=$EVOCATIO/afl-c++ ASAN_OPTIONS=detect_leaks=0   make CFLAGS="-ldl -lutil -fsanitize=address -ggdb -Wno-error" CXXFLAGS="-fsanitize=address -ldl -lutil -ggdb -Wno-error" LDFLAGS=" -ldl -lutil -fsanitize=address" -j 10
popd

rm -rf evocatio-runtime && mkdir -p evocatio-runtime/in
cp exploit ./evocatio-runtime/in
cp ./evocatio-build/binutils/nm-new evocatio-runtime/nm-new
