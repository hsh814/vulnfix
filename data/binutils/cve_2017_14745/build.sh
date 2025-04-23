#!/bin/bash
cd $VULNFIX_HOME/vulnfix/data/binutils/cve_2017_14745/pacfix/
make clean && ASAN_OPTIONS=detect_leaks=0 make CFLAGS="-ldl -lutil -fsanitize=address -fsanitize=undefined -g -Wno-error" CXXFLAGS="-fsanitize=address -fsanitize=undefined -ldl -lutil -g -Wno-error" LDFLAGS=" -ldl -lutil -fsanitize=address -fsanitize=undefined" -j10
cd $VULNFIX_HOME/vulnfix/data/binutils/cve_2017_14745
