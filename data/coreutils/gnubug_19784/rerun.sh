#!/bin/bash
pushd pacfix/src
  cp make-prime-list.c.i.c make-prime-list.c
popd
rm -rf runtime runtime-moo
mkdir -p runtime/afl-in
mkdir runtime/afl-out

/home/yuntong/pacfix/main.exe -debug -epsilon 0.0 -cycle 60 -lvfile ./live_variables -nouniq  -timeout 300 ./config
