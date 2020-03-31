#!/bin/bash

if [[ -z $EXPIR_ARGS || -z $DATASET || -z $REF_ARGS ]]; then
  echo "FATAL: EXPIR_ARGS and DATASET and REF_ARGS vars need to be set"
  exit -1
fi

PAD="                                                                      "

RUN_ROOT="$(get_run_root)"

encode_one_qp() {
    local filepath="$1"
    local filename="$(basename "$filepath")"
    local minq="$2"
    local extra_args="$3"
    local index="$4"
    local job="$5"

    local qualifier="${filename}_${minq}_${index}_${extra_args//[^[:alnum:]]/}"
    local script_name="${RUN_ROOT}/${qualifier}.sh"
    local log_file="${RUN_ROOT}/${qualifier}.log"
    local out_file="${RUN_ROOT}/${qualifier}"
    local msg="+ $filename @qp $minq"
    local log="${msg}${PAD:${#msg}}"
    local command="$(get_enc_command "$index" "$job" "$extra_args" "$minq" "$filepath" "$out_file" "$log_file")"

cat <<XXX > $script_name
    $command
    echo -e "\r$log"
XXX

    chmod +x $script_name
    echo $script_name
}

process_one_qp() {
    local filepath="$1"
    local filename="$(basename $1)"
    local minq="$2"
    local extra_args="$3"
    local index="$4"
    local job="$5"
    local log_file="${RUN_ROOT}/${filename}_${minq}_${index}_${extra_args//[^[:alnum:]]/}.log"
    local out_file="${RUN_ROOT}/${filename}_${minq}_${index}_${extra_args//[^[:alnum:]]/}"

    local vals=( $(parse_result "$index" "$job" "$log_file" "$out_file" "$filepath") )

    local str="{\"filename\":\"${filename%.*}\",\"minq\":\"$minq\",\"dist\":["
    for (( n = 0; n < ${#vals[@]}; n = n + 2)) do
      str="${str}\"${vals[$n]}\"";
      if [[ $n < $((${#vals[@]} - 2)) ]]; then
        str="${str},"
      fi
    done
    str="${str}],\"rate\":["
    for (( n = 0; n < ${#vals[@]}; n = n + 2)) do
      str="${str}\"${vals[$n+1]}\""
      if [[ $n < $((${#vals[@]} - 2)) ]]; then
        str="${str},"
      fi
    done
    str="${str}]},"
    echo "${str}" >> $out
}

encode_one_set() {
  local extra_args=$1
  local out="$2"
  local index="$3"
  local job=0

  # Encoding
  local list="$(get_source_list)"
  for file in $list; do
    for minq in `seq $QP_SEQ`; do
      encode_one_qp "$file" "$minq" "$extra_args" "$index" "$job"
      job=$(($job+1))
    done
  done
}

process_one_set() {
  local extra_args="$1"
  local out="$2"
  local index="$3"
  local job=0

  # Output
  local encoder_args="$ENCODER_ARGS $PROFILE"
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
    for minq in `seq $QP_SEQ`; do
      process_one_qp "$file" "$minq" "$extra_args" "$index" "$job"
      job=$(($job+1))
    done
  done
  echo "{\"filename\":\"DUMMY\"}" >> $out
  echo "]" >> $out
  echo "}" >> $out
}

echo "Running in $RUN_ROOT"
mkdir -p "$RUN_ROOT"

OUT1="data_${RANDOM}.json"
OUT2="data_${RANDOM}.json"
echo "Data 1: $OUT1"
echo "Data 2: $OUT2"

HTML="comp_${RANDOM}.html"
if [[ -z "$REF_ARGS" ]]; then
  REF_ARGS="-q"
fi
commands=$(encode_one_set "$EXPIR_ARGS" "$OUT1" "0"; encode_one_set "$REF_ARGS" "$OUT2" "1" )

PAR_ARGS=""
if [[ ! -z $N_JOBS ]]; then
  PAR_ARGS="-j $N_JOBS"
  echo "Running $N_JOBS jobs."
fi

echo "$commands" | parallel $PAR_ARGS --eta bash {}

process_one_set "$EXPIR_ARGS" "$OUT1" "0"; process_one_set "$REF_ARGS" "$OUT2" "1"

bash $COMPRESSI_BASE/compressi.html.sh "$(cat $OUT1)" "$(cat $OUT2)" > "$HTML"
