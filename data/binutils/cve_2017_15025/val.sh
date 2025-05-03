#!/bin/bash

rm -rf pacfix
eval $(opam env --switch=default)

git clone https://github.com/bminor/binutils-gdb.git
mv binutils-gdb pacfix
pushd pacfix/
  git checkout 515f23e63c0074ab531bc954f84ca40c6281a724
popd

cp dwarf2.pacfix.c pacfix/bfd/dwarf2.c



pushd pacfix
  ASAN_OPTIONS=detect_leaks=0 CC=gcc CXX=g++ CFLAGS="-DFORTIFY_pacfix=2 -fno-omit-frame-pointer -fsanitize=address -ggdb -Wno-error" CXXFLAGS="$CFLAGS" ./configure --disable-shared --disable-gdb --disable-libdecnumber --disable-readline --disable-sim LIBS='-ldl -lutil'
  ASAN_OPTIONS=detect_leaks=0 make CFLAGS="-ldl -lutil -fsanitize=address -ggdb -Wno-error" CXXFLAGS="-fsanitize=address -ldl -lutil -ggdb -Wno-error" LDFLAGS=" -ldl -lutil -fsanitize=address" -j 10
  pushd bfd
    gcc -E -fno-optimize-sibling-calls -fno-strict-aliasing -fno-asm -std=c99 -DHAVE_CONFIG_H -I. -I. -I. -I./../include -DHAVE_x86_64_elf64_vec -DHAVE_i386_elf32_vec -DHAVE_iamcu_elf32_vec -DHAVE_x86_64_elf32_vec -DHAVE_i386_aout_linux_vec -DHAVE_i386_pei_vec -DHAVE_x86_64_pei_vec -DHAVE_l1om_elf64_vec -DHAVE_k1om_elf64_vec -DHAVE_elf64_le_vec -DHAVE_elf64_be_vec -DHAVE_elf32_le_vec -DHAVE_elf32_be_vec -DHAVE_plugin_vec -DBINDIR=\"/usr/local/bin\" -W -Wall -Wstrict-prototypes -Wmissing-prototypes -Wshadow -Wstack-usage=262144 -Werror -I./../zlib -ldl -lutil -fsanitize=address -ggdb -Wno-error -MT dwarf2.lo -MD -MP -MF .deps/dwarf2.Tpo -c -DDEBUGDIR=\"/usr/local/lib/debug\" ./dwarf2.c -lm -s > dwarf2.c.i
    cilly --domakeCFG --gcc=/usr/bin/gcc-7 --out=tmp.c dwarf2.c.i
    mv tmp.c ./dwarf2.c.i.c 
    cp dwarf2.c.i.c dwarf2.c
  popd
popd
mkdir -p runtime/afl-in
mkdir -p runtime/afl-out/memory/pos
mkdir -p runtime/afl-out/memory/neg
/home/yuntong/pacfix/main.exe -debug -seed -epsilon 0.0 -nouniq -lvfile ./live_variables -cycle 60 -timeout 300 ./config
