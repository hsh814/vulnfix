#!/bin/bash
cd $VULNFIX_HOME/vulnfix/data/libtiff/cve_2016_9532/pacfix
make clean && make CFLAGS="-static -fsanitize=address -g" CXXFLAGS="-static -fsanitize=address -g" -j10
cd $VULNFIX_HOME/vulnfix/data/libtiff/cve_2016_9532

