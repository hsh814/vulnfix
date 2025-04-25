#!/bin/bash
rm -rf evocatio-source
git clone https://github.com/gdraheim/zziplib.git
mv zziplib evocatio-source
pushd evocatio-source
  git checkout 33d6e9c
  pushd docs
    wget https://github.com/LuaDist/libzzip/raw/master/docs/zziplib-manpages.tar
  popd
  cp ../memdisk.evocatio.c zzip/memdisk.c
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
  echo "memdisk.c:182" > $TMP_DIR/BBtargets.txt
  export AFLRUN_BB_TARGETS=$TMP_DIR/BBtargets.txt
  export AFLRUN_TARGETS="unzzipcat-mem"
  # export ADDITIONAL_FLAGS="-flto -fuse-ld=gold -Wl,-plugin-opt=save-temps"
  export FORCE_UNSAFE_CONFIGURE=1
  CC=$EVOCATIO/afl-cc CXX=$EVOCATIO/afl-c++ ASAN_OPTIONS=detect_leaks=0 ../evocatio-source/configure
  CC=$EVOCATIO/afl-cc CXX=$EVOCATIO/afl-c++ ASAN_OPTIONS=detect_leaks=0 make CFLAGS="-static -fsanitize=address -g" CXXFLAGS="-static -fsanitize=address -g" -j10
popd

rm -rf evocatio-runtime && mkdir -p evocatio-runtime/in
cp exploit ./evocatio-runtime/in
cp ./evocatio-build/bins/unzzipcat-mem evocatio-runtime/unzzipcat-mem

