//
//  DeviceConfig.swift
//  RealDeviceMap-UIControlUITests
//
//  Created by Florian Kostenzer on 18.11.18.
//

import Foundation
import XCTest

class DeviceConfig {
    
    public static private(set) var global: DeviceConfigProtocol!
    
    public static func setup(app: XCUIApplication) {
        let ratio = Int(app.frame.size.height / app.frame.size.width * 1000)
        if ratio >= 1770 && ratio <= 1780 { // iPhones
            switch app.frame.size.width {
            case 375: // iPhone Normal
                global = DeviceIPhoneNormal(width: Int(app.frame.size.width), height: Int(app.frame.size.height))
            default: // other iPhones
                global = DeviceRatio1775(width: Int(app.frame.size.width), height: Int(app.frame.size.height))
            }
        } else {
            Log.error("Unsuported Device")
            fatalError("Unsuported Device")
        }
    }
    
}
