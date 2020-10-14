class TradfriHub < Device
  attr_reader :ip

  def initialize(args)
    super(args)
    @ip = args['ip']
    connect!
  end

  def connect!
    puts "Connecting to Tradfri hub with IP #{@ip}"
    @pid = Process.spawn("FLASK_APP=server.py HOST=#{@ip} python3 -m flask run", chdir: "./drivers/tradfri/")
    sleep(5)
  end

  def close!
    Process.kill("TERM", @pid)
  end
end
