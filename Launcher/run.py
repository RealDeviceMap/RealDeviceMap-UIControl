import argparse
import sys
import shlex
import subprocess
from datetime import datetime

####### EDIT VARIABLES BELOW

backend_url = '' # url to RDM api (ie. http://10.0.0.1:9001)
workspace = '' # full path of UIControl workspace (ie. '/Source/RDM/_Base/RealDeviceMap-UIControl.xcworkspace')
derived_data_base_path = '' # desired location of where your DerivedData folder is from build.sh (ie. '/Source/RDM/DerivedData')

####### BEGIN SCRIPT

parser = argparse.ArgumentParser()
parser.add_argument("-uuid", "-u")
parser.add_argument("-name", "-n")
parser.add_argument("-acct_mgr", "-a")

args = parser.parse_args()

device_id = args.uuid
device_name = args.name
enable_account_manager = args.acct_mgr
derived_data_path = '{}/{}'.format(derived_data_base_path, device_name)

while True:
    print '[{}] Attempting to connect to device: {}'.format(datetime.now().time().strftime('%H:%M:%S'), device_name)
    process = subprocess.Popen(shlex.split('xcodebuild test-without-building -workspace "{}" -scheme "RealDeviceMap-UIControl" -destination "id={}" -allowProvisioningUpdates -destination-timeout 900 -derivedDataPath "{}" name="{}" backendURL="{}" enableAccountManager="{}"'
        .format(workspace, device_id, derived_data_path, device_name, backend_url, enable_account_manager)), stdout=subprocess.PIPE)
    loop_start = datetime.now()
    while True:
        output = process.stdout.readline()
        if output == '' and process.poll() is not None:
            break
        if output:
            if 'tmp//.safeMode-' in output or 'Received signal 5' in output or 'Lost connection to test process' in output or 'Unable to find device with identifier' in output or 'Early unexpected exit' in output:
                process.terminate()
            else:
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