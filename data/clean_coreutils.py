import os
import sys
from time import sleep
from typing import List

original_files = {
    "aflrun_build",
    "aflrun_out",
    "aflrun_samples",
    "aflrun.sh",
    "aflrun.sh~",

    "dafl_all",
    "dafl_samples",
    "dafl_source",
    "dafl_val",

    "pacfix",
    "pacfix.sh",

    "raw_build",
    "raw_source",
    "runtime",
    "seed",
    "smake_source",
    "source",
    "sparrow-out",
    "temp",
    "cludafl.sh",
    "run-cludafl-single.sh",
    "build.sh",
    "config",
    "dev.patch",
    "README.txt",
    "bins",
    "dummy",
    "exploit",
    "repair-out",
    "rerun.sh",
    "run-afl.sh",
    "run-aflrun-single.sh",
    "setup.sh",
    "shred.aflrun",
    "shred.orig.c",
    "shred.pacfix.c",
    "shred.pacfix2.c",
    "txt",
    "cludafl_out",
    "cludafl_samples",
    "pacfuzz_samples",
    "pacfix_val",
    "cludafl-runtime",
    "dafl2_all",
    "help.txt",

    "dafl-out",
    'dafl-seed',
    'live_variables',
    'run-rafl.sh',
    'split.aflrun',
    'split.orig.c',
    'split.pacfix.c',
}

home_dir=os.getenv('VULNFIX_HOME')
bug_id=sys.argv[1:]

def remove_all_files(dir: str):
    files = os.listdir(dir)
    for file in files:
        full = os.path.join(dir, file)
        if not os.path.isdir(full) and file!='dependencies':
            os.remove(full)


remove_all_files("/")
remove_all_files(f"{home_dir}/vulnfix/data/coreutils")
for id in bug_id:
    files = os.listdir(f"{home_dir}/vulnfix/data/coreutils/gnubug_{id}")
    remove_count = 0
    total = len(files)
    for file in files:
        full = os.path.join(f"{home_dir}/vulnfix/data/coreutils/gnubug_{id}", file)
        if os.path.isdir(full):
            continue
        if file in original_files:
            continue
        if file.startswith('cludafl') and file.endswith('.log'):
            continue
        remove_count += 1
        print(f"{remove_count}/{total}) Removing {file.encode('utf-8', errors='replace').decode('utf-8')}")
        try:
            os.remove(os.fsencode(full))
        except FileNotFoundError:
            pass
        except Exception as e:
            print(e)
