#!/bin/bash
pushd pacfix/src/libjasper/jpc
    cp jpc_dec.c.i.c jpc_dec.c
popd

# rm -rfruntime runtime-moo
# mkdir -p runtime/afl-in
# mkdir runtime/afl-out

/home/yuntong/pacfix/main.exe -synth_only -debug -nouniq -seed -epsilon 0.0 -lvfile ./live_variables -cycle 60 -timeout 300 ./config
