import re
import os
import sys
import shutil
import random
import string
import threading
import subprocess
from tqdm import tqdm
import concurrent.futures
import sqlite3
import hashlib
import datetime

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
max_threads = 30
max_processes = 30
out_postfix = ""
mode = ""

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
            result = subprocess.run(cmd, env=temp_env, stdout=subprocess.PIPE, stderr=subprocess.PIPE, cwd=os.path.join(base_path, "evocatio-runtime"), shell=True, timeout=30)
    except subprocess.TimeoutExpired as e:
        if os.path.exists(pacfix_filename):
            os.remove(pacfix_filename)
        return -1, ""
    finally:
        if os.path.exists(temp_file):
            os.remove(temp_file)
    ret_code = result.returncode
    err_result = result.stderr.decode('utf-8', errors='ignore')
    return ret_code, err_result

def get_line(sample_dir: str = ""):
    global target
    rc, errlog = run_target(base_path + "/exploit", "exploit")
    print(errlog)
    if sample_dir == "":
        target = extract_file_and_line(errlog)
    else:
        dest_file = os.path.join(sample_dir, "neg", "exploit")
        shutil.move(valfile + out_postfix + "exploit", dest_file)
    # os.remove(valfile + "exploit")

def initialize():
    if len(sys.argv) != 5:
        print("Usage: python3 get_val.py <subject> <id> <mode> <seed-dir>")
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
    global mode

    subject = sys.argv[1]
    out_postfix = sys.argv[2]
    if len(sys.argv) > 3:
        mode = sys.argv[3]
        seed_save_base_dir = sys.argv[4]
    base_path = os.path.join(base_path, subject)
    config_path = base_path + "/config"
    valuation_exe = base_path + "/runtime/"
    valfile = base_path + "/val_file"
    os.makedirs(os.path.join(base_path, "evocatio-runtime"), exist_ok=True)

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

def process_worker(testcase_file, sample_dir, out_dir) -> bool:
    try:
        ret_code, err_result = run_target(os.path.join(out_dir, testcase_file), os.path.basename(testcase_file))
        if ret_code != -1:
            is_neg = False
            dest_dir = sample_dir + "/pos/" + testcase_file
            if target == extract_file_and_line(err_result):
                is_neg = True
                dest_dir = sample_dir + "/neg/" + testcase_file
            shutil.move(valfile + out_postfix + str(testcase_file), dest_dir)
            return True
    except Exception as e:
        print(f"Run ID {testcase_file} failed with error: {e}")
        import traceback
        traceback.print_exc()
    return False

def create_directory(dir_path):
    if os.path.exists(dir_path):
        print(f"Directory already exists - remove: {dir_path}")
        shutil.rmtree(dir_path)
    os.makedirs(dir_path)
    print(f"Directory created: {dir_path}")
        

def init_sqlite(conn):
    cursor = conn.cursor()
    cursor.execute("""
    CREATE TABLE IF NOT EXISTS val (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        md5_hash TEXT UNIQUE NOT NULL,
        content BLOB NOT NULL
    )
    """)
    cursor.execute("""
    CREATE TABLE IF NOT EXISTS file (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        path TEXT NOT NULL UNIQUE,
        is_pos INTEGER NOT NULL, -- 1 for pos, 0 for neg
        val_id INTEGER NOT NULL,
        time INTEGER NOT NULL,
        FOREIGN KEY (val_id) REFERENCES val (id)
    )
    """)
    cursor.execute("CREATE INDEX IF NOT EXISTS idx_val_md5_hash ON val (md5_hash)")
    cursor.execute("CREATE INDEX IF NOT EXISTS idx_file_path ON file (path)")
    cursor.execute("CREATE INDEX IF NOT EXISTS idx_file_val_id ON file (val_id)")
    conn.commit()

def md5_hash(file_path):
    hash_md5 = hashlib.md5()
    with open(file_path, "rb") as f:
        for chunk in iter(lambda: f.read(4096), b""):
            hash_md5.update(chunk)
    return hash_md5.hexdigest()

def get_file_content(file_path):
    try:
        with open(file_path, "rb") as f:
            return f.read()
    except IOError:
        print(f"Error: Could not read file content for {file_path}")
        return None


def save_files(conn, dir, is_pos):
    cursor = conn.cursor()
    files = [os.path.join(dir, f) for f in os.listdir(dir) if os.path.isfile(os.path.join(dir, f))]
    count = 0
    for file_path in tqdm(files, desc=f"Processing files in {dir}"):
        cursor.execute("SELECT id FROM file WHERE path = ?", (file_path,))
        if cursor.fetchone():
            continue
        current_md5 = md5_hash(file_path)
        if not current_md5:
            continue
        val_id = None
        cursor.execute("SELECT id FROM val WHERE md5_hash = ?", (current_md5,))
        row = cursor.fetchone()
        if row:
            val_id = row[0]
        else:
            file_content = get_file_content(file_path)
            if file_content is None:
                continue
            try:
                cursor.execute("INSERT INTO val (md5_hash, content) VALUES (?, ?)", (current_md5, sqlite3.Binary(file_content)))
                val_id = cursor.lastrowid
            except sqlite3.IntegrityError:
                conn.rollback()
                cursor.execute("SELECT id FROM val WHERE md5_hash = ?", (current_md5,))
                row = cursor.fetchone()
                if row:
                    val_id = row[0]
                else:
                    print(f"Critical error: cannot insert or find val for {file_path}, md5 {current_md5}")
                    continue
        if val_id is not None:
            file_name = os.path.basename(file_path)
            val_time = 0
            if mode == "dafl":
                if file_name == "exploit":
                    val_time = 0
                else:
                    tokens = file_name.split(",")
                    time = int(tokens[1])
            elif mode in ["evocatio", "afl"]:
                if file_name == "exploit":
                    val_time = 0
                else:
                    val_time = int(file_name.split("_")[2])

            try:
                cursor.execute("INSERT INTO file (name, path, is_pos, time, val_id) VALUES (?, ?, ?, ?, ?)",
                               (file_name, file_path, is_pos, val_time, val_id))
                count += 1
            except sqlite3.IntegrityError:
                conn.rollback()
        if count % 1000 == 0:
            conn.commit()
    conn.commit()

if __name__ == "__main__":
    initialize()
    out_dir = os.path.join(seed_save_base_dir, subject, "seeds")
    print(f"Out: {out_dir}")
    
    sample_dir = os.path.join(base_path, f"{mode}-samples", f"{out_postfix}")
    create_directory(sample_dir)
    create_directory(os.path.join(sample_dir, "pos"))
    create_directory(os.path.join(sample_dir, "neg"))
    get_line(sample_dir)

    aflrun_tc = get_testcases(out_dir)
    with concurrent.futures.ProcessPoolExecutor(max_workers=max_processes) as executor:
        futures = [executor.submit(process_worker, tc_file, sample_dir, out_dir) for tc_file in aflrun_tc]
    
        for future in tqdm(concurrent.futures.as_completed(futures), total=len(aflrun_tc), desc=f"processing {subject}"):
            try:
                result = future.result()
            except Exception as e:
                tqdm.write(f"A process generated an exception {e}")
    
    db_file = os.path.join(sample_dir, "vals.db")
    if os.path.exists(db_file):
        timestamp = datetime.datetime.now().strftime("%Y%m%d_%H%M%S")
        backup_file = f"{db_file}.{timestamp}.bak"
        try:
            os.rename(db_file, backup_file)
        except OSError as e:
            print(f"Failed to backup file {db_file} {e}")
    conn = sqlite3.connect(db_file)
    init_sqlite(conn)
    save_files(conn, os.path.join(sample_dir, "pos"), True)
    save_files(conn, os.path.join(sample_dir, "neg"), False)
    conn.close()
        