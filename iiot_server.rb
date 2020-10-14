require 'sinatra'
require 'yaml'
require 'json'
require_relative './devices/list'

set :bind, '0.0.0.0'

NETWORK_IPS = `arp -a`.lines.map do |line|
  line = line.split
  l_mac = line[3].split(':').map { |e| e.rjust(2, "0") }.join(':')
  [l_mac, line[1][1..-2]]
end.to_h

DEVICE_ENV = ARGV[0] || 'office'
DEVICES = 
  begin
    YAML.load(File.open('./config/devices.yml').read)['devices'][DEVICE_ENV].map do |name, conf|
      conf['device_name'] = name
      if conf['ip'].nil? && !conf['mac'].nil?
        dev_ip = NETWORK_IPS[conf['mac']] || raise("Device IP for MAC #{conf['mac']} not detected!")
        conf.merge!('ip' => NETWORK_IPS[conf['mac']])
      end
      device = Object::const_get(conf['model_class']).new(conf)
      if conf['devices'].nil?
        [[name, device]]
      else
        conf['devices'].map { |sub_name, sub_conf| [sub_name, Object::const_get(sub_conf['model_class']).new(sub_conf.merge('device_name' => sub_name), device)] }
      end
    end.flatten(1).to_h
  rescue StandardError => e
    raise 'please provide a valid environment configuration file'
  end

EVENT_WEBHOOK_URL = ENV.fetch('EVENT_WEBHOOK_URL', DEVICES['xapix']&.webhook_url || false)
JSON_TYPE = { 'Content-Type' => 'application/json' }

$logger = Logger.new(STDOUT)
$logger.level = Logger.const_get(ENV['LOG_LEVEL'] || 'WARN')

def parse_body(request)
  case request.content_type
  when 'application/json' then JSON.parse(request.body.read)
  when 'application/yaml' then YAML.load(request.body.read)
  else raise('content type not supported')
  end
end

def exec_command(device_name, cmd, action)
  DEVICES[device_name].send(cmd, action)
end

def send_to_webhook(event)
  uri = URI(EVENT_WEBHOOK_URL)
  req = Net::HTTP::Post.new(uri, JSON_TYPE)
  req.body = event.to_json
  res = Net::HTTP.start(uri.hostname, uri.port, use_ssl: uri.scheme == 'https') do |http|
    http.request(req)
  end
end

post '/event' do
  payload = parse_body(request)
  raise('event does not contain attribute name') if payload['name'].nil?
  raise('event does not contain attribute value') if payload['value'].nil?
  unless params['device_name'].nil?
    device_data = DEVICES[params['device_name']].to_h 
    payload.key?('data') ? payload['data'].merge!(device_data) : payload['data'] = device_data
  end
  send_to_webhook(payload) if EVENT_WEBHOOK_URL
  status 201
end

post '/device_cmd' do
  payload = parse_body(request)
  exec_command(payload['device'], payload['action'].delete('cmd'), payload['action'])
  #event = { 'name' => payload['device'], 'value' => payload['action']['cmd'], 'data' => payload['action'] }
  #track_event!(event)
  status 201
end

post '/:device_type/:device_name/:cmd' do
  payload = parse_body(request)
  exec_command(device_name, cmd, payload['action'])
  #event = { 'name' => payload['device'], 'value' => payload['action']['cmd'], 'data' => payload['action'] }
  #track_event!(event)
  status 201
rescue StandardError => error
  status 400
  { error: error.message }.to_json
end
