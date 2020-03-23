#!/bin/bash

#JCODEC_DIST="https://github.com/jcodec/jcodec.git"
JCODEC_DIST="$HOME/eclipse-workspace/jcodec/.git"

# Checking dependencies
MVN_BIN=mvn
$MVN_BIN --version > /dev/null 2>&1 || error "maven not installed"
JAVA_BIN=java
$JAVA_BIN -version > /dev/null 2>&1 || error "java not installed"

# Top level codec plugins
enc_jcodec__build() {
  local _jcodec_root="$1"
  local hsh="$2"

  git clone "$JCODEC_DIST" "$_jcodec_root"
  (  
    cd $_jcodec_root
    if [[ ! -z $hsh ]]; then
      git checkout $hsh
    fi
    $MVN_BIN clean install > /dev/null
  )
}

enc_jcodec__get_enc_command() {
  local _jcodec_root="$1"
  local index="$2"
  local extra_args="$3"
  local minq="$4"
  local filepath="$5"
  local filename="$(basename "$5")"
  local out_file="$6"
  local log_file="$7"

  local jcodec_jar="$(ls $_jcodec_root/target/jcodec-*-SNAPSHOT.jar)"
  local jcodec_command="$JAVA_BIN -cp \"${jcodec_jar}\" org.jcodec.api.transcode.TranscodeMain"

  echo "$jcodec_command $JCODEC_ARGS -f y4m -i \"$DATASET_DIR/$filename\" -vcodec h264 --h264Opts=encDecMismatch:true,psnrEn:true,enableRdo:true,rc:cqp,qp:$minq \"${out_file}.264\" >> $log_file 2>&1"
}

enc_jcodec__parse_result() {
  local _jcodec_root="$1"
  local index="$2"
  local log_file="$3"
  local out_file="$4"
  local filepath="$5"
  local filename="$(basename "$filepath")"

  local num="[0-9.]*"
  cat "$log_file" | grep "PSNR " | sed "s/.*AVG:\($num\) Y:$num U:$num V:$num kbps:\($num\).*/\1 \2/g" | tail -1
}
