#!/bin/bash

# Downloading a test set
[[ -f ${DATASET}.set ]] || error "Unknown dataset $DATASET"
DATASET_CACHE=/tmp/dataset
DATASET_DIR="$DATASET_CACHE/$DATASET"

download_dataset() {
  if [[ ! -e $DATASET_DIR ]]; then
    echo "Downloading dataset $DATASET into $DATASET_DIR"
    mkdir -p "$DATASET_DIR"
    for url in `cat ${DATASET}.set`; do
      wget -O "$DATASET_DIR/$(basename "$url")" "$url"
    done
  fi
}

YUV_DIR="$DATASET_CACHE"

get_source_list() {
  ls "$YUV_DIR/$DATASET" | grep "yuv\|y4m\$"
}

