#!/bin/bash

FUZZ_DIR=$(realpath $(dirname "${BASH_SOURCE}"))
source "${FUZZ_DIR}/_fuzz.env"

[ -x "${QEMU_FUZZ}" ] || die "qemu build ${QEMU_FUZZ} not complete."

CORPUS="${1}"

if [ -z "$1" ]; then
    # Default to the corpus that was most recently updated
    CORPUS="${MOST_RECENT_CORPUS}"
fi

echo "${CORPUS}"

[ -d "${CORPUS}" ] || die "Corpus directory ${CORPUS} not found."


DEVICE=$(basename ${CORPUS})
echo "${DEVICE}"


MAX_CORPUS="${CORPUS}_large"

echo "Removing old maximum leftovers"
[ -d "${MAX_CORPUS}" ] && rm -r -I "${MAX_CORPUS}"

mv "${CORPUS}" "${MAX_CORPUS}"


set_qemu_device_vars "${DEVICE}"


mkdir -p "${CORPUS}"

(cd /tmp && "${QEMU_FUZZ}" --fuzz-target=generic-fuzz -use_value_profile=1 -merge=1 "${CORPUS}" "${MAX_CORPUS}")
