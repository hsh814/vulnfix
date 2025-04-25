#!/bin/bash
rm -rf evocatio-source
git clone https://github.com/libjpeg-turbo/libjpeg-turbo.git evocatio-source

pushd evocatio-source
  git checkout 4f24016
  autoreconf -fiv
  cp ../jdmarker.evocatio.c ./jdmarker.c
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
  echo "jdmarker.c:327" > $TMP_DIR/BBtargets.txt
  export AFLRUN_BB_TARGETS=$TMP_DIR/BBtargets.txt
  export AFLRUN_TARGETS="djpeg"
  # export ADDITIONAL_FLAGS="-flto -fuse-ld=gold -Wl,-plugin-opt=save-temps"
  export FORCE_UNSAFE_CONFIGURE=1
  CC=$EVOCATIO/afl-cc CXX=$EVOCATIO/afl-c++ ASAN_OPTIONS=detect_leaks=0 ../evocatio-source/configure
  CC=$EVOCATIO/afl-cc CXX=$EVOCATIO/afl-c++ ASAN_OPTIONS=detect_leaks=0 make CFLAGS="-static -fsanitize=address -fsanitize=undefined -g" CXXFLAGS="-static -fsanitize=address -fsanitize=undefined -g" -j 10
popd

rm -rf evocatio-runtime && mkdir -p evocatio-runtime/in
cp exploit ./evocatio-runtime/in
cp ./evocatio-build/djpeg evocatio-runtime/djpeg

# AFL_NO_UI=1 timeout 12h /home/yuntong/vulnfix/thirdparty/DAFL/afl-fuzz -C -t 2000ms -m none -i ./in -p /home/yuntong/vulnfix/data/libtiff/cve_2016_5321/sparrow-out/bug/slice_dfg.txt -o 2024-04-04-test -- ./tiffcrop.instrumented @@ /tmp/out.tmp


