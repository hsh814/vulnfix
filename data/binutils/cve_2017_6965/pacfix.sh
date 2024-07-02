#!/bin/bash
rm -rf source
git clone https://github.com/bminor/binutils-gdb.git
mv binutils-gdb source
pushd source/
  git checkout 53f7e8ea7fad1fcff1b58f4cbd74e192e0bcbc1d
popd

sed '11639s/.*/                 if((reloc_type * reloc_type) < 0) exit(0);/' ./source/binutils/readelf.c > temp && mv temp ./source/binutils/readelf.c

cp ./source/binutils/readelf.c ./readelf.orig.c
cp ./source/binutils/elfcomm.c ./elfcomm.orig.c

rm -rf pacfix
cp -r source pacfix

pushd pacfix
  ASAN_OPTIONS=detect_leaks=0 CC=gcc CXX=g++ CFLAGS="-DFORTIFY_SOURCE=2 -fstack-protector-all -fsanitize=undefined,address -fno-omit-frame-pointer -ggdb -Wno-error" ./configure --disable-shared --disable-gdb --disable-libdecnumber --disable-readline --disable-sim LIBS='-ldl -lutil'
  ASAN_OPTIONS=detect_leaks=0 make CFLAGS="-ldl -lutil -fsanitize=address -fsanitize=undefined -g -Wno-error" CXXFLAGS="-fsanitize=address -fsanitize=undefined -ldl -lutil -g -Wno-error" LDFLAGS=" -ldl -lutil -fsanitize=address -fsanitize=undefined" -j10
  pushd binutils
    gcc -E -fno-optimize-sibling-calls -fno-strict-aliasing -fno-asm -std=c99 -DHAVE_CONFIG_H -I.  -I. -I. -I../bfd -I./../bfd -I./../include -DLOCALEDIR="\"/usr/local/share/locale\"" -Dbin_dummy_emulation=bin_vanilla_emulation  -W -Wall -Wstrict-prototypes -Wmissing-prototypes -Wshadow -Wstack-usage=262144 -Werror -I./../zlib -ldl -lutil -fsanitize=address -fsanitize=undefined -g -MT elfcomm.o -MD -MP -MF .deps/elfcomm.Tpo -c elfcomm.c -lm -s > elfcomm.c.i
    cilly --domakeCFG --gcc=/usr/bin/gcc-7 --out=tmp.c elfcomm.c.i
    mv tmp.c ./elfcomm.c.i.c 
    cp elfcomm.c.i.c elfcomm.c
    gcc -E -fno-optimize-sibling-calls -fno-strict-aliasing -fno-asm -std=c99 -DHAVE_CONFIG_H -I.  -I. -I. -I../bfd -I./../bfd -I./../include -DLOCALEDIR="\"/usr/local/share/locale\"" -Dbin_dummy_emulation=bin_vanilla_emulation  -W -Wall -Wstrict-prototypes -Wmissing-prototypes -Wshadow -Wstack-usage=262144 -Werror -I./../zlib -ldl -lutil -fsanitize=address -fsanitize=undefined -g -MT readelf.o -MD -MP -MF .deps/readelf.Tpo -c readelf.c -lm -s > readelf.c.i
    cilly --domakeCFG --gcc=/usr/bin/gcc-7 --out=tmp.c readelf.c.i
    mv tmp.c ./readelf.c.i.c 
    cp readelf.c.i.c readelf.c
  popd
popd
/home/yuntong/pacfix/main.exe -lv_only config

cp ./readelf.pacfix.c ./source/binutils/readelf.c
cp ./elfcomm.pacfix.c ./source/binutils/elfcomm.c

rm -rf smake_source
mkdir smake_source
pushd smake_source
  # Build with Smake
  ASAN_OPTIONS=detect_leaks=0 CC=gcc CXX=g++ CMAKE_EXPORT_COMPILE_COMMANDS=1 CFLAGS="-DFORTIFY_SOURCE=2 -fstack-protector-all -fsanitize=undefined,address -fno-omit-frame-pointer -ggdb -Wno-error" ../source/configure --disable-shared --disable-gdb --disable-libdecnumber --disable-readline --disable-sim LIBS='-ldl -lutil'
  /home/yuntong/vulnfix/thirdparty/smake/smake --init
  ASAN_OPTIONS=detect_leaks=0 /home/yuntong/vulnfix/thirdparty/smake/smake CFLAGS="-ldl -lutil -fsanitize=address -fsanitize=undefined -g" CXXFLAGS="-fsanitize=address -fsanitize=undefined -ldl -lutil -g" LDFLAGS=" -ldl -lutil -fsanitize=address -fsanitize=undefined" -j10
popd

rm -rf sparrow-out
mkdir sparrow-out

# Run Sparrow
/home/yuntong/vulnfix/thirdparty/sparrow/bin/sparrow -outdir ./sparrow-out \
-frontend "clang" -unsound_alloc -unsound_const_string -unsound_recursion -unsound_noreturn_function \
-unsound_skip_global_array_init 1000 -skip_main_analysis -cut_cyclic_call -unwrap_alloc \
-entry_point "main" -max_pre_iter 10 -slice "bug=elfcomm.c:75" \
./smake_source/sparrow/binutils/readelf/*.i

cp ./readelf.orig.c ./source/binutils/readelf.c
cp ./elfcomm.orig.c ./source/binutils/elfcomm.c

rm -rf dafl_source
mkdir dafl_source
pushd dafl_source
  # Run DAFL Instrumentation
  DAFL_SELECTIVE_COV="/home/yuntong/vulnfix/data/binutils/cve_2017_6965/sparrow-out/bug/slice_func.txt" \
  DAFL_DFG_SCORE="/home/yuntong/vulnfix/data/binutils/cve_2017_6965/sparrow-out/bug/slice_dfg.txt" \
  ASAN_OPTIONS=detect_leaks=0 CC=/home/yuntong/vulnfix/thirdparty/DAFL/afl-clang-fast CXX=/home/yuntong/vulnfix/thirdparty/DAFL/afl-clang-fast++ \
  CMAKE_EXPORT_COMPILE_COMMANDS=1 CFLAGS="-DFORTIFY_SOURCE=2 -fstack-protector-all -fsanitize=undefined,address -fno-omit-frame-pointer -ggdb -Wno-error" \
  CXXFLAGS="$CFLAGS" ../source/configure --disable-shared --disable-gdb --disable-libdecnumber --disable-readline --disable-sim LIBS='-ldl -lutil'

  DAFL_SELECTIVE_COV="/home/yuntong/vulnfix/data/binutils/cve_2017_6965/sparrow-out/bug/slice_func.txt" \
  DAFL_DFG_SCORE="/home/yuntong/vulnfix/data/binutils/cve_2017_6965/sparrow-out/bug/slice_dfg.txt" \
  ASAN_OPTIONS=detect_leaks=0 CC=/home/yuntong/vulnfix/thirdparty/DAFL/afl-clang-fast CXX=/home/yuntong/vulnfix/thirdparty/DAFL/afl-clang-fast++ \
  make CFLAGS="-ldl -lutil -fsanitize=address -fsanitize=undefined -g -Wno-error" CXXFLAGS="-fsanitize=address -fsanitize=undefined -ldl -lutil -g -Wno-error" \
  LDFLAGS=" -ldl -lutil -fsanitize=address -fsanitize=undefined" -j 10
popd

cp ./dafl_source/binutils/readelf ./readelf.instrumented