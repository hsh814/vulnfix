#!/bin/bash
pushd pacfix
  cp valid.c.i.c valid.c
popd
rm -rf runtime runtime-dafl
mkdir -p runtime/afl-in
mkdir runtime/afl-out

/home/yuntong/pacfix/main.exe -nouniq -seed -epsilon 0.0 -debug -lvfile ./live_variables -cycle 20 -timeout 30 ./config
#-mode d ./config > runtime/pacfix.log 2>&1

#mv runtime runtime-dafl

#pushd pacfix
#  cp valid.c.i.c valid.c
#popd
#rm -rf runtime
#mkdir -p runtime/afl-in
#mkdir runtime/afl-out

#/home/yuntong/pacfix/main.exe -debug -lvfile ./live_variables -cycle 600 -timeout 21600 -mode m ./config > runtime/pacfix.log 2>&1

#mv runtime runtime-moo
