#!/bin/sh

PULL_SCRIPT="`dirname $0`/pull-catalog.rb"
SAVE_FILE="/srv/www/data.open-austin.org/html/data-catalogs/`date +'catalog-data_austintexas_gov-%Y%m%d.json'`"
TEMP_FILE="$SAVE_FILE.$$"

$PULL_SCRIPT > $TEMP_FILE
if [ $? -ne 0 ] ; then
	echo "$0: pull failed - output saved to: $TEMP_FILE" >&2
	exit 1
fi

mv $TEMP_FILE $SAVE_FILE
echo "$0: pull complete - output saved to: $SAVE_FILE" >&2
exit 0

