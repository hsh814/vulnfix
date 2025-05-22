#!/usr/bin/env python3
from typing import List, Dict
import multiprocessing.pool as mpp
import multiprocessing as mp
import subprocess

import os
import sys
import time
import argparse
import shutil
import signal
import toml


SUBJECTS = (
  "binutils/cve_2017_6965",
  "binutils/cve_2017_14745",
  "binutils/cve_2017_15025",

  "coreutils/gnubug_19784",
  "coreutils/gnubug_25003",
  "coreutils/gnubug_25023",
  "coreutils/gnubug_26545",

  "jasper/cve_2016_8691",
  "jasper/cve_2016_9557",

  "libjpeg/cve_2012_2806",
  "libjpeg/cve_2017_15232",

  "libming/cve_2016_9264",

  "libtiff/bugzilla_2633",
  "libtiff/cve_2016_5321",
  "libtiff/cve_2016_9532",
  "libtiff/cve_2016_10094",
  "libtiff/cve_2017_7595",
  "libtiff/cve_2017_7599",
  "libtiff/cve_2017_7600",
  "libtiff/cve_2017_7601",

  "libxml2/cve_2012_5134",
  "libxml2/cve_2016_1838",
  "libxml2/cve_2016_1839",
  "libxml2/cve_2017_5969",

  "zziplib/cve_2017_5974",
  "zziplib/cve_2017_5975",
  "zziplib/cve_2017_5976"
)

ROOT_DIR=os.getenv('VULNFIX_HOME') + '/vulnfix'
SEED_COLLECTION_DIR = os.getenv('VULNFIX_HOME') + "/seed-collection"


def log_out(msg: str):
  print(msg, file=sys.stderr)

def get_seeds(subject: str) -> List[str]:
  with open(os.path.join(SEED_COLLECTION_DIR, "vulnfix.toml")) as f:
    config = toml.load(f)
  subj, vers = subject.split("/")
  if subj=='coreutils':
    if vers in ('gnubug_19784', 'gnubug_26545'):
      vers=vers.replace('gnubug','bugzilla')
  file_type = config[subj][vers]
  subject_dir = os.path.join(ROOT_DIR, "data", subject)
  os.makedirs(os.path.join(subject_dir, "random-seeds-all"), exist_ok=True)
  for file in os.listdir(os.path.join(SEED_COLLECTION_DIR, 'new-seeds',file_type)):
    shutil.copy(os.path.join(SEED_COLLECTION_DIR, 'new-seeds',file_type,file), os.path.join(subject_dir, "random-seeds-all", file))
  shutil.copy(os.path.join(subject_dir, 'exploit'), os.path.join(subject_dir, "random-seeds-all", 'exploit'))

def execute(cmd: str, cwd: str, env: Dict[str, str], exp: str) -> bool:
  """
  Executes a command in a specified directory and environment.
  It isolates the command in its own process group and attempts a graceful shutdown on timeout.
  """
  global args
  print(f"Executing: {cmd}")
  start_time = time.time()
  timeout = 3600 * args.timeout + 600 # Timeout in seconds; 12h + 10m

  # Start the subprocess in a new process group.
  with open(f'{cwd}/cludafl-{exp}.log','w') as f:
    proc = subprocess.Popen(cmd, shell=True, cwd=cwd, env=env, preexec_fn=os.setpgrp,stdout=f,stderr=f)

  try:
    proc.communicate(timeout=timeout)
  except subprocess.TimeoutExpired:
    log_out(f"Timeout: {cmd} - Terminating process group for PID {proc.pid}")
    proc.terminate()  # Graceful termination
    time.sleep(60)
    proc.kill()  # Forceful termination if still running
    end_time = time.time()
    log_out(f"{cwd}: {exp},{end_time - start_time}\n")
    return True
  
  end_time = time.time()
  log_out(f"{cwd}: {exp},{end_time - start_time}\n")

  if proc.returncode != 0:
    print(f"Failed to execute: {cwd}, return code: {proc.returncode}")
    try:
      log_out(f"Failed to execute: {cwd}, return code: {proc.returncode}")
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

def run_cmd(subject: str, exp_iter: int, pool: mpp.Pool):
  subject_dir = os.path.join(ROOT_DIR, "data", subject)
  get_seeds(subject)
  seed_dir = os.path.join(subject_dir, "random-seeds-all")

  # Make new dir
  os.makedirs(os.path.join(subject_dir, "dafl-random-all-out", str(exp_iter)), exist_ok=True)
  new_output_dir = os.path.join(subject_dir, "dafl-random-all-out", str(exp_iter))

  env = os.environ.copy()
  env["SEED_DIR_OVERRIDE"] = seed_dir
  env["AFL_OPTS_COMMON_OVERRIDE"] = "-t 2000+ -m none -d -s dafl -v"
  env["OUTPUT_DIR_OVERRIDE"] = new_output_dir
  env["TIMEOUT_OVERRIDE"] = f"{args.timeout}h"
  cmd = f"./run-cludafl-single.sh dafl-{exp_iter}"
  log_out(f"SEED_DIR_OVERRIDE=\"{seed_dir}\" AFL_OPTS_COMMON_OVERRIDE=\"{env['AFL_OPTS_COMMON_OVERRIDE']}\" OUTPUT_DIR_OVERRIDE=\"{new_output_dir}\" TIMEOUT_OVERRIDE=\"{env['TIMEOUT_OVERRIDE']}\" {cmd}")
  pool.apply_async(execute, args=(cmd, subject_dir, env, f"{exp_iter}"))

def run_subjects(pool: mpp.Pool, exp_iter: int):
  for subject in SUBJECTS:
    run_cmd(subject, exp_iter, pool)

def run_experiments(cores: int):
  with mpp.Pool(processes=cores) as pool:
    for exp in range(0, args.iter):
      run_subjects(pool, exp)
    try:
      pool.close()
      pool.join()
    except KeyboardInterrupt:
      os.system('killall timeout')

if __name__ == "__main__":
  parser = argparse.ArgumentParser(description="Run symvass experiments")
  parser.add_argument("--iter", type=int, help="Iteration to run experiment", default=1)
  parser.add_argument("--cores", "-j", type=int, help="Number of cores to use", default=30)
  parser.add_argument('--timeout', type=int, help='Timeout in hours', default=12)
  args = parser.parse_args(sys.argv[1:])
  run_experiments(args.cores)