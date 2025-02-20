#!/bin/bash
# pushd pacfix
#   cp parser.c.i.c parser.c
# popd
# # rm -rfruntime
# # mkdir -p runtime/afl-in
# # mkdir runtime/afl-out

# /home/yuntong/pacfix/main.exe -synth_only -debug -lvfile ./live_variables -cycle 600 -timeout 21600 -mode m ./config > runtime/pacfix.log 2>&1

# mv runtime runtime-moo

pushd pacfix
  cp parser.c.i.c parser.c
popd
# rm -rfruntime
# rm -rfruntime-dafl
# mkdir -p runtime/afl-in
# mkdir runtime/afl-out

/home/yuntong/pacfix/main.exe -synth_only -debug -nouniq -seed -epsilon 0.0 -lvfile ./live_variables -cycle 60 -timeout 120 ./config
#-mode d ./config > runtime/pacfix.log 2>&1



