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
import queue
import logging
from logging.handlers import RotatingFileHandler

ROOT_DIR = "/home/yuntong/vulnfix"
OUT_FILE = "/home/yuntong/vulnfix/fig/log.log"
SEED_COLLECTION_DIR = "/home/yuntong/seed-collection"
LOG_FILE = "/home/yuntong/vulnfix/data/log/parallel_seeds.log"
os.makedirs(os.path.dirname(LOG_FILE), exist_ok=True)
logging.basicConfig(level=logging.DEBUG, format="%(asctime)s - %(message)s")
file_handler = RotatingFileHandler(LOG_FILE, maxBytes=100*1024*1024, backupCount=5)
file_handler.setFormatter(logging.Formatter('%(asctime)s - %(message)s'))
logging.getLogger().addHandler(file_handler)
logging.warning("Starting parallel seed experiment")

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
  logging.info(msg)

class FuzzProcess:
  subject: str
  cmd: str
  cwd: str
  env: Dict[str, str]
  exp: str
  out_dir: str
  start_time: float
  proc: subprocess.Popen
  index: int
  prev_output: int
  prev_monitor_secondary: float
  
  def __init__(self, subject: str, cmd: str, cwd: str, env: Dict[str, str], exp: str, out_dir: str, index: int):
    self.subject = subject
    self.cmd = cmd
    self.cwd = cwd
    self.env = env
    self.exp = exp
    self.out_dir = out_dir
    self.start_time = time.time()
    self.proc = subprocess.Popen(cmd, shell=True, cwd=cwd, env=env, start_new_session=True)
    self.index = index
    self.prev_output = 0
    self.prev_monitor_secondary = 0
    log_out(f"Started {index} from {self.cmd} with PID {self.proc.pid}")
  
  def timespan(self) -> float:
    return time.time() - self.start_time
  
  def check_output(self) -> int:
    if self.prev_output > 0:
      return self.prev_output
    if os.path.exists(os.path.join(self.out_dir, "memory", "input")):
      files = os.listdir(os.path.join(self.out_dir, "memory", "input"))
      self.prev_output = len(files)
      log_out(f"{self.subject} {self.index} Output files: {self.prev_output}")
      return self.prev_output
    return 0
  
  def check_output_secondary(self, timespan: float) -> bool:
    if self.prev_monitor_secondary > 0:
      if time.time() - self.prev_monitor_secondary < timespan:
        return True
    if os.path.exists(os.path.join(self.out_dir, "memory", "input")):
      files = os.listdir(os.path.join(self.out_dir, "memory", "input"))
      log_out(f"{self.subject} {self.index} Output files: {self.prev_output} -> {len(files)}")
      result = self.prev_output < len(files)
      self.prev_output = len(files)
      self.prev_monitor_secondary = time.time()
      return result
    return False
  
  def poll(self) -> Optional[int]:
    return self.proc.poll()
  
  def kill(self):
    try:
      if self.poll() is not None:
        return
      log_out(f"{self.subject} {self.index} Terminating process group for PID {self.proc.pid}")
      # Find all child processes using psutil
      try:
        parent = psutil.Process(self.proc.pid)
        children = parent.children(recursive=True)
        
        for child in reversed(children):
          try:
            child.terminate()
          except (psutil.NoSuchProcess, psutil.AccessDenied):
            pass
                
        # Wait for termination
        time.sleep(5)
        
        # Send SIGKILL to any remaining processes
        for child in reversed(children):
            try:
              if child.is_running():
                child.kill()
            except (psutil.NoSuchProcess, psutil.AccessDenied):
              pass
                
        # Finally kill the parent if still running
        if self.poll() is None:
          os.killpg(os.getpgid(self.proc.pid), signal.SIGKILL)
      
              
      except Exception as e:
        log_out(f"{self.subject} {self.index} Error in process cleanup: {e}")
            
    except Exception as e:
      log_out(f"{self.subject} {self.index} Kill error: {e}")

def start_fuzzer_for_seed(seed: str, index: int, subject_dir: str, exp_name: str, seed_dir: str, seed_parallel_dir: str):
  new_seed_dir = os.path.join(seed_parallel_dir, f"{index}")
  os.system(f"rm -rf {new_seed_dir}")
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

def get_seeds(subject: str) -> List[str]:
  subject_dir = os.path.join(ROOT_DIR, "data", subject)
  seed_dir = os.path.join(subject_dir, "seed")
  seed_queue = list()
  for file in sorted(os.listdir(seed_dir)):
    if file.startswith("exploit"): # exploit files first
      seed_queue.append(os.path.join(seed_dir, file))
  # TODO: Fetch files from seed-collection
  rank_file = os.path.join(SEED_COLLECTION_DIR, "rank", subject, "rank.csv")
  if os.path.exists(rank_file):
    with open(rank_file, "r") as f:
      for line in f.readlines():
        file = line.strip().split("\t")[0]
        seed_queue.append(file)
  else:
    log_out(f"Rank file not found!!!: {rank_file}")
  return seed_queue

def run_fuzzers_for_subject(subject: str, exp_name: str, cores: int, monitor_timeout: int = 3600, secondary_monitor_timeout: int = 3 * 3600, default_timeout: int = 12 * 3600, global_timeout: int = 3600 * 24 * 3):
  subject_dir = os.path.join(ROOT_DIR, "data", subject)
  os.makedirs(os.path.join(subject_dir, "cludafl_out", exp_name), exist_ok=True)
  seed_dir = os.path.join(subject_dir, "seed")
  seed_queue = get_seeds(subject)
  index = 0
  active_slots: Dict[int, FuzzProcess] = dict()
  for slot in range(min(cores, len(seed_queue))):
    seed = seed_queue.pop(0)
    cmd, cwd, env, opt, exp = start_fuzzer_for_seed(seed, index, subject_dir, exp_name, seed_dir, os.path.join(subject_dir, "seed_parallel"))
    time.sleep(1)
    fp = FuzzProcess(subject, cmd, cwd, env, exp, env["OUTPUT_DIR_OVERRIDE"], index)
    active_slots[slot] = fp
    index += 1
  check_interval = 10
  global_start = time.time()
  while active_slots:
    removed_slots = list()
    for slot, fp in active_slots.items():
      if time.time() - global_start > global_timeout:
        log_out(f"Global timeout: {fp.subject} {fp.index} - Terminating process group for PID {fp.proc.pid} time {fp.timespan()}")
        fp.kill()
        time.sleep(5)

      if fp.timespan() > monitor_timeout:
        output_num = fp.check_output()
        if output_num == 0:
          log_out(f"Monitor kill (no output): {fp.subject} {fp.index} - Terminating process group for PID {fp.proc.pid} time {fp.timespan()}")
          fp.kill()
          time.sleep(5)
      
      if fp.timespan() > secondary_monitor_timeout:
        if not fp.check_output_secondary(secondary_monitor_timeout):
          log_out(f"Secondary monitor kill (no output): {fp.subject} {fp.index}- Terminating process group for PID {fp.proc.pid} time {fp.timespan()}")
          fp.kill()
          time.sleep(5)
      
      if fp.timespan() > default_timeout:
        log_out(f"Timeout kill: {fp.subject} {fp.index} - Terminating process group for PID {fp.proc.pid} time {fp.timespan()}")
        fp.kill()
        time.sleep(5)

      if fp.poll() is not None:
        if len(seed_queue) > 0:
          seed = seed_queue.pop(0)
          log_out(f"Seed {fp.index} finished, starting new seed {seed} with {index}")
          cmd, cwd, env, opt, exp = start_fuzzer_for_seed(seed, index, subject_dir, exp_name, seed_dir, os.path.join(subject_dir, "seed_parallel"))
          fp = FuzzProcess(subject, cmd, cwd, env, exp, env["OUTPUT_DIR_OVERRIDE"], index)
          active_slots[slot] = fp
          index += 1
        else:
          removed_slots.append(slot)
    for slot in removed_slots:
      del active_slots[slot]
    time.sleep(check_interval)

def run_subject_with_handling(subject, exp_name, cores_per_subject):
  try:
    log_out(f"Starting subject {subject} with {cores_per_subject} cores")
    run_fuzzers_for_subject(subject, exp_name, cores_per_subject)
  except Exception as e:
    log_out(f"Error running subject {subject}: {str(e)}")
    raise

def run_subjects(exp_name: str, cores: int):
  cores_per_subject = cores // len(subjects)
  args = [(subject, exp_name, cores_per_subject) for subject in subjects]

  try:
    pool = mp.Pool(processes=len(subjects))
    pool.starmap(run_subject_with_handling, args)
    pool.close()
    pool.join()
  except KeyboardInterrupt:
    log_out("Keyboard interrupt received. Terminating all processes...")
    pool.terminate()
    pool.join()
    

def main(argv: List[str]):
  parser = argparse.ArgumentParser(description="Run symvass experiments")
  # parser.add_argument("exp", type=str, help="Command to run", choices=["run"])
  # parser.add_argument("exp_name", type=str, help="Extra arguments")
  # parser.add_argument("subject", type=str, help="Subject to run")
  parser.add_argument("--cores", "-j", type=int, help="Number of cores to use", default=150)
  args = parser.parse_args(argv)
  run_subjects("cludafl-seed-clustering", args.cores)

if __name__ == "__main__":
  main(sys.argv[1:])