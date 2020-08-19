require 'sinatra'
require 'yaml'
require 'json'
require_relative './devices/list'

set :bind, '0.0.0.0'

DEVICE_ENV = ARGV[1] || 'office'
DEVICES = 
  begin
    YAML.load(File.open('./config/devices.yml').read)['devices'][DEVICE_ENV].map do |name, conf|
      [name, Object::const_get(conf['model_class']).new(conf)]
    end.to_h
  rescue StandardError => e
    raise 'please provide a valid environment configuration file'
  end

$logger = Logger.new(STDOUT)
$logger.level = Logger.const_get(ENV['LOG_LEVEL'] || 'WARN')

def parse_body(request)
  case request.content_type
  when 'application/json' then JSON.parse(request.body.read)
  when 'application/yaml' then YAML.load(request.body.read)
  else raise('content type not supported')
  end
end

post '/event' do
  payload = parse_body(request)
  raise('event does not contain attribute name') if payload['name'].nil?
  raise('event does not contain attribute value') if payload['value'].nil?
  #track_event!(payload)
  status 201
rescue StandardError => error
  status 400
  { error: error.message }.to_json
end

post '/device_cmd' do
  payload = parse_body(request)
  DEVICES[payload['device']].send(payload['action']['cmd'], payload['action'])
  #event = { 'name' => payload['device'], 'value' => payload['action']['cmd'], 'data' => payload['action'] }
  #track_event!(event)
  status 201
rescue StandardError => error
  status 400
  { error: error.message }.to_json
end
