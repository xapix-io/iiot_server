require 'os'

class Audio < Device
  def initialize(args)
    super(args)
    @installation_name = args['installation_name']
    @mode = args['mode'] || 'single'
  end

  # TODO: add flash vs loop option
  def play(conf)
    case
    when OS.mac? then process_spawn("afplay ./tmp/#{@installation_name}/media/#{conf['tune']} -t #{(conf['duration_ms'].to_f / 1000).round}")
    when OS.linux? then process_spawn("mpg123 --timeout #{(conf['duration_ms'].to_f / 1000).round} ./tmp/#{@installation_name}/media/#{conf['tune']}")
    end
  end

  def process_spawn(cmd)
    if @mode == 'single'
      no_process_running = (Process.getpgid(@pid) rescue nil).nil?
      @pid = Process.spawn(cmd) if no_process_running
    elsif @mode == 'override'
      Process.kill("TERM", @pid) if @pid
      @pid = Process.spawn(cmd)
    elsif @mode == 'parallel'
      Process.spawn(cmd)
    end
  end
end
