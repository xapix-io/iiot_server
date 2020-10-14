require 'net/http'
require 'uri'
require 'color'

class TradfriLedColorBulb < ColorBulb
  def initialize(args, hub)
    super(args)
    @name = args['name']
    @id = Net::HTTP.get('localhost', "/pytradfri/bulbs/#{@name}/id", 5000).to_i
    @hub_ip = hub.ip
    @base_path = URI.parse("http://localhost:5000/pytradfri/bulbs/#{@id}")
    update_device_status!
    connect!
  end

  def connect!
    puts "Observing light #{@name} on Tradfri hub with IP #{@hub_ip}"
    @pid = Process.spawn("HOST=#{@hub_ip} BULB_ID=#{@id} DEVICE_NAME=#{@device_name} python3 light_observer.py", chdir: "./drivers/tradfri/")
  end

  def close!
    Process.kill("TERM", @pid)
  end

  def update_device_status!
    @on, th, ts, tl = JSON.parse(Net::HTTP.get('localhost', "/pytradfri/bulbs/#{@id}/color_hsb", 5000))
    @h = (th.to_f / 65535 * 360).ceil
    @s = (ts.to_f / 65279 * 100).ceil
    @l = (tl.to_f / 254 * 100).ceil
  end

  def to_h
    { 'id' => @id, 'name' => @name, 'on' => @on, 'h' => @h, 's' => @s, 'l' => @l, 'hsl' => "#{@h},#{@s},#{@l}" }
  end

  def bulb_on(conf)
    update_device_status!
    send_cmd('state/1') unless @on
    change_color(conf)
  end

  def bulb_off(conf)
    update_device_status!
    change_color(conf)
    send_cmd('state/0') if @on
  end

  def flash_color(conf)
    #TODO d = conf['fade_ms'] || 0
    update_device_status!
    o_conf = to_h
    send_cmd('state/1') unless @on 
    change_color(conf)
    sleep (conf['duration_ms'] || 0).to_f / 1000
    change_color(o_conf.merge(conf.slice('fade_ms')))
    send_cmd('state/0') unless o_conf['on']
  end

  def flash_brightness(conf)
    #TODO d = conf['fade_ms'] || 0
    update_device_status!
    o_conf = to_h
    send_cmd('state/1') unless @on 
    th, ts, tl = convert_tradfri_hsb(@h, @s, @l + conf['by_pc'])
    send_cmd("color_hsb/#{th}/#{ts}/#{tl}")
    sleep (conf['duration_ms'] || 0).to_f / 1000
    th, ts, tl = convert_tradfri_hsb(@h, @s, @l)
    send_cmd("color_hsb/#{th}/#{ts}/#{tl}")
    send_cmd('state/0') unless o_conf['on']
  end

  private

  def equals_current_color?(compare)
    to_h.slice('h', 's', 'l') == compare.slice('h', 's', 'l')
  end

  def convert_tradfri_hsb(h, s, l)
    [(h * 65535 / 360).to_i, (s * 65279 / 100).to_i, (l * 254 / 100).to_i]
  end

  def change_color(conf)
    #TODO d = conf['fade_ms'] || 0
    old_conf = to_h
    @h, @s, @l = convert_hsl(conf)
    if !conf.empty? && !equals_current_color?(old_conf)
      th, ts, tl = convert_tradfri_hsb(@h, @s, @l)
      send_cmd("color_hsb/#{th}/#{ts}/#{tl}")
    end
  end

  def send_cmd(cmd)
    uri = URI.parse("#{@base_path}/#{cmd}")
    http = Net::HTTP.new(uri.host, uri.port)
    request = Net::HTTP::Post.new(uri.request_uri)
    http.request(request)
  end
end
