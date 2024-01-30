#!/bin/bash

FUZZ_DIR=$(realpath $(dirname "${BASH_SOURCE}"))
source "${FUZZ_DIR}/_fuzz.env"

[ -x "${QEMU_FUZZ}" ] || die "qemu build ${QEMU_FUZZ} not complete."

RUN="${1}"

if [ -z "$1" ]; then
    # Default to the corpus that was most recently updated
    RUN="${MOST_RECENT_RUN}"
fi

echo "${RUN}"

[ -d "${RUN}" ] || die "Run directory ${RUN} not found."

MAX_COV=$(grep cov: "${RUN}"/fuzz-*.log | awk '{print $4}' | sort -n | tail -n 1)

echo "Coverage: ${MAX_COV}"

echo "Functions (per file) covered:"
grep NEW_FUNC "${RUN}"/fuzz-*.log \
  | sed -re 's/.*(\S+) (\S+):([0-9]+)$/\2/' \
  | xargs -L 250 realpath \
  | sed -re "s;^${QEMU_ROOT_DIR}/;;" \
  | sort | uniq --count


N_CRASHES=$(find ${RUN} -iname 'crash*' | wc -l)
echo "${N_CRASHES} crashes so far."
