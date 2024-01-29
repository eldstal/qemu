#!/bin/bash

FUZZ_DIR=$(realpath $(dirname "${BASH_SOURCE}"))
source "${FUZZ_DIR}/_fuzz.env"

[ -x "${QEMU_FUZZ}" ] || die "qemu build ${QEMU_FUZZ} not complete."

DEVICE=${1:-isa-ide}
shift

set_qemu_device_vars "${DEVICE}"

RUN_DIR="${RUNS_DIR}/${DEVICE}/$(date +%F_%H.%M.%S)"
CORPUS="${DATA_DIR}/${DEVICE}"

if [ -n "$TEST" ]; then
    EXTRA_ARGS="-runs=0"
fi

mkdir -p "${RUN_DIR}"
mkdir -p "${CORPUS}"

echo "Run info in ${RUN_DIR}"
(cd ${RUN_DIR} && "${QEMU_FUZZ}" --fuzz-target=generic-fuzz -use_value_profile=1 ${EXTRA_ARGS} "${@}" "${CORPUS}")
