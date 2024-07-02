#!/bin/bash
cd /home/yuntong/vulnfix/data/binutils/cve_2017_6965/pacfix/
make clean && ASAN_OPTIONS=detect_leaks=0 make CFLAGS="-ldl -lutil -fsanitize=address -fsanitize=undefined -g -w -Wno-error" CXXFLAGS="-fsanitize=address -fsanitize=undefined -ldl -lutil -g -w -Wno-error" LDFLAGS=" -ldl -lutil -fsanitize=address -fsanitize=undefined" -j10
cd /home/yuntong/vulnfix/data/binutils/cve_2017_6965/