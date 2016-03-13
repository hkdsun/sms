require 'sinatra/base'
require 'thin'
require 'eventmachine'
require_relative 'common'
require_relative 'lib/supervisor'

unless APP_SECRET
  puts "No secret configured..aborting"
  exit 1
end

unless command_exists?('lftp')
  puts "LFTP not found on your system..aborting"
  exit 1
end

def run(opts)

  EM.run do
    Signal.trap("INT")  { EventMachine.stop }
    Signal.trap("TERM") { EventMachine.stop }

    server  = opts[:server] || 'thin'
    host    = opts[:host]   || '0.0.0.0'
    port    = opts[:port]   || '4568'
    web_app = opts[:app]

    dispatch = Rack::Builder.app do
      map '/' do
        run web_app
      end
    end

    unless ['thin', 'hatetepe', 'goliath'].include? server
      raise "Need an EM webserver, but #{server} isn't"
    end

    Rack::Server.start({
      app:    dispatch,
      server: server,
      signals: false,
      Host:   host,
      Port:   port
    })
  end
end

class ClientApp < Sinatra::Base

  configure do
    set :threaded, false
  end

  supervisor = Supervisor.new

  before do
    payload = parse_json(request)
    halt 403 unless authorized?(payload['secret'])
    request.body.rewind
  end

  post CLIENT_ENDPOINT do
    data = parse_json(request)

    puts "Processing request:\n#{data}" if DEBUG
    response = "Processing notification for "
    VALID_CLIENT_PARAMS.each do |key|
      response += "\n#{key}: #{data[key]}"
    end
    puts response
    supervisor.push(data)
  end
end

run app: ClientApp.new
