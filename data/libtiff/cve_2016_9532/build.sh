#!/bin/bash
cd /home/yuntong/vulnfix/data/libtiff/cve_2016_9532/pacfix
make clean && make CFLAGS="-static -fsanitize=address -g" CXXFLAGS="-static -fsanitize=address -g" -j10
cd /home/yuntong/vulnfix/data/libtiff/cve_2016_9532

