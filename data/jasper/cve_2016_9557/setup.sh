#!/bin/bash
rm -rf source
unzip source.zip

pushd source
  autoreconf -i
popd

rm -rf smake_source && mkdir smake_source
pushd smake_source
  CC=clang CXX=clang++ ../source/configure
  CC=clang CXX=clang++ /home/yuntong/vulnfix/thirdparty/smake/smake --init
  CC=clang CXX=clang++ /home/yuntong/vulnfix/thirdparty/smake/smake CFLAGS="-static -g -fsanitize=address -fsanitize=undefined" CXXFLAGS="-static -g -fsanitize=address -fsanitize=undefined" LDFLAGS="-fsanitize=address -fsanitize=undefined" -j 10
popd

rm -rf sparrow-out && mkdir sparrow-out
/home/yuntong/vulnfix/thirdparty/sparrow/bin/sparrow -outdir ./sparrow-out \
-frontend "clang" -unsound_alloc -unsound_const_string -unsound_recursion -unsound_noreturn_function \
-unsound_skip_global_array_init 1000 -skip_main_analysis -cut_cyclic_call -unwrap_alloc \
-entry_point "jas_image_create" -max_pre_iter 10 -slice "bug=jas_image.c:162" \
./smake_source/sparrow/src/appl/imginfo/*.i ./smake_source/sparrow/src/libjasper/base/*.i

rm -rf dafl_source && mkdir dafl_source
pushd dafl_source
  DAFL_SELECTIVE_COV="/home/yuntong/vulnfix/data/jasper/cve_2016_9557/sparrow-out/bug/slice_func.txt" \
  DAFL_DFG_SCORE="/home/yuntong/vulnfix/data/jasper/cve_2016_9557/sparrow-out/bug/slice_dfg.txt" \
  ASAN_OPTIONS=detect_leaks=0 CC=/home/yuntong/vulnfix/thirdparty/DAFL/afl-clang-fast CXX=/home/yuntong/vulnfix/thirdparty/DAFL/afl-clang-fast++ \
  ../source/configure

  DAFL_SELECTIVE_COV="/home/yuntong/vulnfix/data/jasper/cve_2016_9557/sparrow-out/bug/slice_func.txt" \
  DAFL_DFG_SCORE="/home/yuntong/vulnfix/data/jasper/cve_2016_9557/sparrow-out/bug/slice_dfg.txt" \
  ASAN_OPTIONS=detect_leaks=0 CC=/home/yuntong/vulnfix/thirdparty/DAFL/afl-clang-fast CXX=/home/yuntong/vulnfix/thirdparty/DAFL/afl-clang-fast++ \
  make CFLAGS="-static -g -fsanitize=address -fsanitize=undefined" CXXFLAGS="-static -g -fsanitize=address -fsanitize=undefined" LDFLAGS="-fsanitize=address -fsanitize=undefined" -j 10
popd

rm -rf raw_build && mkdir raw_build
pushd raw_build
  ../source/configure 
  make CFLAGS="-static -g -fsanitize=address -fsanitize=undefined" CXXFLAGS="-static -g -fsanitize=address -fsanitize=undefined" LDFLAGS="-fsanitize=address -fsanitize=undefined" -j 10
popd

cp raw_build/src/appl/imginfo ./imginfo
cp dafl_source/src/appl/imginfo ./imginfo.instrumented