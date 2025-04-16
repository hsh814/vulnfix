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
    "help.txt"
}

original_file_25003 = {"help.txt", 'pacfix', 'build.sh', 'sparrow-out', 'split.aflrun', 'run-cludafl-single.sh', 'smake_source', 'README.txt', 'runtime', 'pacfix_val', 'rerun.sh~', 'repair-out', 'temp', 'cludafl.sh', 'dafl_all', 'split.instrumented', 'dafl_val', 'aflrun.sh', 'seed', 'cludafl-runtime', 'split.pacfix.c', 'setup.sh', 'dev.patch', 'dafl_samples', 'pacfuzz_samples', 'run-afl.sh', 'dafl2_all', 'run-rafl.sh', 'run-aflrun-single.sh', 'dafl_source', 'split.orig.c', 'aflrun_build', 'live_variables', 'exploit', 'source', 'pacfix.sh', 'rerun.sh', 'config', 'cludafl_out', 'seed_parallel', 'dummy'}

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

files = os.listdir("/home/yuntong/vulnfix/data/coreutils/gnubug_25003")
remove_count = 0
total = len(files)
for file in files:
    full = os.path.join("/home/yuntong/vulnfix/data/coreutils/gnubug_25003", file)
    if os.path.isdir(full):
        continue
    if file in original_file_25003:
        continue
    remove_count += 1
    print(f"{remove_count}/{total}) Removing {file.encode('utf-8', errors='replace').decode('utf-8')}")
    try:
        os.remove(os.fsencode(full))
    except FileNotFoundError:
        pass
    except Exception as e:
        print(e)
