#! /bin/bash -xv

OUTPUT_FOLDER=build
DUMP_URL=https://dumps.wikimedia.org/other/static_html_dumps/2008-06/he/wikipedia-he-html.tar.7z
DUMP_NAME=wikipedia-he-html

mkdir -p $OUTPUT_FOLDER
curl -s -o $OUTPUT_FOLDER/$DUMP_NAME.tar.7z "$DUMP_URL"