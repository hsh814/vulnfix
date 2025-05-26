import os
import hashlib
import sys
import sqlite3
from tqdm import tqdm
import datetime

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
            if "dafl-samples" in file_path:
                if file_name == "exploit":
                    val_time = 0
                else:
                    tokens = file_name.split(",")
                    time = int(tokens[1])
            elif "evocatio-samples" in file_path or "afl-samples" in file_path:
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
    
target_dir = sys.argv[1]
db_file = os.path.join(target_dir, "vals.db")
if os.path.exists(db_file):
    timestamp = datetime.datetime.now().strftime("%Y%m%d_%H%M%S")
    backup_file = f"{db_file}.{timestamp}.bak"
    try:
        os.rename(db_file, backup_file)
    except OSError as e:
        print(f"Failed to backup file {db_file} {e}")
conn = sqlite3.connect(db_file)
init_sqlite(conn)
save_files(conn, os.path.join(target_dir, "pos"), True)
save_files(conn, os.path.join(target_dir, "neg"), False)
conn.close()