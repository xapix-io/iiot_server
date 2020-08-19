#!/usr/bin/env ruby
# frozen_string_literal: true

require 'json'
require 'rest-client'
require_relative 'lib/xapix/executor_client'

CLOJUD_ENDPOINT = ENV['XAPIX_EXT_EXEC_ENDPOINT'] || raise('Please provide XAPIX_EXT_EXEC_ENDPOINT')

client = Xapix::ExecutorClient.new(CLOJUD_ENDPOINT)
client.on_event do |payload, reply|
  begin
    RestClient.post('http://127.0.0.1:4567/device_cmd', payload.to_json, { 'Content-Type' => 'application/json' })
    reply.success('status' => 'executed')
  rescue StandardError => error
    reply.failure("Unable to execute command #{payload['action']['cmd']} on device #{payload['device']}: #{error.message}")
  end
end

client.run
