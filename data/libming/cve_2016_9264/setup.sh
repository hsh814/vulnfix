#!/bin/bash
rm -rf source
git clone https://github.com/libming/libming.git
mv libming source

pushd source
  git checkout cc6a386
  ./autogen.sh
popd

rm -rf smake_source && mkdir smake_source
pushd smake_source
  ../source/configure --disable-freetype
  /home/yuntong/vulnfix/thirdparty/smake/smake --init
  /home/yuntong/vulnfix/thirdparty/smake/smake CFLAGS="-static -fsanitize=address -fsanitize=undefined -g" CXXFLAGS="-static -fsanitize=address -fsanitize=undefined -g"
popd

rm -rf sparrow-out && mkdir sparrow-out
/home/yuntong/vulnfix/thirdparty/sparrow/bin/sparrow -outdir ./sparrow-out \
-frontend "clang" -unsound_alloc -unsound_const_string -unsound_recursion -unsound_noreturn_function \
-unsound_skip_global_array_init 1000 -skip_main_analysis -cut_cyclic_call -unwrap_alloc \
-entry_point "main" -max_pre_iter 10 -slice "bug=listmp3.c:128" \
./smake_source/sparrow/util/listmp3/*.i

rm -rf dafl_source && mkdir dafl_source
pushd dafl_source
  DAFL_SELECTIVE_COV="/home/yuntong/vulnfix/data/libming/cve_2016_9264/sparrow-out/bug/slice_func.txt" \
  DAFL_DFG_SCORE="/home/yuntong/vulnfix/data/libming/cve_2016_9264/sparrow-out/bug/slice_dfg.txt" \
  ASAN_OPTIONS=detect_leaks=0 CC=/home/yuntong/vulnfix/thirdparty/DAFL/afl-clang-fast CXX=/home/yuntong/vulnfix/thirdparty/DAFL/afl-clang-fast++ \
  ../source/configure --disable-freetype

  DAFL_SELECTIVE_COV="/home/yuntong/vulnfix/data/libming/cve_2016_9264/sparrow-out/bug/slice_func.txt" \
  DAFL_DFG_SCORE="/home/yuntong/vulnfix/data/libming/cve_2016_9264/sparrow-out/bug/slice_dfg.txt" \
  ASAN_OPTIONS=detect_leaks=0 CC=/home/yuntong/vulnfix/thirdparty/DAFL/afl-clang-fast CXX=/home/yuntong/vulnfix/thirdparty/DAFL/afl-clang-fast++ \
  make CFLAGS="-static -fsanitize=address -fsanitize=undefined -g" CXXFLAGS="-static -fsanitize=address -fsanitize=undefined -g"
popd

rm -rf raw_build && mkdir raw_build
pushd raw_build
  ../source/configure --disable-freetype
  make CFLAGS="-static -fsanitize=address -fsanitize=undefined -g" CXXFLAGS="-static -fsanitize=address -fsanitize=undefined -g"
popd

cp raw_build/util/listmp3 ./listmp3
cp dafl_source/util/listmp3 ./listmp3.instrumented