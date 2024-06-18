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
import sbsv

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
    if not os.path.exists(file):
        print(f"ERROR: {file} does not exist")
        return
    
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
    if not df["loc"].empty:
        df.groupby(pd.cut(df["loc"], bins=16))['loc'].count().plot(kind='bar', ax=axes[3])
    axes[3].set_title("loc - distribution")
    axes[3].set_xlabel("loc")
    axes[3].set_ylabel("#")
    
    plt.tight_layout()
    out_file = os.path.join(dir, "loc_distribution.png")
    plt.savefig(out_file)


def load_dafl_log(unique_log: str) -> dict:
    parser = sbsv.parser()
    parser.add_schema("[pacfix] [mem] [neg] [seed: int] [id: int] [hash: int] [time: int] [file: str]")
    parser.add_schema("[pacfix] [mem] [pos] [seed: int] [id: int] [hash: int] [time: int] [file: str]")
    parser.add_schema("[moo] [save] [seed: int] [moo-id: int] [fault: int] [path: int] [val: int] [file: str] [mut: str] [time: int]")
    parser.add_schema("[vertical] [save] [seed: int] [id: int] [dfg-path: int] [cov: int] [prox: int] [adj: float] [mut: str] [file: str] [time: int]")
    parser.add_schema("[vertical] [dry-run] [id: int] [dfg-path: int] [res: int] [file: str]")
    parser.add_schema("[vertical] [valuation] [seed: int] [dfg-path: int] [hash: int] [id: int] [persistent: int] [time: int]")
    parser.add_schema("[sel] [dafl] [id: int] [time: int]")
    parser.add_schema("[sel] [vertical] [id: int] [dfg-path: int] [time: int]")
    parser.add_schema("[sel] [moo] [id: int] [prev: int] [rank: int] [dfg-path: int] [time: int]")
    parser.add_schema("[moo] [uniq-path] [seed: int] [moo-id: int]")
    with open(unique_log, 'r') as f:
        parser.load(f)
        return parser


def analyze_dafl(dir: str, out: str, subj: str, ex: str):
    unique_log = os.path.join(dir, "unique_dafl.log")
    if not os.path.exists(unique_log):
        print(f"ERROR: {unique_log} does not exist")
        return
    parser = load_dafl_log(unique_log)
    result = parser.get_result()

    seed_time_map = dict()
    seeds = parser.get_result_in_order(["sel$dafl", "sel$moo", "sel$vertical"])
    prev_time = 0
    prev_id = -1
    for seed in seeds:
        seed_id = seed["id"]
        seed_time = seed["time"]
        if prev_id in seed_time_map:
            seed_time_map[prev_id] += (seed_time - prev_time) // 1000
        else:
            seed_time_map[prev_id] = (seed_time - prev_time) // 1000
        prev_id = seed_id
        prev_time = seed_time
    
    moo_path_map = dict()
    for path in result["moo"]["uniq-path"]:
        seed_id = path["seed"]
        moo_id = path["moo-id"]
        if seed_id not in moo_path_map:
            moo_path_map[seed_id] = 0
        moo_path_map[seed_id] += 1

    pos_map = dict()
    neg_map = dict()
    for res in result["pacfix"]["mem"]["pos"]:
        seed = res["seed"]
        if seed not in pos_map:
            pos_map[seed] = 0
        pos_map[seed] += 1
    for res in result["pacfix"]["mem"]["neg"]:
        seed = res["seed"]
        if seed not in neg_map:
            neg_map[seed] = 0
        neg_map[seed] += 1
    # Step 2: Prepare data for plotting
    seeds = sorted(set(pos_map.keys()).union(set(neg_map.keys())))
    pos_counts = [pos_map.get(seed, 0) for seed in seeds]
    neg_counts = [neg_map.get(seed, 0) for seed in seeds]
    time_counts = [seed_time_map.get(seed, 0) for seed in seeds]
    path_counts = [moo_path_map.get(seed, 0) for seed in seeds]

    # Step 3: Plot data using ordering for x-axis
    fig, ax1 = plt.subplots()

    bar_width = 0.22
    index = range(len(seeds))

    # Plot Positive, Negative, and Paths bars on primary y-axis
    bar1 = ax1.bar(index, pos_counts, bar_width, label='Positive')
    bar2 = ax1.bar([i + bar_width for i in index], neg_counts, bar_width, label='Negative')
    bar4 = ax1.bar([i + 2 * bar_width for i in index], path_counts, bar_width, label='Paths')

    ax1.set_xlabel('Seed')
    ax1.set_ylabel('Count')
    ax1.set_title('Positive and Negative Seed Counts')
    ax1.set_xticks([i + bar_width for i in index])
    ax1.set_xticklabels(seeds, rotation=90)
    ax1.legend(loc='upper left')

    # Create a secondary y-axis for the Time bar
    ax2 = ax1.twinx()
    bar3 = ax2.bar([i + 3 * bar_width for i in index], time_counts, bar_width, label='Time', color='y')
    ax2.set_ylabel('Time')
    ax2.set_yscale('log')

    # Combine legends from both y-axes
    bars = [bar1, bar2, bar4, bar3]
    ax1.legend(bars, [bar.get_label() for bar in bars], loc='upper left')

    # Add grid to both axes
    ax1.grid(True)
    plt.savefig(f"{dir}/seed.png")


    plt.clf()
    plt.xlabel("seed")
    plt.ylabel("time")
    time_list = list(seed_time_map.values())
    time_list.sort()
    filtered_time_list = [time for time in time_list if time >= 10]
    mean_time = sum(filtered_time_list) / len(filtered_time_list) if filtered_time_list else 0
    median_time = filtered_time_list[int(len(filtered_time_list) * 0.5)]
    print(f"[time-stat] [tot {len(time_list)}] [filter {len(filtered_time_list)}] [mean {mean_time}] [median {median_time}]")
    plt.plot(range(len(time_list)), time_list, 'bx-')
    plt.yscale('log')
    plt.savefig(f"{dir}/time.png")

    # print(result["vertical"]["valuation"])
    path_map = dict()
    for res in result["vertical"]["valuation"]:
        dfg_path = res["dfg-path"]
        hash = res["hash"]
        if dfg_path not in path_map:
            path_map[dfg_path] = set()
        path_map[dfg_path].add(hash)
    dfg_paths = list(path_map.keys())
    val_counts = [len(path_map[p]) for p in dfg_paths]
    # print(dfg_paths)
    # print(val_counts)
    paths = 0
    if len(result['moo']['save']) > 1:
        paths = result['moo']['save'][-1]['moo-id']
    result = f"[stat] [subj {subj}] [ex {ex}] [id {exp_id}] [neg {len(result['pacfix']['mem']['neg'])}] [pos {len(result['pacfix']['mem']['pos'])}] [paths {paths}]"
    if out == "":
        print(result)
    else:
        with open(out, "a") as f:
            f.write(result + "\n")
    # x = range(len(dfg_paths))
    # plt.figure(figsize=(10, 5))
    # plt.bar(x, val_counts, color='blue')
    # plt.xlabel('DFG Path')
    # plt.ylabel('Number of Unique Hashes')
    # plt.title('Number of Unique Hashes per DFG Path')
    # plt.xticks(x)  # Set the x-ticks to match the dfg_paths
    # plt.savefig(os.path.join(dir, "vertical-path.png"))


def execute(cmd: str, dir: str):
    print(f"Change directory to {dir}")
    print(f"Executing: {cmd}")
    proc = subprocess.run(cmd, shell=True, cwd=dir, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    if proc.returncode != 0:
        print(f"!!!!! Error !!!! {cmd}")
        try:
            print(proc.stderr.decode("utf-8", errors="ignore"))
        except Exception as e:
            print(e)
    return proc.returncode


def collect_inputs(runtime_dir: str, dir: str):
    unique_log = os.path.join(dir, "unique_dafl.log")
    if not os.path.exists(unique_log):
        print(f"ERROR: {unique_log} does not exist")
        return
    target = os.path.join(runtime_dir, "vert-in")
    execute(f"rm -r {target}", runtime_dir)
    os.makedirs(target, exist_ok=True)
    execute(f"cp in/* {target}", runtime_dir)
    result = load_dafl_log(unique_log)
    print(result["vertical"]["dry-run"])
    print(result["vertical"]["save"])
    path_filter = set()
    for save in result["vertical"]["save"]:
        path = save["dfg-path"]
        if path in path_filter:
            continue
        file = save["file"]
        path_filter.add(path)
        execute(f"cp {file} {target}", runtime_dir)
        print(f"Save {len(path_filter)}")


def run_cmd(subject: dict, cmd: str, out: str):
    subject_dir = os.path.join(root_dir, "data", subject["subject"], subject["bug_id"])
    runtime_dir = os.path.join(subject_dir, "dafl-runtime")
    config = read_config(os.path.join(subject_dir, "config"))

    # ex_list = ["dafl", "moo", "vert"]
    ex_list = ["moo", "dafl", "vert", "dyn"]
    for ex in ex_list:
        out_dir = os.path.join(runtime_dir, f"{exp_id}-{ex}")
        # analyze_vertical(out_dir)
        if cmd == "collect":
            collect_inputs(runtime_dir, out_dir)
            continue
        analyze_dafl(out_dir, out, subject["subject"] + "/" + subject["bug_id"], ex)
        # analyze_vertical(out_dir)


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
                        choices=["run", "collect", "analyze"])
    parser.add_argument("subject", help="subject_id")
    parser.add_argument("--id", help="id", default="")
    parser.add_argument("--out", help="out-file", default="")
    args = parser.parse_args(argv)
    meta = read_meta_data()
    subject = find_subject(args.subject, meta)
    if subject is None:
        print(f"FATAL: invalid subject {subject}")
        exit(1)
    global exp_id
    if args.id != "":
        exp_id = args.id
    run_cmd(subject, args.cmd, args.out)


if __name__ == "__main__":
    main(sys.argv[1:])
