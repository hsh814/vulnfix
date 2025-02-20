#!/bin/bash
rm -rf source
git clone https://github.com/libjpeg-turbo/libjpeg-turbo.git source

pushd source
  git checkout 4f24016
  autoreconf -fiv
popd

cp ./jdmarker.pacfix2.c ./source/jdmarker.c
cp ./source/jdmarker.c ./jdmarker.orig.c
cp ./source/jdapimin.c ./jdapimin.orig.c 
cp ./source/jpeglib.h jpeglib.orig.h


eval $(opam env --switch=default)
rm -rf pacfix
cp -r source pacfix
pushd pacfix
  ./configure
  make CFLAGS="-static -fsanitize=address -fsanitize=undefined -g" CXXFLAGS="-static -fsanitize=address -fsanitize=undefined -g" -j10 > make.log
  # cat make.log | grep jdmarker.c
  gcc -E -fno-optimize-sibling-calls -fno-strict-aliasing -fno-asm -std=c99 -DHAVE_CONFIG_H -I. -Wall -fsanitize=address -fsanitize=undefined -g -MT libturbojpeg_la-jdmarker.lo -MD -MP -MF .deps/libturbojpeg_la-jdmarker.Tpo -c jdmarker.c -lm -s > jdmarker.c.i
  cilly --domakeCFG --gcc=/usr/bin/gcc-7 --out=tmp.c jdmarker.c.i
  mv tmp.c jdmarker.c.i.c
  cp jdmarker.c.i.c jdmarker.c
popd
# /home/yuntong/pacfix/main.exe -lv_only 1 ./config

# manually fix the code
# python3 /home/yuntong/vulnfix/src/add_lv.py 327 repair-out/live_variables ./source/jdmarker.c 
#cp jdmarker.pacfix.c ./source/jdmarker.c
#cp jdapimin.pacfix.c ./source/jdapimin.c
#cp jpeglib.pacfix.h ./source/jpeglib.h


#rm -rf smake_source && mkdir smake_source
#pushd smake_source
#  CC=clang CXX=clang++ ../source/configure
#  CC=clang CXX=clang++ /home/yuntong/vulnfix/thirdparty/smake/smake --init
#  CC=clang CXX=clang++ /home/yuntong/vulnfix/thirdparty/smake/smake CFLAGS="-static -fsanitize=address -fsanitize=undefined -g" CXXFLAGS="-static -fsanitize=address -fsanitize=undefined -g" -j 10
#popd

cp ./jdmarker.orig.c ./source/jdmarker.c 
cp ./jdapimin.orig.c ./source/jdapimin.c
cp ./jpeglib.orig.h ./source/jpeglib.h

#rm -rf sparrow-out && mkdir sparrow-out
#/home/yuntong/vulnfix/thirdparty/sparrow/bin/sparrow -outdir ./sparrow-out \
#-frontend "clang" -unsound_alloc -unsound_const_string -unsound_recursion -unsound_noreturn_function \
#-unsound_skip_global_array_init 1000 -skip_main_analysis -cut_cyclic_call -unwrap_alloc \
#-entry_point "main" -max_pre_iter 10 -slice "bug=jdmarker.c:328" \
#./smake_source/sparrow/djpeg/*.i ./smake_source/sparrow/jdapimin.o.i  ./smake_source/sparrow/jdinput.o.i  ./smake_source/sparrow/jdmarker.o.i ./smake_source/sparrow/djpeg-*.i

rm -rf dafl_source && mkdir dafl_source
pushd dafl_source
  DAFL_SELECTIVE_COV="/home/yuntong/vulnfix/data/libjpeg/cve_2012_2806/sparrow-out/bug/slice_func.txt" \
  DAFL_DFG_SCORE="/home/yuntong/vulnfix/data/libjpeg/cve_2012_2806/sparrow-out/bug/slice_dfg.txt" \
  ASAN_OPTIONS=detect_leaks=0 CC=/home/yuntong/vulnfix/thirdparty/CLUDAFL/afl-clang-fast CXX=/home/yuntong/vulnfix/thirdparty/CLUDAFL/afl-clang-fast++ \
  ../source/configure

  DAFL_SELECTIVE_COV="/home/yuntong/vulnfix/data/libjpeg/cve_2012_2806/sparrow-out/bug/slice_func.txt" \
  DAFL_DFG_SCORE="/home/yuntong/vulnfix/data/libjpeg/cve_2012_2806/sparrow-out/bug/slice_dfg.txt" \
  ASAN_OPTIONS=detect_leaks=0 CC=/home/yuntong/vulnfix/thirdparty/CLUDAFL/afl-clang-fast CXX=/home/yuntong/vulnfix/thirdparty/CLUDAFL/afl-clang-fast++ \
  make CFLAGS="-static -fsanitize=address -fsanitize=undefined -g" CXXFLAGS="-static -fsanitize=address -fsanitize=undefined -g" -j 10
popd

rm -rf cludafl-runtime && mkdir cludafl-runtime
cp dafl_source/djpeg cludafl-runtime/djpeg