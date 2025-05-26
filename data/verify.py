import sys
import os
import re
import threading
from tqdm import tqdm
import random
operators = ["==", "<", ">", "<=", ">=", "!=", "&&", "||", "*", "/", "+", "-"]
correct = 0
incorrect = 0
patch_expr = "lh.line_range == 0"
POS_PATH = "./pos"
NEG_PATH = "./neg"
VALUATION_PATH = "/home/yuntong/vulnfix/data/libxml2/runtime/afl-out/memory/pos"

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

def grep(pattern, filename):
    try:
        import subprocess
        cmd = f"grep '{pattern}' {filename}"
        result = subprocess.check_output(cmd, shell=True).decode('utf-8')
        return result.strip()
    except subprocess.CalledProcessError:
        return ""  # 패턴을 찾지 못한 경우 빈 문자열 반환

# 사용 예시
# print(grep_A1("__valuation", "valuation.c"))
def extract_constants_from_fprintf(line):
    numbers = re.findall(r'(?<![a-zA-Z0-9_])([0-9]+)(?![a-zA-Z0-9_])', line)
    return ' '.join(numbers[1:])


def grep_vars_with_prev_line_dict(vars, text):
    lines = text.splitlines()
    result_dict = {}
    for var in vars:
        result_lines = []
        for i, line in enumerate(lines):
            if " " + var + ");" in line or ")" + var +");" in line:
                if i > 0:
                    result_lines.append(lines[i-1].rstrip())
                result_lines.append(line.rstrip())
        if result_lines:
            result_dict[var] = extract_constants_from_fprintf('\n'.join(result_lines[:2]))
    return result_dict

def get_valuation_from_line(var_id, line):
    if var_id in line:
        return int(line.split(var_id)[1])
    return None

def get_valuation_from_file(filename, varval, is_neg=False):
    valuation = []
    for var, var_id in varval.items():
        grep_result = grep(var_id, filename)
        for i, var_str in enumerate(grep_result.split("\n")):
            var_value = get_valuation_from_line(var_id, var_str)
            if var_value is None:
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
        test_expr = test_expr_orig
        # dict 안에 있는 변수들을 숫자값으로 치환
        for var, val in pos_val.items():
            test_expr = test_expr.replace(var, str(val))
        #print(test_expr)
        if eval(test_expr):
            incorrect += 1
        else:
            correct += 1
    for neg_val in neg_valuation:
        test_expr = test_expr_orig
        for var, val in neg_val.items():
            test_expr = test_expr.replace(var, str(val))
        #print(test_expr)
        if not eval(test_expr):
            incorrect += 1
        else:
            correct += 1
    return correct, incorrect

def process_file(filename, varval, is_neg):
    pos_valuation, neg_valuation = get_valuation_from_file(filename, varval, is_neg)
    return verify_patch_with_valuation(pos_valuation, neg_valuation, patch_expr)


def process_all_files(pos_dir, neg_dir, varval):
    results = {}
    threads = []
    incorrect_files = []
    
    def worker(filename, is_neg):
        correctt, incorrectt = process_file(filename, varval, is_neg)
        global correct
        global incorrect
        correct += correctt
        incorrect += incorrectt
        if incorrectt > 0:
            incorrect_files.append(filename)

    # 전체 파일 목록 생성
    pos_files = [f for f in os.listdir(pos_dir) if os.path.isfile(os.path.join(pos_dir,f))]
    neg_files = [f for f in os.listdir(neg_dir) if os.path.isfile(os.path.join(neg_dir,f))]

    # pos 디렉토리 파일에서 30000개 랜덤 선택
    sampled_pos = random.sample(pos_files, min(30000, len(pos_files)))
    
    # pos 디렉토리 파일 순회 
    for fname in tqdm(sampled_pos, desc="Positive 파일 처리중"):
        fpath = os.path.join(pos_dir, fname)
        t = threading.Thread(target=worker, args=(fpath, False))
        threads.append(t)
        t.start()

    # neg 디렉토리 파일에서 30000개 랜덤 선택
    sampled_neg = random.sample(neg_files, min(30000, len(neg_files)))
    
    # neg 디렉토리 파일 순회
    for fname in tqdm(sampled_neg, desc="Negative 파일 처리중"):
        fpath = os.path.join(neg_dir, fname)
        t = threading.Thread(target=worker, args=(fpath, True))
        threads.append(t)
        t.start()

    for t in threads:
        t.join()

    return correct, incorrect, incorrect_files
# pos/neg 디렉토리의 모든 파일에 대해 병렬로 검증

# patch_expr과 neg pos dir 경로 일부를 인자로 받아서 검증
if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: python3 verify_patch.py <patch_expr> <subject_name>")
        sys.exit(1)
    patch_expr = sys.argv[1]
    POS_PATH = f"/home/yuntong/vulnfix/data/{sys.argv[2]}/runtime/afl-out/memory/pos"
    NEG_PATH = f"/home/yuntong/vulnfix/data/{sys.argv[2]}/runtime/afl-out/memory/neg"
    VALUATION_PATH = f"/home/yuntong/vulnfix/data/{sys.argv[2]}/repair-out/valuation.c"
    

# 사용 예시
# grep_A1 결과에서 변수별로 추출하여 dict로 반환
a1_result = grep_A1("__valuation", VALUATION_PATH)
vars = extract_variables(patch_expr)
result_dict = grep_vars_with_prev_line_dict(vars, a1_result)
print(result_dict)
result_dict = {"content->c2": "1552 5073 1181 1859"}
#pos_valuation, neg_valuation = get_valuation_from_file("/home/yuntong/vulnfix/data/libming/cve_2016_9264/runtime/afl-out/memory/neg/29486_neg_27010308", result_dict, is_neg=True)
#print(pos_valuation)
#print(neg_valuation)
#print(verify_patch_with_valuation(pos_valuation, neg_valuation, patch_expr))
correct, incorrect, incorrect_files = process_all_files(POS_PATH, NEG_PATH, result_dict)
print(f"correct: {correct}, incorrect: {incorrect}, empirical error rate: {incorrect / (correct + incorrect)}")

# 틀린 파일 10개만 출력
print("\n틀린 파일 목록 (최대 10개):")
pincorrect_files = incorrect_files
if len(incorrect_files) > 10:
    pincorrect_files = pincorrect_files[:10]
for f in pincorrect_files:
    print(f)




