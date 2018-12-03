#!/usr/local/bin/bash

####### EDIT VARIABLES BELOW

# Edit device name array below
DEVICE_NAMES=(
	"DEVICE NAME 1"
	"DEVICE NAME 2"
)

# Change to full path of UIControl workspace (ie. "/Source/RDM/_Base/RealDeviceMap-UIControl.xcworkspace")
WORKSPACE_PATH=""

# Change to desired location of where you want your DerivedData folders to go (ie. "/Source/RDM/DerivedData")
DERIVEDDATA_PATH=""

####### BEGIN SCRIPT

clear

printf "[$(date '+%Y-%m-%d %H:%M:%S')] %s\n" "Begin building UIControl"

xcodebuild build-for-testing -workspace "${WORKSPACE_PATH}" -scheme RealDeviceMap-UIControl -allowProvisioningUpdates -allowProvisioningDeviceRegistration -destination "generic/platform=iOS" -derivedDataPath "${DERIVEDDATA_PATH}/_Base"

for i in "${DEVICE_NAMES[@]}"
do
	printf "[$(date '+%Y-%m-%d %H:%M:%S')] %s\n" "Copying DerivedData folder to ${DERIVEDDATA_PATH}/${i}..."
	cp -r "${DERIVEDDATA_PATH}/_Base" "${DERIVEDDATA_PATH}/${i}"
done

printf "[$(date '+%Y-%m-%d %H:%M:%S')] %s\n" "Finished building UIControl"

# Uncomment below if you want to launch the UIControl instances after the build completes
#./launch.sh

####### END SCRIPT
