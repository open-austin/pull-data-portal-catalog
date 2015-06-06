#!/usr/bin/env ruby

require 'json/ext'

USAGE = "Usage: #{$0} metadata.json"

def die(args)
  $stderr.puts(args)
  exit(1)
end

die USAGE unless ARGV.length == 1
filename = ARGV.shift

# Slurp in the full catalog.
data = open(filename) {|fp| JSON.parse(fp.read)}

# Build a summarized list of datsets from data['results']
datasets = []

data['results'].each do |dataset|
  a = dataset['view']

puts "===========\n"
require "pp" ; pp a

  #
  # The "metadata" object is mostly boring, but the City of Austin
  # uses the "custom_fields" to indicate things such as
  # departments and update frequency.
  #
  metadata = a['metadata'] || {}
  a['customFields'] = metadata['custom_fields']


  #
  # Believe it or not, Socrata does not provide any information on
  # the dataset size in the metadata. It does, however, provide
  # a detailed listing of the columns, including the count of non-null
  # values for the column. We'll pick the largest such count to be
  # the dataset row count.
  #
  a['rowCount'] = a['columns'].map do |b|
    b.has_key?('cachedContents') ? b['cachedContents']['non_null'] : 0
  end.max

  #
  # The following elements are nested objects and arrays that probably
  # aren't going to be useful for analysis. So, remove them.
  #
  %w(
    columns
    flags
    grants
    metadata
    owner
    query
    rights
    sortBys
    tableAuthor
    viewFilters
  ).each {|key| a.delete(key)}

  datasets << a
end

# Drop the detailed metadata and add the summary list.
data.delete('results')
data['datasets'] = datasets

puts data.to_json

