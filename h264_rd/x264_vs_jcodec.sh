#!/bin/bash

DATASET="$1"
EXPIR_ARGS="$2"
REF_ARGS="$3"

if [[ -z $EXPIR_ARGS ]]; then
  EXPIR_ARGS=" "
fi
if [[ -z $REF_ARGS ]]; then
  REF_ARGS=" "
fi

error() {
  local msg="$1"
  echo $msg
  exit -1 
}

. dataset.sh
. enc_jcodec.sh
. enc_x264.sh

JCODEC_ROOT="/tmp/jcodec_${RANDOM}"
ENCODERS=( "x264" "jcodec" )

get_enc_command() {
  local index="$1"

  if [[ 1 == $index ]]; then enc_jcodec__get_enc_command "$JCODEC_ROOT" "$@"; fi
  if [[ 0 == $index ]]; then enc_x264__get_enc_command "$@";fi
}

parse_result() {
  local index="$1"

  if [[ 1 == $index ]]; then enc_jcodec__parse_result "$JCODEC_ROOT" "$@"; fi
  if [[ 0 == $index ]]; then enc_x264__parse_result "$@"; fi
}

get_label() {
  local index="$1"
  
  echo ${ENCODERS[$index]}
}

#### MAIN

# Download the dataset
download_dataset

enc_jcodec__build "$JCODEC_ROOT"
enc_x264__build

QP_SEQ="15 4 47"

# The RD curve generation engine
COMPRESSI_BASE="../compressi"
. $COMPRESSI_BASE/compressi.sh

# Sending out reports
echo "Created file $HTML"
