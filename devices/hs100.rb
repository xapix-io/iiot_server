class Hs100 < Plug
  def initialize(args)
    super(args['avg_lag_ms'])
    @ip = args['ip']
  end

  def plug_on(_conf)
    `bash ./drivers/hs100/hs100.sh -i #{@ip} on`
  end

  def plug_off(_conf)
    `bash ./drivers/hs100/hs100.sh -i #{@ip} off`
  end

  def self.discover
    `bash ./drivers/hs100/hs100.sh discover`
  end
end
