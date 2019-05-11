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
    override var loginTerms2Text: DeviceCoordinate {
        return DeviceCoordinate(x: 188, y: 450)
    }
    override var loginTerms2: DeviceCoordinate {
        return DeviceCoordinate(x: 375, y: 725)
    }
    override var startupLoggedOut: DeviceCoordinate {
        return DeviceCoordinate(x: 400, y: 115)
    }
    override var encounterNoARConfirm: DeviceCoordinate {  //no AR popup after saying no on iPhone6
        return DeviceCoordinate(x: 0, y: 0)
    }
    override var encounterTmp: DeviceCoordinate {
        return DeviceCoordinate(x: 0, y: 0)
    }
    override var loginNewPlayer: DeviceCoordinate {
        return DeviceCoordinate(x: 320, y: 925)
    }
    
    
    
    // MARK: - Item Clearing
    
    override var itemDeleteIncrease: DeviceCoordinate {
        return DeviceCoordinate(x: 540, y: 573)
    }
    override var itemDeleteConfirm: DeviceCoordinate {
        return DeviceCoordinate(x: 320, y: 826)
    }
    override var itemDeleteX: Int {
        return 686
    }
    override var itemGiftX: Int {
        return 154
    }
    override var itemEggX: Int {
        return 173
    }
    override var itemDeleteYs: [Int] {
        return [
            252,
            516,
            785,
            1053,
            1315
        ]
    }
    
}
