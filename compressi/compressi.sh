#!/bin/bash

if [[ -z $EXPIR_ARGS || -z $DATASET || -z $REF_ARGS ]]; then
  echo "FATAL: EXPIR_ARGS and DATASET and REF_ARGS vars need to be set"
  exit -1
fi

PAD="                                                                      "

encode_one_qp() {
    local filepath="$1"
    local filename="$(basename "$filepath")"
    local minq="$2"
    local extra_args="$3"
    local index="$4"

    local qualifier="${filename}_${minq}_${index}_${extra_args//[^[:alnum:]]/}"
    local script_name="/tmp/${qualifier}.sh"
    local log_file="/tmp/${qualifier}.log"
    local msg="+ $filename @qp $minq"
    local log="${msg}${PAD:${#msg}}"
    local command="$(get_enc_command "$index" "$extra_args" "$minq" "$filepath")"

cat <<XXX > $script_name
    $command > $log_file 2>&1
    echo -e "\r$log"
XXX

    chmod +x $script_name
    echo $script_name
}

process_one_qp() {
    local filename="$(basename $1)"
    local minq="$2"
    local extra_args="$3"
    local index="$4"
    local log_file="/tmp/${filename}_${minq}_${index}_${extra_args//[^[:alnum:]]/}.log"

    local vals=( $(parse_result "$index" "$log_file") )
    echo "{\"filename\":\"${filename%.*}\",\"minq\":\"$minq\",\"psnr1\":\"${vals[0]}\",\"psnr2\":\"${vals[1]}\",\"y_psnr\":\"${vals[2]}\",\"u_psnr\":\"${vals[3]}\",\"v_psnr\":\"${vals[4]}\",\"bps\":\"${vals[5]}\",\"time\":\"${vals[7]}\"}," >> $out
}

encode_one_stream() {
  local filepath="$1"
  local extra_args="$2"
  local out="$3"
  local index="$4"

  for minq in `seq $QP_SEQ`; do
    encode_one_qp "$filepath" "$minq" "$extra_args" "$index"
  done
}

process_one_stream() {
  local filepath="$1"
  local extra_args="$2"
  local out="$3"
  local index="$4"

  for minq in `seq $QP_SEQ`; do
    process_one_qp "$filepath" "$minq" "$extra_args" "$index"
  done
}

encode_one_set() {
  local extra_args=$1
  local out="$2"
  local index="$3"

  # Encoding
  local list="$(get_source_list)"
  for file in $list; do
    encode_one_stream "$file" "$extra_args" "$out" "$index"
  done
}

process_one_set() {
  local extra_args="$1"
  local out="$2"
  local index="$3"

  # Output
  local encoder_args="$ENCODER_ARGS $PROFILE --end-usage=q --limit=$MAX_FRAMES"
  echo "Storing result in $out"
  echo "{" >> $out
  echo "\"encoder\": \"$(get_label $index)\"," >> $out
  echo "\"encoderArgs\": \"$encoder_args\"," >> $out
  echo "\"extraArgs\": \"$extra_args\"," >> $out
  echo "\"maxFrames\": \"$MAX_FRAMES\"," >> $out
  echo "\"profile\": \"$PROFILE\"," >> $out
  echo "\"points\": [" >> $out
  
  local list="$(get_source_list)"
  for file in $list; do
    process_one_stream "$file" "$extra_args" "$out" "$index"
  done
  echo "{\"filename\":\"DUMMY\"}" >> $out
  echo "]" >> $out
  echo "}" >> $out
}

OUT1="data_${RANDOM}.json"
OUT2="data_${RANDOM}.json"
echo "Data 1: $OUT1"
echo "Data 2: $OUT2"

HTML="comp_${RANDOM}.html"
if [[ -z "$REF_ARGS" ]]; then
  REF_ARGS="-q"
fi
commands=$(encode_one_set "$EXPIR_ARGS" "$OUT1" "0"; encode_one_set "$REF_ARGS" "$OUT2" "1" )

echo "$commands" | parallel --eta bash {}

process_one_set "$EXPIR_ARGS" "$OUT1" "0"; process_one_set "$REF_ARGS" "$OUT2" "1"

bash $COMPRESSI_BASE/compressi.html.sh "$(cat $OUT1)" "$(cat $OUT2)" > "$HTML"
