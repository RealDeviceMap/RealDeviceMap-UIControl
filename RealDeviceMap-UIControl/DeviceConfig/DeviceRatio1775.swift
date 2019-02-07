//
//  DeviceRatio1775.swift
//  RealDeviceMap-UIControlUITests
//
//  Created by Florian Kostenzer on 18.11.18.
//

import Foundation
import XCTest

class DeviceRatio1775: DeviceConfigProtocol {
    
    private var scaler: DeviceCoordinateScaler
    
    required init(width: Int, height: Int, multiplier: Double=1.0) {
        self.scaler = DeviceCoordinateScaler(widthNow: width, heightNow: height, widthTarget: 320, heightTarget: 568, multiplier: multiplier)
    }
    
    // MARK: - Startup
    
    var startup: DeviceCoordinate {
        return DeviceCoordinate(x: 320, y: 590, scaler: scaler)
    }
    var startupLoggedOut: DeviceCoordinate {
        return DeviceCoordinate(x: 320, y: 175, scaler: scaler)
    }
    var passenger: DeviceCoordinate {
        return DeviceCoordinate(x: 320, y: 775, scaler: scaler)
    }
    var weather: DeviceCoordinate {
        return DeviceCoordinate(x: 320, y: 780, scaler: scaler)
    }
    var closeWeather1: DeviceCoordinate {
        return DeviceCoordinate(x: 240, y: 975, scaler: scaler)
    }
    var closeWeather2: DeviceCoordinate {
        return DeviceCoordinate(x: 220, y: 1080, scaler: scaler)
    }
    var closeWarning: DeviceCoordinate {
        return DeviceCoordinate(x: 320, y: 960, scaler: scaler)
    }
    var closeNews: DeviceCoordinate {
        return DeviceCoordinate(x: 320, y: 960, scaler: scaler)
    }
    var compareWarningL: DeviceCoordinate {
        return DeviceCoordinate(x: 90, y: 950, scaler: scaler)
    }
    var compareWarningR: DeviceCoordinate {
        return DeviceCoordinate(x: 550, y: 950, scaler: scaler)
    }
    var closeFailedLogin: DeviceCoordinate {
        return DeviceCoordinate(x: 315, y: 665, scaler: scaler)
    }
    
    
    // MARK: - Misc
    
    var closeMenu: DeviceCoordinate {
        return DeviceCoordinate(x: 320, y: 1060, scaler: scaler)
    }
    
    
    // MARK: - Logout
    
    var settingsButton: DeviceCoordinate {
        return DeviceCoordinate(x: 600, y: 183, scaler: scaler)
    }
    var logoutDragStart: DeviceCoordinate {
        return DeviceCoordinate(x: 320, y: 900, scaler: scaler)
    }
    var logoutDragEnd: DeviceCoordinate {
        return DeviceCoordinate(x: 320, y: 100, scaler: scaler)
    }
    var logoutConfirm: DeviceCoordinate {
        return DeviceCoordinate(x: 320, y: 610, scaler: scaler)
    }
    var logoutCompareX: Int {
        return scaler.scaleY(y: 523)
    }

    
    // MARK: - Pokemon Encounter
    
    var encounterPokemonUpper: DeviceCoordinate {
        return DeviceCoordinate(x: 320, y: 740, scaler: scaler)
    }
    var encounterPokemonLower: DeviceCoordinate {
        return DeviceCoordinate(x: 320, y: 730, scaler: scaler)
    }
    var encounterNoAR: DeviceCoordinate {
        return DeviceCoordinate(x: 312, y: 1070, scaler: scaler)
    }
    var encounterNoARConfirm: DeviceCoordinate {
        return DeviceCoordinate(x: 320, y: 645, scaler: scaler)
    }
    var encounterTmp: DeviceCoordinate {
        return DeviceCoordinate(x: 575, y: 107, scaler: scaler)
    }
    var encounterPokemonRun: DeviceCoordinate {
        return DeviceCoordinate(x: 50, y: 75, scaler: scaler)
    }
    var encounterPokeball: DeviceCoordinate {
        return DeviceCoordinate(x: 570, y: 990, scaler: scaler)
    }
    
    
    // MARK: - Pokestop Encounter
    
    var openPokestop: DeviceCoordinate {
        return DeviceCoordinate(x: 320, y: 500, scaler: scaler)
    }
    
    
    // MARK: - Quest Clearing
    
    var openQuest: DeviceCoordinate {
        return DeviceCoordinate(x: 590, y: 970, scaler: scaler)
    }
    var questDelete: DeviceCoordinate {
        return DeviceCoordinate(x: 598, y: 530, scaler: scaler)
    }
    var questDeleteConfirm: DeviceCoordinate {
        return DeviceCoordinate(x: 320, y: 620, scaler: scaler)
    }
    var openItems: DeviceCoordinate {
        return DeviceCoordinate(x: 500, y: 950, scaler: scaler)
    }
    
    
    // MARK: - Item Clearing
    
    var itemDeleteIncrease: DeviceCoordinate {
        return DeviceCoordinate(x: 470, y: 510, scaler: scaler)
    }
    var itemDeleteConfirm: DeviceCoordinate {
        return DeviceCoordinate(x: 320, y: 710, scaler: scaler)
    }
    var itemDeleteX: Int {
        return scaler.scaleX(x: 585)
    }
    var itemGiftX: Int {
        return scaler.scaleX(x: 133)
    }
    var itemEggX: Int {
        return scaler.scaleX(x: 148)
    }
    var itemEggMenuItem: DeviceCoordinate {
        return DeviceCoordinate(x: 325, y: 225, scaler: scaler) //Anywhere in the first menu item
    }
    var itemEggDeploy: DeviceCoordinate {
        return DeviceCoordinate(x: 315, y: 880, scaler: scaler) // Taps the egg to deploy
    }
    var itemDeleteYs: [Int] {
        return [
            scaler.scaleY(y: 215),
            scaler.scaleY(y: 443),
            scaler.scaleY(y: 670),
            scaler.scaleY(y: 897),
            scaler.scaleY(y: 1124)
        ]
    }
    
    
    // MARK: - Login
    
    var loginNewPlayer: DeviceCoordinate {
        return DeviceCoordinate(x: 320, y: 785, scaler: scaler)
    }
    
    var loginPTC: DeviceCoordinate {
        return DeviceCoordinate(x: 320, y: 800, scaler: scaler)
    }
    
    var loginUsernameTextfield: DeviceCoordinate {
        return DeviceCoordinate(x: 320, y: 500, scaler: scaler)
    }
    
    var loginPasswordTextfield: DeviceCoordinate {
        return DeviceCoordinate(x: 320, y: 600, scaler: scaler)
    }
    
    var loginConfirm: DeviceCoordinate {
        return DeviceCoordinate(x: 375, y: 680, scaler: scaler)
    }
    
    var loginBannedBackground: DeviceCoordinate {
        return DeviceCoordinate(x: 100, y: 900, scaler: scaler)
    }
    
    var loginBannedText: DeviceCoordinate {
        return DeviceCoordinate(x: 320, y: 700, scaler: scaler)
    }
    
    var loginBanned: DeviceCoordinate {
        return DeviceCoordinate(x: 320, y: 575, scaler: scaler)
    }
    
    var loginBannedSwitchAccount: DeviceCoordinate {
        return DeviceCoordinate(x: 320, y: 660, scaler: scaler)
    }
    
    var loginTermsText: DeviceCoordinate {
        return DeviceCoordinate(x: 109, y: 351, scaler: scaler)
    }
    
    var loginTerms: DeviceCoordinate {
        return DeviceCoordinate(x: 320, y: 600, scaler: scaler)
    }
    
    var loginTerms2Text: DeviceCoordinate {
        return DeviceCoordinate(x: 109, y: 374, scaler: scaler)
    }
    
    var loginTerms2: DeviceCoordinate {
        return DeviceCoordinate(x: 320, y: 620, scaler: scaler)
    }
    
    var loginFailedText: DeviceCoordinate {
        return DeviceCoordinate(x: 140, y: 446, scaler: scaler)
    }
    
    var loginFailed: DeviceCoordinate {
        return DeviceCoordinate(x: 320, y: 700, scaler: scaler)
    }
    
    var loginPrivacyText: DeviceCoordinate {
        return DeviceCoordinate(x: 320, y: 720, scaler: scaler)
    }
    
    var loginPrivacy: DeviceCoordinate {
        return DeviceCoordinate(x: 320, y: 600, scaler: scaler)
    }
    
    
    // MARK: - Tutorial
 
    
    var compareTutorialL: DeviceCoordinate {
        return DeviceCoordinate(x: 100, y: 900, scaler: scaler)
    }
    
    var compareTutorialR: DeviceCoordinate {
        return DeviceCoordinate(x: 550, y: 900, scaler: scaler)
    }
    
    var tutorialNext: DeviceCoordinate {
        return DeviceCoordinate(x: 565, y: 1085, scaler: scaler)
    }
    
    var tutorialStyleDone: DeviceCoordinate {
        return DeviceCoordinate(x: 320, y: 610, scaler: scaler)
    }
    
    var tutorialCatchOk: DeviceCoordinate {
        return DeviceCoordinate(x: 320, y: 750, scaler: scaler)
    }
    
    var tutorialCatchClose: DeviceCoordinate {
        return DeviceCoordinate(x: 320, y: 1050, scaler: scaler)
    }
    
    var tutorialKeybordDone: DeviceCoordinate {
        return DeviceCoordinate(x: 550, y: 1075, scaler: scaler)
    }
    
    var tutorialUsernameOk: DeviceCoordinate {
        return DeviceCoordinate(x: 320, y: 770, scaler: scaler)
    }
    
    var tutorialUsernameConfirm: DeviceCoordinate {
        return DeviceCoordinate(x: 320, y: 620, scaler: scaler)
    }
    
    
    // MARK: - Adevture Sync
    var adventureSyncRewards: DeviceCoordinate {
        return DeviceCoordinate(x: 320, y: 330, scaler: scaler)
    }
    var adventureSyncButton: DeviceCoordinate {
        return DeviceCoordinate(x: 320, y: 975, scaler: scaler)
    }
    
    
    // MARK: - Team Select

    var teamSelectBackgorundL: DeviceCoordinate {
        return DeviceCoordinate(x: 100, y: 800, scaler: scaler)
    }
    
    var teamSelectBackgorundR: DeviceCoordinate {
        return DeviceCoordinate(x: 550, y: 800, scaler: scaler)
    }
    
    var teamSelectNext: DeviceCoordinate {
        return DeviceCoordinate(x: 550, y: 1055, scaler: scaler)
    }
    
    var teamSelectY: Int {
        return scaler.scaleY(y: 700)
    }
    
    var teamSelectWelcomeOk: DeviceCoordinate {
        return DeviceCoordinate(x: 320, y: 610, scaler: scaler)
    }
    
}
