//
//  DeviceIPhoneNormal.swift
//  RealDeviceMap-UIControlUITests
//
//  Created by Florian Kostenzer on 19.11.18.
//

import Foundation

class DeviceIPhoneNormal: DeviceRatio1775 {
    
    // This has no porpous expect to show how a override for a specific resolution works
    // All values not overriden here default to DeviceRatio562s values
    override var startup: DeviceCoordinate {
        return DeviceCoordinate(x: 375, y: 690)
    }
    
}
