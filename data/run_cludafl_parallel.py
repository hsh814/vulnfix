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
OUT_FILE = "/home/yuntong/vulnfix/fig/log.log"

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

experiments = [
  "cludafl-par-1", "cludafl-par-2", "cludafl-par-3", 
  "cludafl-par-4", "cludafl-par-5", "cludafl-par-6", 
  "cludafl-par-7", "cludafl-par-8", "cludafl-par-9", 
  "cludafl-par-10"
]
# experiments = ["cludafl-test-1", "cludafl-test-2"]

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

def run_cmd(opt: str, subject: str, exp_name: str, pool: mpp.Pool):
  subject_dir = os.path.join(ROOT_DIR, "data", subject)
  seed_dir = os.path.join(subject_dir, "seed")
  files = sorted(os.listdir(seed_dir))
  args_list = list()
  index = 0
  # Make new dir
  os.makedirs(os.path.join(subject_dir, "seed_parallel"), exist_ok=True)
  os.makedirs(os.path.join(subject_dir, "cludafl_out", exp_name), exist_ok=True)
  for file in files:
    new_seed_dir = os.path.join(subject_dir, "seed_parallel", f"{index}")
    if not os.path.exists(new_seed_dir):
      os.makedirs(new_seed_dir, exist_ok=True)
      shutil.copy(os.path.join(seed_dir, file), os.path.join(new_seed_dir, file))
    new_output_dir = os.path.join(subject_dir, "cludafl_out", exp_name, f"{index}")
    env = os.environ.copy()
    env["SEED_DIR_OVERRIDE"] = new_seed_dir
    env["AFL_OPTS_COMMON_OVERRIDE"] = "-t 2000+ -m none -d -s dafl -v"
    env["OUTPUT_DIR_OVERRIDE"] = new_output_dir
    env["TIMEOUT_OVERRIDE"] = "12h"
    cmd = f"./run-cludafl-single.sh {exp_name}-{index}"
    index += 1
    log_out(f"SEED_DIR_OVERRIDE=\"{new_seed_dir}\" AFL_OPTS_COMMON_OVERRIDE=\"{env['AFL_OPTS_COMMON_OVERRIDE']}\" OUTPUT_DIR_OVERRIDE=\"{new_output_dir}\" TIMEOUT_OVERRIDE=\"{env['TIMEOUT_OVERRIDE']}\" {cmd}")
    # args_list.append((cmd, subject_dir, env, opt, f"{exp_name}/{index}"))
    pool.apply_async(execute, args=(cmd, subject_dir, env, opt, f"{exp_name}/{index}"))

def run_subjects(pool: mpp.Pool, exp_name: str):
  for subject in subjects:
    run_cmd("run", subject, exp_name, pool)

def run_experiments(cmd: str, cores: int):
  with mpp.Pool(processes=cores) as pool:
    for exp in experiments:
      run_subjects(pool, exp)
    pool.close()
    pool.join()

def main(argv: List[str]):
  parser = argparse.ArgumentParser(description="Run symvass experiments")
  parser.add_argument("cmd", type=str, help="Command to run", choices=["run"])
  # parser.add_argument("exp_name", type=str, help="Extra arguments")
  # parser.add_argument("subject", type=str, help="Subject to run")
  parser.add_argument("--cores", "-j", type=int, help="Number of cores to use", default=150)
  args = parser.parse_args(argv)
  run_experiments(args.cmd, args.cores)

if __name__ == "__main__":
  main(sys.argv[1:])