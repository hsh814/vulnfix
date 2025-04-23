#!/bin/bash
rm -rf source
unzip source.zip

pushd source
  autoreconf -i
popd

cp ./source/src/libjasper/base/jas_image.c jas_image.orig.c
cp ./source/src/libjasper/jpc/jpc_dec.c  ./jpc_dec.orig.c

rm -rf pacfix
cp -r source pacfix

pushd pacfix
  ./configure 
  make CFLAGS="-static -g -fsanitize=address -fsanitize=undefined" CXXFLAGS="-static -g -fsanitize=address -fsanitize=undefined" LDFLAGS="-fsanitize=address -fsanitize=undefined" -j 10
  pushd src/libjasper/base
    gcc -E -DHAVE_CONFIG_H -I. -I../../../src/libjasper/include/jasper -I../../../src/libjasper/include -I../../../src/libjasper/include -g -fsanitize=address -fsanitize=undefined -MT jas_image.lo -MD -MP -MF .deps/jas_image.Tpo -c jas_image.c -lm -s > jas_image.c.i
    cilly --domakeCFG --gcc=/usr/bin/gcc-7 --out=tmp.c jas_image.c.i
    mv tmp.c jas_image.c.i.c 
    cp jas_image.c.i.c jas_image.c
  popd
popd
$VULNFIX_HOME/pacfix/main.exe -lv_only 1 config

#cp ./jas_image.pacfix.c ./source/src/libjasper/base/jas_image.c
#cp ./jpc_dec.pacfix.c ./source/src/libjasper/jpc/jpc_dec.c 

#rm -rf smake_source && mkdir smake_source
#pushd smake_source
#  CC=clang CXX=clang++ ../source/configure
#  CC=clang CXX=clang++ $VULNFIX_HOME/vulnfix/thirdparty/smake/smake --init
#  CC=clang CXX=clang++ $VULNFIX_HOME/vulnfix/thirdparty/smake/smake CFLAGS="-static -g -fsanitize=address -fsanitize=undefined" CXXFLAGS="-static -g -fsanitize=address -fsanitize=undefined" LDFLAGS="-fsanitize=address -fsanitize=undefined" -j 10
#popd

cp jas_image.orig.c ./source/src/libjasper/base/jas_image.c 
cp ./jpc_dec.orig.c ./source/src/libjasper/jpc/jpc_dec.c 

#rm -rf sparrow-out && mkdir sparrow-out
#$VULNFIX_HOME/vulnfix/thirdparty/sparrow/bin/sparrow -outdir ./sparrow-out \
#-frontend "clang" -unsound_alloc -unsound_const_string -unsound_recursion -unsound_noreturn_function \
#-unsound_skip_global_array_init 1000 -skip_main_analysis -cut_cyclic_call -unwrap_alloc \
#-max_pre_iter 10 -slice "bug=jas_image.c:162" \
#./smake_source/sparrow/src/appl/imginfo/*.i ./smake_source/sparrow/src/libjasper/base/*.i ./smake_source/sparrow/src/libjasper/jpc/*.i ./smake_source/sparrow/src/libjasper/jp2/*.i

rm -rf dafl_source && mkdir dafl_source
pushd dafl_source
  DAFL_SELECTIVE_COV="$VULNFIX_HOME/vulnfix/data/jasper/cve_2016_9557/sparrow-out/bug/slice_func.txt" \
  DAFL_DFG_SCORE="$VULNFIX_HOME/vulnfix/data/jasper/cve_2016_9557/sparrow-out/bug/slice_dfg.txt" \
  ASAN_OPTIONS=detect_leaks=0 CC=$VULNFIX_HOME/vulnfix/thirdparty/DAFL/afl-clang-fast CXX=$VULNFIX_HOME/vulnfix/thirdparty/DAFL/afl-clang-fast++ \
  ../source/configure

  DAFL_SELECTIVE_COV="$VULNFIX_HOME/vulnfix/data/jasper/cve_2016_9557/sparrow-out/bug/slice_func.txt" \
  DAFL_DFG_SCORE="$VULNFIX_HOME/vulnfix/data/jasper/cve_2016_9557/sparrow-out/bug/slice_dfg.txt" \
  ASAN_OPTIONS=detect_leaks=0 CC=$VULNFIX_HOME/vulnfix/thirdparty/DAFL/afl-clang-fast CXX=$VULNFIX_HOME/vulnfix/thirdparty/DAFL/afl-clang-fast++ \
  make CFLAGS="-static -g -fsanitize=address -fsanitize=undefined" CXXFLAGS="-static -g -fsanitize=address -fsanitize=undefined" LDFLAGS="-fsanitize=address -fsanitize=undefined" -j 10
popd

#rm -rf raw_build && mkdir raw_build
#pushd raw_build
#  ../source/configure 
#  make CFLAGS="-static -g -fsanitize=address -fsanitize=undefined" CXXFLAGS="-static -g -fsanitize=address -fsanitize=undefined" LDFLAGS="-fsanitize=address -fsanitize=undefined" -j 10
#popd

cp dafl_source/src/appl/imginfo ./imginfo.instrumented

