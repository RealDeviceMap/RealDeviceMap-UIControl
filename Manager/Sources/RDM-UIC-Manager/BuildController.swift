//
//  BuildController.swift
//  RDM-UIC-Manager
//
//  Created by Florian Kostenzer on 28.11.18.
//

import Foundation
import PerfectLib
import PerfectThread

class BuildController {
    
    public static var global = BuildController()
    
    private var devicesLock = Threading.Lock()
    private var devicesToRemove = [Device]()
    private var devicesToAdd = [Device]()
    
    private var managerQueue: ThreadQueue!
    
    private var activeDeviceLock = Threading.Lock()
    private var activeDevices = [Device]()
    
    private var path: String = ""
    private var timeout: Int = 60
    
    private var buildLock = Threading.Lock()
    private var isBuilding = false
    
    public func start(path: String, timeout: Int) {
        
        self.path = path
        self.timeout = timeout
        
        print("[INFO] Building Project...")
        Log.info(message: "Building Project...")
        let xcodebuild = Shell("xcodebuild", "build-for-testing", "-workspace", "\(path)/RealDeviceMap-UIControl.xcworkspace", "-scheme", "RealDeviceMap-UIControl", "-allowProvisioningUpdates", "-allowProvisioningDeviceRegistration", "-destination", "generic/platform=iOS")
        let errorPipe = Pipe()
        let outputPipe = Pipe()
        _ = xcodebuild.run(outputPipe: outputPipe, errorPipe: errorPipe)
        let error = String(data: errorPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
        let output = String(data: outputPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
        if error.trimmingCharacters(in: .whitespacesAndNewlines) != "" {
            Log.terminal(message: "Building Project Failed!\n\(output)\n\(error)")
        }
        print("[INFO] Building Project done")
        Log.info(message: "Building Project done")
        
        devicesLock.lock()
        devicesToAdd = Device.getAll()
        devicesLock.unlock()
        managerQueue = Threading.getQueue(name: "BuildController-Manager", type: .serial)
        managerQueue.dispatch(managerQueueRun)
    }
    
    public func addDevice(device: Device) {
        devicesLock.lock()
        devicesToAdd.append(device)
        devicesLock.unlock()
    }
    
    public func removeDevice(device: Device) {
        devicesLock.lock()
        devicesToRemove.append(device)
        devicesLock.unlock()
    }
    
    private func managerQueueRun() {
        while true {
            devicesLock.lock()
            let devicesToAdd = self.devicesToAdd
            let devicesToRemove = self.devicesToRemove
            self.devicesToAdd = [Device]()
            self.devicesToRemove = [Device]()
            devicesLock.unlock()
            
            for device in devicesToRemove {
                let queue = Threading.getQueue(name: "BuildController-\(device.uuid)", type: .serial)
                activeDeviceLock.lock()
                if let index = activeDevices.index(of: device) {
                    activeDevices.remove(at: index)
                }
                activeDeviceLock.unlock()
                Threading.destroyQueue(queue)
            }
            
            for device in devicesToAdd {
                let queue = Threading.getQueue(name: "BuildController-\(device.uuid)", type: .serial)
                activeDeviceLock.lock()
                activeDevices.append(device)
                activeDeviceLock.unlock()
                queue.dispatch {
                    self.deviceQueueRun(device: device)
                }
            }
            
            Threading.sleep(seconds: 1)
        }
    }
    
    private func deviceQueueRun(device: Device) {
        
        Log.info(message: "Starting \(device.name)'s Manager")
        
        let xcodebuild = Shell("xcodebuild", "test-without-building", "-workspace", "\(path)/RealDeviceMap-UIControl.xcworkspace", "-scheme", "RealDeviceMap-UIControl", "-destination", "id=\(device.uuid)", "-allowProvisioningUpdates", "-destination-timeout", "\(timeout * device.delayMultiplier)",
            "name=\(device.name)", "backendURL=\(device.backendURL)", "enableAccountManager=\(device.enableAccountManager)", "port=\(device.port)", "pokemonMaxTime=\(device.pokemonMaxTime)", "raidMaxTime=\(device.raidMaxTime)", "maxWarningTimeRaid=\(device.maxWarningTimeRaid)", "delayMultiplier=\(device.delayMultiplier)", "jitterValue=\(device.jitterValue)", "targetMaxDistance=\(device.targetMaxDistance)", "itemFullCount=\(device.itemFullCount)", "questFullCount=\(device.questFullCount)", "itemsPerStop=\(device.itemsPerStop)", "minDelayLogout=\(device.minDelayLogout)", "maxNoQuestCount=\(device.maxNoQuestCount)", "maxFailedCount=\(device.maxFailedCount)", "maxEmptyGMO=\(device.maxEmptyGMO)", "startupLocationLat=\(device.startupLocationLat)", "startupLocationLon=\(device.startupLocationLon)", "encoutnerMaxWait=\(device.encoutnerMaxWait)"
        )

        var contains = true
        
        let lastChangedLock = Threading.Lock()
        var lastChanged: Date?
        
        var task: Process?
        let xcodebuildQueue = Threading.getQueue(name: "BuildController-\(device.uuid)-runner", type: .serial)
        xcodebuildQueue.dispatch {
            
            var locked = false
            
            while contains {
                
                let outputPipe = Pipe()
                let errorPipe = Pipe()
                
                let timestamp = Int(Date().timeIntervalSince1970)
                let fullLog = FileLogger(file: "./logs/\(timestamp)-\(device.name)-xcodebuild.full.log")
                let debugLog = FileLogger(file: "./logs/\(timestamp)-\(device.name)-xcodebuild.debug.log")
                
                Log.debug(message: "[\(device.name)] Waiting for build lock...")
                locked = true
                self.buildLock.lock()
                while !self.isBuilding {
                    self.buildLock.unlock()
                    Threading.sleep(seconds: 1)
                    self.buildLock.lock()
                }
                self.isBuilding = true
                self.buildLock.unlock()
                lastChangedLock.lock()
                lastChanged = Date()
                lastChangedLock.unlock()
                
                Log.info(message: "[\(device.name)] Starting xcodebuild")
                task = xcodebuild.run(outputPipe: outputPipe, errorPipe: errorPipe)

                outputPipe.fileHandleForReading.readabilityHandler = { fileHandle in
                    let string = String(data: fileHandle.availableData, encoding: .utf8)
                    if string != nil && string!.trimmingCharacters(in: .whitespacesAndNewlines) != "" {
                        if string!.contains(string: "[STATUS] Started") && locked {
                            Log.debug(message: "[\(device.name)] Done building")
                            locked = false
                            self.buildLock.lock()
                            self.isBuilding = false
                            self.buildLock.unlock()
                        }
                        fullLog.uic(message: string!, all: true)
                        debugLog.uic(message: string!, all: false)
                        lastChangedLock.lock()
                        lastChanged = Date()
                        lastChangedLock.unlock()
                    }
                }
                errorPipe.fileHandleForReading.readabilityHandler = { fileHandle in
                    let string = String(data: fileHandle.availableData, encoding: .utf8)
                    if string != nil && string!.trimmingCharacters(in: .whitespacesAndNewlines) != "" {
                        fullLog.uic(message: string!, all: true)
                        debugLog.uic(message: string!, all: false)
                        lastChangedLock.lock()
                        lastChanged = Date()
                        lastChangedLock.unlock()
                    }

                }
                task?.waitUntilExit()
                Log.debug(message: "[\(device.name)] Xcodebuild ended")
                if locked {
                    locked = false
                    self.buildLock.lock()
                    self.isBuilding = false
                    self.buildLock.unlock()
                }
                outputPipe.fileHandleForReading.readabilityHandler = nil
                errorPipe.fileHandleForReading.readabilityHandler = nil
                
                lastChangedLock.lock()
                lastChanged = nil
                lastChangedLock.unlock()
                
                Threading.sleep(seconds: 1.0)
            }
            task?.suspend()
        }
        
        while contains {
            
            lastChangedLock.lock()
            if task != nil && lastChanged != nil && Int(Date().timeIntervalSince(lastChanged!)) >= (timeout * device.delayMultiplier) {
                task!.terminate()
                Log.info(message: "[\(device.name)] Stopping xcodebuild. No output for over \(timeout * device.delayMultiplier)s")
            }
            lastChangedLock.unlock()
            
            Threading.sleep(seconds: 5.0)
            activeDeviceLock.lock()
            contains = activeDevices.contains(device)
            activeDeviceLock.unlock()
        }
        task?.terminate()
        Threading.destroyQueue(xcodebuildQueue)
        Log.info(message: "Stopping \(device.name)'s Manager")
    }
    
}
