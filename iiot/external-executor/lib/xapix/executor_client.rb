# frozen_string_literal: true

require 'faye/websocket'
require 'eventmachine'
require 'json'

module Xapix
  class ExecutorClient
    class Reply
      attr_reader :event

      def initialize(event)
        @event = event
        @result = 'fail'
        @response = []
      end

      def success(response_data)
        @result = 'success'
        @response = [{ callback: event.dig('callbacks', 'success'), args: [response_data] }]
      end

      def failure(reason)
        @result = 'success'
        @response = [{ callback: event.dig('callbacks', 'success'), args: [{ 'error' => reason }] }]
      end

      def to_hash
        { type: 'reply', id: event['id'], result: @result, response: @response }
      end

      def to_json
        to_hash.to_json
      end
    end

    def initialize(clojud_endpoint)
      $stdout.sync = true
      @clojud_endpoint = clojud_endpoint
    end

    def on_event(&block)
      @on_event = block
    end

    def run
      EM.run { connect(Time.now) }
    end

    private

    def connect(start_time)
      ws = Faye::WebSocket::Client.new(CLOJUD_ENDPOINT)

      ws.on :open do |event|
        p [Time.now.to_f, :open]
      end

      ws.on :message do |event|
        p [Time.now.to_f, :message]
        event_data = JSON.parse(event.data)
        reply = Reply.new(event_data)
        begin
          @on_event.call(event_data['payload'], reply)
        rescue => err
          reply.failure("Unable to query: #{err}")
        ensure
          ws.send(reply.to_json)
        end
      end

      ws.on :close do |event|
        reconnecting = start_time + 30 < Time.now
        p [Time.now.to_f, :close, event.code, event.reason, reconnecting]
        reconnecting ? connect(Time.now) : EventMachine.stop_event_loop
      end
    end
  end
end
