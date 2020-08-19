class Plug < Device
  def plug_on; raise(NotImplementedError); end
  def plug_off; raise(NotImplementedError); end
end
