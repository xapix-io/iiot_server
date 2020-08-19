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

app = Flask(__name__)

@app.route('/pytradfri/bulbs/<bulb_id>/state/<bulb_state>', methods=['POST'])
def bulb_set_state(bulb_id, bulb_state):
    bulb = next((dev for dev in devices if dev.id == int(bulb_id)), None)
    api(bulb.light_control.set_state(int(bulb_state)))
    return 'success'
