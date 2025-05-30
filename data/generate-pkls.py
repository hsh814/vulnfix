import sys
import os
import re
import threading
import sqlite3
import pickle
from tqdm import tqdm

operators = ["==", "(", ")", "<", ">", "<=", ">=", "!=", "&&", "||", "*", "/", "+", "-"]
correct = 0
incorrect = 0
patch_expr = "lh.line_range == 0"
POS_PATH = "./pos"
NEG_PATH = "./neg"
VALUATION_PATH = "/home/yuntong/vulnfix/data/libxml2/runtime/afl-out/memory/pos"
fuzzer = "evocatio"
subject = "libxml2"


def extract_variables(expr):
    exprs = expr.split(" ")
    variables = []
    for expr in exprs:
        if expr in operators or expr.isdigit():
            continue
        variables.append(expr)
    return variables


def grep_A1(pattern, filename):
    # grep 명령어를 사용하여 패턴 검색 및 다음 줄까지 출력 (-A1 옵션)
    try:
        import subprocess
        cmd = f"grep -A1 '{pattern}' {filename}"
        result = subprocess.check_output(cmd, shell=True).decode('utf-8')
        return result.strip()
    except subprocess.CalledProcessError:
        return ""  # 패턴을 찾지 못한 경우 빈 문자열 반환


def grep(pattern, file_content: str):
    lines = list()
    for line in file_content.splitlines():
        if pattern in line:
            lines.append(line)
    return lines


# 사용 예시
# print(grep_A1("__valuation", "valuation.c"))
def extract_constants_from_fprintf(line):
    numbers = re.findall(r'(?<![a-zA-Z0-9_])([0-9]+)(?![a-zA-Z0-9_])', line)
    return ' '.join(numbers[1:5])


def grep_vars_with_prev_line_dict(vars, text):
    lines = text.splitlines()
    result_dict = {}
    for var in vars:
        result_lines = []
        for i, line in enumerate(lines):
            if " " + var + ");" in line or ")" + var + ");" in line:
                if i > 0:
                    result_lines.append(lines[i - 1].rstrip())
                result_lines.append(line.rstrip())
        if result_lines:
            result_dict[var] = extract_constants_from_fprintf('\n'.join(result_lines[:2]))
    return result_dict


def get_valuation_from_line(var_id, line):
    if var_id in line:
        return int(line.split(var_id)[1])
    else:
        print(line, "line")
    return None


def get_unique_valuation_from_file(file_content, is_neg=False):
    lines = file_content.splitlines()
    all_dicts = []
    current_dict = {}

    for line in lines:
        line = line.strip()
        if line.startswith('__valuation: 0'):
            parts = line.split()
            if len(parts) != 7:
                continue
            key = ' '.join(parts[2:6])  # 4개 숫자 문자열 그대로
            value = parts[6]  # 마지막 숫자 (문자열 그대로 또는 int로 변환 가능)
            current_dict[key] = value
        elif line.startswith('---'):  # 경계 구분
            if current_dict:
                all_dicts.append(current_dict)
                current_dict = {}

    # 마지막 dict도 포함
    if current_dict:
        all_dicts.append(current_dict)

    if is_neg:
        return [all_dicts[-1]], all_dicts[:-1]
    else:
        return [], all_dicts


def get_valuation_from_file(file_content, varval, is_neg=False):
    valuation = []
    for var, var_id in varval.items():
        grep_result = grep(var_id, file_content)
        for i, var_str in enumerate(grep_result):
            var_value = get_valuation_from_line(var_id, var_str)
            if var_value is None:
                print(grep_result, var_id)
                raise Exception("valuation 값이 여러개 있음")
            if len(valuation) <= i:
                valuation.append({var: var_value})
            else:
                valuation[i][var] = var_value
    if is_neg:
        return valuation[:-1], [valuation[-1]]
    else:
        return valuation, []


def verify_patch_with_valuation(pos_valuation, neg_valuation, test_expr):
    # valuation을 돌면서 참이 되는지 확인
    result = True
    correct = 0
    incorrect = 0
    test_expr_orig = test_expr.replace("&&", "and").replace("||", "or")
    for pos_val in pos_valuation:
        tex = test_expr_orig
        # dict 안에 있는 변수들을 숫자값으로 치환
        for var, val in pos_val.items():
            tex = tex.replace(var, str(val))
        if eval(tex):
            incorrect += 1
        else:
            correct += 1
    for neg_val in neg_valuation:
        tex = test_expr_orig
        for var, val in neg_val.items():
            tex = tex.replace(var, str(val))
        if not eval(tex):
            incorrect += 1
        else:
            correct += 1
    return correct, incorrect


def verify_patch_with_uniq_valuation(pos_valuation, neg_valuation, test_expr, varval):
    result = True
    correct = 0
    incorrect = 0
    passer = False
    test_expr_orig = test_expr.replace("&&", "and").replace("||", "or")
    for pos_val in pos_valuation:
        tex = test_expr_orig
        passer = False
        for var, var_id in varval.items():
            if var_id in pos_val:
                tex = tex.replace(" " + var + " ", " " + str(pos_val[var_id]) + " ")
            else:
                # print(pos_val, var_id)
                passer = True
                # raise Exception("valuation 조회 안됨")
        if passer:
            continue
        if eval(tex):
            print("pos :", pos_val)
            incorrect += 1
        else:
            correct += 1
    for neg_val in neg_valuation:
        tex = test_expr_orig
        passer = False
        for var, var_id in varval.items():
            if var_id in neg_val:
                tex = tex.replace(" " + var + " ", " " + str(neg_val[var_id]) + " ")
            else:
                # print(neg_val, var_id)
                passer = True
                # raise Exception("valuation 조회 안됨")
        if passer:
            continue
        if not eval(tex):
            print("neg : ", neg_val)
            incorrect += 1
        else:
            correct += 1
    return correct, incorrect


def process_file(file_content, varval, is_neg):
    pos_valuation, neg_valuation = get_valuation_from_file(file_content, varval, is_neg)
    return verify_patch_with_valuation(pos_valuation, neg_valuation, patch_expr)


def remove_duplicates(vals):
    unique_dicts = []
    seen = set()
    for d in vals:
        frozen = frozenset(d.items())  # dict을 해시 가능한 형태로
        if frozen not in seen:
            seen.add(frozen)
            unique_dicts.append(d)
    return unique_dicts


def process_all_files_db(db_file, varval):
    conn = None
    incorrect_files = list()
    neg_vals = []
    pos_vals = []
    correct = 0
    incorrect = 0
    print(db_file)

    def worker(file_content, is_neg):
        c, i = process_file(file_content, varval, is_neg)
        global correct, incorrect
        correct += c
        incorrect += i
        if i > 0:
            incorrect_files.append(file_content)

    def file_worker(file_content, is_neg):
        neg_valuation, pos_valuation = get_unique_valuation_from_file(file_content, is_neg)
        if is_neg:
            neg_vals.extend(neg_valuation)
        else:
            pos_vals.extend(pos_valuation)

    try:
        conn = sqlite3.connect(f"file:{db_file}?mode=ro", uri=True)
        cursor = conn.cursor()
        query = """
                SELECT f.id, f.path, f.is_pos, v.content
                FROM file f
                         JOIN val v ON f.val_id = v.id \
                """
        cursor.execute(query)
        tasks = []
        db_results = cursor.fetchall()
        if not db_results:
            print(f"No data in {db_file}")
            return 0, 0
        for file_id, path, is_pos, content_blob in tqdm(db_results, desc=f"Verify val from {db_file}"):
            try:
                content_str = content_blob.decode("utf-8")
                is_neg = is_pos == 0
                file_worker(content_str, is_neg)
            except Exception as e:
                print(f"Error {e}")
        # print(pos_vals)
        # print(neg_vals)
        pos_vals = remove_duplicates(pos_vals)
        print(f"pos_vals: {len(pos_vals)}")
        neg_vals = remove_duplicates(neg_vals)
        print(f"neg_vals: {len(neg_vals)}")

        with open(f'pkls/{fuzzer}_{subject}_pos.pkl', 'wb') as f:
            pickle.dump(pos_vals, f)
        with open(f'pkls/{fuzzer}_{subject}_neg.pkl', 'wb') as f:
            pickle.dump(neg_vals, f)
        # print(pos_vals)
        # print(neg_vals)
        # correct, incorrect = verify_patch_with_uniq_valuation(pos_vals, neg_vals, patch_expr, varval)
    except Exception as e:
        print(f"Error {e}")
    finally:
        if conn:
            conn.close()

    # return correct, incorrect, incorrect_files


# pos/neg 디렉토리의 모든 파일에 대해 병렬로 검증

# patch_expr과 neg pos dir 경로 일부를 인자로 받아서 검증
if __name__ == "__main__":
    if len(sys.argv) != 4:
        print("Usage: python3 verify_patch.py <patch_expr> <subject_name> <db_file>")
        sys.exit(1)
    # patch_expr = sys.argv[1]
    subject = sys.argv[2].replace("/", "_")
    POS_PATH = f"/home/yuntong/vulnfix/data/{sys.argv[2]}/runtime/afl-out/memory/pos"
    NEG_PATH = f"/home/yuntong/vulnfix/data/{sys.argv[2]}/runtime/afl-out/memory/neg"
    VALUATION_PATH = f"/home/yuntong/vulnfix/data/{sys.argv[2]}/repair-out/valuation.c"
    # vals.db file generated from count_vals.py <sample_dir>
    db_file = sys.argv[3]
    if "evocatio" in db_file:
        fuzzer = "evocatio"
    elif "dafl" in db_file:
        fuzzer = "dafl"
    else:
        fuzzer = "afl"

# 사용 예시
# grep_A1 결과에서 변수별로 추출하여 dict로 반환
a1_result = grep_A1("__valuation", VALUATION_PATH)
# vars = extract_variables(patch_expr)
# print(vars)
# result_dict = grep_vars_with_prev_line_dict(vars, a1_result)
# print(result_dict)
# pos_valuation, neg_valuation = get_valuation_from_file("pos/1", result_dict, is_neg=False)
# print(pos_valuation)
# print(neg_valuation)
if os.path.exists(f'pkls/{fuzzer}_{subject}_pos.pkl') and os.path.exists(f'pkls/{fuzzer}_{subject}_neg.pkl'):
    # # 기존 pickle 파일이 있는지 확인
    pass
    # with open(f'pkls/{fuzzer}_{subject}_pos.pkl', 'rb') as f:
    #     pos_vals = pickle.load(f)
    # with open(f'pkls/{fuzzer}_{subject}_neg.pkl', 'rb') as f:
    #     neg_vals = pickle.load(f)
    # print("기존 pickle 파일을 불러왔습니다.")
    # print(f"pos_vals: {len(pos_vals)}")
    # print(f"neg_vals: {len(neg_vals)}")
    # correct, incorrect = verify_patch_with_uniq_valuation(pos_vals, neg_vals, patch_expr, result_dict)
    # print(f"correct: {correct}, incorrect: {incorrect}, empirical error rate: {incorrect / (correct + incorrect)}")
else:
    # correct, incorrect, incorrect_files
    process_all_files_db(db_file, {})
    # print(f"correct: {correct}, incorrect: {incorrect}, empirical error rate: {incorrect / (correct + incorrect)}")

# incorrect_files = incorrect_files[:10]
# for f in incorrect_files:
#    print(f)
