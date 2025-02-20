#!/bin/bash
rm -rf source
unzip source
mv libxml2-db07dd61 source

cp HTMLparser.pacfix.c source/HTMLparser.c
cp source/dict.c dict.orig.c
cp source/HTMLparser.c HTMLparser.orig.c

rm -rf pacfix
cp -r source pacfix
pushd pacfix
  ./autogen.sh
  make CFLAGS="-static -fsanitize=address -fsanitize=undefined -g" CXXFLAGS="-static -fsanitize=address -fsanitize=undefined -g" -j10
  # cat make.log | grep parser.c
  gcc -E -DHAVE_CONFIG_H -I. -I./include -I./include -D_REENTRANT -fsanitize=address -g -MT dict.lo -MD -MP -MF .deps/dict.Tpo -c dict.c > dict.c.i
  cilly --domakeCFG --gcc=/usr/bin/gcc-7 --out=tmp.c dict.c.i
  mv tmp.c dict.c.i.c
  cp dict.c.i.c dict.c
  gcc -E -DHAVE_CONFIG_H -I. -I./include -I./include -D_REENTRANT -fsanitize=address -g -MT HTMLparser.lo -MD -MP -MF .deps/HTMLparser.Tpo -c HTMLparser.c > HTMLparser.c.i
  cilly --domakeCFG --gcc=/usr/bin/gcc-7 --out=tmp.c HTMLparser.c.i
  mv tmp.c HTMLparser.c.i.c
  cp HTMLparser.c.i.c HTMLparser.c
popd
/home/yuntong/pacfix/main.exe -lv_only 1 config

# manually fix the code
# python3 /home/yuntong/vulnfix/src/add_lv.py 4079 repair-out/live_variables ./source/parser.c
cp dict.pacfix.c ./source/dict.c

rm -rf smake_source && cp -R source smake_source
pushd smake_source
  CC=clang CXX=clang++ ./autogen.sh
  CC=clang CXX=clang++ /home/yuntong/vulnfix/thirdparty/smake/smake --init
  CC=clang CXX=clang++ /home/yuntong/vulnfix/thirdparty/smake/smake CFLAGS="-static -fsanitize=address -fsanitize=undefined -g" CXXFLAGS="-static -fsanitize=address -fsanitize=undefined -g" -j10
popd

cp dict.orig.c ./source/dict.c

rm -rf sparrow-out && mkdir sparrow-out
/home/yuntong/vulnfix/thirdparty/sparrow/bin/sparrow -outdir ./sparrow-out \
-frontend "cil" -unsound_alloc -unsound_const_string -unsound_recursion -unsound_noreturn_function \
-unsound_skip_global_array_init 1000 -skip_main_analysis -cut_cyclic_call -unwrap_alloc \
-entry_point "main" -max_pre_iter 10 -slice "bug=dict.c:285" \
./smake_source/sparrow/xmllint/*.i

rm -rf dafl_source && cp -R source dafl_source
pushd dafl_source
  DAFL_SELECTIVE_COV="/home/yuntong/vulnfix/data/libxml2/cve_2016_1839/sparrow-out/bug/slice_func.txt" \
  DAFL_DFG_SCORE="/home/yuntong/vulnfix/data/libxml2/cve_2016_1839/sparrow-out/bug/slice_dfg.txt" \
  ASAN_OPTIONS=detect_leaks=0 CC=/home/yuntong/vulnfix/thirdparty/DAFL/afl-clang-fast CXX=/home/yuntong/vulnfix/thirdparty/DAFL/afl-clang-fast++ \
  CMAKE_EXPORT_COMPILE_COMMANDS=1 ./autogen.sh

  DAFL_SELECTIVE_COV="/home/yuntong/vulnfix/data/libxml2/cve_2016_1839/sparrow-out/bug/slice_func.txt" \
  DAFL_DFG_SCORE="/home/yuntong/vulnfix/data/libxml2/cve_2016_1839/sparrow-out/bug/slice_dfg.txt" \
  ASAN_OPTIONS=detect_leaks=0 CC=/home/yuntong/vulnfix/thirdparty/DAFL/afl-clang-fast CXX=/home/yuntong/vulnfix/thirdparty/DAFL/afl-clang-fast++ \
  make CFLAGS="-static -fsanitize=address -fsanitize=undefined -g" CXXFLAGS="-static -fsanitize=address -fsanitize=undefined -g" -j10
popd

cp dafl_source/xmllint ./xmllint.instrumented

# AFL_NO_UI=1 timeout 12h /home/yuntong/vulnfix/thirdparty/DAFL/afl-fuzz -C -t 2000ms -m none -i ./in -p /home/yuntong/vulnfix/data/libtiff/cve_2016_5321/sparrow-out/bug/slice_dfg.txt -o 2024-04-04-test -- ./tiffcrop.instrumented @@ /tmp/out.tmp


