#!/bin/bash
rm -rf source
unzip source.zip
mv libtiff-d651abc097d91fac57f33b5f9447d0a9183f58e7 source
cp tiffcrop.pacfix2.c ./source/tools/tiffcrop.c
cp ./source/tools/tiffcrop.c tiffcrop.orig.c 

rm -rf pacfix
cp -r source pacfix
pushd pacfix
  ./configure
  make CFLAGS="-static -fsanitize=address -g" CXXFLAGS="-static -fsanitize=address -g" -j10
  pushd tools
    gcc -E -DHAVE_CONFIG_H -I. -I../libtiff  -I../libtiff   -static -fsanitize=address -g -MT tiffcrop.o -MD -MP -MF .deps/tiffcrop.Tpo -c tiffcrop.c > tiffcrop.c.i
    cilly --domakeCFG --gcc=/usr/bin/gcc-7 --out=tmp.c tiffcrop.c.i
    mv tmp.c tiffcrop.c.i.c
    cp tiffcrop.c.i.c tiffcrop.c
  popd
popd
$VULNFIX_HOME/pacfix/main.exe -lv_only 1 config

cp tiffcrop.pacfix.c ./source/tools/tiffcrop.c

rm -rf smake_source && mkdir smake_source
pushd smake_source
  CC=clang CXX=clang++ ../source/configure
  CC=clang CXX=clang++ $VULNFIX_HOME/vulnfix/thirdparty/smake/smake --init
  CC=clang CXX=clang++ $VULNFIX_HOME/vulnfix/thirdparty/smake/smake CFLAGS="-static -fsanitize=address -g" CXXFLAGS="-static -fsanitize=address -g" -j10
popd

cp tiffcrop.orig.c ./source/tools/tiffcrop.c

rm -rf sparrow-out && mkdir sparrow-out
$VULNFIX_HOME/vulnfix/thirdparty/sparrow/bin/sparrow -outdir ./sparrow-out \
-frontend "clang" -unsound_alloc -unsound_const_string -unsound_recursion -unsound_noreturn_function \
-unsound_skip_global_array_init 1000 -skip_main_analysis -cut_cyclic_call -unwrap_alloc \
-entry_point "main" -max_pre_iter 10 -slice "bug=tiffcrop.c:2978" \
./smake_source/sparrow/tools/tiffcrop/*.i

rm -rf dafl_source && mkdir dafl_source
pushd dafl_source
  DAFL_SELECTIVE_COV="$VULNFIX_HOME/vulnfix/data/libtiff/cve_2016_9532/sparrow-out/bug/slice_func.txt" \
  DAFL_DFG_SCORE="$VULNFIX_HOME/vulnfix/data/libtiff/cve_2016_9532/sparrow-out/bug/slice_dfg.txt" \
  ASAN_OPTIONS=detect_leaks=0 CC=$VULNFIX_HOME/vulnfix/thirdparty/DAFL/afl-clang-fast CXX=$VULNFIX_HOME/vulnfix/thirdparty/DAFL/afl-clang-fast++ \
  ../source/configure 
  DAFL_SELECTIVE_COV="$VULNFIX_HOME/vulnfix/data/libtiff/cve_2016_9532/sparrow-out/bug/slice_func.txt" \
  DAFL_DFG_SCORE="$VULNFIX_HOME/vulnfix/data/libtiff/cve_2016_9532/sparrow-out/bug/slice_dfg.txt" \
  ASAN_OPTIONS=detect_leaks=0 CC=$VULNFIX_HOME/vulnfix/thirdparty/DAFL/afl-clang-fast CXX=$VULNFIX_HOME/vulnfix/thirdparty/DAFL/afl-clang-fast++ \
  make CFLAGS="-static -fsanitize=address -g" CXXFLAGS="-static -fsanitize=address -g" -j10
popd

cp dafl_source/tools/tiffcrop ./tiffcrop.instrumented

# AFL_NO_UI=1 timeout 12h $VULNFIX_HOME/vulnfix/thirdparty/DAFL/afl-fuzz -C -t 2000ms -m none -i ./in -p $VULNFIX_HOME/vulnfix/data/libtiff/cve_2016_5321/sparrow-out/bug/slice_dfg.txt -o 2024-04-04-test -- ./tiffcrop.instrumented @@ /tmp/out.tmp


