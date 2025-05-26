import subprocess
import os
import csv
from concurrent.futures import ThreadPoolExecutor
import shutil
import psutil
import time

targets = [
    "binutils/cve_2017_6965",
    "binutils/cve_2017_14745",
    "binutils/cve_2017_15025",
    "coreutils/gnubug_19784",
    "coreutils/gnubug_25003",
    "coreutils/gnubug_25023",
    "coreutils/gnubug_26545",
    "jasper/cve_2016_8691",
    "jasper/cve_2016_9557",
    "libjpeg/cve_2012_2806",
    "libjpeg/cve_2017_15232",
    "libming/cve_2016_9264",
    "libtiff/bugzilla_2633",
    "libtiff/cve_2016-5321",
    "libtiff/cve_2016_9532",
    "libtiff/cve_2016_10094",
    "libtiff/cve_2017_7595",
    "libtiff/cve_2017_7599",
    "libtiff/cve_2017_7600",
    "libtiff/cve_2017_7601",
    "libxml2/cve_2012_5134",
    "libxml2/cve_2016_1838",
    "libxml2/cve_2016_1839",
    "libxml2/cve_2017_5969",
    "zziplib/cve_2017_5974",
    "zziplib/cve_2017_5975",
    "zziplib/cve_2017_5976",
]

runs = 10
epsilon = "0.01"
fuzzer = "evocatio"
date_tag = "2025-04-28"
result_file = "results.csv"

def run_and_wait_all(cmd):
    # main.exe 실행
    proc = subprocess.Popen(cmd,stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL)
    # proc = subprocess.Popen(cmd)
    parent = psutil.Process(proc.pid)

    # 자식 포함 전체 프로세스 기다리기
    while True:
        if not parent.is_running():
            break
        children = parent.children(recursive=True)
        if all(not child.is_running() for child in children):
            break
        time.sleep(0.5)

def run_subject(subject):
    orig_dir = os.getcwd()
    subject_dir = os.path.join(orig_dir, subject)

    if not os.path.exists(subject_dir):
        return []

    os.chdir(subject_dir)
    result_rows = []

    try:
        # 심볼릭 링크 설정
        memory_src = os.path.abspath(os.path.join(subject_dir, "evocatio-samples", f"evocatio-{date_tag}"))
        memory_link =  os.path.abspath(os.path.join(subject_dir,"runtime", "afl-out", "memory"))
        if os.path.lexists(memory_link):
            if os.path.islink(memory_link) or os.path.isfile(memory_link):
                os.remove(memory_link)
            elif os.path.isdir(memory_link):
                shutil.rmtree(memory_link)
        # os.makedirs(os.path.dirname(memory_link), exist_ok=True)
        os.symlink(memory_src, memory_link)

        for run_num in range(1, runs + 1):
            run_and_wait_all(["./rerun.sh", epsilon])

            log_path = os.path.join("runtime", "pacfix.log")
            if not os.path.exists(log_path):
                result_rows.append([fuzzer, subject, run_num, "-", "-", "-"])
                continue

            with open(log_path, "r") as f:
                lines = f.readlines()
            last_line = lines[-1].strip() if lines else ""

            if "No Patch Found" in last_line:
                result_rows.append([fuzzer, subject, run_num, "-", "-", "-"])
                continue

            patch = last_line.split("Patch : ")[-1].strip()
            vals_db = os.path.join(orig_dir, subject, f"{fuzzer}-sample", f"{fuzzer}-{date_tag}", "vals.db")
            verify_cmd = [
                "python3", os.path.join(orig_dir, "verify-uniq.py"),
                f"not ( {patch} )", subject, vals_db
            ]

            try:
                result = subprocess.check_output(verify_cmd, stderr=subprocess.DEVNULL).decode()
                emp_rate = "-"
                for line in result.splitlines():
                    if "empirical error rate" in line:
                        emp_rate = line.split("empirical error rate:")[-1].strip()
                        break
                result_rows.append([fuzzer, subject, run_num, patch, emp_rate, patch])
            except:
                result_rows.append([fuzzer, subject, run_num, patch, "verify-error", patch])

    except Exception as e:
        result_rows.append([fuzzer, subject, 0, "-", f"error: {str(e)}", "-"])
    finally:
        os.chdir(orig_dir)

    return result_rows

def main():
    with open(result_file, "w", newline="") as csvfile:
        writer = csv.writer(csvfile)
        writer.writerow(["fuzzer", "subject", "run", "predicted", "empirical", "patch"])

        with ThreadPoolExecutor(max_workers=os.cpu_count()) as executor:
            all_results = executor.map(run_subject, targets)
            for subject_results in all_results:
                for row in subject_results:
                    print("Logged:", row[1], "Run", row[2])
                    writer.writerow(row)

if __name__ == "__main__":
    main()

