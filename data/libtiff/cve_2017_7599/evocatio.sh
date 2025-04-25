#!/bin/bash
commit_id=3cfd62d

rm -rf evocatio-source
git clone https://github.com/vadz/libtiff.git
mv libtiff evocatio-source
pushd evocatio-source
  git checkout $commit_id
  cp ../tif_dirwrite.evocatio.c ./libtiff/tif_dirwrite.c
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
  echo "tif_dirwrite.c:980" > $TMP_DIR/BBtargets.txt
  export AFLRUN_BB_TARGETS=$TMP_DIR/BBtargets.txt
  export AFLRUN_TARGETS="tiffcp"
  # export ADDITIONAL_FLAGS="-flto -fuse-ld=gold -Wl,-plugin-opt=save-temps"
  export FORCE_UNSAFE_CONFIGURE=1
  CC=$EVOCATIO/afl-cc CXX=$EVOCATIO/afl-c++ ASAN_OPTIONS=detect_leaks=0 ../evocatio-source/configure
  CC=$EVOCATIO/afl-cc CXX=$EVOCATIO/afl-c++ ASAN_OPTIONS=detect_leaks=0 make CFLAGS="-fsanitize=float-cast-overflow,address -static -ggdb" CXXFLAGS="-fsanitize=float-cast-overflow,address -static -ggdb" LDFLAGS="-fsanitize=float-cast-overflow,address -fno-sanitize-recover=all" -j10
popd
rm -rf evocatio-runtime && mkdir -p evocatio-runtime/in
cp exploit ./evocatio-runtime/in
cp ./evocatio-build/tools/tiffcp evocatio-runtime/tiffcp

# AFL_NO_UI=1 timeout 12h /home/yuntong/vulnfix/thirdparty/DAFL/afl-fuzz -C -t 2000ms -m none -i ./in -p /home/yuntong/vulnfix/data/libtiff/cve_2017_7599/sparrow-out/bug/slice_dfg.txt -o 2024-04-04-test -- ./tiffcp.instrumented -i @@ /tmp/out.tmp
# AFL_NO_UI=1 timeout 12h /home/yuntong/vulnfix/thirdparty/DAFL/afl-fuzz -C -t 2000ms -m none -i ./in -p /home/yuntong/vulnfix/data/libtiff/cve_2017_7599/sparrow-out/bug/slice_dfg.txt -o 2024-04-04-k -k 0 -r 0.1 -- ./tiffcp.instrumented -i @@ /tmp/out.tmp

