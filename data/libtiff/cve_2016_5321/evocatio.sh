#!/bin/bash
rm -rf evocatio-source
git clone https://github.com/vadz/libtiff.git
mv libtiff evocatio-source
pushd evocatio-source
  git checkout 0ba5d88
  cp ../tiffcrop.evocatio.c ./tools/tiffcrop.c
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
  echo "tiffcrop.c:994" > $TMP_DIR/BBtargets.txt
  export AFLRUN_BB_TARGETS=$TMP_DIR/BBtargets.txt
  export AFLRUN_TARGETS="tiffcrop"
  # export ADDITIONAL_FLAGS="-flto -fuse-ld=gold -Wl,-plugin-opt=save-temps"
  LD=ld CC=$EVOCATIO/afl-cc CXX=$EVOCATIO/afl-c++ ../evocatio-source/configure --enable-static --disable-shared
  CC=$EVOCATIO/afl-cc CXX=$EVOCATIO/afl-c++ make CFLAGS="$ADDITIONAL_FLAGS -static -fsanitize=address -fsanitize=undefined -g" CXXFLAGS="$ADDITIONAL_FLAGS -static -fsanitize=address -fsanitize=undefined -g" -j10
popd

rm -rf evocatio-runtime && mkdir -p evocatio-runtime/in
cp exploit ./evocatio-runtime/in
cp ./evocatio-build/tools/tiffcrop evocatio-runtime/tiffcrop

# $AFLRUN/afl-fuzz -C -i runtime/afl-in -o runtime/afl-run-out -t 2000 -m none -- evocatio-build/tools/tiffcrop @@ /tmp/out.tiff