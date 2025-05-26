#!/bin/bash
# pushd pacfix/tools
#   cp tiffcrop.c.i.c tiffcrop.c
# popd
# # rm -rfruntime
# # mkdir -p runtime/afl-in
# # mkdir runtime/afl-out

# /home/yuntong/pacfix/main.exe -synth_only -debug -lvfile ./live_variables -cycle 600 -timeout 21600 -mode m ./config > runtime/pacfix.log 2>&1

# # rm -rfruntime-moo
# mv runtime runtime-moo

pushd pacfix/tools
  cp tiffcrop.c.i.c tiffcrop.c
popd
# rm -rfruntime
# mkdir -p runtime/afl-in
# mkdir runtime/afl-out

# /home/yuntong/pacfix/main.exe -synth_only -debug -lvfile ./live_variables -cycle 600 -timeout 21600 -mode d ./config > runtime/pacfix.log 2>&1
/root/pacfix/main.exe -synth_only -epsilon $1 -atomic -debug -cycle 60 -timeout 300 ./config
# mv runtime runtime-dafl
