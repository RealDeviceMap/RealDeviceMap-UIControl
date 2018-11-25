import subprocess
import shlex

# EDIT ME
device_id = 'DEVICE_UUID'


# DON'T EDIT ME
while True:
    
    process = subprocess.Popen(shlex.split('xcodebuild test -workspace RealDeviceMap-UIControl.xcworkspace -scheme "RealDeviceMap-UIControl" -destination "id={}" -allowProvisioningUpdates -destination-timeout 90'.format(device_id)), stdout=subprocess.PIPE)
    while True:
        output = process.stdout.readline()
        if output == '' and process.poll() is not None:
            break
        if output:
            if 'tmp//.safeMode-' in output or 'Received signal 5' in output or 'Lost connection to test process' in output or 'Unable to find device with identifier' in output or 'Early unexpected exit' in output:
                process.terminate()
            else:
                print output.strip()
    rc = process.poll()
