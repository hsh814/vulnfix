#!/bin/bash
pushd pacfix/tools
  cp tiff2pdf.c.i.c tiff2pdf.c
popd
# rm -rfruntime runtime-moo
# mkdir -p runtime/afl-in
# mkdir runtime/afl-out

$VULNFIX_HOME/pacfix/main.exe -synth_only -debug -lvfile ./live_variables -cycle 60 -timeout 300 ./config 

#mv runtime runtime-moo

#pushd pacfix/tools
#  cp tiff2pdf.c.i.c tiff2pdf.c
#popd
## rm -rfruntime-dafl
## rm -rfruntime
## mkdir -p runtime/afl-in
## mkdir runtime/afl-out

#$VULNFIX_HOME/pacfix/main.exe -synth_only -debug -lvfile ./live_variables -cycle 600 -timeout 21600 -mode d ./config > runtime/pacfix.log 2>&1
#mv runtime runtime-dafl
