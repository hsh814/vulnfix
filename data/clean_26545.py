import os
import sys
from typing import List

original_files = {
    "aflrun_build",
    "aflrun_out",
    "aflrun_samples",
    "dafl_all",
    "dafl_samples",
    "dafl_source",
    "dafl_val",
    "pacfix",
    "raw_build",
    "raw_source",
    "runtime",
    "seed",
    "smake_source",
    "source",
    "sparrow-out",
    "temp",
    "aflrun.sh",
    "cludafl.sh",
    "run-cludafl-single.sh",
    "build.sh",
    "config",
    "dev.patch",
    "README.txt",
    "aflrun.sh",
    "aflrun.sh~",
    "aflrun_build",
    "aflrun_samples",
    "bins",
    "build.sh",
    "config",
    "dafl_source",
    "dev.patch",
    "dummy",
    "exploit",
    "pacfix",
    "pacfix.sh",
    "repair-out",
    "rerun.sh",
    "run-afl.sh",
    "run-aflrun-single.sh",
    "runtime",
    "seed",
    "setup.sh",
    "shred.aflrun",
    "shred.orig.c",
    "shred.pacfix.c",
    "shred.pacfix2.c",
    "smake_source",
    "source",
    "sparrow-out",
    "temp",
    "txt",
    "cludafl_out",
    "cludafl_samples",
    "pacfuzz_samples",
    "pacfix_val",
    "cludafl-runtime",
    "dafl2_all",
}

def remove_all_files(dir: str):
    files = os.listdir(dir)
    for file in files:
        full = os.path.join(dir, file)
        if not os.path.isdir(full):
            os.remove(full)

remove_all_files("/")
remove_all_files("/home/yuntong/vulnfix/data/coreutils")


files = os.listdir("/home/yuntong/vulnfix/data/coreutils/gnubug_26545")
remove_count = 0
total = len(files)
for file in files:
    full = os.path.join("/home/yuntong/vulnfix/data/coreutils/gnubug_26545", file)
    if os.path.isdir(full):
        continue
    if file in original_files:
        continue
    remove_count += 1
    print(f"{remove_count}/{total}) Removing {file.encode('utf-8', errors='replace').decode('utf-8')}")
    try:
        os.remove(os.fsencode(full))
    except FileNotFoundError:
        pass
    except Exception as e:
        print(e)