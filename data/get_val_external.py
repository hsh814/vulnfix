import re
import os
import sys
import shutil
import random
import string
import threading
import subprocess
from tqdm import tqdm

base_path = "/home/yuntong/vulnfix/data/"
seed_save_base_dir = base_path
config_path = ""
valuation_exe = ""
binary_name = ""
is_stdin = False
command  = ""
subject  = ""
orig_env = os.environ.copy()
valfile = ""
target = ""
max_threads = 20
out_postfix = ""

def generate_random_filename(dirs):
    random_name = ''.join(random.choices(string.ascii_letters + string.digits, k=32))
    return os.path.join(dirs, random_name)

def extract_file_and_line(log):
    match = re.search(r'#0\s+0x[0-9a-f]+\s+in\s+.*\s+([^\s:]+):(\d+)', log)
    if match:
        file_path = match.group(1)
        line_number = match.group(2)
        return file_path.split("/")[-1] + ":" + str(line_number)
    return ""

def run_target(testcase_path, testcase_name):
    print("Running testcase " + testcase_name)
    result = {}
    temp_env = os.environ.copy()
    pacfix_filename = valfile + out_postfix + str(testcase_name)
    temp_env["PACFIX_FILENAME"] = pacfix_filename
    testcase_dir = os.path.dirname(testcase_path)
    temp_file = generate_random_filename(testcase_dir)

    try:
        if is_stdin:
            with open(testcase_path, "r") as stdin_file:
                cmd = valuation_exe
                result = subprocess.run(cmd, env=temp_env, stdin=stdin_file, stdout=subprocess.PIPE, stderr=subprocess.PIPE, timeout=30)
        else:
            shutil.copy2(testcase_path, temp_file)
            cmd = valuation_exe + " " + command.replace("<exploit>", temp_file)
            result = subprocess.run(cmd, env=temp_env, stdout=subprocess.PIPE, stderr=subprocess.PIPE, cwd=base_path, shell=True, timeout=30)
    except subprocess.TimeoutExpired as e:
        os.remove(pacfix_filename)
        return -1, ""
    finally:
        if os.path.exists(temp_file):
            os.remove(temp_file)
    ret_code = result.returncode
    err_result = result.stderr.decode('utf-8', errors='ignore')
    return ret_code, err_result

def get_line():
    global target
    rc, errlog = run_target(base_path + "/exploit", "exploit")
    print(errlog)
    target = extract_file_and_line(errlog)
    # os.remove(valfile + "exploit")


def initialize():
    if len(sys.argv) != 3:
        print("Usage: python3 get_val.py <subject> <id>")
        sys.exit(1)
    
    global base_path
    global subject
    global config_path
    global valuation_exe
    global valfile
    global binary_name
    global command
    global is_stdin
    global out_postfix
    global seed_save_base_dir

    subject = sys.argv[1]
    out_postfix = sys.argv[2]
    if len(sys.argv) > 3:
        seed_save_base_dir = sys.argv[3]
    base_path = os.path.join(base_path, subject)
    config_path = base_path + "/config"
    valuation_exe = base_path + "/runtime/"
    valfile = base_path + "/val_file"

    with open(config_path, 'r') as config:
        lines = config.readlines()
        for l in lines:
            if "binary-dir" in l:
                binary_name = l.split("/")[-1].strip()
                valuation_exe = valuation_exe + binary_name + ".valuation"
                continue
            if "cmd" in l and not "build" in l:
                command = l[4:].strip()
                continue
            if "input-from-stdin" in l:
                is_stdin = True
                continue
    get_line()
    import glob
    for f in glob.glob(valfile + "*"):
        os.remove(f)
        print(f"Deleted: {f}")
    print("Subject : " + subject)
    print("Base Path : " + base_path)
    print("Config Path : " + config_path)
    print("Valuation Executable : " + valuation_exe)
    print("Valuation File Path : " + valfile)
    print("Target Line : " + target)

def get_testcases(target_dir):
    files = os.listdir(target_dir)
    files = [f for f in files if os.path.isfile(os.path.join(target_dir, f))]
    return files

def thread_worker(testcase_file, pbar, sample_dir, out_dir):
    try:
        ret_code, err_result = run_target(out_dir + "/" + testcase_file, testcase_file)
        if ret_code != -1:
            is_neg = False
            dest_dir = sample_dir + "/pos/" + testcase_file
            if target == extract_file_and_line(err_result):
                is_neg = True
                dest_dir = sample_dir + "/neg/" + testcase_file
            shutil.move(valfile + out_postfix + str(testcase_file), dest_dir)
    except Exception as e:
        print(f"Run ID {testcase_file} failed with error: {e}")
        import traceback
        traceback.print_exc()
    finally:
        pbar.update(1)

def create_directory(dir_path):
    if os.path.exists(dir_path):
        print(f"Directory already exists - remove: {dir_path}")
        shutil.rmtree(dir_path)
    os.makedirs(dir_path)
    print(f"Directory created: {dir_path}")
        

if __name__ == "__main__":
    initialize()
    out_dir = os.path.join(seed_save_base_dir, subject, "seeds")
    print(f"Out: {out_dir}")
    aflrun_tc = get_testcases(out_dir)
    sample_dir = os.path.join(base_path, "cludafl_samples", f"{out_postfix}")
    create_directory(sample_dir)
    create_directory(os.path.join(sample_dir, "pos"))
    create_directory(os.path.join(sample_dir, "neg"))

    threads = []
    with tqdm(total=len(aflrun_tc), desc="Processing AFLRun Cases") as pbar:
        for i, testcase_file in enumerate(aflrun_tc):
            t = threading.Thread(target=thread_worker, args=(testcase_file, pbar, sample_dir, out_dir))
            threads.append(t)
            t.start()

            while threading.active_count() > max_threads:
                pass

        for t in threads:
            t.join()
