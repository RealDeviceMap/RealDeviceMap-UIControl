import os
import requests
import subprocess
import sys
import time

# Only use this for iSpoofer not for PokemonGo++

# EDIT ME
device_id = sys.argv[1]
location_url = 'http://{}:8080/loc'.format(sys.argv[2])

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
