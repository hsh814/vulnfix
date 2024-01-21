#!/bin/bash
# download libarchive source (v3.2.0)
wget https://libarchive.org/downloads/libarchive-3.2.0.zip
unzip libarchive-3.2.0.zip
rm libarchive-3.2.0.zip
mv libarchive-3.2.0 source

rm -rf smake_source && mkdir smake_source
pushd smake_source
  CC=clang CXX=clang++ ../source/configure --without-openssl
  CC=clang CXX=clang++ /home/yuntong/vulnfix/thirdparty/smake/smake --init
  CC=clang CXX=clang++ /home/yuntong/vulnfix/thirdparty/smake/smake CFLAGS="-fsanitize=address -fsanitize=signed-integer-overflow -static -ggdb" CXXFLAGS="-fsanitize=address -fsanitize=signed-integer-overflow -static -ggdb" LDFLAGS="-fsanitize=address -fsanitize=signed-integer-overflow" -j 10
popd

rm -rf sparrow-out && mkdir sparrow-out
/home/yuntong/vulnfix/thirdparty/sparrow/bin/sparrow -outdir ./sparrow-out \
-frontend "clang" -unsound_alloc -unsound_const_string -unsound_recursion -unsound_noreturn_function \
-unsound_skip_global_array_init 1000 -skip_main_analysis -cut_cyclic_call -unwrap_alloc \
-entry_point "main" -max_pre_iter 10 -slice "bug=archive_read_support_format_iso9660.c:1094" \
./smake_source/sparrow/bsdtar/*.i

rm -rf dafl_source && mkdir dafl_source
pushd dafl_source
  DAFL_SELECTIVE_COV="/home/yuntong/vulnfix/data/libarchive/cve_2016_5844/sparrow-out/bug/slice_func.txt" \
  DAFL_DFG_SCORE="/home/yuntong/vulnfix/data/libarchive/cve_2016_5844/sparrow-out/bug/slice_dfg.txt" \
  ASAN_OPTIONS=detect_leaks=0 CC=/home/yuntong/vulnfix/thirdparty/DAFL/afl-clang-fast CXX=/home/yuntong/vulnfix/thirdparty/DAFL/afl-clang-fast++ \
  ../source/configure --without-openssl

  DAFL_SELECTIVE_COV="/home/yuntong/vulnfix/data/libarchive/cve_2016_5844/sparrow-out/bug/slice_func.txt" \
  DAFL_DFG_SCORE="/home/yuntong/vulnfix/data/libarchive/cve_2016_5844/sparrow-out/bug/slice_dfg.txt" \
  ASAN_OPTIONS=detect_leaks=0 CC=/home/yuntong/vulnfix/thirdparty/DAFL/afl-clang-fast CXX=/home/yuntong/vulnfix/thirdparty/DAFL/afl-clang-fast++ \
  make CFLAGS="-fsanitize=address -fsanitize=signed-integer-overflow -static -ggdb" CXXFLAGS="-fsanitize=address -fsanitize=signed-integer-overflow -static -ggdb" LDFLAGS="-fsanitize=address -fsanitize=signed-integer-overflow" -j 10
popd

rm -rf raw_build && mkdir raw_build
pushd raw_build
  ../source/configure --without-openssl
  make CFLAGS="-fsanitize=address -fsanitize=signed-integer-overflow -static -ggdb" CXXFLAGS="-fsanitize=address -fsanitize=signed-integer-overflow -static -ggdb" LDFLAGS="-fsanitize=address -fsanitize=signed-integer-overflow" -j 10
popd

cp raw_build/bsdtar ./bsdtar
cp dafl_source/bsdtar ./bsdtar.instrumented