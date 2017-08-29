#!/bin/bash

ROOT="$HOME/scratch"
if [[ ! -d $ROOT ]]; then
  mkdir $ROOT
fi
SCRIPT_DIR="$( dirname "${BASH_SOURCE[0]}" )"
TARGET="$HOME/html"
if [[ ! -d $TARGET ]]; then
  mkdir $TARGET
fi
R="$RANDOM"
DIR="$ROOT/jcodec_$R"
OUT_DIR="$ROOT/out_$R"
mkdir $OUT_DIR
git clone https://github.com/jcodec/jcodec.git $DIR
for file in `find $DIR -name "*.md"`; do
  basename=$(basename $file)
  name=${basename%.*}
  php $SCRIPT_DIR/to_html.php $file > $OUT_DIR/${name}.html
  echo ${name}
done

cp -R $OUT_DIR/* $TARGET/
mv $TARGET/README.html $TARGET/index.html

rm -fR $DIR
rm -fR $OUT_DIR
