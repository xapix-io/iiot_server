class ColorBulb < Device
  def bulb_on(_conf); raise(NotImplementedError); end
  def bulb_off(_conf); raise(NotImplementedError); end
  def flash_color(_conf); raise(NotImplementedError); end
  def flash_brightness(_conf); raise(NotImplementedError); end
end
