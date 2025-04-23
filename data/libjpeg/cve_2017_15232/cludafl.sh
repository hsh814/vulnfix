#!/bin/bash
rm -rf source
unzip source.zip
mv libjpeg-turbo-32120054c224d1911ebe33dc664c0f730a7782b2 source 
pushd source
  autoreconf -i
popd

cp jdpostct.pacfix.c  ./source/jdpostct.c 
cp ./source/jdpostct.c jdpostct.orig.c 
cp ./source/jquant1.c jquant1.orig.c 
cp ./source/jdmainct.c ./jdmainct.orig.c
cp ./source/jdapistd.c ./jdapistd.orig.c
cp ./source/jdmainct.h ./jdmainct.orig.h


eval $(opam env --switch=default)
# rm -rf pacfix
# cp -r source pacfix
# pushd pacfix
#   ./configure
#   make CFLAGS="-static -fsanitize=address -fsanitize=undefined -g" CXXFLAGS="-static -fsanitize=address -fsanitize=undefined -g" -j10
#   # cat make.log | grep jdpostct.c
#   gcc -E -DHAVE_CONFIG_H -I. -Wall -fsanitize=address -fsanitize=undefined -g -MT jdpostct.lo -MD -MP -MF .deps/jdpostct.Tpo -c jdpostct.c > jdpostct.c.i
#   cilly --domakeCFG --gcc=/usr/bin/gcc-7 --out=tmp.c jdpostct.c.i
#   mv tmp.c jdpostct.c.i.c
#   cp jdpostct.c.i.c jdpostct.c
#   gcc -E -DHAVE_CONFIG_H -I. -Wall -fsanitize=address -fsanitize=undefined -g -MT jquant1.lo -MD -MP -MF .deps/jquant1.Tpo -c jquant1.c > jquant1.c.i
#   cilly --domakeCFG --gcc=/usr/bin/gcc-7 --out=tmp.c jquant1.c.i
#   mv tmp.c jquant1.c.i.c
#   cp jquant1.c.i.c jquant1.c
# popd
# $VULNFIX_HOME/pacfix/main.exe -lv_only 1 config

# manually fix the code
# python3 $VULNFIX_HOME/vulnfix/src/add_lv.py 327 repair-out/live_variables ./source/jdmarker.c 
cp jquant1.pacfix.c ./source/jquant1.c
cp ./jdpostct.pacfix2.c  ./source/jdpostct.c 
cp ./jdmainct.pacfix.c ./source/jdmainct.c 
cp ./jdapistd.pacfix.c ./source/jdapistd.c 
cp ./jdmainct.pacfix.h ./source/jdmainct.h 

rm -rf smake_source && mkdir smake_source
echo Running smake...
pushd smake_source
  CC=clang CXX=clang++ ../source/configure
  CC=clang CXX=clang++ $VULNFIX_HOME/vulnfix/thirdparty/smake/smake --init
  CC=clang CXX=clang++ $VULNFIX_HOME/vulnfix/thirdparty/smake/smake CFLAGS="-static -fsanitize=address -fsanitize=undefined -g" CXXFLAGS="-static -fsanitize=address -fsanitize=undefined -g" -j 10
popd

cp ./jdpostct.orig.c  ./source/jdpostct.c 
cp jquant1.orig.c ./source/jquant1.c
cp ./jdmainct.orig.c ./source/jdmainct.c 
cp ./jdapistd.orig.c ./source/jdapistd.c 
cp ./jdmainct.orig.h ./source/jdmainct.h 

echo smake finished!

rm -rf sparrow-out && mkdir sparrow-out
echo Running sparrow...
$VULNFIX_HOME/vulnfix/thirdparty/sparrow/bin/sparrow -outdir ./sparrow-out \
-frontend "clang" -unsound_alloc -unsound_const_string -unsound_recursion -unsound_noreturn_function \
-unsound_skip_global_array_init 1000 -skip_main_analysis -cut_cyclic_call -unwrap_alloc \
-entry_point "main" -max_pre_iter 10 -slice "bug=jquant1.c:536" \
./smake_source/sparrow/djpeg/*.i ./smake_source/sparrow/jquant1.o.i \
./smake_source/sparrow/jdpostct.o.i ./smake_source/sparrow/jdapistd.o.i \
./smake_source/sparrow/jdmainct.o.i

echo sparrow finished!

rm -rf dafl_source && mkdir dafl_source
echo Building with DAFL...
pushd dafl_source
  DAFL_SELECTIVE_COV="$VULNFIX_HOME/vulnfix/data/libjpeg/cve_2017_15232/sparrow-out/bug/slice_func.txt" \
  DAFL_DFG_SCORE="$VULNFIX_HOME/vulnfix/data/libjpeg/cve_2017_15232/sparrow-out/bug/slice_dfg.txt" \
  ASAN_OPTIONS=detect_leaks=0 CC=$VULNFIX_HOME/vulnfix/thirdparty/CLUDAFL/afl-clang-fast CXX=$VULNFIX_HOME/vulnfix/thirdparty/CLUDAFL/afl-clang-fast++ \
  ../source/configure

  DAFL_SELECTIVE_COV="$VULNFIX_HOME/vulnfix/data/libjpeg/cve_2017_15232/sparrow-out/bug/slice_func.txt" \
  DAFL_DFG_SCORE="$VULNFIX_HOME/vulnfix/data/libjpeg/cve_2017_15232/sparrow-out/bug/slice_dfg.txt" \
  ASAN_OPTIONS=detect_leaks=0 CC=$VULNFIX_HOME/vulnfix/thirdparty/CLUDAFL/afl-clang-fast CXX=$VULNFIX_HOME/vulnfix/thirdparty/CLUDAFL/afl-clang-fast++ \
  make CFLAGS="-static -fsanitize=address -fsanitize=undefined -g" CXXFLAGS="-static -fsanitize=address -fsanitize=undefined -g" -j 10
popd

rm -rf cludafl-runtime && mkdir cludafl-runtime
cp dafl_source/djpeg cludafl-runtime/djpeg
#AFL_NO_UI=1 timeout 12h $VULNFIX_HOME/vulnfix/thirdparty/DAFL/afl-fuzz -C -t 2000ms -m none -i ./in -p $VULNFIX_HOME/vulnfix/data/libtiff/cve_2016_5321/sparrow-out/bug/slice_dfg.txt -o 2024-04-04-test -- ./tiffcrop.instrumented @@ /tmp/out.tmp


