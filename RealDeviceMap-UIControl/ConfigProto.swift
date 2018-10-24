//
//  Config.example.swift
//  RealDeviceMap-UIControlUITests
//
//  Created by Florian Kostenzer on 22.10.18.
//

// DON'T EDIT!

import Foundation

protocol ConfigProto {
    
    var uuid: String { get }
    var backendURLBaseString: String { get }
    
    var enableAccountManager: Bool { get }
    var port: Int { get }
    var pokemonMaxTime: Double { get }
    var raidMaxTime: Double { get }
    var maxWarningTimeRaid: Int { get }
    var delayMultiplier: UInt32 { get }
    var jitterValue: Double { get }
    var targetMaxDistance: Double { get }
}

extension ConfigProto {
    
    var enableAccountManager: Bool {
        return false
    }
    var port: Int {
        return 8080
    }
    var pokemonMaxTime: Double {
        return 45.0
    }
    var raidMaxTime: Double {
        return 15.0
    }
    var maxWarningTimeRaid: Int {
        return 432000
    }
    var delayMultiplier: UInt32 {
        return 1
    }
    var jitterValue: Double {
        return 0.00005
    }
    var targetMaxDistance: Double {
        return 250.0
    }
    
}

extension Config {
    
    public static let global = Config()
        
}
