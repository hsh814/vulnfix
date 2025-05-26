#!/bin/bash
pushd pacfix
  cp valid.c.i.c valid.c
popd
# rm -rfruntime runtime-dafl
# mkdir -p runtime/afl-in
# mkdir runtime/afl-out

/root/pacfix/main.exe -synth_only -epsilon $1 -atomic -debug -lvfile ./live_variables -cycle 20 -timeout 30 ./config
#-mode d ./config > runtime/pacfix.log 2>&1

#mv runtime runtime-dafl

#pushd pacfix
#  cp valid.c.i.c valid.c
#popd
## rm -rfruntime
## mkdir -p runtime/afl-in
## mkdir runtime/afl-out

#/home/yuntong/pacfix/main.exe -synth_only -debug -lvfile ./live_variables -cycle 600 -timeout 21600 -mode m ./config > runtime/pacfix.log 2>&1

#mv runtime runtime-moo
