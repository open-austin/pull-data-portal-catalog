#!/bin/sh

USAGE="usage: $0 [-q] [-H HOST] [-S SAVEDIR]"

: ${HOST:="data.austintexas.gov"}
: ${SAVE_DIR:="/srv/www/data.open-austin.org/html/data-catalogs"}

PULL_SCRIPT="pull-catalog.rb"
SUMMARIZE_SCRIPT="summarize-catalog.rb"

DATESTAMP=`date +'%Y%m%d'`
SAVE_SUBDIR="data/`date +'%Y%m'`"
HOSTMUNGED=`echo "$HOST" | sed -e 's/\./_/g'`
ID_FULL="catalog-full"
ID_REDUCED="catalog-reduced"

SAVE_FILE="${SAVE_SUBDIR}/catalog-${HOSTMUNGED}-${DATESTAMP}.json"
SAVE_LATEST="catalog-${HOSTMUNGED}-LATEST.json"
SUMMARY_FILE="${SAVE_SUBDIR}/summary-${HOSTMUNGED}-${DATESTAMP}.json"
SUMMARY_LATEST="summary-${HOSTMUNGED}-LATEST.json"

quiet=false

while getopts "H:S:q" arg ; do
	case $arg in
	H) HOST=$OPTARG ;;
	S) SAVE_DIR=$OPTARG ;;
	q) quiet=true ;;
	*) echo "$USAGE" >&2 ; exit 1 ;;
	esac
done
shift `expr $OPTIND - 1`
if [ $# -ne 0 ] ; then
	echo "$USAGE" >&2
	exit 1
fi

d=`dirname $0`
if [ "X$d" = "X." ] ; then
	d=`pwd`
fi
PATH="$d:$PATH"
export PATH

if $quiet ; then
	qflag='-q'
	vflag=
else
	qflag=
	vflag='-v'
fi

if [ ! -d "$SAVE_DIR" ] ; then
	echo "$0: destination directory does not exist: $SAVE_DIR" >&2
	exit 1
fi
cd $SAVE_DIR || exit 1
if [ ! -d "$SAVE_SUBDIR" ] ; then
        mkdir -p "$SAVE_SUBDIR"
fi

for file in $SAVE_FILE $SAVE_FILE.gz ; do
	if [ -f $file ] ; then
		echo "$0: will not overwrite destination: $SAVE_DIR/$file" >&2
		exit 1
	fi
done

#
# Pull the metadata from the data portal and save all the contents.
#
SAVE_TEMP="$SAVE_FILE.$$"
$PULL_SCRIPT $qflag $HOST >$SAVE_TEMP
if [ $? -ne 0 ] ; then
	echo "$0: pull failed - output saved to: $SAVE_DIR/$SAVE_TEMP" >&2
	exit 1
fi

mv $SAVE_TEMP $SAVE_FILE
$quiet || echo "$0: catalog dumped to: $SAVE_DIR/$SAVE_FILE" >&2

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
$quiet || echo "$0: summary saved to: $SAVE_DIR/$SUMMARY_FILE" >&2

gzip $vflag $SAVE_FILE
rm -f $SAVE_LATEST.gz
ln -s $SAVE_FILE.gz $SAVE_LATEST.gz
rm -f $SUMMARY_LATEST
ln -s $SUMMARY_FILE $SUMMARY_LATEST

exit 0
