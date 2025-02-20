import os
import sys
from typing import List

def file_sorter(files: List[str]) -> List[str]:
    return sorted(files) #, key=lambda x: int(x.split('-')[1].split('.')[0])


def read_pacfix_log(log_path, subject):
    files = os.listdir(log_path)
    files = file_sorter(filter(lambda x: x.endswith('.log'), files))
    for file in files:
        result = ""
        if file.endswith(".log"):
            with open(os.path.join(log_path, file), 'r') as f:
                lines = f.readlines()
                for line in lines:
                    if line.startswith("# of Pos Valuations :"):
                        tokens = line.split(",")
                        pos_val = int(tokens[0].split(":")[1].strip())
                        neg_val = int(tokens[1].split(":")[1].strip())
                        result = f"={pos_val}+{neg_val}"
                    elif line.startswith("Current Epsilon :"):
                        tokens = line.split("/")
                        patch_val = int(tokens[2].split(":")[1].strip())
                        result = f"{subject}\t{file}\t{patch_val}\t{result}"
                        print(result)
                        break

dir = sys.argv[1]
base = os.path.basename(dir)
log_path = os.path.join(dir, "cludafl_samples")
read_pacfix_log(log_path, base)