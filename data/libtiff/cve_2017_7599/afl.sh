#!/bin/bash
commit_id=3cfd62d

rm -rf afl-source
git clone https://github.com/vadz/libtiff.git
mv libtiff afl-source
pushd afl-source
  git checkout $commit_id
  cp ../tif_dirwrite.evocatio.c ./libtiff/tif_dirwrite.c
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
  echo "tif_dirwrite.c:980" > $TMP_DIR/BBtargets.txt
  export AFLRUN_BB_TARGETS=$TMP_DIR/BBtargets.txt
  export AFLRUN_TARGETS="tiffcp"
  # export ADDITIONAL_FLAGS="-flto -fuse-ld=gold -Wl,-plugin-opt=save-temps"
  export FORCE_UNSAFE_CONFIGURE=1
  CC=$AFL_DIR/afl-clang-fast CXX=$AFL_DIR/afl-clang-fast++ ASAN_OPTIONS=detect_leaks=0 ../afl-source/configure
  CC=$AFL_DIR/afl-clang-fast CXX=$AFL_DIR/afl-clang-fast++ ASAN_OPTIONS=detect_leaks=0 make CFLAGS="-fsanitize=float-cast-overflow,address -static -ggdb" CXXFLAGS="-fsanitize=float-cast-overflow,address -static -ggdb" LDFLAGS="-fsanitize=float-cast-overflow,address -fno-sanitize-recover=all" -j10
popd
rm -rf afl-runtime && mkdir -p afl-runtime/in
cp exploit ./afl-runtime/in
cp ./afl-build/tools/tiffcp afl-runtime/tiffcp

# AFL_NO_UI=1 timeout 12h /home/yuntong/vulnfix/thirdparty/DAFL/afl-fuzz -C -t 2000ms -m none -i ./in -p /home/yuntong/vulnfix/data/libtiff/cve_2017_7599/sparrow-out/bug/slice_dfg.txt -o 2024-04-04-test -- ./tiffcp.instrumented -i @@ /tmp/out.tmp
# AFL_NO_UI=1 timeout 12h /home/yuntong/vulnfix/thirdparty/DAFL/afl-fuzz -C -t 2000ms -m none -i ./in -p /home/yuntong/vulnfix/data/libtiff/cve_2017_7599/sparrow-out/bug/slice_dfg.txt -o 2024-04-04-k -k 0 -r 0.1 -- ./tiffcp.instrumented -i @@ /tmp/out.tmp

