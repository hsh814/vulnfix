#!/bin/bash

rm -rf pacfix
eval $(opam env --switch=default)
commit_id=3cfd62d
git clone https://github.com/vadz/libtiff.git pacfix
pushd pacfix
  git checkout $commit_id
popd
cp tif_dirwrite.pacfix2.c ./pacfix/libtiff/tif_dirwrite.c


pushd pacfix
  ./configure
  make CFLAGS="-fsanitize=float-cast-overflow,address -fno-sanitize-recover=all -static -ggdb" CXXFLAGS="-fsanitize=float-cast-overflow,address -fno-sanitize-recover=all -static -ggdb" LDFLAGS="-fsanitize=float-cast-overflow,address -fno-sanitize-recover=all" -j10 > make.log
  # cat make.log | grep tif_dirwrite.c
  pushd libtiff
    if [ -f backup/tif_dirwrite.c ]; then
      cp backup/tif_dirwrite.c ./tif_dirwrite.c
    fi
    mkdir -p backup
    cp tif_dirwrite.c backup
    gcc -E -DHAVE_CONFIG_H -I. -fsanitize=float-cast-overflow,address -fno-sanitize-recover=all -ggdb -MT tif_dirwrite.lo -MD -MP -MF .deps/tif_dirwrite.Tpo -c tif_dirwrite.c > tif_dirwrite.c.i
    cilly --domakeCFG --gcc=/usr/bin/gcc-7 --out=tmp.c tif_dirwrite.c.i
    mv tmp.c tif_dirwrite.c.i.c
    cp tif_dirwrite.c.i.c tif_dirwrite.c
  popd
popd
/home/yuntong/pacfix/main.exe -synth_only -debug -cycle 60 -timeout 300 ./config