class Xapix < Device
  def initialize(args)
    super(args)
    @org = args['org']
    @project = args['project']
    @events_endpoint = args['events_endpoint'] || false
    @executors = args['executors']
    @pids = []
    connect!
  end

  def webhook_url
    @events_endpoint ? "https://api.xapix.dev/#{@org}/#{@project}/#{@events_endpoint}" : false
  end

  def connect!
    puts "Connecting to Xapix Cloud Service"
    @executors.each do |name|
      @pids << Process.spawn("XAPIX_EXT_EXEC_ENDPOINT=wss://executor.xapix.dev/api/v1/register?name=#{@org}/#{@project}/#{name} ruby ./iiot/external-executor/device_command.rb")
    end
  end

  def close!
    @pids.each { |pid| Process.kill("TERM", pid) }
  end
end
