require 'yeelight'
require 'color'

class YeelightLedColorBulb < ColorBulb
  def initialize(args)
    super(args['avg_lag_ms'])
    @client = Yeelight::Client.new(args['ip'], 55443)
    @on = false
    # @on, @h, @s, @l = TODO: fetch from lightbulb
  end

  def bulb_on(conf)
    @client.on unless @on
    @on = true
    change_color(conf) unless conf.empty?
  end

  def bulb_off(conf)
    change_color(conf) unless conf.empty?
    @client.off if @on
    @on = false
  end

  def flash_color(conf)
    o_conf = { 'h' => @h, 's' => @s, 'l' => @l }
    change_color(conf)
    sleep (conf['duration_ms'] || 0).to_f / 1000
    change_color(o_conf.merge(conf.slice('fade_ms', 'effect')))
  end

  def flash_brightness(conf)
    e = conf['effect'] || 'smooth'
    d = conf['fade_ms'] || 0
    @client.set_bright(@l + conf['by_pc'], e, d)
    sleep (conf['duration_ms'] || 0).to_f / 1000
    @client.set_bright(@l, e, d)
  end

  def self.discover
    Yeelight::Client.discover
  end

  private

  def change_color(conf)
    e = conf['effect'] || 'smooth'
    d = conf['fade_ms'] || 0
    @h, @s, @l =
      if (name = conf['color'])
        hsl = Color::CSS[name].to_hsl
        [hsl.hue, hsl.saturation, hsl.brightness * 100]
      else
        [conf['h'], conf['s'], conf['l']]
      end
    @client.set_hsv(@h, @s, e, d)
    @client.set_bright(@l, e, d)
  end
end
