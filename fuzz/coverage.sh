#!/bin/bash

FUZZ_DIR=$(realpath $(dirname "${BASH_SOURCE}"))
source "${FUZZ_DIR}/_fuzz.env"

[ -x "${QEMU_COV}" ] || die "qemu build ${QEMU_COV} not complete."

CORPUS="${1}"

if [ -z "$1" ]; then
    # Default to the corpus that was most recently updated
    CORPUS="${MOST_RECENT_CORPUS}"
fi

echo "${CORPUS}"

[ -d "${CORPUS}" ] || die "Corpus directory ${CORPUS} not found."


DEVICE=$(basename ${CORPUS})
echo "${DEVICE}"

OUTDIR="${COV_DIR}/${DEVICE}"
COVFILE="${OUTDIR}/default.profraw"
DATAFILE="${OUTDIR}/default.profdata"
REPORTDIR="${OUTDIR}/report"

mkdir -p "${OUTDIR}"

set_qemu_device_vars "${DEVICE}"


# Run each corpus input once, gather coverage and then exit
# This creates default.profraw.0 etc
# It may create multiples, if there are too many inputs in the corpus for
# one single invocation
INPUT_CHUNK=150
N_INPUTS=$(find "${CORPUS}" -type f | wc -l);
for START in $(seq 0 ${INPUT_CHUNK} ${N_INPUTS}); do
  echo "${START}"
  ( cd "${OUTDIR}" && \
    find "${CORPUS}" -type f | sort | tail -n +${START} | head -n ${INPUT_CHUNK} \
    | LLVM_PROFILE_FILE="${COVFILE}.${START}" xargs --no-run-if-empty ${QEMU_COV} --fuzz-target=generic-fuzz )
done

llvm-profdata-12 merge "-output=${DATAFILE}" "${COVFILE}".*
llvm-cov-12 show "${QEMU_COV}" "-instr-profile=${DATAFILE}" --format html "-output-dir=${REPORTDIR}"
llvm-cov-12 export "${QEMU_COV}" "-instr-profile=${DATAFILE}" --format lcov > "${OUTDIR}/coverage.lcov"
