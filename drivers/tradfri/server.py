#!/usr/bin/env python3

from flask import Flask

from pytradfri import Gateway
from pytradfri.api.libcoap_api import APIFactory
from pytradfri.error import PytradfriError
from pytradfri.util import load_json

import os

CONFIG_FILE = 'tradfri_standalone_psk.conf'
HOST = os.environ['HOST']

conf = load_json(CONFIG_FILE)
identity = conf[HOST].get('identity')
psk = conf[HOST].get('key')
api_factory = APIFactory(host=HOST, psk_id=identity, psk=psk)
api = api_factory.request
gateway = Gateway()
devices_command = gateway.get_devices()
devices_commands = api(devices_command)
devices = api(devices_commands)
lights = [dev for dev in devices if dev.has_light_control]

app = Flask(__name__)

@app.route('/pytradfri/bulbs/<bulb_id>/state/<bulb_state>', methods=['POST'])
def bulb_set_state(bulb_id, bulb_state):
    bulb = next((dev for dev in lights if dev.id == int(bulb_id)), None)
    api(bulb.light_control.set_state(int(bulb_state)))
    return 'success'

@app.route('/pytradfri/bulbs/<bulb_id>/color_hsb/<h>/<s>/<b>', methods=['POST'])
def bulb_set_color_hsb(bulb_id, h, s, b):
    bulb = next((dev for dev in lights if dev.id == int(bulb_id)), None)
    api(bulb.light_control.set_hsb(int(h), int(s), int(b)))
    return 'success'

@app.route('/pytradfri/bulbs/<bulb_id>/color_hsb', methods=['GET'])
def bulb_get_color_hsb(bulb_id):
    devices = api(devices_commands)
    bulb_dev = next((dev for dev in devices if dev.id == int(bulb_id) and dev.has_light_control), None)
    bulb = bulb_dev.light_control.lights[0]
    state_resp = 'true' if bulb.state else 'false'
    color_resp = bulb.hsb_xy_color
    return f'[{state_resp},{color_resp[0]},{color_resp[1]},{color_resp[2]}]'

@app.route('/pytradfri/bulbs/<bulb_name>/id', methods=['GET'])
def bulb_get_id(bulb_name):
    bulb = next((dev for dev in lights if dev.name == bulb_name), None)
    return str(bulb.id) 
