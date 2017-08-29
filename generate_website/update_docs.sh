#!/bin/bash

ROOT="$HOME/scripts"
TARGET="$HOME/html"
R="$RANDOM"
DIR="$ROOT/jcodec_$R"
OUT_DIR="$ROOT/out_$R"
mkdir $OUT_DIR
git clone https://github.com/jcodec/jcodec.git $DIR
for file in `find $DIR -name "*.md"`; do
  basename=$(basename $file)
  name=${basename%.*}
  php $ROOT/to_html.php $file > $OUT_DIR/${name}.html
  echo ${name}
done

cp -R $OUT_DIR/* $TARGET/
mv $TARGET/README.html $TARGET/index.html

rm -fR $DIR
rm -fR $OUT_DIR
