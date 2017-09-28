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

[[ -z "${DEV}" ]] && R="$RANDOM" || R="dev"


DIR="$ROOT/jcodec_$R"
OUT_DIR="$ROOT/out_$R"
[[ -d $OUT_DIR ]] || mkdir $OUT_DIR

if [[ -z $DEV || ! -d $DIR ]]; then
	git clone https://github.com/jcodec/jcodec.git $DIR
fi

SAME_LEVEL="$(cd $DIR; ls -dm *.md | tr -d '\n ')"
DOCS_LEVEL="$(cd $DIR/docs; ls -dm *.md | tr -d '\n ')"

for file in `(cd $DIR; find . -name "*.md")`; do
  name=${file%.*}
  path="$(dirname $OUT_DIR/${name})"
  [[ -d $path ]] || mkdir $path
  php $SCRIPT_DIR/to_html.php "$DIR/$file" $SAME_LEVEL $DOCS_LEVEL > $OUT_DIR/${name}.html
  echo ${name}
done
php $SCRIPT_DIR/to_html.php "$DIR/LICENSE" $SAME_LEVEL $DOCS_LEVEL > $OUT_DIR/LICENSE.html

cp -R $OUT_DIR/* $TARGET/
mv $TARGET/README.html $TARGET/index.html

if [[ -z $DEV ]]; then
  rm -fR $DIR
  rm -fR $OUT_DIR
fi
