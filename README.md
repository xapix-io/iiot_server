# Office / Facility Management with Home IoT devices

A universal software remote control for various types of Home IoT devices from various manufacturers, conveniently programmable via a simple HTTP API in your local WiFi.

Goals:
- Basic support of as many Home IoT device types as possible.
- Lowering technical hurdles as much as possible.
- Make it easy to install and operate on Raspberry Pi
- Stable, consistent API. Swapping device types only requires configuration changes and no software updates.
- Feature addistions ideally should have concrete use cases in mind. We are open to community suggestions and contributions to this repo.
- Code base consolidation and dependency reduction towards a Ruby ecosystem. Reverse engineering of the proprietary protocols of Home IoT devices is the hardest part and so far I've been cutting corners using readily available libraries in whatever language (Python, bash, ...) building up a dependency zoo.
- Portability: The software needs to allow configuring multiple sets of devices (home, office, etc)
- Compatibility with more operating systems, Linux Debian systems and Windows would be on top of my list.
- Usability within local WiFi only is the default. No Xapix account required, support for Xapix pipelines is optional and needs to be explicitly enabled.

Disclaimers:
- This documentation is work in progress, please point out pitfalls to us.
- Software is work in progress. It's non-commercial, MIT licensed and no Xapix account is required. Some Xapix working hours go into this and many more private freetime hours, please consider this when discussion issues, bugs and features. 
- Odd folder structure roots in the multiple uses this software was intended for. It started out as a hobby art installations library, then 2 more use cases were added and you occasionally may find cross references in the code, so please point them out to me. Also I am more than open to discuss a better structure of this project in GitHub issues
- Project is related to a series of commercial Xapix blog posts addressing developers and pointing out use cases

## Requirements

- MacOS
- Homebrew
- bash
- python3 and pip3
- ruby and bundler

We're working on a docker version.

We're working on a more convenient setup script automating device discovery.

## Home IoT device installation

Generally it's a good idea to follow the intended proprietary installations steps from the manufacturers. This way you will always have the traditional way of accessing your devices no matter what. We're just looking to provide an additional way to access them via an HTTP API and subsequently your home-made application and / or Xapix pipelines.

### Tradfri devices

You'll need a gateway hub that's controlling multiple control devices (such as dimmers) and each of those are controlling multiple end devices (such as lights or blinds). The gateway hub needs to be connected via network cable to your router and have all 3 display LEDs on. You'll need the Home Smart mobile app to register devices, follow the instructions provided in their manuals for the proprietary setup.

On the back of the gateway hub you'll find your security code and the device's MAC address. After your setup, on your Mac run `arp -a` (install: `brew install arp`) to scan for local devices in your WiFi network and find the IP address corresponding with your gateway hubs MAC address and keep those 3 credentials for the installation step.

Clone the codebase and connect to your gateway hub. The script will list your registered Tradfri devices, keep the IDs for the next step.

```
git clone
cd 

pip3 install -r ./drivers/tradfri/requirements.txt
HOST=192.168.10.88 python3 setup.py # Dialog asks for <GATEWAY_SECURITY_CODE>, creates a psk.conf file and displays registered devices
FLASK_APP=server.py HOST=<GATEWAY_IP> python3 -m flask run
```

Configure your Home IoT devices for access via the HTTP API.

```
#./config/devices.yml

devices:
  office:
    test_bulb: # << name your device here
      model_class: TradfriLedColorBulb
      hub_id: <DEVICE_ID_IN_HUB> # << enter the device ID as registered in your gateway hub
    # << add more device entries as needed
```

## HTTP API installation

```
bundle install
bundle exec ruby ./iiot_server.rb office
```

## Start Xapix External Executor

To enable Xapix pipelines to do your desired actions on your local Home IoT setup, you'll need to run the External Executor. Stopping the process also stops all communication with Xapix servers.

Generate a random code of 6 characters or more, e.g. "1x2y3z", make it as eandom and unique you can. 

Open a new terminal tab and start the Xapix External Executor.

```
XAPIX_EXT_EXEC_ENDPOINT=wss://executor.xapix.dev/api/v1/register?name=iiot-office-<RANDOM_CODE> ruby ./iiot/external-executor/device_command.rb
```

Log into [Xapix Community Edition](cloud.xapix.io) and in your Xapix project add a Data Source of type "External Executor". In field name enter "iiot-office-<RANDOM_CODE>" and set up required payload parameters as needed, e.g.:

```
{
	"device": "test_bulb",
	"action": {
		"cmd": "bulb_on"
	}
}
```

Now Xapix pipelines can make use of this Data Source and send commands to your local setup as long as the External Executor is running.

## Acknowledgements

- https://github.com/ggravlingen/pytradfri