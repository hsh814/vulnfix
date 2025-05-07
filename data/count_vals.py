import os
import hashlib
import sys

def md5_hash(file_path):
    hash_md5 = hashlib.md5()
    with open(file_path, "rb") as f:
        for chunk in iter(lambda: f.read(4096), b""):
            hash_md5.update(chunk)
    return hash_md5.hexdigest()

def count_files_and_unique(target_dir):
    pos_dir = os.path.join(target_dir, "pos")
    neg_dir = os.path.join(target_dir, "neg")

    pos_files = [os.path.join(pos_dir, f) for f in os.listdir(pos_dir) if os.path.isfile(os.path.join(pos_dir, f))]
    neg_files = [os.path.join(neg_dir, f) for f in os.listdir(neg_dir) if os.path.isfile(os.path.join(neg_dir, f))]

    pos_unique_hashes = set()
    neg_unique_hashes = set()

    for file_path in pos_files:
        file_hash = md5_hash(file_path)
        pos_unique_hashes.add(file_hash)
    for file_path in neg_files:
        file_hash = md5_hash(file_path)
        neg_unique_hashes.add(file_hash)

    print(f"{target_dir}\t{len(pos_files)}\t{len(neg_files)}\t{len(pos_unique_hashes)}\t{len(neg_unique_hashes)}")

target_dir = sys.argv[1]
count_files_and_unique(target_dir)
