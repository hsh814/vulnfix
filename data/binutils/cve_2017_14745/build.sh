#!/bin/bash
cd /home/yuntong/vulnfix/data/binutils/cve_2017_14745/pacfix/
ASAN_OPTIONS=detect_leaks=0 make CFLAGS="-ldl -lutil -fsanitize=address -fsanitize=undefined -g" CXXFLAGS="-fsanitize=address -fsanitize=undefined -ldl -lutil -g" LDFLAGS=" -ldl -lutil -fsanitize=address -fsanitize=undefined" -j10
cd /home/yuntong/vulnfix/data/binutils/cve_2017_14745