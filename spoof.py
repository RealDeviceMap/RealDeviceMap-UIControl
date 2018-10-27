import subprocess
import time
import requests
import os

# Only use this for iSpoofer not for PokemonGo++

# EDIT ME
device_id = 'DEVICE_UUID'
location_url = 'http://DEVICE_IP:8080/loc'


# DON'T EDIT ME
FNULL = open(os.devnull, 'w')

while True:

    try:
        r = requests.get(location_url)
        result = r.json()

        lat = result['latitude']
        lon = result['longitude']

        if lat < 0:
            lat_str = '-- {}'.format(lat)
            lon_str = str(lon)
        elif lon < 0:
            lat_str = str(lat)
            lon_str = '-- {}'.format(lon)
        else:
            lat_str = str(lat)
            lon_str = str(lon)

        process = subprocess.Popen('idevicelocation -u {} {} {}'.format(device_id, lat_str, lon_str), shell=True,
                                   stdout=FNULL, stderr=FNULL)
        print 'Teleporting to {},{}'.format(lat,lon)
        process.wait()
        time.sleep(0.1)

    except:
        print 'Failed to teleport'
        time.sleep(1)

