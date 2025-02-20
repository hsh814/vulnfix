import os
import sys
from typing import List
import sbsv
import matplotlib.pyplot as plt
import numpy as np

def read_log(log_file: str) -> sbsv.parser:
    parser = sbsv.parser()
    parser.add_schema("[dry-run] [entry: int] [file: str] [hash: int] [dfg: int] [res: int] [prox: int] [pre: int]")
    parser.add_schema("[sel] [entry: int] [perf: int] [inter: int] [total: int] [time: int]")
    parser.add_schema("[PacFuzz] [save_valuation] [pos] [seed: int] [entry: int] [id: int] [hash: int] [time: int] [file: str]")
    parser.add_schema("[PacFuzz] [save_valuation] [neg] [seed: int] [entry: int] [id: int] [hash: int] [time: int] [file: str]")
    parser.add_schema("[seed] [seed: int] [entry: int] [prox: float]")
    with open(log_file, 'r') as f:
        parser.load(f)
        return parser


if __name__ == "__main__":
    dir = sys.argv[1]
    base = os.path.basename(dir)
    proj = os.path.basename(os.path.dirname(dir))
    log_path = os.path.join(dir, "cludafl_out")
    postfix = sys.argv[2]
    parser = read_log(os.path.join(log_path, f"out-{postfix}", "unique_dafl.log"))
    result = dict()
    for val in parser.get_result_in_order(["[PacFuzz] [save_valuation] [pos]", "[PacFuzz] [save_valuation] [neg]"]):
        seed = val["seed"]
        result[seed] = result.get(seed, 0) + 1
    sel_times = dict()
    for sel in parser.get_result_in_order(["sel"]):
        entry = sel["entry"]
        sel_times[entry] = sel_times.get(entry, 0) + 1
    
    # 데이터 정렬 (선택 횟수 기준)
    sorted_sel_times = dict(sorted(sel_times.items()))
    sorted_result = {k: result.get(k, 0) for k in sorted_sel_times.keys()}

    # 시각화 (첫 번째 그래프)
    fig1, ax1 = plt.subplots(figsize=(20, 12))

    # 막대 그래프 (두 번째 y축 사용)
    seeds = list(sorted_sel_times.keys())
    x = np.arange(len(seeds))

    ax1.bar(x - 0.2, sorted_sel_times.values(), 0.4, label='Selection Times', color='tab:blue')
    ax1.set_xticks(x)
    ax1.set_xticklabels(seeds)
    ax1.set_xlabel("Seed (Entry)")
    ax1.set_ylabel("Selection Times", color='tab:blue')
    ax1.tick_params(axis='y', labelcolor='tab:blue')
    ax1.set_title("Selection and Valuation Frequency per Seed (Dual Y-axis)")

    ax2 = ax1.twinx()  # instantiate a second axes that shares the same x-axis
    ax2.bar(x + 0.2, sorted_result.values(), 0.4, label='Valuation Times', color='tab:orange')
    ax2.set_ylabel("Valuation Times", color='tab:orange')
    ax2.tick_params(axis='y', labelcolor='tab:orange')

    fig1.legend(loc="upper left", bbox_to_anchor=(0.1, 0.9))

    # 여백 조정
    plt.subplots_adjust(top=0.9)
    
    # 첫 번째 그래프 저장
    plt.savefig(f"/home/yuntong/vulnfix/fig/{proj}-{base}-{postfix}-bar.png")
    plt.close(fig1)  # 첫 번째 figure 닫기

    # 상관 관계 scatter plot (두 번째 그래프)
    sel_times_list = list(sorted_sel_times.values())
    result_list = list(sorted_result.values())
    
    fig2, ax = plt.subplots(figsize=(15,8))

    ax.scatter(sel_times_list, result_list)
    ax.set_xlabel("Selection Times")
    ax.set_ylabel("Valuation Times")
    ax.set_title("Correlation between Selection and Valuation Times")
    
    # 두 번째 그래프 저장
    plt.savefig(f"/home/yuntong/vulnfix/fig/{proj}-{base}-{postfix}-scatter.png")
    plt.close(fig2)