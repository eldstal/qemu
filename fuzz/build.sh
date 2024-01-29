#!/bin/bash

FUZZ_DIR=$(realpath $(dirname "${BASH_SOURCE}"))
source "${FUZZ_DIR}/_fuzz.env"

QEMU_BUILD_FUZZ="$(dirname ${QEMU_FUZZ})"
QEMU_BUILD_COV="$(dirname ${QEMU_COV})"

export CC=clang-12
export CXX=clang++-12

function mkdir_and_configure {

  local BUILD_DIR="${1}"
  shift

  [ -d "${BUILD_DIR}" ] && return

  mkdir -p "${BUILD_DIR}"
  (cd "${BUILD_DIR}" &&
      ${QEMU_ROOT_DIR}/configure "${@}"
  )

}


mkdir_and_configure "${QEMU_BUILD_FUZZ}" \
          --target-list=x86_64-softmmu,i386-softmmu \
          --enable-fuzzing --enable-sanitizers \
&& (cd "${QEMU_BUILD_FUZZ}" && make -j6) \
&& mkdir_and_configure "${QEMU_BUILD_COV}" \
          --target-list=x86_64-softmmu,i386-softmmu \
          --enable-fuzzing --enable-sanitizers \
          --extra-cflags="-fprofile-instr-generate -fcoverage-mapping" \
&& (cd "${QEMU_BUILD_COV}" && make -j6)
