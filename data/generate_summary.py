import os
import csv
import subprocess
import sys

if len(sys.argv) != 4:
    print("Usage: python3 script.py <fuzzer> <run> <epsilon>")
    sys.exit(1)

DATE="2025-04-28"
FUZZER = sys.argv[1]
if "evocatio" == FUZZER:
    DATE="2025-04-28"
elif "dafl" == FUZZER:
    DATE="single-2025-05-15"
else:
    DATE="2025-04-30"
RUN = int(sys.argv[2])
EPSILON = float(sys.argv[3])
RESULT_DIR = f"results{RUN}-{FUZZER}-{EPSILON}"
VALS_BASE = f"{FUZZER}-samples/{FUZZER}-{DATE}"
CSV_PATH = f"summary-{FUZZER}-{RUN}-{EPSILON}.csv"

with open(CSV_PATH, "w", newline="") as csvfile:
    writer = csv.writer(csvfile)
    writer.writerow(["subject", "status", "patch", "empirical_error"])

    for filename in os.listdir(RESULT_DIR):
        if not filename.endswith(".log"):
            continue

        filepath = os.path.join(RESULT_DIR, filename)
        with open(filepath) as f:
            lines = f.readlines()
        last = lines[-1].strip() if lines else ""

        subject = filename.replace(".log", "").replace("_", "/", 1)
        status = ""
        patch = "-"
        emp_error = "-"

        if "No Patch Found" in last:
            status = "Sample 부족"
        elif "Patch :" in last:
            patch = last.split("Patch :")[1].strip()
            status = "패치 있음"

            # verify 실행
            try:
                verify_cmd = [
                        "python3", "verify-uniq2.py",
                        f"not ( {patch} )", subject, os.path.join(subject, VALS_BASE, "vals.db")
                ]
                result = subprocess.check_output(verify_cmd).decode()
                emp_rate = "-"
                print(result)
                for line in result.splitlines():
                    if "empirical error rate" in line:
                        emp_error = line.split(":")[-1].strip()
                        break
            except subprocess.CalledProcessError:
                emp_error = "verify 실패"
        else:
            status = "정답 없음"

        writer.writerow([subject, status, patch, emp_error])
