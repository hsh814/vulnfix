#!/bin/bash
rm -rf source
unzip source.zip 
mv libtiff-2c00d31b6cd5282d172754958b8b87c362f852ee source

cp tif_jpeg.pacfix.c source/libtiff/tif_jpeg.c
cp source/libtiff/tif_jpeg.c tif_jpeg.orig.c
cp source/libtiff/tif_write.c tif_write.orig.c
cp source/libtiff/tiffiop.h tiffiop.orig.h

eval $(opam env --switch=default)
rm -rf pacfix
cp -r source pacfix
pushd pacfix
  ./configure
  make CFLAGS="-static -fsanitize=address -fsanitize=undefined -g" CXXFLAGS="-static -fsanitize=address -fsanitize=undefined -g" -j10
  pushd libtiff
    gcc -E -DHAVE_CONFIG_H -I. -fsanitize=address -fsanitize=undefined -g -MT tif_jpeg.lo -MD -MP -MF .deps/tif_jpeg.Tpo -c tif_jpeg.c > tif_jpeg.c.i
    cilly --domakeCFG --gcc=/usr/bin/gcc-7 --out=tmp.c tif_jpeg.c.i
    mv tmp.c tif_jpeg.c.i.c
    cp tif_jpeg.c.i.c tif_jpeg.c
  popd
popd
/home/yuntong/pacfix/main.exe -lv_only 1 config

cp tif_jpeg.pacfix2.c source/libtiff/tif_jpeg.c
cp tif_write.pacfix.c source/libtiff/tif_write.c 
cp tiffiop.pacfix.h source/libtiff/tiffiop.h

rm -rf smake_source && mkdir smake_source
pushd smake_source
  CC=clang CXX=clang++ ../source/configure
  CC=clang CXX=clang++ /home/yuntong/vulnfix/thirdparty/smake/smake --init
  CC=clang CXX=clang++ /home/yuntong/vulnfix/thirdparty/smake/smake CFLAGS="-static -fsanitize=address -fsanitize=undefined -g" CXXFLAGS="-static -fsanitize=address -fsanitize=undefined -g" -j10
popd
cp tif_jpeg.orig.c source/libtiff/tif_jpeg.c
cp tif_write.orig.c source/libtiff/tif_write.c 
cp tiffiop.orig.h source/libtiff/tiffiop.h

rm -rf sparrow-out && mkdir sparrow-out
/home/yuntong/vulnfix/thirdparty/sparrow/bin/sparrow -outdir ./sparrow-out \
-frontend "cil" -unsound_alloc -unsound_const_string -unsound_recursion -unsound_noreturn_function \
-unsound_skip_global_array_init 1000 -skip_main_analysis -cut_cyclic_call -unwrap_alloc \
-entry_point "main" -max_pre_iter 10 -slice "bug=tif_jpeg.c:1687" \
./smake_source/sparrow/tools/tiffcp/*.i

rm -rf dafl_source && mkdir dafl_source
pushd dafl_source
  DAFL_SELECTIVE_COV="/home/yuntong/vulnfix/data/libtiff/cve_2017_7595/sparrow-out/bug/slice_func.txt" \
  DAFL_DFG_SCORE="/home/yuntong/vulnfix/data/libtiff/cve_2017_7595/sparrow-out/bug/slice_dfg.txt" \
  ASAN_OPTIONS=detect_leaks=0 CC=/home/yuntong/vulnfix/thirdparty/CLUDAFL/afl-clang-fast CXX=/home/yuntong/vulnfix/thirdparty/CLUDAFL/afl-clang-fast++ \
  CMAKE_EXPORT_COMPILE_COMMANDS=1 ../source/configure

  DAFL_SELECTIVE_COV="/home/yuntong/vulnfix/data/libtiff/cve_2017_7595/sparrow-out/bug/slice_func.txt" \
  DAFL_DFG_SCORE="/home/yuntong/vulnfix/data/libtiff/cve_2017_7595/sparrow-out/bug/slice_dfg.txt" \
  ASAN_OPTIONS=detect_leaks=0 CC=/home/yuntong/vulnfix/thirdparty/CLUDAFL/afl-clang-fast CXX=/home/yuntong/vulnfix/thirdparty/CLUDAFL/afl-clang-fast++ \
  make CFLAGS="-static -fsanitize=address -fsanitize=undefined -g" CXXFLAGS="-static -fsanitize=address -fsanitize=undefined -g" -j10
popd

rm -rf cludafl-runtime && mkdir cludafl-runtime
cp dafl_source/tools/tiffcp cludafl-runtime/tiffcp

# AFL_NO_UI=1 timeout 12h /home/yuntong/vulnfix/thirdparty/DAFL/afl-fuzz -C -t 2000ms -m none -i ./in -p /home/yuntong/vulnfix/data/libtiff/cve_2016_5321/sparrow-out/bug/slice_dfg.txt -o 2024-04-04-test -- ./tiffcrop.instrumented @@ /tmp/out.tmp


