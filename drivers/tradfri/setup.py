#!/usr/bin/env python3
"""
This is an example of how the pytradfri-library can be used.

To run the script, do the following:
$ pip install -r requirements.txt
$ python3 -m flask run <IP>

Where <IP> is the address to your IKEA gateway. The first time
running you will be asked to input the 'Security Code' found on
the back of your IKEA gateway.
"""

from pytradfri import Gateway
from pytradfri.api.libcoap_api import APIFactory
from pytradfri.error import PytradfriError
from pytradfri.util import load_json, save_json

import os
import uuid
import argparse

CONFIG_FILE = 'tradfri_standalone_psk.conf'
HOST = os.environ['HOST']

parser = argparse.ArgumentParser()
parser.add_argument('-K', '--key', dest='key', required=False, help='Security code found on your Tradfri gateway')
args = parser.parse_args()

if HOST not in load_json(CONFIG_FILE) and args.key is None:
    print("Please provide the 'Security Code' on the back of your "
          "Tradfri gateway:", end=" ")
    key = input().strip()
    if len(key) != 16:
        raise PytradfriError("Invalid 'Security Code' provided.")
    else:
        args.key = key

    # Assign configuration variables.
    # The configuration check takes care they are present.
    conf = load_json(CONFIG_FILE)

    try:
        identity = conf[HOST].get('identity')
        psk = conf[HOST].get('key')
        api_factory = APIFactory(host=HOST, psk_id=identity, psk=psk)
    except KeyError:
        identity = uuid.uuid4().hex
        api_factory = APIFactory(host=HOST, psk_id=identity)

        try:
            psk = api_factory.generate_psk(args.key)
            print('Generated PSK: ', psk)

            conf[HOST] = {'identity': identity,
                               'key': psk}
            save_json(CONFIG_FILE, conf)
        except AttributeError:
            raise PytradfriError("Please provide the 'Security Code' on the "
                                 "back of your Tradfri gateway using the "
                                 "-K flag.")

conf = load_json(CONFIG_FILE)
identity = conf[HOST].get('identity')
psk = conf[HOST].get('key')
api_factory = APIFactory(host=HOST, psk_id=identity, psk=psk)
api = api_factory.request
gateway = Gateway()
devices_command = gateway.get_devices()
devices_commands = api(devices_command)
print(api(devices_commands))
