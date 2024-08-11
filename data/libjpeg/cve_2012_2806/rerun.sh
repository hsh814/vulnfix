#!/bin/bash
pushd pacfix
  cp jdmarker.c.i.c jdmarker.c
popd
rm -rf runtime
mkdir -p runtime/afl-in
mkdir runtime/afl-out

/home/yuntong/pacfix/main.exe -debug -seed -nouniq -epsilon 0.0 -lvfile ./live_variables -cycle 60 -timeout 300 ./config
