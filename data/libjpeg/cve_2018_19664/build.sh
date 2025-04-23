#!/bin/bash
cd $VULNFIX_HOME/vulnfix/data/libjpeg/cve_2018_19664/pacfix
make clean && make -j10
cd $VULNFIX_HOME/vulnfix/data/libjpeg/cve_2018_19664

