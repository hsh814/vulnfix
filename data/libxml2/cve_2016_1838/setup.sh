#!/bin/bash
rm -rf source
git clone https://gitlab.gnome.org/GNOME/libxml2.git
mv libxml2 source
pushd source
  git checkout cbb27165
popd

rm -rf smake_source && mkdir smake_source
pushd smake_source
  CC=clang CXX=clang++ ../source/autogen.sh
  CC=clang CXX=clang++ /home/yuntong/vulnfix/thirdparty/smake/smake --init
  CC=clang CXX=clang++ /home/yuntong/vulnfix/thirdparty/smake/smake CFLAGS="-static -fsanitize=address -g" CXXFLAGS="-static -fsanitize=address -g" LDFLAGS="-fsanitize=address" -j10
popd

rm -rf sparrow-out && mkdir sparrow-out
/home/yuntong/vulnfix/thirdparty/sparrow/bin/sparrow -outdir ./sparrow-out \
-frontend "cil" -unsound_alloc -unsound_const_string -unsound_recursion -unsound_noreturn_function \
-unsound_skip_global_array_init 1000 -skip_main_analysis -cut_cyclic_call -unwrap_alloc \
-entry_point "main" -max_pre_iter 10 -slice "bug=parser.c:9837" \
./smake_source/sparrow/xmllint/*.i

rm -rf dafl_source && mkdir dafl_source
pushd dafl_source
  DAFL_SELECTIVE_COV="/home/yuntong/vulnfix/data/libxml2/cve_2016_1838/sparrow-out/bug/slice_func.txt" \
  DAFL_DFG_SCORE="/home/yuntong/vulnfix/data/libxml2/cve_2016_1838/sparrow-out/bug/slice_dfg.txt" \
  ASAN_OPTIONS=detect_leaks=0 CC=/home/yuntong/vulnfix/thirdparty/DAFL/afl-clang-fast CXX=/home/yuntong/vulnfix/thirdparty/DAFL/afl-clang-fast++ \
  CMAKE_EXPORT_COMPILE_COMMANDS=1 ../source/autogen.sh

  DAFL_SELECTIVE_COV="/home/yuntong/vulnfix/data/libxml2/cve_2016_1838/sparrow-out/bug/slice_func.txt" \
  DAFL_DFG_SCORE="/home/yuntong/vulnfix/data/libxml2/cve_2016_1838/sparrow-out/bug/slice_dfg.txt" \
  ASAN_OPTIONS=detect_leaks=0 CC=/home/yuntong/vulnfix/thirdparty/DAFL/afl-clang-fast CXX=/home/yuntong/vulnfix/thirdparty/DAFL/afl-clang-fast++ \
  make CFLAGS="-static -fsanitize=address -g" CXXFLAGS="-static -fsanitize=address -g" LDFLAGS="-fsanitize=address" -j10
popd

rm -rf raw_build && mkdir raw_build
pushd raw_build
  ../source/autogen.sh
  make CFLAGS="-static -fsanitize=address -g" CXXFLAGS="-static -fsanitize=address -g" LDFLAGS="-fsanitize=address" -j10
popd

cp raw_build/xmllint ./xmllint
cp dafl_source/xmllint ./xmllint.instrumented
