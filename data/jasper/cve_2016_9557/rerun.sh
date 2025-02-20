#!/bin/bash
pushd pacfix/src/libjasper/base
    cp jas_image.c.i.c jas_image.c
popd

# rm -rfruntime runtime-moo
# mkdir -p runtime/afl-in
# mkdir runtime/afl-out

/home/yuntong/pacfix/main.exe -synth_only -debug -cycle 60 -timeout 300 ./config
