//
//  Config.example.swift
//  RealDeviceMap-UIControlUITests
//
//  Created by Florian Kostenzer on 22.10.18.
//

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
    var itemFullCount: Int { get }
    var questFullCount: Int { get }
    var itemsPerStop: Int { get }
    var minDelayLogout: Double { get }
    var maxNoQuestCount: Int { get }
    var maxFailedCount: Int { get }
    var maxEmptyGMO: Int { get }
    var startupLocation: (lat: Double, lon: Double) { get }
    var encoutnerMaxWait: UInt32 { get }
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
        return 25.0
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
    var targetMaxDistance: Double {
        return 250.0
    }
    var itemFullCount: Int {
        return 250
    }
    var questFullCount: Int {
        return 3
    }
    var itemsPerStop: Int {
        return 10
    }
    var minDelayLogout: Double {
        return 180
    }
    var maxNoQuestCount: Int {
        return 5
    }
    var maxNoEncounterCount: Int {
        return 5
    }
    var maxFailedCount: Int {
        return 5
    }
    var maxEmptyGMO: Int {
        return 5
    }
    var startupLocation: (lat: Double, lon: Double) {
        return (1.0, 1.0)
    }
    var encoutnerMaxWait: UInt32 {
        return 7
    }
    
}

extension Config {
    
    public static let global = Config()
        
}
