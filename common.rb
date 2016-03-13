require 'json'

DEBUG = false
VALID_CLIENT_PARAMS = ['label', 'path', 'name'].freeze
CLIENT_ENDPOINT = '/notify'
SUBSCRIBE_ENDPOINT = '/subscribe'
PUBLISH_ENDPOINT = '/publish'
APP_SECRET = ENV['SYNCMYSHIT_SECRET']
DOWNLOAD_DIR = '/path/to/downloads/'

#########################
# Helpers
#########################

def authorized?(secret)
  secret == APP_SECRET
end

def verify_params(data, *params)
  params.each do |param|
    return false unless data[param.to_s]
  end
  true
end

def parse_json(request)
  request.body.rewind
  parsed_response = JSON.parse(request.body.read)
rescue JSON::ParserError => e
  {}
end

def command_exists?(command)
  ENV['PATH'].split(File::PATH_SEPARATOR).any? {|d| File.exists? File.join(d, command) }
end
