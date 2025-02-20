#!/bin/bash
cd /home/yuntong/vulnfix/data/potrace/cve_2013_7437/pacfix
make clean && make CFLAGS="-static -fsanitize=address,implicit-conversion -g" CXXFLAGS="-static -fsanitize=address,implicit-conversion -g" LDFLAGS=" -fsanitize=address,implicit-conversion" -j10
cd /home/yuntong/vulnfix/data/potrace/cve_2013_7437
