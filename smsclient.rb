require 'faraday'

class SMSClient
  attr_accessor :name, :url, :port

  class << self
    def deserialize(hash)
      new(hash['name'], hash['callback_url'], hash['callback_port'])
    end
  end

  def initialize(name, callback_url, callback_port)
    @name = name
    @url = callback_url
    @port = callback_port
  end

  def send_notification(params = {})
    payload = {
        secret: APP_SECRET,
        timestamp: Time.now.utc,
    }.merge(params)

    begin
      response = http_post(payload)
      true unless response.status != 200
    rescue Faraday::Error => e
      false
    end
  end

  private

  def http_post(hash)
    conn = Faraday.new(url: @url) do |faraday|
      faraday.request  :url_encoded
      faraday.response :logger if DEBUG
      faraday.adapter  Faraday.default_adapter
    end

    conn.post do |req|
      req.options.timeout = 5
      req.options.open_timeout = 2
      req.url CLIENT_ENDPOINT
      req.headers['Content-Type'] = 'application/json'
      req.body = JSON.generate(hash)
    end
  end
end
