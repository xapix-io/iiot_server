require 'os'

class Audio < Device
  def initialize(args)
    super(args['avg_lag_ms'])
    @installation_name = args['installation_name']
  end

  # TODO: add flash vs loop option
  def play(conf)
    case
    when OS.mac? then `afplay ./tmp/#{@installation_name}/media/#{conf['tune']} -t #{(conf['duration_ms'].to_f / 1000).round}`
    when OS.linux? then `mpg123 --timeout #{(conf['duration_ms'].to_f / 1000).round} ./tmp/#{@installation_name}/media/#{conf['tune']}`
    end
  end

  def self.discover
    puts 'only system audio available'
  end
end
