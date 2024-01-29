#!/bin/bash -x

FUZZ_DIR=$(realpath $(dirname "${BASH_SOURCE}"))
source "${FUZZ_DIR}/_fuzz.env"

[ -x "${QEMU_COV}" ] || die "qemu build ${QEMU_COV} not complete."

CORPUS="${1}"

if [ -z "$1" ]; then
    # Default to the corpus that was most recently updated
    CORPUS=$(find "${DATA_DIR}" -mindepth 1 -maxdepth 1 | xargs ls -td | head -n 1)
fi

echo "${CORPUS}"

[ -d "${CORPUS}" ] || die "Corpus directory ${CORPUS} not found."


DEVICE=$(basename ${CORPUS})
echo "${DEVICE}"

CORPUS="${DATA_DIR}/${DEVICE}"
OUTDIR="${COV_DIR}/${DEVICE}"
COVFILE="${OUTDIR}/default.profraw"
DATAFILE="${OUTDIR}/default.profdata"
REPORTDIR="${OUTDIR}/report"

mkdir -p "${OUTDIR}"

set_qemu_device_vars "${DEVICE}"


# Run each corpus input once, gather coverage and then exit
# This creates default.profraw
( cd "${OUTDIR}" && ${QEMU_COV} --fuzz-target=generic-fuzz "${CORPUS}"/* )

llvm-profdata-12 merge "-output=${DATAFILE}" "${COVFILE}"
llvm-cov-12 show "${QEMU_COV}" "-instr-profile=${DATAFILE}" --format html "-output-dir=${REPORTDIR}"
llvm-cov-12 export "${QEMU_COV}" "-instr-profile=${DATAFILE}" --format lcov > "${OUTDIR}/coverage.lcov"
