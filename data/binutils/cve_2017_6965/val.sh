#!/bin/bash

rm -rf pacfix
eval $(opam env --switch=default)

git clone https://github.com/bminor/binutils-gdb.git
mv binutils-gdb pacfix
pushd pacfix/
  git checkout 53f7e8ea7fad1fcff1b58f4cbd74e192e0bcbc1d
popd

cp ./readelf.pacfix2.c ./pacfix/binutils/readelf.c



pushd pacfix
  ASAN_OPTIONS=detect_leaks=0 CC=gcc CXX=g++ CFLAGS="-DFORTIFY_pacfix=2 -fstack-protector-all -fsanitize=undefined,address -fno-omit-frame-pointer -ggdb -Wno-error" ./configure --disable-shared --disable-gdb --disable-libdecnumber --disable-readline --disable-sim LIBS='-ldl -lutil'
  ASAN_OPTIONS=detect_leaks=0 make CFLAGS="-ldl -lutil -fsanitize=address -fsanitize=undefined -g" CXXFLAGS="-fsanitize=address -fsanitize=undefined -ldl -lutil -g" LDFLAGS=" -ldl -lutil -fsanitize=address -fsanitize=undefined" -j10
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
mkdir -p runtime/afl-in
mkdir -p runtime/afl-out/memory/pos
mkdir -p runtime/afl-out/memory/neg
/home/yuntong/pacfix/main.exe -debug -nouniq -seed -epsilon 0.0 -lvfile ./live_variables -cycle 60 -timeout 300 ./config
