#!/bin/sh

: ${HOST:="data.austintexas.gov"}
: ${SAVE_DIR:="/srv/www/data.open-austin.org/html/data-catalogs/data"}

PULL_SCRIPT="pull-catalog.rb"
SUMMARIZE_SCRIPT="summarize-catalog.rb"

DATESTAMP=`date +'%Y%m%d'`
MONTHSTAMP=`date +'%Y%m'`
HOSTMUNGED=`echo "$HOST" | sed -e 's/\./_/g'`
ID_FULL="catalog-full"
ID_REDUCED="catalog-reduced"

SAVE_FILE="${MONTHSTAMP}/catalog-${HOSTMUNGED}-${DATESTAMP}.json"
SAVE_LATEST="catalog-${HOSTMUNGED}-LATEST.json"
SUMMARY_FILE="${MONTHSTAMP}/summary-${HOSTMUNGED}-${DATESTAMP}.json"
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
if [ ! -d "$MONTHSTAMP" ] ; then
        mkdir -p "$MONTHSTAMP"
fi

if [ -f "$SAVE_FILE" ] ; then
	echo "$0: will not overwrite destination: $SAVE_DIR/$SAVE_FILE" >&2
	exit 1
fi

#
# Pull the metadata from the data portal and save all the contents.
#
SAVE_TEMP="$SAVE_FILE.$$"
$PULL_SCRIPT $HOST >$SAVE_TEMP
if [ $? -ne 0 ] ; then
	echo "$0: pull failed - output saved to: $SAVE_DIR/$SAVE_TEMP" >&2
	exit 1
fi

mv $SAVE_TEMP $SAVE_FILE
echo "$0: catalog dumped to: $SAVE_DIR/$SAVE_FILE" >&2

#
# Process the full metadata dump to a reduced (more usable) set.
#
SUMMARY_TEMP="$SUMMARY_FILE.$$"
$SUMMARIZE_SCRIPT $SAVE_FILE >$SUMMARY_TEMP
if [ $? -ne 0 ] ; then
	echo "$0: summary failed - output saved to: $SAVE_DIR/$SUMMARY_TEMP" >&2
	exit 1
fi

mv $SUMMARY_TEMP $SUMMARY_FILE
echo "$0: summary saved to: $SAVE_DIR/$SUMMARY_FILE" >&2

gzip -v $SAVE_FILE
rm -f $SAVE_LATEST.gz
ln -s $SAVE_FILE.gz $SAVE_LATEST.gz
rm -f $SUMMARY_LATEST
ln -s $SUMMARY_FILE $SUMMARY_LATEST

exit 0

