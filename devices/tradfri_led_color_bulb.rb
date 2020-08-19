require 'net/http'
require 'uri'
require 'color'

class TradfriLedColorBulb < ColorBulb
  def initialize(args)
    super(args['avg_lag_ms'])
    @base_path = URI.parse("http://localhost:5000/pytradfri/bulbs/#{args['hub_id']}")
    @on = false
    # @on, @h, @s, @l = TODO: fetch from lightbulb
  end

  def bulb_on(conf)
    send_cmd('state/1') unless @on
    @on = true
  end

  def bulb_off(conf)
    send_cmd('state/0') if @on
    @on = false
  end

  private

  def send_cmd(cmd)
    uri = URI.parse("#{@base_path}/#{cmd}")
    http = Net::HTTP.new(uri.host, uri.port)
    request = Net::HTTP::Post.new(uri.request_uri)
    http.request(request)
  end
end
