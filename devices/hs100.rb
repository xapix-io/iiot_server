class Hs100 < Plug
  def initialize(args)
    super(args)
    @ip = args['ip']
  end

  def plug_on(_conf)
    Process.spawn("bash ./drivers/hs100/hs100.sh -i #{@ip} on")
  end

  def plug_off(_conf)
    Process.spawn("bash ./drivers/hs100/hs100.sh -i #{@ip} off")
  end
end
