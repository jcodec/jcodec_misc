#!/bin/bash

DATASET="$1"
HASHES=("$2" "$3")

error() {
  local msg="$1"
  echo $msg
  exit -1 
}

. dataset.sh
. enc_jcodec.sh

JCODEC_ROOTS=("/tmp/jcodec_${HASHES[0]}_${RANDOM}" "/tmp/jcodec_${HASHES[1]}_${RANDOM}")

get_enc_command() {
  local index="$1"

  enc_jcodec__get_enc_command "${JCODEC_ROOTS[$index]}" "$@"
}

parse_result() {
  local index="$1"

  enc_jcodec__parse_result "${JCODEC_ROOTS[$index]}" "$@"
}

get_label() {
  local index="$1"
  echo "jcodec@${HASHES[$index]}"
}

#### MAIN

download_dataset

enc_jcodec__build "${JCODEC_ROOTS[0]}" "${HASHES[0]}"
enc_jcodec__build "${JCODEC_ROOTS[1]}" "${HASHES[1]}"

QP_SEQ="15 4 47"
EXPIR_ARGS=" "
REF_ARGS=" "

# The RD curve generation engine
COMPRESSI_BASE="../compressi"
. $COMPRESSI_BASE/compressi.sh

# Sending out reports
echo "Created file $HTML"
