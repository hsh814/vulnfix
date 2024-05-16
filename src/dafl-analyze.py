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


import pandas as pd
import matplotlib.pyplot as plt

def analyze_vertical(dir: str):
    file = os.path.join(dir, "vertical.log")
    
    df = pd.read_csv(file, names=['type', 'is_preserve', 'is_inter', 'is_new_val', 'mut', 'loc'])
    df = df[df['type'] == 'v']

    fig, axes = plt.subplots(1, 3, figsize=(18, 6))
    if not df[df['is_preserve'] == 1].empty:
        df[df['is_preserve'] == 1].groupby(['mut', 'is_preserve']).size().unstack().plot(kind='bar', ax=axes[0])
        axes[0].set_title('mut - is_preserve distribution')
        axes[0].set_ylabel('#')
    
    if not df[df['is_inter'] == 1].empty:
        df[df['is_inter'] == 1].groupby(['mut', 'is_inter']).size().unstack().plot(kind='bar', ax=axes[1])
        axes[1].set_title('mut - is_interesting distribution')
        axes[1].set_ylabel('#')
    
    if not df[df['is_new_val'] == 1].empty:
        df[df['is_new_val'] == 1].groupby(['mut', 'is_new_val']).size().unstack().plot(kind='bar', ax=axes[2])
        axes[2].set_title('mut - is_new_val distribution')
        axes[2].set_ylabel('#')
    
    plt.tight_layout()
    out_file = os.path.join(dir, "mut_distribution.png")
    plt.savefig(out_file)
    
    # loc에 대한 분포 시각화
    fig, axes = plt.subplots(1, 4, figsize=(24, 6))
    
    if not df[df['is_preserve'] == 1].empty:
        df[df['is_preserve'] == 1].groupby(pd.cut(df["loc"], bins=16))['is_preserve'].value_counts().unstack().plot(kind='bar', ax=axes[0])
        axes[0].set_title('loc - is_preserve distribution')
        axes[0].set_ylabel('#')
    
    if not df[df['is_inter'] == 1].empty:
        df[df['is_inter'] == 1].groupby(pd.cut(df["loc"], bins=16))['is_inter'].value_counts().unstack().plot(kind='bar', ax=axes[1])
        axes[1].set_title('loc - is_interesting distribution')
        axes[1].set_ylabel('#')
    
    if not df[df['is_new_val'] == 1].empty:
        df[df['is_new_val'] == 1].groupby(pd.cut(df["loc"], bins=16))['is_new_val'].value_counts().unstack().plot(kind='bar', ax=axes[2])
        axes[2].set_title('loc - is_new_val distribution')
        axes[2].set_ylabel('#')

    df.groupby(pd.cut(df["loc"], bins=16))['loc'].count().plot(kind='bar', ax=axes[3])
    axes[3].set_title("loc - distribution")
    axes[3].set_xlabel("loc")
    axes[3].set_ylabel("#")
    
    plt.tight_layout()
    out_file = os.path.join(dir, "loc_distribution.png")
    plt.savefig(out_file)


# def analyze_vertical(dir: str):
#     file = os.path.join(dir, "vertical.log")
#     out_file = os.path.join(dir, "out.png")
#     with open(file, "r") as f:
#         for line in f.readlines():
#             line = line.strip()
#             tokens = line.split(",")
#             if tokens[0] == "v":
#                 is_preserve = tokens[1] == "1"
#                 is_inter = tokens[2] == "1"
#                 is_new_val = tokens[3] == "1"
#                 mut = int(tokens[4])
#                 loc = float(tokens[5])




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
    analyze_vertical(out_dir)

    out_dir_dafl = os.path.join(runtime_dir, f"{exp_id}-dafl")
    tmp_dafl = os.path.join(runtime_dir, "tmp-dafl")
    os.makedirs(tmp_dafl, exist_ok=True)
    env_dafl = new_env(env, tmp_dafl)
    # analyze_vertical(out_dir_dafl)

    out_dir_vert = os.path.join(runtime_dir, f"{exp_id}-vert")
    cmd_vert = f"timeout 6h /home/yuntong/vulnfix/thirdparty/DAFL/afl-fuzz -C -t 2000ms -m none -p {config['dfg']} -i {in_dir} -o {out_dir_vert} -s m -v -- {default_bin} {prog_cmd} >{runtime_dir}/{exp_id}-vert.log 2>&1"
    tmp_vert = os.path.join(runtime_dir, "tmp-vert")
    os.makedirs(tmp_vert, exist_ok=True)
    env_vert = new_env(env, tmp_vert)
    analyze_vertical(out_dir_vert)


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
