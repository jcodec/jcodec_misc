#!/bin/bash

# Checking dependencies
X264_BIN="x264"
$X264_BIN --help   > /dev/null 2>&1 || error "x264 not found (apt-get install x264)"

X264_ARGS="--no-psy --psnr"

enc_x264__build() {
  echo ""
}

enc_x264__get_enc_command() {
  local index="$1"
  local extra_args="$2"
  local minq="$3"
  local filepath="$4"
  local filename="$(basename "$4")"
  local out_file="$5"
  local log_file="$6"

  echo "$X264_BIN $X264_ARGS -q $minq -o \"${out_file}.264\" \"$DATASET_DIR/$filename\" >> $log_file 2>&1"
}

enc_x264__parse_result() {
  local index="$1"
  local log_file="$2"
  local out_file="$3"
  local filepath="$4"
  local filename="$(basename "$filepath")"

  local num="[0-9.]*"
  cat "$log_file" | grep "PSNR Mean" | sed "s{.*Y:\($num\) U:\($num\) V:\($num\) Avg:\($num\) Global:\($num\) kb/s:\($num\).*{\5 \6{g" | tail -1
}
