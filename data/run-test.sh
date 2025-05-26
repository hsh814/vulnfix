#!/bin/bash

set -e

EPSILON="0.01"
#SAMPLE_PATH=dafl-samples/dafl-single-2025-05-15
SAMPLE_PATH=evocatio-samples/evocatio-2025-04-28
#SAMPLE_PATH=afl-samples/afl-2025-04-30

SUBJECTS=(
  binutils/cve_2017_6965
  binutils/cve_2017_14745
  binutils/cve_2017_15025
  coreutils/gnubug_19784
  coreutils/gnubug_25003
  coreutils/gnubug_25023
  coreutils/gnubug_26545
  jasper/cve_2016_8691
  jasper/cve_2016_9557
  libjpeg/cve_2012_2806
  libjpeg/cve_2017_15232
  libming/cve_2016_9264
  libtiff/bugzilla_2633
  libtiff/cve_2016_5321
  libtiff/cve_2016_9532
  libtiff/cve_2016_10094
  libtiff/cve_2017_7595
  libtiff/cve_2017_7599
  libtiff/cve_2017_7600
  libtiff/cve_2017_7601
  libxml2/cve_2012_5134
  libxml2/cve_2016_1838
  libxml2/cve_2016_1839
  libxml2/cve_2017_5969
  zziplib/cve_2017_5974
  zziplib/cve_2017_5975
  zziplib/cve_2017_5976
)

# 작업 함수
run_subject() {
  subject="$1"
  echo "[*] Starting $subject"

  cd "$subject" || exit 1

  # 심볼릭 링크 설정
  mkdir -p runtime/afl-out
  rm runtime/afl-out/memory
  ln -s "$(realpath "$SAMPLE_PATH")" runtime/afl-out/memory

  # 로그 디렉토리
  mkdir -p "../../logs/$subject"

  for i in $(seq 1 10); do
    echo "    [>] $subject run $i"
    ./rerun.sh "$EPSILON"
    tail -n 3 runtime/pacfix.log > "../../logs/$subject/run-$i.log"
  done

  echo "[✓] Finished $subject"
}

export -f run_subject
export EPSILON
export EVOCATIO_SAMPLE_PATH

# 병렬 실행
printf "%s\n" "${SUBJECTS[@]}" | parallel -j$(nproc) run_subject {}

echo "[+] All done in parallel!"

