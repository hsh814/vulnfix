import re
import os
import sys
import math
import pickle
import random
from tqdm import tqdm
import csv
import pandas as pd
import seaborn as sns
import matplotlib.pyplot as plt
import argparse
from scipy import stats
import numpy as np

from typing import List

subjects = [ "binutils/cve_2017_6965", "binutils/cve_2017_14745", "binutils/cve_2017_15025",
    "coreutils/gnubug_19784", "coreutils/gnubug_25003", "coreutils/gnubug_25023",
    "coreutils/gnubug_26545", "jasper/cve_2016_8691", "jasper/cve_2016_9557",
    "libjpeg/cve_2012_2806", "libjpeg/cve_2017_15232", "libming/cve_2016_9264",
    "libtiff/bugzilla_2633", "libtiff/cve_2016_5321", "libtiff/cve_2016_9532",
    "libtiff/cve_2016_10094", "libtiff/cve_2017_7595", "libtiff/cve_2017_7599",
    "libtiff/cve_2017_7600", "libtiff/cve_2017_7601", "libxml2/cve_2012_5134",
    "libxml2/cve_2016_1838", "libxml2/cve_2016_1839", "libxml2/cve_2017_5969",
    "zziplib/cve_2017_5974", "zziplib/cve_2017_5975", "zziplib/cve_2017_5976" ]

epsilons = [0.01, 0.05, 0.1, 0.2, 0.5, 0.8]

observed = []
sps = [8, 16, 32, 256, 32768, 4294967295]

EXPERIMENT_DIR = "/home/yuntong/vulnfix/data/experiment-results"

def extract_id_variable_pairs(filename):
    with open(filename, 'r') as f:
        code = f.read()

    # fprintf(__tmp_descr, ..., ..., 마지막인자); 전체 매치
    pattern = re.compile(
        r'fprintf\s*\(\s*__tmp_descr\s*,(.*?)\);',
        re.DOTALL
    )

    matches = pattern.findall(code)
    id_var_pairs = {}

    for full_args in matches:
        # 숫자와 마지막 인자를 분리
        args = [arg.strip() for arg in full_args.split(',')]

        if len(args) < 5:
            continue  # 4개 ID + 1 변수명 최소 필요

        # 숫자 추출 (마지막 전 4개)
        try:
            id_numbers = args[-5:-1]
            if all(re.fullmatch(r'[0-9]+', id) for id in id_numbers):
                id_key = "_".join(id_numbers)
            else:
                continue  # 숫자 아닌게 섞여 있으면 건너뜀
        except:
            continue

        # 마지막 인자에서 캐스트 제거
        last_arg = args[-1]
        cleaned = re.sub(r'\([^\)]+\)', '', last_arg).strip()

        # 숫자 상수 제외
        if re.fullmatch(r'[0-9]+[lLuU]*', cleaned):
            continue

        if cleaned in observed:
            continue

        observed.append(cleaned)
        id_var_pairs[id_key] = cleaned

    return id_var_pairs

def generate_one_of_scalar(ids, lower=0, upper=4, sps=sps):
    invs = []
    for id_val in ids:
        for sp in sps:
            invs.append(f"{id_val} == {sp}")
        for i in range(lower, upper + 1):
            invs.append(f"{id_val} == {i}")
    return invs

def generate_non_zero(ids):
    invs = []
    for id_val in ids:
        invs.append(f"{id_val} != 0")
    return invs

def generate_lower_bound(ids, lower=0, upper=4, sps=sps):
    invs = []
    for id_val in ids:
        for sp in sps:
            invs.append(f"{id_val} >= {sp}")
        for i in range(lower, upper + 1):
            invs.append(f"{id_val} >= {i}")
    return invs

def generate_upper_bound(ids, lower=0, upper=4, sps=sps):
    invs = []
    for id_val in ids:
        for sp in sps:
            invs.append(f"{id_val} < {sp}")
        for i in range(lower, upper + 1):
            invs.append(f"{id_val} < {i}")
    return invs

# var1 > var2 
def generate_int_greater_than(ids):
    invs = []
    for id_val in ids:
        for id_val2 in ids:
            if id_val != id_val2:
                invs.append(f"{id_val} > {id_val2}")
    return invs

# var1 - var2 >= const
def generate_int_diff_lower_bound(ids, lower=0, upper=4, sps=sps):
    invs = []
    for id_val in ids:
        for id_val2 in ids:
            if id_val != id_val2:
                for i in range(lower, upper + 1):
                    invs.append(f"{id_val} - {id_val2} >= {i}")
                for sp in sps:
                    invs.append(f"{id_val} - {id_val2} >= {sp}")
    return invs

# var1 - var2 < const
def generate_int_diff_upper_bound(ids, lower=0, upper=4, sps=sps):
    invs = []
    for id_val in ids:
        for id_val2 in ids:
            if id_val != id_val2:
                for i in range(lower, upper + 1):
                    invs.append(f"{id_val} - {id_val2} < {i}")
                for sp in sps:
                    invs.append(f"{id_val} - {id_val2} < {sp}")
    return invs

# var1 <= var2 / const
def generate_int_div_upper_bound(ids, lower=1, upper=4, sps=sps):
    invs = []
    for id_val in ids:
        for id_val2 in ids:
            if id_val != id_val2:
                for i in range(lower, upper + 1):
                    invs.append(f"{id_val} <= {id_val2} / {i}")
                for sp in sps:
                    invs.append(f"{id_val} <= {id_val2} / {sp}")
    return invs

# var1 * var2 < const
def generate_int_mul_upper_bound(ids, lower=0, upper=4, sps=sps):
    invs = []
    for id_val in ids:
        for id_val2 in ids:
            if id_val != id_val2:
                for i in range(lower, upper + 1):
                    invs.append(f"{id_val} * {id_val2} < {i}")
                for sp in sps:
                    invs.append(f"{id_val} * {id_val2} < {sp}")
    return invs

def build_invariants(ids):
    print("[INFO] 불변식 생성 중...")
    one_of_scalar = generate_one_of_scalar(ids)
    non_zero = generate_non_zero(ids)
    lower_bound = generate_lower_bound(ids)
    upper_bound = generate_upper_bound(ids)
    int_greater_than = generate_int_greater_than(ids)
    int_diff_lower_bound = generate_int_diff_lower_bound(ids)
    int_diff_upper_bound = generate_int_diff_upper_bound(ids)
    int_div_upper_bound = generate_int_div_upper_bound(ids)
    int_mul_upper_bound = generate_int_mul_upper_bound(ids)
    all_invs = one_of_scalar + non_zero + lower_bound + upper_bound + int_greater_than + int_diff_lower_bound + int_diff_upper_bound + int_div_upper_bound + int_mul_upper_bound
    print(f"[INFO] 생성된 불변식 개수: {len(all_invs)}")
    return all_invs


VALUATION_FILE = "data/libtiff/cve_2016_10024/valuation.c"
POS_PICKLE = "pkls/libtiff_cve_2016_10024_pos.pkl"
NEG_PICKLE = "pkls/libtiff_cve_2016_10024_neg.pkl"
FUZZER = "evocatio"
EPSILON = 0.01
DELTA = 0.01

def load_pickle(pickle_file):
    print(f"[INFO] {pickle_file} 로딩 중...")
    with open(pickle_file, 'rb') as f:
        data = pickle.load(f)
    print(f"[INFO] {pickle_file} 샘플 개수: {len(data)}")
    return data
    
def label_samples(samples, is_neg):
    return [(True if is_neg else False, sample) for sample in samples]

def compile_invariant(inv_str):
    import re
    # 변수명: 1234_5678_91011_1213 꼴
    var_names = sorted(set(re.findall(r'\d+_\d+_\d+_\d+', inv_str)))
    expr = inv_str
    for var in var_names:
        # 변수명 앞뒤로 알파벳/숫자/언더스코어가 없는 경우만 치환
        expr = re.sub(rf'(?<![\w\']){re.escape(var)}(?![\w\'])', f"d['{var}']", expr)
    lambda_str = f"lambda d: {expr}"
    return eval(lambda_str), var_names

def validate_invariants_with_samples(invariants, samples):
    pos_samples = [sample[1] for sample in samples if sample[0] == False]
    neg_samples = [sample[1] for sample in samples if sample[0] == True]

    # 불변식 람다로 미리 컴파일
    compiled_invs = []
    for inv in invariants:
        func, var_names = compile_invariant(inv)
        compiled_invs.append((func, var_names, inv))

    print("[INFO] pos 샘플에 대해 불변식 람다로 필터링 중...")
    valid_invariants = []
    for func, var_names, inv in tqdm(compiled_invs, desc="pos 필터링"):
        is_valid = True
        for sample in pos_samples:
            try:
                if func(sample):
                    is_valid = False
                    break
            except:
                is_valid = False
                break
        if is_valid:
            valid_invariants.append((func, var_names, inv))

    print("[INFO] neg 샘플에 대해 불변식 람다로 필터링 중...")
    final_invariants = []
    for func, var_names, inv in tqdm(valid_invariants, desc="neg 필터링"):
        is_valid = True
        for sample in neg_samples:
            try:
                if not func(sample):
                    is_valid = False
                    break
            except:
                is_valid = False
                break
        if is_valid:
            final_invariants.append(inv)

    print(f"[INFO] 최종 유효 불변식 개수: {len(final_invariants)}")
    return final_invariants

def string_of_invariant(inv, id_map):
    for key in id_map.keys():
        inv = inv.replace(key, id_map[key])
    return inv

def calculate_error(invariant, samples):
    func, var_names = compile_invariant(invariant)
    pos_samples = [sample[1] for sample in samples if sample[0] == False]
    neg_samples = [sample[1] for sample in samples if sample[0] == True]
    error = 0
    no_key = 0
    for sample in tqdm(pos_samples, desc="pos error 계산"):
        try:
            if func(sample):
                error += 1
        except:
            no_key += 1
    for sample in tqdm(neg_samples, desc="neg error 계산"):
        try:
            if not func(sample):
                error += 1
        except:
            no_key += 1
    return error / (len(samples) - no_key)

# python3 experiment.py <subject_id>
# python3 experiment.py libtiff/cve_2016_10024

def read_from_file(subject_file: str) -> List[str]:
    if os.path.exists(subject_file):
        result = list()
        with open(subject_file, "r") as f:
            for line in f.readlines():
                line = line.strip()
                if line.startswith("#") or line == "":
                    continue
                result.append(line)
            return result
    else:
        return subjects


# def subject_checker(subject_id: str, result):
#     files = [
#         f"{EXPERIMENT_DIR}/pkls/evocatio_{subject_id.replace('/', '_')}_pos.pkl",
#         f"{EXPERIMENT_DIR}/pkls/evocatio_{subject_id.replace('/', '_')}_neg.pkl",
#         f"{EXPERIMENT_DIR}/pkls/afl_{subject_id.replace('/', '_')}_pos.pkl",
#         f"{EXPERIMENT_DIR}/pkls/afl_{subject_id.replace('/', '_')}_neg.pkl",
#         f"{EXPERIMENT_DIR}/pkls/dafl_{subject_id.replace('/', '_')}_pos.pkl",
#         f"{EXPERIMENT_DIR}/pkls/dafl_{subject_id.replace('/', '_')}_neg.pkl",
#     ]
#     for file in files:
#         if not os.path.exists(file):
#             print(f"{subject} {file} not found!!!")
#             fuzzer = "evocatio"
#             if "/afl_" in file:
#                 fuzzer = "afl"
#             elif "/dafl_" in file:
#                 fuzzer = "dafl"
#             result.append({"subject": subject_id, "fuzzer": fuzzer})

# retry = list()
# import json
# for subject in subjects:
#     subject_checker(subject, retry)
# with open("retry.json", "w") as f:
#     json.dump(retry, f, indent=2)
# exit(0)

if __name__ == "__main__":
    
    argparser = argparse.ArgumentParser(description="Generate plot from pacfix results")
    argparser.add_argument("fuzzer", help="fuzzer", choices=["evocatio", "dafl", "afl"])
    argparser.add_argument("--subjects-file", help="File to restrict subjects", default="/home/yuntong/vulnfix/data/subjects.txt")
    argparser.add_argument("--single-subject", help="Run on single subject", default="")
    argparser.add_argument("--single-epsilon", help="Run on single epsilon", default="")
    argparser.add_argument("--experiment-dir", help="Experiment dir", default="/home/yuntong/vulnfix/data/experiment-results")
    argparser.add_argument("--skip-cal", help="Skip calculation", default=False, action="store_true")
    argparser.add_argument("--skip-plot", help="Skip plot", default=False, action="store_true")
    args = argparser.parse_args(sys.argv[1:])
    EXPERIMENT_DIR = args.experiment_dir
    subjects = read_from_file(args.subjects_file)
    # For parallelism
    if args.single_subject != "":
        subjects = [args.single_subject]
    if args.single_epsilon != "":
        epsilons = [float(args.single_epsilon)]
    FUZZER = args.fuzzer
    if not args.skip_cal:
        # This can be parallelized
        for subject_id in subjects:
            print(f"Do {subject_id}")
            for ep in epsilons:
                observed = []
                EPSILON = ep
                VALUATION_FILE = f"{EXPERIMENT_DIR}/data/{subject_id}/valuation.c"
                POS_PICKLE = f"{EXPERIMENT_DIR}/pkls/{FUZZER}_{subject_id.replace('/', '_')}_pos.pkl"
                NEG_PICKLE = f"{EXPERIMENT_DIR}/pkls/{FUZZER}_{subject_id.replace('/', '_')}_neg.pkl"

                # 만약 피클 파일이 없으면 넘어감
                if not os.path.exists(POS_PICKLE) or not os.path.exists(NEG_PICKLE):
                    print(f"[WARN] {POS_PICKLE} 또는 {NEG_PICKLE} 파일이 존재하지 않습니다.")
                    continue

                print(f"[INFO] {VALUATION_FILE}에서 변수 추출 중...")
                results = extract_id_variable_pairs(VALUATION_FILE)
                print(f"[INFO] 추출된 변수(ID): {list(results.keys())}")

                pos_samples = label_samples(load_pickle(POS_PICKLE), False)
                neg_samples = label_samples(load_pickle(NEG_PICKLE), True)
                new_pos_samples = []
                new_neg_samples = []
                for sample in pos_samples:
                    new_sample = {}
                    for key in sample[1].keys():
                        new_sample[key.replace(" ", "_")] = int(sample[1][key])
                    new_pos_samples.append((sample[0], new_sample))
                for sample in neg_samples:
                    new_sample = {}
                    for key in sample[1].keys():
                        new_sample[key.replace(" ", "_")] = int(sample[1][key])
                    new_neg_samples.append((sample[0], new_sample))
                pos_samples = new_pos_samples
                neg_samples = new_neg_samples
                all_samples = pos_samples + neg_samples
                print(f"[INFO] 전체 샘플 개수: {len(all_samples)}")

                invariants = build_invariants(results.keys())

                samples = math.ceil((math.log(len(invariants)) + math.log(1.0 / DELTA)) / EPSILON)
                print(f"[INFO] epsilon: {EPSILON}, delta: {DELTA}, required samples: {samples}")
                os.makedirs(f"{EXPERIMENT_DIR}/epsilon", exist_ok=True)

                # CSV 파일 준비
                with open(f"{EXPERIMENT_DIR}/epsilon/result_{FUZZER}_{subject_id.replace('/', '_')}_{EPSILON}.csv", "w", newline='', encoding='utf-8') as csvfile:
                    writer = csv.writer(csvfile)
                    writer.writerow(["fuzzer", "patch", "predicted error", "max empirical error", "median empirical error", "average empirical error", "samples"])

                    for i in range(10):
                        print(f"[INFO] {i}번째 실험")

                        print(f"[INFO] 대용량 샘플에서 무작위 샘플 추출 중... {int(samples)} from {len(all_samples)}")
                        if len(all_samples) < samples:
                            patch = "not enough samples"
                            predicted_error = EPSILON
                            max_empirical_error = "-"
                            median_empirical_error = "-"
                            average_empirical_error = "-"
                            writer.writerow([FUZZER, patch, predicted_error, max_empirical_error, median_empirical_error, average_empirical_error, int(samples)])
                            print(f"[WARN] not enough samples: {len(all_samples)} < {samples}")
                            continue

                        sampled_samples = []
                        for s in tqdm(random.sample(range(len(all_samples)), samples), desc="샘플 추출"):
                            sampled_samples.append(all_samples[s])

                        print("[INFO] 불변식 검증 중...")
                        validated_invariants = validate_invariants_with_samples(invariants, sampled_samples)
                        print(f"[INFO] 검증 통과 불변식 개수: {len(validated_invariants)}")

                        if len(validated_invariants) == 0:
                            patch = "NONE"
                            predicted_error = EPSILON
                            max_empirical_error = "-"
                            median_empirical_error = "-"
                            average_empirical_error = "-"
                            writer.writerow([FUZZER, patch, predicted_error, max_empirical_error, median_empirical_error, average_empirical_error, int(samples)])
                            print(f"[WARN] NONE")
                            continue

                        # random_answer = random.choice(validated_invariants)
                        max_empirical_error = 0
                        median_empirical_error = 0
                        average_empirical_error = 0
                        empirical_errors = []
                        #  10% sample
                        sample_amount = len(validated_invariants) // 10
                        if len(validated_invariants) < 10:
                            sample_amount = 1 #len(validated_invariants)
                        sampled_invariants = random.sample(validated_invariants, sample_amount)
                        print(f"val_inv {len(validated_invariants)} sampled_inv {len(sampled_invariants)}")
                        for inv in sampled_invariants:
                            patch_str = string_of_invariant(inv, results)
                            predicted_error = EPSILON
                            empirical_error = calculate_error(inv, all_samples)
                            empirical_errors.append(empirical_error)
                            if empirical_error > max_empirical_error:
                                max_empirical_error = empirical_error
                                patch_str = patch_str
                        empirical_errors.sort()
                        median_empirical_error = empirical_errors[len(empirical_errors) // 2]
                        average_empirical_error = sum(empirical_errors) / len(empirical_errors)
                        print(f"\n[RESULT] patch : {patch_str}")
                        print(f"[RESULT] predicted error : {predicted_error}")
                        print(f"[RESULT] max empirical error : {max_empirical_error}")
                        print(f"[RESULT] median empirical error : {median_empirical_error}")
                        print(f"[RESULT] average empirical error : {average_empirical_error}")

                        writer.writerow([FUZZER, patch_str, predicted_error, max_empirical_error, median_empirical_error, average_empirical_error, int(samples)])

    # === 각 subject별 epsilon에 따른 평균 max empirical error 선 그래프 ===
    if not args.skip_plot:
        os.makedirs(os.path.join(EXPERIMENT_DIR, "fig"), exist_ok=True)
        for subject in subjects:
            plt.figure(figsize=(14, 8))
            subject_num_id = subject.split('_')[-1]
            subject_name = subject.split('_')[0]
            subject_label = subject_name + '-' + subject_num_id
            mean_max_errors = []
            all_max_errors = list()
            ci_lower_max_errors = list()
            ci_upper_max_errors = list()
            confidence_level = 0.95
            valid_epsilons = []
            sample_nums = list()
            inv_num = 0
            VALUATION_FILE = os.path.join(EXPERIMENT_DIR, "data", subject, "valuation.c")
            if os.path.exists(VALUATION_FILE):
                results = extract_id_variable_pairs(VALUATION_FILE)
                invariants = build_invariants(results.keys())
                inv_num = len(invariants)
            else:
                print(f"valuation_file {VALUATION_FILE} not found")
                continue
            for ep in epsilons:
                csv_path = f"{EXPERIMENT_DIR}/epsilon/result_{FUZZER}_{subject.replace('/', '_')}_{ep}.csv"
                if not os.path.exists(csv_path):
                    print(f"[INFO] {csv_path} does not exist")
                    continue
                df = pd.read_csv(csv_path)
                if 'max empirical error' not in df.columns:
                    print(f"[INFO] {csv_path} does not contain max empirical error")
                    continue
                df['max empirical error'] = pd.to_numeric(df['max empirical error'], errors='coerce')
                df = df.dropna(subset=['max empirical error'])
                if len(df) == 0:
                    print(f"[INFO] {csv_path} does not contain max empirical error")
                    continue
                samples = math.ceil((math.log(inv_num) + math.log(1.0 / DELTA)) / ep)
                sample_nums.append(samples)
                errors = df['max empirical error'].tolist()
                all_max_errors.append(errors)
                mean_max = df['max empirical error'].mean()
                mean_max_errors.append(mean_max)
                sem = stats.sem(errors)
                n = len(errors)
                if n < 2:
                    cl, cu = mean_max, mean_max
                elif sem == 0 or np.isnan(sem):
                    cl, cu = mean_max, mean_max
                else:
                    cl, cu = stats.t.interval(confidence_level, df=len(errors)-1, loc=mean_max, scale=sem)

                ci_lower_max_errors.append(cl)
                ci_upper_max_errors.append(cu)
                valid_epsilons.append(ep)
            # plt.xlabel('epsilon')
            # plt.ylabel('Avg max empirical error (10 times)')
            # plt.title(f'Avg max empirical error per subject from {FUZZER}')
            # plt.legend(fontsize=8, loc='upper left', bbox_to_anchor=(1,1))
            # plt.ylim(1e-7, 1.0)
            # plt.grid(True, linestyle='--', alpha=0.5)
            # plt.tight_layout()
            # os.makedirs(f"{EXPERIMENT_DIR}/fig", exist_ok=True)
            # filename = f"{EXPERIMENT_DIR}/fig/{subject.replace('/', '_')}_empirical_error_{FUZZER}.png"
            # plt.savefig(filename, dpi=200)
            # plt.close()
            log_plot_min_y_val = 1e-9
            plt.figure(figsize=(14, 8))
            eps_array = np.array(valid_epsilons)
            means_array = np.array(mean_max_errors)
            ci_lower_array = np.array(ci_lower_max_errors)
            ci_upper_array = np.array(ci_upper_max_errors)
            print(eps_array)
            print(means_array)

            plt.plot(sample_nums, means_array, marker='o', color='b', label=subject_label)
            plt.plot(sample_nums, eps_array, marker='o', color='r', label="epsilon")
            plt.fill_between(sample_nums, ci_lower_array, ci_upper_array, alpha=0.2, color='b', label="95% CI")
            plt.xlabel('Samples')
            plt.ylabel('Avg max empirical error (10 times) - log scale')
            plt.title(f'Avg max empirical error per subject {subject} from {FUZZER}')
            plt.legend(fontsize=8, loc='upper left', bbox_to_anchor=(1,1))
            min_y_val = 1e-7
            if len(ci_lower_array) > 0:
                min_y_val = np.min(ci_lower_array) / 10.0
                print(ci_lower_array)
            plt.ylim(max(1e-7, min_y_val), 1.0)
            plt.yscale('log')
            plt.grid(True, which="both", linestyle='--', alpha=0.5)
            plt.tight_layout()
            filename = f"{EXPERIMENT_DIR}/fig/{subject.replace('/', '_')}_empirical_error_{FUZZER}_log_scale.png"
            plt.savefig(filename, dpi=200)
            plt.close()
            print(f"{filename} 파일로 저장 완료!")
