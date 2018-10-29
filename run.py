import shlex
import subprocess
import sys

# EDIT ME
device_id = sys.argv[1]


# DON'T EDIT ME
while True:

    process = subprocess.Popen(shlex.split('xcodebuild test -workspace RealDeviceMap-UIControl.xcworkspace -scheme "RealDeviceMap-UIControl" -destination "id={}" -allowProvisioningUpdates'.format(device_id)), stdout=subprocess.PIPE)
    while True:
        output = process.stdout.readline()
        if output == '' and process.poll() is not None:
            break
        if output:
            if 'tmp//.safeMode-' in output or 'Received signal 5' in output:
                process.terminate()
            else:
                print output.strip()
    rc = process.poll()



