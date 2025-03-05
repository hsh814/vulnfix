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

# experiments = [
#   "cludafl-par-seeds"
# ]
# experiments = ["cludafl-test-1", "cludafl-test-2"]

def log_out(msg: str):
  print(msg, file=sys.stderr)

class FuzzProcess:
  cmd: str
  cwd: str
  env: Dict[str, str]
  exp: str
  out_dir: str
  start_time: float
  proc: subprocess.Popen
  index: int
  
  def __init__(self, cmd: str, cwd: str, env: Dict[str, str], exp: str, out_dir: str, index: int):
    self.cmd = cmd
    self.cwd = cwd
    self.env = env
    self.exp = exp
    self.out_dir = out_dir
    self.start_time = time.time()
    self.proc = subprocess.Popen(cmd, shell=True, cwd=cwd, env=env, start_new_session=True)
    self.index = index
    log_out(f"Started {index} from {self.cmd} with PID {self.proc.pid}")
  
  def timespan(self) -> float:
    return time.time() - self.start_time
  
  def check_output(self) -> int:
    # For now, just choose random number
    if os.path.exists(os.path.join(self.out_dir, "memory", "input")):
      files = os.listdir(os.path.join(self.out_dir, "memory", "input"))
      log_out(f"{self.index} Output files: {len(files)}")
      return 0 #len(files)
    return 0
  
  def poll(self) -> Optional[int]:
    return self.proc.poll()
  
  def kill(self):
    try:
      os.killpg(os.getpgid(self.proc.pid), signal.SIGTERM)
      time.sleep(5)
      if self.poll() is None:
        os.killpg(os.getpgid(self.proc.pid), signal.SIGKILL)
    except Exception as e:
      log_out(e)

def start_fuzzer_for_seed(seed: str, index: int, subject_dir: str, exp_name: str, seed_dir: str, seed_parallel_dir: str):
  new_seed_dir = os.path.join(seed_parallel_dir, f"{index}")
  if not os.path.exists(new_seed_dir):
    os.makedirs(new_seed_dir, exist_ok=True)
    log_out(f"Created new seed directory: {new_seed_dir}")
    shutil.copy(seed, os.path.join(new_seed_dir, os.path.basename(seed)))
  new_output_dir = os.path.join(subject_dir, "cludafl_out", exp_name, f"{index}")
  env = os.environ.copy()
  env["SEED_DIR_OVERRIDE"] = new_seed_dir
  env["AFL_OPTS_COMMON_OVERRIDE"] = "-t 2000+ -m none -d -s dafl"
  env["OUTPUT_DIR_OVERRIDE"] = new_output_dir
  env["TIMEOUT_OVERRIDE"] = "12h"
  cmd = f"./run-cludafl-single.sh {exp_name}-{index}"
  log_out(f"SEED_DIR_OVERRIDE=\"{new_seed_dir}\" AFL_OPTS_COMMON_OVERRIDE=\"{env['AFL_OPTS_COMMON_OVERRIDE']}\" OUTPUT_DIR_OVERRIDE=\"{new_output_dir}\" TIMEOUT_OVERRIDE=\"{env['TIMEOUT_OVERRIDE']}\" {cmd}")
  return cmd, subject_dir, env, exp_name, f"{index}"

def run_fuzzers_for_subject(subject: str, exp_name: str, cores: int, monitor_timeout: int = 3600, global_timeout: int = 3600 * 24 * 3):
  subject_dir = os.path.join(ROOT_DIR, "data", subject)
  os.makedirs(os.path.join(subject_dir, "cludafl_out", exp_name), exist_ok=True)
  seed_dir = os.path.join(subject_dir, "seed")
  seed_queue = list()
  for file in sorted(os.listdir(seed_dir)):
    seed_queue.append(os.path.join(seed_dir, file))
  index = 0
  active_slots: Dict[int, FuzzProcess] = dict()
  for slot in range(min(cores, len(seed_queue))):
    seed = seed_queue.pop(0)
    cmd, cwd, env, opt, exp = start_fuzzer_for_seed(seed, index, subject_dir, exp_name, seed_dir, os.path.join(subject_dir, "seed_parallel"))
    time.sleep(1)
    fp = FuzzProcess(cmd, cwd, env, exp, env["OUTPUT_DIR_OVERRIDE"], index)
    active_slots[slot] = fp
    index += 1
  check_interval = 10
  global_start = time.time()
  while active_slots:
    for slot, fp in active_slots.items():
      if time.time() - global_start > global_timeout:
        log_out(f"Global timeout: {fp.cmd} - Terminating process group for PID {fp.proc.pid}")
        fp.kill()
        time.sleep(5)

      if fp.timespan() > monitor_timeout:
        output_num = fp.check_output()
        if output_num == 0:
          log_out(f"Monitor kill (no output): {fp.cmd} - Terminating process group for PID {fp.proc.pid}")
          fp.kill()
          time.sleep(5)

      if fp.poll() is not None:
        if len(seed_queue) > 0:
          seed = seed_queue.pop(0)
          log_out(f"Seed {fp.index} finished, starting new seed {seed} with {index}")
          cmd, cwd, env, opt, exp = start_fuzzer_for_seed(seed, index, subject_dir, exp_name, seed_dir, os.path.join(subject_dir, "seed_parallel"))
          fp = FuzzProcess(cmd, cwd, env, exp, env["OUTPUT_DIR_OVERRIDE"], index)
          active_slots[slot] = fp
          index += 1
        else:
          del active_slots[slot]
    
    time.sleep(check_interval)
  

def run_subjects(exp_name: str, cores: int):
  cores_per_subject = cores // len(subjects)
  for subject in subjects:
    run_fuzzers_for_subject(subject, exp_name, cores_per_subject, monitor_timeout=3600, global_timeout=3 * 24 * 3600)

def main(argv: List[str]):
  parser = argparse.ArgumentParser(description="Run symvass experiments")
  # parser.add_argument("exp", type=str, help="Command to run", choices=["run"])
  # parser.add_argument("exp_name", type=str, help="Extra arguments")
  # parser.add_argument("subject", type=str, help="Subject to run")
  parser.add_argument("--cores", "-j", type=int, help="Number of cores to use", default=150)
  args = parser.parse_args(argv)
  run_subjects("cludafl-seed-test", args.cores)

if __name__ == "__main__":
  main(sys.argv[1:])