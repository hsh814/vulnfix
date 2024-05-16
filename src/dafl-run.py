#! /usr/bin/env python3.8
import os
import subprocess
import time
import sys
from typing import Union, List, Dict, Tuple, Optional, Set
import multiprocessing as mp
import datetime
import json
import argparse

date = datetime.datetime.now().strftime("%Y-%m-%d")
root_dir = "/home/yuntong/vulnfix"
exp_id = date


def execute(cmd: str, dir: str, out_dir: str, env: dict = None):
    print(f"Change directory to {dir}")
    print(f"Executing: {cmd}")
    if env is None:
        env = os.environ
    else:
        print_env_str(env)
    proc = subprocess.run(cmd, shell=True, cwd=dir, env=env, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    if proc.returncode != 0:
        with open(f"{out_dir}/error.log", "wb") as f:
            f.write(proc.stderr)
            f.write(b"############")
            f.write(proc.stdout)
        print(f"!!!!! Error !!!! {cmd}")
        try:
            print(proc.stderr.decode("utf-8", errors="ignore"))
        except Exception as e:
            print(e)
    return proc.returncode


def execute_wrapper(args):
    return execute(args[0], args[1], args[2], args[3])


def read_config(file) -> dict:
    result = dict()
    with open(file, "r") as f:
        for line in f.readlines():
            line = line.strip()
            if line == "":
                continue
            tokens = line.split("=", maxsplit=1)
            result[tokens[0]] = tokens[1]
    return result


def print_env_str(env: dict):
    cov_exe = env["PACFIX_COV_EXE"]
    val_exe = env["PACFIX_VAL_EXE"]
    cov_dir = env["PACFIX_COV_DIR"]
    print(f"PACFIX_COV_EXE={cov_exe};PACFIX_VAL_EXE={val_exe};PACFIX_COV_DIR={cov_dir};AFL_NO_UI=1")


def new_env(env: dict, dir: str) -> dict:
    result = env.copy()
    result["PACFIX_COV_DIR"] = dir
    return result
def run_cmd(subject: dict):
    subject_dir = os.path.join(root_dir, "data", subject["subject"], subject["bug_id"])
    runtime_dir = os.path.join(subject_dir, "dafl-runtime")
    config = read_config(os.path.join(subject_dir, "config"))
    in_dir = os.path.join(runtime_dir, "in")
    if not os.path.exists(in_dir):
        os.makedirs(in_dir)
        os.system(f"cp {config['exploit']} {in_dir}")
    tmp_moo = os.path.join(runtime_dir, "tmp-moo")
    os.makedirs(tmp_moo, exist_ok=True)
    env = os.environ.copy()
    env["AFL_NO_UI"] = "1"
    bin = config["binary"].split("/")[-1]
    default_bin = os.path.join(runtime_dir, f"{bin}.instrumented")
    env["PACFIX_COV_EXE"] = os.path.join(runtime_dir, f"{bin}.coverage")
    env["PACFIX_VAL_EXE"] = os.path.join(runtime_dir, f"{bin}.valuation")
    env_moo = new_env(env, tmp_moo)
    out_dir = os.path.join(runtime_dir, f"{exp_id}-moo")
    prog_cmd = config["cmd"].replace("<exploit>", "@@")
    cmd = f"timeout 6h /home/yuntong/vulnfix/thirdparty/DAFL/afl-fuzz -C -t 2000ms -m none -p {config['dfg']} -i {in_dir} -o {out_dir} -s m -- {default_bin} {prog_cmd} >{runtime_dir}/{exp_id}-moo.log 2>&1"

    p_moo = mp.Process(target=execute, args=(cmd, runtime_dir, out_dir, env_moo))
    # execute(cmd, runtime_dir, out_dir, env=env)

    # out_dir_dafl = os.path.join(runtime_dir, f"{exp_id}-dafl")
    # cmd_dafl = f"timeout 6h /home/yuntong/vulnfix/thirdparty/DAFL/afl-fuzz -C -t 2000ms -m none -p {config['dfg']} -i {in_dir} -o {out_dir_dafl} -s d -- {default_bin} {prog_cmd} >{runtime_dir}/{exp_id}-dafl.log 2>&1"
    # tmp_dafl = os.path.join(runtime_dir, "tmp-dafl")
    # os.makedirs(tmp_dafl, exist_ok=True)
    # env_dafl = new_env(env, tmp_dafl)
    # # execute(cmd_dafl, runtime_dir, out_dir_dafl, env=env)
    # p_dafl = mp.Process(target=execute, args=(cmd_dafl, runtime_dir, out_dir_dafl, env_dafl))

    out_dir_vert = os.path.join(runtime_dir, f"{exp_id}-vert")
    cmd_vert = f"timeout 6h /home/yuntong/vulnfix/thirdparty/DAFL/afl-fuzz -C -t 2000ms -m none -p {config['dfg']} -i {in_dir} -o {out_dir_vert} -s m -v -- {default_bin} {prog_cmd} >{runtime_dir}/{exp_id}-vert.log 2>&1"
    tmp_vert = os.path.join(runtime_dir, "tmp-vert")
    os.makedirs(tmp_vert, exist_ok=True)
    env_vert = new_env(env, tmp_vert)
    # execute(cmd_vert, runtime_dir, out_dir_vert, env=env)
    p_vert = mp.Process(target=execute, args=(cmd_vert, runtime_dir, out_dir_vert, env_vert))

    p_moo.start()
    # p_dafl.start()
    p_vert.start()
    p_moo.join()
    # p_dafl.join()
    p_vert.join()


def analyze(dir: str):
    result = list()
    for d in sorted(os.listdir(dir)):
        if os.path.isdir(os.path.join(dir, d)):
            file = os.path.join(dir, d, "unique_dafl.log")
            with open(file, "r") as f:
                uniq = 0
                tot = 0
                lines = f.readlines()
                for line in lines:
                    if "[uniq]" in line:
                        uniq += 1
                    if "[q]" in line:
                        tot += 1
                result.append((d, uniq, tot))
    with open(os.path.join(dir, "result.csv"), "w") as f:
        f.write("id,uniq,tot\n")
        for r in result:
            f.write(f"{r[0]},{r[1]},{r[2]}\n")


def read_meta_data():
    with open(f"{root_dir}/meta-data.json") as f:
        meta_data = json.load(f)
    return meta_data


def find_subject(subject_id: str, meta) -> dict:
    for sbj in meta:
        if str(sbj["id"]) == subject_id:
            return sbj
        if sbj["bug_id"] == subject_id:
            return sbj
        if subject_id in sbj["bug_id"]:
            return sbj
    return None


def main(argv: List[str]):
    parser = argparse.ArgumentParser()
    parser.add_argument("cmd", help="Command to execute",
                        choices=["run", "rerun", "snapshot", "clean", "kill", "filter", "analyze"])
    parser.add_argument("subject", help="subject_id")
    parser.add_argument("--id", help="id", default="")
    args = parser.parse_args(argv)
    meta = read_meta_data()
    subject = find_subject(args.subject, meta)
    if subject is None:
        print(f"FATAL: invalid subject {subject}")
        exit(1)
    global exp_id
    if args.id != "":
        exp_id = args.id
    run_cmd(subject)


if __name__ == "__main__":
    main(sys.argv[1:])
