#!/bin/bash
cd $VULNFIX_HOME/vulnfix/data/libtiff/cve_2017_7599/pacfix
make clean && make CFLAGS="-fsanitize=float-cast-overflow,address -static -ggdb" CXXFLAGS="-fsanitize=float-cast-overflow,address -static -ggdb" LDFLAGS="-fsanitize=float-cast-overflow,address" -j10
cd $VULNFIX_HOME/vulnfix/data/libtiff/cve_2017_7599
