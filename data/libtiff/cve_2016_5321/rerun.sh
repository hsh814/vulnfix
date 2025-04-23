#!/bin/bash
# pushd pacfix/tools
#   cp tiffcrop.c.i.c tiffcrop.c
# popd
# # rm -rfruntime
# # mkdir -p runtime/afl-in
# # mkdir runtime/afl-out

# $VULNFIX_HOME/pacfix/main.exe -synth_only -debug -lvfile ./live_variables -cycle 600 -timeout 21600 -mode m ./config > runtime/pacfix.log 2>&1

# # rm -rfruntime-moo
# mv runtime runtime-moo

pushd pacfix/tools
  cp tiffcrop.c.i.c tiffcrop.c
popd
# rm -rfruntime
# mkdir -p runtime/afl-in
# mkdir runtime/afl-out

# $VULNFIX_HOME/pacfix/main.exe -synth_only -debug -lvfile ./live_variables -cycle 600 -timeout 21600 -mode d ./config > runtime/pacfix.log 2>&1
$VULNFIX_HOME/pacfix/main.exe -synth_only -nouniq -seed -epsilon 0.0 -debug -cycle 60 -timeout 300 ./config
# mv runtime runtime-dafl
