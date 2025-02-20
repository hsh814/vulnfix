#!/bin/bash
SRC_BASE="/home/yuntong/vulnfix/data"
DST_BASE="backup-20241226/data"

# find 명령으로 aflrun_out 디렉토리 검색 및 복사
find "$SRC_BASE" -type d -name "aflrun_out" | while read -r dir; do
    # 상대 경로 계산
    REL_PATH=${dir#$SRC_BASE/}
    # 복사 대상 디렉토리 경로 생성
    DEST_DIR="$DST_BASE/${REL_PATH%/aflrun_out}"
    # 대상 디렉토리 생성
    mkdir -p "$DEST_DIR"
    # aflrun_out 디렉토리 복사
    cp -r "$dir" "$DEST_DIR/"
    echo "Copied $dir to $DEST_DIR"
done