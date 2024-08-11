#!/bin/bash
pushd pacfix/util
  cp listmp3.c.i.c listmp3.c
popd
rm -rf runtime
mkdir -p runtime/afl-in
mkdir runtime/afl-out

/home/yuntong/pacfix/main.exe -debug -epsilon 0.0 -cycle 60 -timeout 300 -seed -nouniq ./config
