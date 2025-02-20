import re
import os
import sys
import shutil
import random
import string
import threading
import subprocess
from tqdm import tqdm

base_path = "/home/yuntong/vulnfix/data/"
config_path = ""
valuation_exe = ""
binary_name = ""
is_stdin = False
command  = ""
subject  = ""
orig_env = os.environ.copy()
valfile = ""
target = ""
max_threads = 20
subject_path = sys.argv[1]
out_postfix = sys.argv[2]

if __name__ == "__main__":
    out_dir = os.path.join(base_path, subject_path, "cludafl_out", f"out-{out_postfix}", "memory")
    pos = os.listdir(os.path.join(out_dir, "pos"))
    neg = os.listdir(os.path.join(out_dir, "neg"))
    print(f"{subject_path}\t{out_postfix}\t={len(pos)}+{len(neg)}")
