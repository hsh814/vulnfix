#!/usr/bin/env python3
from typing import Union, List, Dict, Tuple, Optional, Set, TextIO
import multiprocessing as mp
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

ROOT_DIR = "/home/yuntong/vulnfix"

def log_out(msg: str):
  print(msg, file=sys.stderr)

def kill_proc_tree(pid: int, including_parent: bool = True):
  parent = psutil.Process(pid)
  children = parent.children(recursive=True)
  for child in children:
    child.kill()
  psutil.wait_procs(children, timeout=5)
  if including_parent:
    parent.kill()
    parent.wait(5)

def execute(cmd: str, dir: str, env: Dict[str, str], opt: str, exp: str):
  print(f"Executing: {cmd}")
  start = time.time()
  timeout = 12 * 3600 + 600 # 12 hours + 10 minutes for analysis
  proc = subprocess.Popen(cmd, shell=True, cwd=dir, env=env, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
  try:
    stdout, stderr = proc.communicate(timeout=timeout)
  except subprocess.TimeoutExpired:
    log_out(f"Timeout: {cmd} - kill pid {proc.pid}")
    kill_proc_tree(proc.pid)
    stdout, stderr = proc.communicate()
  finally:
    end = time.time()
  log_out(f"{exp},{end - start}\n")
  # if log_dir == "exp":
  #   collect_result(meta)
  if proc.returncode != 0:
    print(f"Failed to execute: {cmd}")
    try:
      log_out(f"Failed to execute: {cmd}")
      log_out(stdout.decode('utf-8', errors='ignore'))
      log_out(stderr.decode('utf-8', errors='ignore'))
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

def run_cmd(opt: str, subject: str, exp_name: str):
  subject_dir = os.path.join(ROOT_DIR, "data", subject)
  seed_dir = os.path.join(subject_dir, "seed")
  files = sorted(os.listdir(seed_dir))
  core = len(files)
  pool = mp.Pool(core)
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
    args_list.append((cmd, subject_dir, env, opt, f"{exp_name}/{index}"))
  print(f"Total {opt}: {len(args_list)}")
  pool.map(execute_wrapper, args_list)
  pool.close()
  pool.join()
  print(f"{opt} done")

def main(argv: List[str]):
  parser = argparse.ArgumentParser(description="Run symvass experiments")
  parser.add_argument("cmd", type=str, help="Command to run", choices=["run"])
  parser.add_argument("exp_name", type=str, help="Extra arguments")
  parser.add_argument("subject", type=str, help="Subject to run")
  args = parser.parse_args(argv)
  run_cmd(args.cmd, args.subject, args.exp_name)

if __name__ == "__main__":
  main(sys.argv[1:])