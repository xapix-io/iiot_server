class Device
  class NotImplementedError < StandardError; end 

  attr_reader :device_name, :avg_lag_ms

  def initialize(args)
    @device_name = args['device_name']
    @avg_lag_ms = args['avg_lag_ms'] || 0
  end

  def connect!; end
  def close!; end

  # @return void
  def self.test; raise 'not implemented'; end

  # @return integer avg_lag_ms
  def self.benchmark_cmds(args); raise 'not implemented'; end
end
