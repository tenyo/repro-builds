#!/bin/bash
# Build script to reproduce and validate Coldcard firmware binary on Linux
# The version we are building for should be passed as an argument ($1) to this script
set -e

VER=${1}
ROOT=$(pwd)

echo "Starting coldcard-fw/build-linux.sh script for version ${VER} at $(date) ..."
ls -la stm32

# start the actual build
cd stm32
make repro

# generated and original binaries should be here
ls -la built

# compare the checksum of our output (repro-got.txt) to the original (repro-want.txt), and save output to a file
cd built
echo "Comparing Coldcard firmware (repro-want.txt <=> repro-got.txt) for version ${VER}" | tee "${ROOT}/output.txt"
sha256sum repro-want.txt repro-got.txt | tee -a "${ROOT}/output.txt"
echo "$(sha256sum repro-want.txt | awk '{print $1}') repro-got.txt" | sha256sum --check | tee -a "${ROOT}/output.txt"
SHAERR=${PIPESTATUS[1]}
if [ ${SHAERR} -eq 0 ]; then
   echo "OK: builds are identical" | tee -a "${ROOT}/output.txt"
else
   echo "FAIL: builds are different!" | tee -a "${ROOT}/output.txt"
   exit ${SHAERR}
fi
