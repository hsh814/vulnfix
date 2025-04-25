#!/bin/bash
rm -rf evocatio-source
unzip source.zip -d evocatio-tmp
mv evocatio-tmp/source evocatio-source
rm -r evocatio-tmp

pushd evocatio-source
  autoreconf -i
  cp ../jpc_dec.evocatio.c ./src/libjasper/jpc/jpc_dec.c
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
  echo "jpc_dec.c:1195" > $TMP_DIR/BBtargets.txt
  export AFLRUN_BB_TARGETS=$TMP_DIR/BBtargets.txt
  export AFLRUN_TARGETS="imginfo"
  # export ADDITIONAL_FLAGS="-flto -fuse-ld=gold -Wl,-plugin-opt=save-temps"
  export FORCE_UNSAFE_CONFIGURE=1
  CC=$EVOCATIO/afl-cc CXX=$EVOCATIO/afl-c++ ASAN_OPTIONS=detect_leaks=0 ../evocatio-source/configure
  CC=$EVOCATIO/afl-cc CXX=$EVOCATIO/afl-c++ ASAN_OPTIONS=detect_leaks=0 make CFLAGS="-static -fsanitize=address -g" CXXFLAGS="-static -fsanitize=address -g" -j 10
popd

rm -rf evocatio-runtime && mkdir -p evocatio-runtime/in
cp exploit ./evocatio-runtime/in
cp ./evocatio-build/src/appl/imginfo evocatio-runtime/imginfo
