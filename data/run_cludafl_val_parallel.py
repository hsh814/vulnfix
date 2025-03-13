#!/usr/bin/env python3
from typing import Union, List, Dict, Tuple, Optional, Set, TextIO
import multiprocessing as mp
import multiprocessing.pool as mpp
import subprocess

import os
import sys
import json
import time
import datetime
import sbsv
import argparse
import shutil
import psutil
import signal

ROOT_DIR = "/home/yuntong/vulnfix"

subjects = [
  # "binutils/cve_2017_6965",
  # "binutils/cve_2017_14745",
  # "binutils/cve_2017_15025",
  # "coreutils/gnubug_19784",
  # "coreutils/gnubug_25003",
  # "coreutils/gnubug_25023",
  # "coreutils/gnubug_26545",
  # "jasper/cve_2016_8691",
  # "jasper/cve_2016_9557",
  # "libjpeg/cve_2012_2806",
  # "libjpeg/cve_2017_15232",
  # "libming/cve_2016_9264",
  # "libtiff/bugzilla_2633",
  # "libtiff/cve_2016_5321",
  # "libtiff/cve_2016_9532",
  # "libtiff/cve_2016_10094",
  # "libtiff/cve_2017_7595",
  # "libtiff/cve_2017_7599",
  # "libtiff/cve_2017_7600",
  # "libtiff/cve_2017_7601",
  # "libxml2/cve_2012_5134",
  # "libxml2/cve_2016_1838",
  # "libxml2/cve_2016_1839",
  # "libxml2/cve_2017_5969",
  # "zziplib/cve_2017_5974",
  # "zziplib/cve_2017_5975",
  # "zziplib/cve_2017_5976"
]

# experiments = [
#   "cludafl-par-1", "cludafl-par-2", "cludafl-par-3", 
#   "cludafl-par-4", "cludafl-par-5", 
#   "cludafl-par-6", 
#   "cludafl-par-7", "cludafl-par-8", "cludafl-par-9", 
#   "cludafl-par-10"
# ]
experiments = ["cludafl-seed-clustering"]

def log_out(msg: str):
  print(msg, file=sys.stderr)

def execute(cmd: str, cwd: str, env: Dict[str, str], opt: str, exp: str) -> bool:
  """
  Executes a command in a specified directory and environment.
  It isolates the command in its own process group and attempts a graceful shutdown on timeout.
  """
  print(f"Executing: {cmd}")
  start_time = time.time()
  timeout = 3600 * 12 + 600 # Timeout in seconds; 12h + 10m

  # Start the subprocess in a new process group.
  proc = subprocess.Popen(cmd, shell=True, cwd=cwd, env=env, preexec_fn=os.setpgrp)

  try:
    proc.communicate(timeout=timeout)
  except subprocess.TimeoutExpired:
    log_out(f"Timeout: {cmd} - Terminating process group for PID {proc.pid}")
    os.killpg(proc.pid, signal.SIGTERM)  # Graceful termination
    time.sleep(5)
    os.killpg(proc.pid, signal.SIGKILL)  # Force kill if needed
  finally:
    end_time = time.time()

  log_out(f"{exp},{end_time - start_time}\n")

  if proc.returncode != 0:
    print(f"Failed to execute: {cmd}")
    try:
      log_out(f"Failed to execute: {cmd}")
    except Exception as e:
      print(e)
    return False
  return True

def execute_wrapper(args):
  return execute(*args)

def str_to_list(s: str) -> List[int]:
  ss = s.strip('[]')
  res = list()
  for x in ss.split(", "):
    if x.strip() == "":
      continue
    res.append(int(x))
  return res

def find_num(dir: str, prefix: str) -> int:
  result = 0
  dirs = os.listdir(dir)
  while True:
    if f"{prefix}-{result}" in dirs:
      result += 1
    else:
      break
  return result

def run_cmd(opt: str, subject: str):
  subject_dir = os.path.join(ROOT_DIR, "data", subject)
  for exp_name in experiments:
    cludafl_out_seeds_dir = os.path.join(ROOT_DIR, "data", "cludafl_out_seeds", exp_name, subject)
    os.system(f"rm -rf {cludafl_out_seeds_dir}")
    os.makedirs(cludafl_out_seeds_dir, exist_ok=True)
    exp_dir = os.path.join(subject_dir, "cludafl_out", exp_name)
    seed_dir = os.path.join(subject_dir, "seed")
    dirs = sorted(os.listdir(exp_dir))
    index = 0
    # Make new dir
    new_dir = os.path.join(exp_dir, "memory", "input")
    os.makedirs(new_dir, exist_ok=True)
    for dir in dirs:
      if dir == "memory":
        continue
      exp_res_dir = os.path.join(exp_dir, dir, "cludafl", "seeds")
      if not os.path.exists(exp_res_dir):
        continue
      files = sorted(os.listdir(exp_res_dir))
      for file in files:
        shutil.copy(os.path.join(exp_res_dir, file), os.path.join(new_dir, f"{dir}-{file}"))
        shutil.copy(os.path.join(exp_res_dir, file), os.path.join(cludafl_out_seeds_dir, f"{dir}-{file}"))
    cmd = f"python3 {ROOT_DIR}/data/get_val_cludafl.py {subject} {exp_name}"
    execute(cmd, subject_dir, os.environ.copy(), opt, f"{exp_name}")
  
def run_subjects(cores: int):
  pool = mp.Pool(processes=cores)
  for subject in subjects:
    pool.apply_async(run_cmd, args=("run", subject))
  pool.close()
  pool.join()

def run_cmd_for_pacfix(subject: str):
  subject_dir = os.path.join(ROOT_DIR, "data", subject)
  for exp in experiments:
    print(f"Running pacfix for {subject} with {exp}")
    os.system(f"rm -rf {subject_dir}/runtime/afl-out/memory")
    os.makedirs(f"{subject_dir}/runtime/afl-out/memory/neg", exist_ok=True)
    os.makedirs(f"{subject_dir}/runtime/afl-out/memory/pos", exist_ok=True)
    os.system(f"rsync -az {subject_dir}/cludafl_samples/{exp}/ {subject_dir}/runtime/afl-out/memory/")
    execute("./rerun.sh", subject_dir, os.environ.copy(), "run", f"{exp}")
    os.system(f"mv {subject_dir}/runtime/pacfix.log {subject_dir}/cludafl_samples/pacfix-{exp}.log")


def run_pacfix(cores: int):
  pool = mp.Pool(processes=cores)
  for subject in subjects:
    pool.apply_async(run_cmd_for_pacfix, args=(subject,))
  pool.close()
  pool.join()
  

def main(argv: List[str]):
  parser = argparse.ArgumentParser(description="Run symvass experiments")
  # parser.add_argument("cmd", type=str, help="Command to run", choices=["run"])
  # parser.add_argument("exp_name", type=str, help="Extra arguments")
  # parser.add_argument("subject", type=str, help="Subject to run")
  parser.add_argument("--cores", "-j", type=int, help="Number of cores to use", default=150)
  args = parser.parse_args(argv)
  run_subjects(args.cores)
  run_pacfix(args.cores)

if __name__ == "__main__":
  main(sys.argv[1:])