class Device
  class NotImplementedError < StandardError; end 

  attr_reader :avg_lag_ms

  def initialize(avg_lag_ms)
    @avg_lag_ms = avg_lag_ms || 0
  end

  # @return Hash config
  def self.detect(args); raise 'not implemented'; end

  # @return void
  def self.test; raise 'not implemented'; end

  # @return integer avg_lag_ms
  def self.benchmark_cmds(args); raise 'not implemented'; end
end
