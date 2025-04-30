#!/bin/bash

rm -rf afl-source
git clone https://gitlab.gnome.org/GNOME/libxml2.git
mv libxml2 afl-source
pushd afl-source
  git checkout 362b3229
  cp ../valid.evocatio.c ./valid.c
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
  echo "valid.c:1181" > $TMP_DIR/BBtargets.txt
  export AFLRUN_BB_TARGETS=$TMP_DIR/BBtargets.txt
  export AFLRUN_TARGETS="xmllint"
  # export ADDITIONAL_FLAGS="-flto -fuse-ld=gold -Wl,-plugin-opt=save-temps"
  export FORCE_UNSAFE_CONFIGURE=1
  CC=$AFL_DIR/afl-clang-fast CXX=$AFL_DIR/afl-clang-fast++ ASAN_OPTIONS=detect_leaks=0 ../afl-source/autogen.sh
  CC=$AFL_DIR/afl-clang-fast CXX=$AFL_DIR/afl-clang-fast++ ASAN_OPTIONS=detect_leaks=0 make  CFLAGS="-static -fsanitize=address -g" CXXFLAGS="-static -fsanitize=address -g" LDFLAGS="-fsanitize=address" -j10
popd

rm -rf afl-runtime && mkdir -p afl-runtime/in
cp exploit ./afl-runtime/in
cp ./afl-build/xmllint afl-runtime/xmllint
