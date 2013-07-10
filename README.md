Pull Data Portal Catalog
========================

Pull all the metatdata on datasets published at data.austintexas.gov
and dump a JSON structure to stdout.

Elements are:
* count: number of data catalogs
* searchType: "views"
* timestamp: time at which pull occurred, integer seconds since epoch
* results: array of catalog metadata, one entry per dataset

The accompanying "run-pull-catalog.sh" is designed to be run
nightly from cron, to capture a dump to data.open-austin.org.

