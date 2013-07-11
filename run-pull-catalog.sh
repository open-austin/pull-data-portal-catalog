#!/bin/sh

PATH="`dirname $0`:$PATH"
export PATH

PULL_SCRIPT="pull-catalog.rb"
SUMMARIZE_SCRIPT="summarize-catalog.rb"

HOST="data.austintexas.gov"
#SAVE_DIR="/srv/www/data.open-austin.org/html/data-catalogs"
SAVE_DIR="/tmp"

DATESTAMP=`date +'%Y%m%d'`
HOSTMUNGED=`echo "$HOST" | sed -e 's/\./_/g'`
SAVE_FILE="${SAVE_DIR}/catalog-${HOSTMUNGED}-${DATESTAMP}.json"
TEMP_FILE="$SAVE_FILE.$$"
SUMMARY_FILE="${SAVE_DIR}/summary-${HOSTMUNGED}-${DATESTAMP}.json"

if [ ! -d "$SAVE_DIR" ] ; then
	echo "$0: destination directory does not exist: $SAVE_DIR" >&2
	exit 1
fi
if [ -f "$SAVE_FILE" ] ; then
	echo "$0: will not overwrite destination: $SAVE_FILE" >&2
	exit 1
fi

$PULL_SCRIPT $HOST > $TEMP_FILE
if [ $? -ne 0 ] ; then
	echo "$0: pull failed - output saved to: $TEMP_FILE" >&2
	exit 1
fi

mv $TEMP_FILE $SAVE_FILE
echo "$0: metadata saved to: $SAVE_FILE" >&2

$SUMMARIZE_SCRIPT $SAVE_FILE >$SUMMARY_FILE
echo "$0: summary saved to: $SUMMARY_FILE" >&2

exit 0

