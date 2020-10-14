require 'color'

class ColorBulb < Device
  def bulb_on(_conf); raise(NotImplementedError); end
  def bulb_off(_conf); raise(NotImplementedError); end
  def flash_color(_conf); raise(NotImplementedError); end
  def flash_brightness(_conf); raise(NotImplementedError); end

  def convert_hsl(conf)
    if (name = conf['color'])
      hsl = Color::CSS[name].to_hsl
      [hsl.hue, hsl.saturation, hsl.brightness * 100]
    else
      [conf['h'], conf['s'], conf['l']]
    end
  end
end
