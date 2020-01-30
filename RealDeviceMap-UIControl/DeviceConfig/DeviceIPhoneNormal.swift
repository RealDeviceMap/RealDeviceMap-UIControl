//
//  DeviceIPhoneNormal.swift
//  RealDeviceMap-UIControlUITests
//
//  Created by Florian Kostenzer on 19.11.18.
//

import Foundation

class DeviceIPhoneNormal: DeviceRatio1775 {

    // All values not overriden here default to DeviceRatio1775s values
    override var startup: DeviceCoordinate {
        return DeviceCoordinate(x: 325, y: 960, tapScaler: tapScaler)
    }
    override var startupNewButton: DeviceCoordinate {
        return DeviceCoordinate(x: 475, y: 960, tapScaler: tapScaler)
    }
    override var startupNewCautionSign: DeviceCoordinate {
        return DeviceCoordinate(x: 375, y: 385, tapScaler: tapScaler)
    }
    override var loginTerms2Text: DeviceCoordinate {
        return DeviceCoordinate(x: 188, y: 450, tapScaler: tapScaler)
    }
    override var loginTerms2: DeviceCoordinate {
        return DeviceCoordinate(x: 375, y: 725, tapScaler: tapScaler)
    }
    override var startupLoggedOut: DeviceCoordinate {
        return DeviceCoordinate(x: 400, y: 115, tapScaler: tapScaler)
    }
    override var encounterNoARConfirm: DeviceCoordinate {  //no AR popup after saying no on iPhone6
        return DeviceCoordinate(x: 0, y: 0, tapScaler: tapScaler)
    }
    override var encounterTmp: DeviceCoordinate {
        return DeviceCoordinate(x: 0, y: 0, tapScaler: tapScaler)
    }
    override var closeFailedLogin: DeviceCoordinate {
        return DeviceCoordinate(x: 383, y: 779, tapScaler: tapScaler)
    }
    override var loginNewPlayer: DeviceCoordinate {
        return DeviceCoordinate(x: 320, y: 925, tapScaler: tapScaler)
    }
    override var loginPrivacyUpdateText: DeviceCoordinate {
        return DeviceCoordinate(x: 133, y: 459, tapScaler: tapScaler)
    }
    override var loginPrivacyUpdate: DeviceCoordinate {
        return DeviceCoordinate(x: 375, y: 745, tapScaler: tapScaler)
    }

    // MARK: - Item Clearing

    override var itemDeleteIncrease: DeviceCoordinate {
        return DeviceCoordinate(x: 540, y: 573, tapScaler: tapScaler)
    }
    override var itemDeleteConfirm: DeviceCoordinate {
        return DeviceCoordinate(x: 320, y: 826, tapScaler: tapScaler)
    }
    override var itemDeleteX: Int {
        return 686
    }
    override var itemGiftX: Int {
        return 156
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
