#!/bin/sh

: ${HOST:="data.austintexas.gov"}
: ${SAVE_DIR:="/srv/www/data.open-austin.org/html/data-catalogs"}

PULL_SCRIPT="pull-catalog.rb"
SUMMARIZE_SCRIPT="summarize-catalog.rb"

DATESTAMP=`date +'%Y%m%d'`
HOSTMUNGED=`echo "$HOST" | sed -e 's/\./_/g'`
SAVE_FILE="catalog-${HOSTMUNGED}-${DATESTAMP}.json"
SAVE_LATEST="catalog-${HOSTMUNGED}-LATEST.json"
SAVE_TEMP="$SAVE_FILE.$$"
SUMMARY_FILE="summary-${HOSTMUNGED}-${DATESTAMP}.json"
SUMMARY_LATEST="summary-${HOSTMUNGED}-LATEST.json"

d=`dirname $0`
if [ "X$d" = "X." ] ; then
	d=`pwd`
fi
PATH="$d:$PATH"
export PATH

if [ ! -d "$SAVE_DIR" ] ; then
	echo "$0: destination directory does not exist: $SAVE_DIR" >&2
	exit 1
fi
cd $SAVE_DIR || exit 1

if [ -f "$SAVE_FILE" ] ; then
	echo "$0: will not overwrite destination: $SAVE_DIR/$SAVE_FILE" >&2
	exit 1
fi

$PULL_SCRIPT $HOST > $SAVE_TEMP
if [ $? -ne 0 ] ; then
	echo "$0: pull failed - output saved to: $SAVE_DIR/$SAVE_TEMP" >&2
	exit 1
fi

mv $SAVE_TEMP $SAVE_FILE
echo "$0: catalog dumped to: $SAVE_DIR/$SAVE_FILE" >&2

$SUMMARIZE_SCRIPT $SAVE_FILE >$SUMMARY_FILE
echo "$0: summary saved to: $SAVE_DIR/$SUMMARY_FILE" >&2

rm -f $SAVE_LATEST $SUMMARY_LATEST
ln -s $SAVE_FILE $SAVE_LATEST
ln -s $SUMMARY_FILE $SUMMARY_LATEST

exit 0

