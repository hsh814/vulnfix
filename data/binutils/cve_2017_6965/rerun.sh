#!/bin/bash
pushd pacfix/binutils
  cp elfcomm.c.i.c elfcomm.c
  cp readelf.c.i.c readelf.c
popd
rm -rf runtime runtime-moo
mkdir -p runtime/afl-in
mkdir runtime/afl-out

/home/yuntong/pacfix/main.exe -debug -nouniq -seed -epsilon 0.0 -lvfile ./live_variables -cycle 60 -timeout 300 ./config
