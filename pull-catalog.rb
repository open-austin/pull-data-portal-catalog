#!/usr/bin/env ruby

require 'optparse'
require 'net/https'
require 'json/ext'
require 'logger'

def die(args)
  $stderr.puts(args)
  exit(1)
end

USAGE = "Usage: #{$0} [options] host_or_url (try \"--help\" for help)"

$log = Logger.new($stderr)
$log.level = Logger::INFO

oparser = OptionParser.new do |opts|
  opts.banner = "Usage: #{$0} [options]"
  opts.separator ""
  opts.separator "Options:"

  opts.on("-q", "--quiet", "Suppress info messages") do |flag|
    $log.level = (flag ? Logger::NOTICE : Logger::INFO)
  end

  opts.on("-h", "--help", "Show this message") do
    puts opts
    exit
  end

end

begin
  oparser.parse!
rescue OptionParser::InvalidOption => e
  die "#{$0}: #{e} (try \"--help\" for help)"
end

die USAGE unless ARGV.length == 1
arg = ARGV.shift
if arg =~ /^http/
  url = arg
else
  url = "https://#{arg}/api/search/views.json"
end
uri = URI.parse(url)

http = Net::HTTP.new(uri.host, uri.port)
if uri.scheme == "https"
  http.use_ssl = true
  http.verify_mode = OpenSSL::SSL::VERIFY_NONE
end

def http.perform_get(uri)
  $log.info {">>> #{uri}"}
  req = Net::HTTP::Get.new(uri.request_uri)
  res = self.request(req)
  $log.info {"<<< HTTP #{res.code} #{res.message} (size = #{res.body.length})"}
  raise "HTTP get failed [#{res.code} #{res.message}]" unless res.is_a?(Net::HTTPSuccess)
  res
end

data = nil
page = 0
max_datasets = nil
num_datasets = 0
while max_datasets.nil? || num_datasets < max_datasets

  page += 1
  params = {:limitTo => 'TABLES', :limit => 100, :page => page}
  uri.query = URI.encode_www_form(params)

  response = http.perform_get(uri)

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
$log.info {"dumped metadata for #{data['results'].length} datasets"}

