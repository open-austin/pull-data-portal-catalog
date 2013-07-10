#!/usr/bin/env ruby

require 'net/https'
require 'json/ext'
require 'logger'

@log = Logger.new($stderr)
@log.level = Logger::DEBUG

uri = URI.parse("https://data.austintexas.gov/api/search/views.json")

http = Net::HTTP.new(uri.host, uri.port)
if uri.scheme == "https"
  http.use_ssl = true
  http.verify_mode = OpenSSL::SSL::VERIFY_NONE
end

data = nil
page = 0
max_datasets = nil
num_datasets = 0
while max_datasets.nil? || num_datasets < max_datasets

  page += 1
  params = {:limitTo => 'TABLES', :limit => 100, :page => page}
  uri.query = URI.encode_www_form(params)

  @log.debug {">>> #{uri}"}
  request = Net::HTTP::Get.new(uri.request_uri)
  response = http.request(request)
  @log.debug {"<<< HTTP #{response.code} #{response.message} (size = #{response.body.length})"}
  raise "HTTP get failed [#{response.code} #{response.message}]" unless response.is_a?(Net::HTTPSuccess)

  a = JSON.parse(response.body)
  if data.nil?
    data = a
    data['timestamp'] = Time.now.to_i
    max_datasets = data['count'].to_i
    raise "failed to extract dataset 'count'" unless max_datasets > 0
  else
    data['results'] += a['results']
  end
  num_datasets += a['results'].length

end

puts data.to_json
@log.debug {"dumped metadata for #{data['results'].length} datasets"}

