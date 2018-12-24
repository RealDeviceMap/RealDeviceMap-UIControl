import argparse
import sys
import shlex
import subprocess
from datetime import datetime

####### EDIT VARIABLES BELOW

backend_url = '' # url to RDM api (ie. http://10.0.0.1:9001)
workspace = '' # full path of UIControl workspace (ie. '/Source/RDM/_Base/RealDeviceMap-UIControl.xcworkspace')
derived_data_base_path = '' # desired location of where your DerivedData folder is from build.sh (ie. '/Source/RDM/DerivedData')
destination_timeout = 90 # max number of seconds to wait before terminating a process when connecting to a device
idle_timeout = 30 # max number of seconds of idle time before terminating a process

####### BEGIN SCRIPT

parser = argparse.ArgumentParser()
parser.add_argument("-uuid", "-u")
parser.add_argument("-name", "-n")
parser.add_argument("-acct_mgr", "-a", default="false")
parser.add_argument("-fast_iv", "-f", default="false")
parser.add_argument("-maxFailedCount", "-fc", default="5")
parser.add_argument("-maxEmptyGMO", "-eg", default="5")

args = parser.parse_args()

device_id = args.uuid
device_name = args.name
enable_account_manager = args.acct_mgr
fast_iv = args.fast_iv
max_failed_count = args.maxFailedCount
max_empty_gmo = args.maxEmptyGMO
derived_data_path = '{}/{}'.format(derived_data_base_path, device_name)

while True:
    print '[{}] Attempting to connect to device: {}'.format(datetime.now().time().strftime('%H:%M:%S'), device_name)
    process = subprocess.Popen(shlex.split('xcodebuild test-without-building -workspace "{}" -scheme "RealDeviceMap-UIControl" -destination "id={}" -destination-timeout {} -derivedDataPath "{}" name="{}" backendURL="{}" enableAccountManager="{}" fastIV="{}" maxFailedCount="{}" maxEmptyGMO="{}"'
        .format(workspace, device_id, destination_timeout, derived_data_path, device_name, backend_url, enable_account_manager, fast_iv, max_failed_count, max_empty_gmo)), stdout=subprocess.PIPE)
    loop_start = datetime.now()
    
    while True:
        output = process.stdout.readline()
        if output == '' and process.poll() is not None:
            break
        if output:
            if 'tmp//.safeMode-' in output or 'Received signal 5' in output or 'Lost connection to test process' in output or 'Unable to find device with identifier' in output or 'Early unexpected exit' in output:
                process.terminate()
            else:
                loop_start = datetime.now()
                print '[{}] {}'.format(datetime.now().time().strftime('%H:%M:%S'), output.strip())
        else:
            loop_now = datetime.now()
            difference = loop_now - loop_start

            if (difference.seconds > idle_timeout):
                print '[{}] Terminating connection to device {} for exceeding the maximum allowed idle time of {} seconds.'.format(loop_now.time().strftime('%H:%M:%S'), device_name, idle_timeout)
                process.terminate()
            else: 
                print '[{}] Connection to device {} has been idle for {} seconds...'.format(loop_now.time().strftime('%H:%M:%S'), device_name, difference.seconds)

    rc = process.poll()

####### END SCRIPT