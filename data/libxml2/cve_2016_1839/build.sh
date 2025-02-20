#!/bin/bash
cd /home/yuntong/vulnfix/data/libxml2/cve_2016_1839/pacfix
make clean && make CFLAGS="-static -fsanitize=address -fsanitize=undefined -g" CXXFLAGS="-static -fsanitize=address -fsanitize=undefined -g" -j10
cd /home/yuntong/vulnfix/data/libxml2/cve_2016_1839
