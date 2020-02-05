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

        let tapMultiplier: Double
        if #available(iOS 13.0, *) {
            tapMultiplier = 0.5
        } else {
            tapMultiplier = 1.0
        }

        let ratio = Int(app.frame.size.height / app.frame.size.width * 1000)

        if ratio >= 1770 && ratio <= 1780 { // iPhones
            switch app.frame.size.width {
            case 375: // iPhone Normal
                // This has no use and is an example only
                global = DeviceIPhoneNormal(
                    width: Int(app.frame.size.width),
                    height: Int(app.frame.size.height),
                    multiplier: 1.0,
                    tapMultiplier: tapMultiplier
                )
            case 414: // iPhone Large
                global = DeviceRatio1775(
                    width: Int(app.frame.size.width),
                    height: Int(app.frame.size.height),
                    multiplier: 1.5,
                    tapMultiplier: tapMultiplier
                )
            default: // other iPhones
                global = DeviceRatio1775(
                    width: Int(app.frame.size.width),
                    height: Int(app.frame.size.height),
                    multiplier: 1.0,
                    tapMultiplier: tapMultiplier
                )
            }
        } else if ratio >= 1330 && ratio <= 1340 { // iPad
            global = DeviceRatio1333(
                width: Int(app.frame.size.width),
                height: Int(app.frame.size.height),
                multiplier: 1.0,
                tapMultiplier: tapMultiplier
            )
        } else {
            Log.error("Unsuported Device")
            fatalError("Unsuported Device")
        }
    }
}
