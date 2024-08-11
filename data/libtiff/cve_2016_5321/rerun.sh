#!/bin/bash
# pushd pacfix/tools
#   cp tiffcrop.c.i.c tiffcrop.c
# popd
# rm -rf runtime
# mkdir -p runtime/afl-in
# mkdir runtime/afl-out

# /home/yuntong/pacfix/main.exe -debug -lvfile ./live_variables -cycle 600 -timeout 21600 -mode m ./config > runtime/pacfix.log 2>&1

# rm -rf runtime-moo
# mv runtime runtime-moo

pushd pacfix/tools
  cp tiffcrop.c.i.c tiffcrop.c
popd
rm -rf runtime
mkdir -p runtime/afl-in
mkdir runtime/afl-out

# /home/yuntong/pacfix/main.exe -debug -lvfile ./live_variables -cycle 600 -timeout 21600 -mode d ./config > runtime/pacfix.log 2>&1
/home/yuntong/pacfix/main.exe -nouniq -seed -epsilon 0.0 -debug -lvfile ./live_variables -cycle 60 -timeout 300 ./config
# mv runtime runtime-dafl
