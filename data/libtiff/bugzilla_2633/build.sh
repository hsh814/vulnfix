#!/bin/bash
cd /home/yuntong/vulnfix/data/libtiff/bugzilla_2633/pacfix
make clean && make CFLAGS="-static -fsanitize=address -fsanitize=undefined -g" CXXFLAGS="-static -fsanitize=address -fsanitize=undefined -g" -j10
cd /home/yuntong/vulnfix/data/libtiff/bugzilla_2633
