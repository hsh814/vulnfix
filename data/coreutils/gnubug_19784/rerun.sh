#!/bin/bash
pushd pacfix/src
  cp make-prime-list.c.i.c make-prime-list.c
popd
rm -rf runtime runtime-moo
mkdir -p runtime/afl-in
mkdir runtime/afl-out

/home/yuntong/pacfix/main.exe -debug -cycle 600 -timeout 21600 ./config