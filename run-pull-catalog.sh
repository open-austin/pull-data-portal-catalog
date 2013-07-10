#!/bin/sh

PULL_SCRIPT="`dirname $0`/pull-catalog.rb"

HOST="data.austintexas.gov"
SAVE_DIR="/srv/www/data.open-austin.org/html/data-catalogs"

DATESTAMP=`date +'%Y%m%d'`
HOSTMUNGED=`echo "$HOST" | sed -e 's/\./_/g'`
SAVE_FILE="${SAVE_DIR}/catalog-${HOSTMUNGED}-${DATESTAMP}.json"
TEMP_FILE="$SAVE_FILE.$$"

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
echo "$0: pull complete - output saved to: $SAVE_FILE" >&2
exit 0

