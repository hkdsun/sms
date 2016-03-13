require 'sinatra'
require 'yaml'
require_relative 'smsclient'
require_relative 'common'

SUBSCRIBED_CLIENT = YAML.load_file('clients.yml')['default_clients'].map(&SMSClient.method(:deserialize))

unless APP_SECRET
  puts "No secret configured..aborting"
  exit 1
end

#########################
# Server Definition
#########################

set :port, 4567

before do
  payload = parse_json(request)
  halt 403 unless authorized?(payload['secret'])
  request.body.rewind
end

get '/' do
  "Nothing to see here"
end

post SUBSCRIBE_ENDPOINT do
  data = parse_json(request)
  halt 400, "Wrong arguments include name, callback_url, callback_port" unless verify_params(data, :name, :callback_url, :callback_port)

  name = data['name']
  callback_url = data['callback_url']
  callback_port = data['callback_port']

  SUBSCRIBED_CLIENT << SMSClient.new(name, callback_url, callback_port)
  "Subscription successfull for client #{name}"
end

post PUBLISH_ENDPOINT do
  data = parse_json(request)
  halt 400, "Wrong arguments. Include #{VALID_CLIENT_PARAMS.join(', ')}" unless verify_params(data, *VALID_CLIENT_PARAMS)

  label = data['label']
  path = data['path']

  response = "Sending messages to clients:\n"
  SUBSCRIBED_CLIENT.each do |client|
    if client.send_notification(data)
      response += "[SUCCESS] client #{client.name}\n"
    else
      response += "[FAILURE] client #{client.name}\n"
    end
  end
  response
end
