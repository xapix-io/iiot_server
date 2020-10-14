#!/usr/bin/env python3

from pytradfri import Gateway
from pytradfri.api.libcoap_api import APIFactory
from pytradfri.error import PytradfriError
from pytradfri.util import load_json

import time
import os
import requests

CONFIG_FILE = 'tradfri_standalone_psk.conf'
HOST = os.environ['HOST']
BULB_ID = os.environ['BULB_ID']
DEVICE_NAME = os.environ['DEVICE_NAME']
JSON_HEADER = { 'Content-Type': 'application/json' }

conf = load_json(CONFIG_FILE)
identity = conf[HOST].get('identity')
psk = conf[HOST].get('key')
api_factory = APIFactory(host=HOST, psk_id=identity, psk=psk)
api = api_factory.request
gateway = Gateway()
devices_command = gateway.get_devices()
devices_commands = api(devices_command)
devices = api(devices_commands)
bulb_device = next((dev for dev in devices if dev.id == int(BULB_ID) and dev.has_light_control), None)
bulb = bulb_device.light_control.lights[0]

current_state = bulb.state
current_color = bulb.hsb_xy_color

def error_listener(device):
    print("[TRADFRI] Observer disconnected for " + bulb_device.name + ": " + str(bulb_device.id))

def change_listener(device):
    global current_state, current_color
    light = device.light_control.lights[0]
    if(light.state != current_state or light.hsb_xy_color != current_color):
        current_state = light.state
        current_color = light.hsb_xy_color
        print("[TRADFRI] Received update for " + device.name + ": " + str(device.id))
        status = 'on' if light.state else 'off'
        switch_data = {"name": "light_switch", "value": status }
        requests.post('http://localhost:4567/event?device_name=' + DEVICE_NAME, json=switch_data, headers=JSON_HEADER)

while True:
    print("[TRADFRI] Observer reconnecting for " + bulb_device.name + ": " + str(bulb_device.id) + " ...")
    api(bulb_device.observe(change_listener, error_listener, duration=120))
    print("[TRADFRI] Observer reconnected for " + bulb_device.name + ": " + str(bulb_device.id) + " ...")
    time.sleep(120)
