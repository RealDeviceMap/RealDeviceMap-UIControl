//
//  RealDeviceMap_UIControlUITests.swift
//  RealDeviceMap-UIControlUITests
//
//  Created by Florian Kostenzer on 28.09.18.
//

import Foundation
import XCTest
import Embassy
import EnvoyAmbassador
import CoreLocation

class RealDeviceMap_UIControlUITests: XCTestCase {
    
    var backendControlerURL: URL!
    var backendRawURL: URL!
    var isStarted = false
    var currentLocation: (lat: Double, lon: Double)?
    var waitRequiresPokemon = false
    var waitForData = false
    var lock = NSLock()
    var firstWarningDate: Date?
    var jitterCorner = 0
    var gotQuest = false
    var gotIV = false
    var noQuestCount = 0
    var noEncounterCount = 0
    var targetMaxDistance = 250.0
    var emptyGmoCount = 0
    var pokemonEncounterId: String?
    var encounterDistance = 0.0
    
    var level: Int = 0
    
    var shouldExit: Bool {
        get {
            return UserDefaults.standard.bool(forKey: "should_exit")
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "should_exit")
            UserDefaults.standard.synchronize()
        }
    }
    
    var username: String? {
        get {
            return UserDefaults.standard.string(forKey: "username")
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "username")
            UserDefaults.standard.synchronize()
        }
    }
    var password: String? {
        get {
            return UserDefaults.standard.string(forKey: "password")
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "password")
            UserDefaults.standard.synchronize()
        }
    }
    var newLogIn: Bool {
        get {
            return UserDefaults.standard.bool(forKey: "new_log_in")
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "new_log_in")
            UserDefaults.standard.synchronize()
        }
    }
    var isLoggedIn: Bool {
        get {
            return UserDefaults.standard.bool(forKey: "is_logged_in")
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "is_logged_in")
            UserDefaults.standard.synchronize()
        }
    }
    var newCreated: Bool {
        get {
            return UserDefaults.standard.bool(forKey: "new_created")
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "new_created")
            UserDefaults.standard.synchronize()
        }
    }
    var needsLogout: Bool {
        get {
            return UserDefaults.standard.bool(forKey: "needs_logout")
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "needs_logout")
            UserDefaults.standard.synchronize()
        }
    }
    
    var minLevel: Int {
        get {
            if UserDefaults.standard.object(forKey: "min_level") == nil {
                return 0
            }
            return UserDefaults.standard.integer(forKey: "min_level")
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "min_level")
            UserDefaults.standard.synchronize()
        }
    }
    var maxLevel: Int {
        get {
            if UserDefaults.standard.object(forKey: "max_level") == nil {
                return 29
            }
            return UserDefaults.standard.integer(forKey: "max_level")
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "max_level")
            UserDefaults.standard.synchronize()
        }
    }
    var zoomedOut: Bool {
        get {
            return UserDefaults.standard.bool(forKey: "zoomed_out")
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "zoomed_out")
            UserDefaults.standard.synchronize()
        }
    }
    
    override func setUp() {
        super.setUp()
        
        backendControlerURL = URL(string: config.backendURLBaseString + "/controler")!
        backendRawURL = URL(string: config.backendURLBaseString + "/raw")!
        continueAfterFailure = false
        
    }
    
    func test0Setup() {
        
        print("[STATUS] Started")
        
        shouldExit = false
        newCreated = false
        needsLogout = false
        
        app.terminate()

        // Wake up device if screen is off (recently rebooted), then press home to get to home screen.
        Log.info("Waking up the device")
        XCUIDevice.shared.press(.home)
        XCUIDevice.shared.press(.home)

        // Register on backend
        postRequest(url: backendControlerURL, data: ["uuid": config.uuid, "username": self.username as Any, "type": "init"], blocking: true) { (result) in
            if result == nil {
                Log.error("Failed to connect to Backend!")
                self.shouldExit = true
                return
            } else if result!["status"] as? String != "ok" {
                let error = result!["error"] ?? "? (no error sent)"
                Log.error("Backend returned a error: \(error)")
                self.shouldExit = true
                return
            }
            let data = result!["data"] as? [String: Any]
            if data == nil {
                Log.error("Backend did not include data!")
                self.shouldExit = true
                return
            }
            if data!["assigned"] as? Bool == false {
                Log.error("Device is not assigned to an instance!")
                self.shouldExit = true
                return
            }
            if let firstWarningTimestamp = data!["first_warning_timestamp"] as? Int {
                self.firstWarningDate = Date(timeIntervalSince1970: Double(firstWarningTimestamp))
            }
            Log.info("Connected to Backend sucesfully")
            
        }
        
        if shouldExit {
            return
        }
        
        if username == nil && config.enableAccountManager {
            postRequest(url: backendControlerURL, data: ["uuid": config.uuid, "username": self.username as Any, "type": "get_account", "min_level": minLevel, "max_level": maxLevel], blocking: true) { (result) in
                guard
                    let data = result!["data"] as? [String: Any],
                    let username = data["username"] as? String,
                    let password = data["password"] as? String
                    else {
                        Log.error("Failed to get account and not logged in.")
                        self.shouldExit = true
                        return
                }
                self.username = username
                self.password = password
                self.newLogIn = true
                self.isLoggedIn = false
                
                if let firstWarningTimestamp = data["first_warning_timestamp"] as? Int {
                    self.firstWarningDate = Date(timeIntervalSince1970: Double(firstWarningTimestamp))
                }
                
                Log.info("Got account \(username) from backend.")
            }
        }
        
        app.launch()
        while app.state != .runningForeground {
            sleep(1)
            app.activate()
            Log.debug("Waiting for App to run in foreground. Currently \(app.state).")
        }
        DeviceConfig.setup(app: app)
        
    }
    
    func test1LoginSetup() {
        
        if shouldExit || !config.enableAccountManager {
            return
        }
        
        if username != nil && !isLoggedIn {
            
            print("[STATUS] Login")
            
            var loaded = false
            var count = 0
            while !loaded {
                let screenshotComp = XCUIScreen.main.screenshot()
                if (screenshotComp.rgbAtLocation(
                    pos: deviceConfig.loginBanned,
                    min: (red: 0.0, green: 0.75, blue: 0.55),
                    max: (red: 1.0, green: 0.90, blue: 0.70)) &&
                    screenshotComp.rgbAtLocation(
                        pos: deviceConfig.loginBannedText,
                        min: (red: 0.0, green: 0.75, blue: 0.55),
                        max: (red: 1.0, green: 0.90, blue: 0.70))
                    ) {
                    deviceConfig.loginBannedSwitchAccount.toXCUICoordinate(app: app).tap()
                    username = nil
                    isLoggedIn = false
                    sleep(7 * config.delayMultiplier)
                    shouldExit = true
                    return
                }
                else if screenshotComp.rgbAtLocation(
                    pos: self.deviceConfig.startup,
                    min: (red: 0.0, green: 0.75, blue: 0.55),
                    max: (red: 1.0, green: 0.90, blue: 0.70)) {
                    Log.info("Tried to log in but allready logged in.")
                    needsLogout = true
                    isLoggedIn = true
                    newLogIn = false
                    return
                } else if screenshotComp.rgbAtLocation(
                    pos: self.deviceConfig.startupLoggedOut,
                    min: (0.95, 0.75, 0.0),
                    max: (1.00, 0.85, 0.1)) {
                    Log.debug("App Started in login screen.")
                    loaded = true
                }
                count += 1
                if count == 60 && !loaded {
                    count = 0
                    app.launch()
                    sleep(1 * config.delayMultiplier)
                }
                sleep(1 * config.delayMultiplier)
            }
            
            sleep(1 * config.delayMultiplier)
            deviceConfig.loginNewPlayer.toXCUICoordinate(app: app).tap()
            sleep(1 * config.delayMultiplier)
            deviceConfig.loginPTC.toXCUICoordinate(app: app).tap()
        }
    }
    
    func test2LoginUsername() {
        
        if shouldExit || !config.enableAccountManager {
            return
        }
        
        if username != nil && !isLoggedIn {
            
            sleep(1 * config.delayMultiplier)
            deviceConfig.loginUsernameTextfield.toXCUICoordinate(app: app).tap()
            sleep(1 * config.delayMultiplier)
            continueAfterFailure = true
            app.typeText(username!)
        }
        
    }
    
    func test3LoginPassword() {
        
        if shouldExit || !config.enableAccountManager {
            return
        }
        
        if username != nil && !isLoggedIn {
            
            sleep(1 * config.delayMultiplier)
            deviceConfig.loginPasswordTextfield.toXCUICoordinate(app: app).tap()
            sleep(1 * config.delayMultiplier)
            continueAfterFailure = true
            app.typeText(password!)
            
        }
        
    }
    
    func test4LoginEnd() {
        
        if shouldExit || !config.enableAccountManager {
            return
        }
        
        if username != nil && !isLoggedIn {
            
            sleep(1 * config.delayMultiplier)
            deviceConfig.loginConfirm.toXCUICoordinate(app: app).tap()
            sleep(1 * config.delayMultiplier)
            
            var loggedIn = false
            var count = 0
            
            while !loggedIn {
                
                if app.state != .runningForeground {
                    app.launch()
                    sleep(10 * config.delayMultiplier)
                }
                
                let screenshotComp = XCUIScreen.main.screenshot()
                
                if (screenshotComp.rgbAtLocation(
                    pos: deviceConfig.loginBannedBackground,
                    min: (red: 0.0, green: 0.2, blue: 0.3),
                    max: (red: 0.05, green: 0.3, blue: 0.4))
                    ) {
                    Log.debug("Got ban. Restarting...")
                    app.launch()
                    sleep(10 * config.delayMultiplier)
                } else if (
                    screenshotComp.rgbAtLocation(
                        pos: deviceConfig.loginTerms,
                        min: (red: 0.0, green: 0.75, blue: 0.55),
                        max: (red: 1.0, green: 0.90, blue: 0.70)) &&
                        screenshotComp.rgbAtLocation(
                            pos: deviceConfig.loginTermsText,
                            min: (red: 0.0, green: 0.0, blue: 0.0),
                            max: (red: 0.3, green: 0.5, blue: 0.5))
                    ) {
                    Log.debug("Accepting Terms")
                    deviceConfig.loginTerms.toXCUICoordinate(app: app).tap()
                    sleep(2 * config.delayMultiplier)
                } else if (
                    screenshotComp.rgbAtLocation(
                        pos: deviceConfig.loginTerms2,
                        min: (red: 0.0, green: 0.75, blue: 0.55),
                        max: (red: 1.0, green: 0.90, blue: 0.70)) &&
                        screenshotComp.rgbAtLocation(
                            pos: deviceConfig.loginTerms2Text,
                            min: (red: 0.0, green: 0.0, blue: 0.0),
                            max: (red: 0.3, green: 0.5, blue: 0.5))
                    ) {
                    Log.debug("Accepting Updated Terms.")
                    deviceConfig.loginTerms2.toXCUICoordinate(app: app).tap()
                    sleep(2 * config.delayMultiplier)
                } else if (
                    screenshotComp.rgbAtLocation(
                        pos: deviceConfig.loginPrivacy,
                        min: (red: 0.0, green: 0.75, blue: 0.55),
                        max: (red: 1.0, green: 0.90, blue: 0.70)) &&
                        screenshotComp.rgbAtLocation(
                            pos: deviceConfig.loginPrivacyText,
                            min: (red: 0.0, green: 0.75, blue: 0.55),
                            max: (red: 1.0, green: 0.90, blue: 0.70))
                    ) {
                    Log.debug("Accepting Privacy.")
                    deviceConfig.loginPrivacy.toXCUICoordinate(app: app).tap()
                    sleep(2 * config.delayMultiplier)
                } else if (
                    screenshotComp.rgbAtLocation(
                        pos: deviceConfig.loginBanned,
                        min: (red: 0.0, green: 0.75, blue: 0.55),
                        max: (red: 1.0, green: 0.90, blue: 0.70)) &&
                        screenshotComp.rgbAtLocation(
                            pos: deviceConfig.loginBannedText,
                            min: (red: 0.0, green: 0.75, blue: 0.55),
                            max: (red: 1.0, green: 0.90, blue: 0.70))
                    ) {
                    Log.error("Account \(username!) is banned.")
                    deviceConfig.loginBannedSwitchAccount.toXCUICoordinate(app: app).tap()
                    postRequest(url: backendControlerURL, data: ["uuid": config.uuid, "username": self.username as Any, "type": "account_banned"], blocking: true) { (result) in }
                    username = nil
                    isLoggedIn = false
                    sleep(7 * config.delayMultiplier)
                    shouldExit = true
                    return
                } else if (
                    screenshotComp.rgbAtLocation(
                        pos: deviceConfig.loginFailed,
                        min: (red: 0.0, green: 0.75, blue: 0.55),
                        max: (red: 1.0, green: 0.90, blue: 0.70)) &&
                        screenshotComp.rgbAtLocation(
                            pos: deviceConfig.loginFailedText,
                            min: (red: 0.0, green: 0.0, blue: 0.0),
                            max: (red: 0.3, green: 0.5, blue: 0.5))
                    ) {
                    Log.error("Invalid credentials for \(username!)")
                    username = nil
                    isLoggedIn = false
                    postRequest(url: backendControlerURL, data: ["uuid": config.uuid, "username": self.username as Any, "type": "account_invalid_credentials"], blocking: true) { (result) in }
                    sleep(7 * config.delayMultiplier)
                    shouldExit = true
                    return
                } else if (
                    screenshotComp.rgbAtLocation(
                        pos: deviceConfig.startup,
                        min: (red: 0.0, green: 0.75, blue: 0.55),
                        max: (red: 1.0, green: 0.90, blue: 0.70))
                        || isTutorial()
                    ) {
                    loggedIn = true
                    isLoggedIn = true
                    Log.info("Logged in as \(username!)")
                } else {
                    count += 1
                    if count == 60 {
                        Log.error("Login timed out. Restarting...")
                        shouldExit = true
                        return
                    }
                    sleep(2 * config.delayMultiplier)
                }
                
            }
            
        }
    }
    
    func test5TutorialStart() {
        
        if shouldExit || username == nil || !isLoggedIn || !config.enableAccountManager {
            return
        }
        
        if newLogIn {
            
            print("[STATUS] Tutorial")
            
            sleep(4 * config.delayMultiplier)
            
            if !isTutorial() {
                Log.info("Tutorial already done. Restarting...")
                self.postRequest(url: self.backendControlerURL, data: ["uuid": self.config.uuid, "username": self.username as Any, "type": "tutorial_done"], blocking: true) { (result) in }
                newCreated = true
                newLogIn = false
                app.launch()
                sleep(1 * config.delayMultiplier)
                
                return
            }
            
            Log.info("Solving Tutorial for \(username!)")
            
            for _ in 1...9 {
                deviceConfig.tutorialNext.toXCUICoordinate(app: app).tap()
                usleep(UInt32(1500000 * config.delayMultiplier))
            }
            sleep(2 * config.delayMultiplier)
            for _ in 1...4 {
                deviceConfig.tutorialNext.toXCUICoordinate(app: app).tap()
                usleep(UInt32(1500000 * config.delayMultiplier))
            }
            
            deviceConfig.tutorialStyleDone.toXCUICoordinate(app: app).tap()
            sleep(3 * config.delayMultiplier)
            deviceConfig.tutorialNext.toXCUICoordinate(app: app).tap()
            usleep(UInt32(1500000 * config.delayMultiplier))
            deviceConfig.tutorialNext.toXCUICoordinate(app: app).tap()
            sleep(3 * config.delayMultiplier)
            
            while !findAndClickPokemon() {
                app.swipeLeft()
            }
            
            sleep(4 * config.delayMultiplier)
            deviceConfig.encounterNoAR.toXCUICoordinate(app: app).tap()
            sleep(2 * config.delayMultiplier)
            deviceConfig.encounterNoARConfirm.toXCUICoordinate(app: app).tap()
            sleep(3 * config.delayMultiplier)
            deviceConfig.encounterTmp.toXCUICoordinate(app: app).tap()
            sleep(3 * config.delayMultiplier)
            for _ in 1...5 {
                app.swipeUp()
                sleep(3 * config.delayMultiplier)
            }
            sleep(10 * config.delayMultiplier)
            deviceConfig.tutorialCatchOk.toXCUICoordinate(app: app).tap()
            sleep(7 * config.delayMultiplier)
            deviceConfig.tutorialCatchClose.toXCUICoordinate(app: app).tap()
            sleep(3 * config.delayMultiplier)
            for _ in 1...2 {
                deviceConfig.tutorialNext.toXCUICoordinate(app: app).tap()
                sleep(1 * config.delayMultiplier)
            }
            self.postRequest(url: self.backendControlerURL, data: ["uuid": self.config.uuid, "username": self.username as Any, "type": "tutorial_done"], blocking: true) { (result) in }
        }
        
    }
    
    func test6TutorialUsername() {
        
        if shouldExit || username == nil || !isLoggedIn || !config.enableAccountManager {
            return
        }
        
        if newLogIn {
            
            continueAfterFailure = true
            app.typeText(username!)
            
        }
        
    }
    
    func test7TutorialEnd() {
        
        if shouldExit || username == nil || !isLoggedIn || !config.enableAccountManager {
            return
        }
        
        if newLogIn {
            
            sleep(2 * config.delayMultiplier)
            deviceConfig.tutorialKeybordDone.toXCUICoordinate(app: app).tap()
            sleep(1 * config.delayMultiplier)
            deviceConfig.tutorialUsernameOk.toXCUICoordinate(app: app).tap()
            sleep(1 * config.delayMultiplier)
            deviceConfig.tutorialUsernameConfirm.toXCUICoordinate(app: app).tap()
            sleep(4 * config.delayMultiplier)
            
            for _ in 1...6 {
                deviceConfig.tutorialNext.toXCUICoordinate(app: app).tap()
                sleep(1 * config.delayMultiplier)
            }
            sleep(1 * config.delayMultiplier)
            deviceConfig.tutorialNext.toXCUICoordinate(app: app).tap()
            
            Log.info("Tutorial Done. Restarting...")
            newCreated = true
            newLogIn = false
            app.launch()
            sleep(1 * config.delayMultiplier)
        }
        
    }
    
    func test999Main() {
        
        if shouldExit || ((username == nil || isLoggedIn == false) && config.enableAccountManager) {
            return
        }
        
        let loop = try! SelectorEventLoop(selector: try! KqueueSelector())
        let router = Router()
        let server = DefaultHTTPServer(eventLoop: loop, interface: "0.0.0.0", port: config.port, app: router.app)
        
        router["/loc"] = DelayResponse(JSONResponse(handler: { environ -> Any in
            
            self.lock.lock()
            let currentLocation = self.currentLocation
            if currentLocation != nil {
                if self.waitRequiresPokemon {
                    self.lock.unlock()
                    
                    let jitterValue = self.config.jitterValue
                    
                    let jitterLat: Double
                    let jitterLon: Double
                    switch self.jitterCorner {
                    case 0:
                        jitterLat = jitterValue
                        jitterLon = jitterValue
                        self.jitterCorner = 1
                    case 1:
                        jitterLat = -jitterValue
                        jitterLon = jitterValue
                        self.jitterCorner = 2
                    case 2:
                        jitterLat = -jitterValue
                        jitterLon = -jitterValue
                        self.jitterCorner = 3
                    default:
                        jitterLat = jitterValue
                        jitterLon = -jitterValue
                        self.jitterCorner = 0
                    }
                    
                    return [
                        "latitude": currentLocation!.lat + jitterLat,
                        "longitude": currentLocation!.lon + jitterLon,
                        "lat": currentLocation!.lat + jitterLat,
                        "lng": currentLocation!.lon + jitterLon
                    ]
                } else {
                    self.lock.unlock()
                    return [
                        "latitude": currentLocation!.lat,
                        "longitude": currentLocation!.lon,
                        "lat": currentLocation!.lat,
                        "lng": currentLocation!.lon
                    ]
                }
            } else {
                self.lock.unlock()
                return []
            }
        }), delay: .delay(seconds: 0.01))
        
        router["/data"] = DelayResponse(JSONResponse(handler: { environ -> Any in
            let input = environ["swsgi.input"] as! SWSGIInput
            DataReader.read(input) { data in
                
                self.lock.lock()
                let currentLocation = self.currentLocation
                let targetMaxDistance = self.targetMaxDistance
                let pokemonEncounterId = self.pokemonEncounterId
                self.lock.unlock()
                
                var jsonData: [String: Any]?
                do {
                    jsonData = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                } catch {
                    return
                }
                
                if jsonData != nil && currentLocation != nil {
                    jsonData!["lat_target"] = currentLocation!.lat
                    jsonData!["lon_target"] = currentLocation!.lon
                    jsonData!["target_max_distnace"] = targetMaxDistance
                    jsonData!["username"] = self.username
                    jsonData!["pokemon_encounter_id"] = pokemonEncounterId
                    
                    let url = self.backendRawURL
                    
                    self.postRequest(url: url!, data: jsonData!, blocking: true, completion: { (resultJson) in
                        
                        let data = resultJson?["data"] as? [String: Any]
                        let inArea = data?["in_area"] as? Bool ?? false
                        let level = data?["level"] as? Int ?? 0
                        let nearby = data?["nearby"] as? Int ?? 0
                        let wild = data?["wild"] as? Int ?? 0
                        //let forts = data?["forts"] as? Int ?? 0
                        let quests = data?["quests"] as? Int ?? 0
                        let encounters = data?["encounters"] as? Int ?? 0
                        let pokemonLat = data?["pokemon_lat"] as? Double
                        let pokemonLon = data?["pokemon_lon"] as? Double
                        let pokemonEncounterIdResult = data?["pokemon_encounter_id"] as? String
                        let targetLat = data?["lat_target"] as? Double ?? 0
                        let targetLon = data?["lon_target"] as? Double ?? 0
                        let onlyEmptyGmos = data?["only_empty_gmos"] as? Bool ?? true
                        let onlyInvalidGmos = data?["only_invalid_gmos"] as? Bool ?? false
                        
                        if level != 0 {
                            self.level = level
                        }
                        
                        let toPrint: String
                        
                        self.lock.lock()
                        let diffLat = fabs((self.currentLocation?.lat ?? 0) - targetLat)
                        let diffLon = fabs((self.currentLocation?.lon ?? 0) - targetLon)
                        
                        if onlyInvalidGmos {
                            self.waitForData = false
                            toPrint = "[DEBUG] Got GMO but it was malformed. Skipping."
                        } else {
                            if inArea && diffLat < 0.0001 && diffLon < 0.0001 {
                                self.emptyGmoCount = 0
                                
                                if self.pokemonEncounterId != nil {
                                    if (nearby + wild) > 0 {
                                        if pokemonLat != nil && pokemonLon != nil && self.pokemonEncounterId == pokemonEncounterIdResult {
                                            self.waitRequiresPokemon = false
                                            let oldLocation = CLLocation(latitude: self.currentLocation!.lat, longitude: self.currentLocation!.lon)
                                            self.currentLocation = (pokemonLat!, pokemonLon!)
                                            let newLocation = CLLocation(latitude: self.currentLocation!.lat, longitude: self.currentLocation!.lon)
                                            self.encounterDistance = newLocation.distance(from: oldLocation)
                                            self.pokemonEncounterId = nil
                                            self.waitForData = false
                                            toPrint = "[DEBUG] Got Data and found Pokemon"
                                        } else {
                                            toPrint = "[DEBUG] Got Data but didn't find Pokemon"
                                        }
                                    } else {
                                        toPrint = "[DEBUG] Got Data without Pokemon"
                                    }
                                    
                                } else if self.waitRequiresPokemon {
                                    if (nearby + wild) > 0 {
                                        toPrint = "[DEBUG] Got Data with Pokemon"
                                        self.waitForData = false
                                    } else {
                                        toPrint = "[DEBUG] Got Data without Pokemon"
                                    }
                                } else {
                                    toPrint = "[DEBUG] Got Data"
                                    self.waitForData = false
                                }
                            } else if onlyEmptyGmos {
                                self.emptyGmoCount += 1
                                toPrint = "[DEBUG] Got Empty Data"
                            } else {
                                self.emptyGmoCount = 0
                                toPrint = "[DEBUG] Got Data outside Target-Area"
                            }
                        }
                        if !self.gotQuest && quests != 0 {
                            self.gotQuest = true
                        }
                        if !self.gotIV && encounters != 0 {
                            self.gotIV = true
                        }
                        self.lock.unlock()
                        print(toPrint)
                    })
                }
            }
            return []
        }), delay: .delay(seconds: 0.01))
        
        // Start HTTP server to listen on the port
        try! server.start()
        
        // Run event loop
        DispatchQueue(label: "http_server").async {
            loop.runForever()
        }
        
        Log.info("Server running at localhost:\(config.port)")
        
        // Start Heartbeat
        DispatchQueue(label: "heartbeat_sender").async {
            while true {
                sleep(5)
                self.postRequest(url: self.backendControlerURL, data: ["uuid": self.config.uuid, "username": self.username as Any, "type": "heartbeat"]) { (cake) in /* The cake is a lie! */ }
            }
        }
        
        
        // Time to start the actuall work
        runLoop()
        
    }
    
    func runLoop() {
        
        if shouldExit {
            return
        }
        
        isStarted = false
        
        // State vars
        var startupCount = 0
        var isStartupCompleted = false
        var hasWarning = false
        
        var currentQuests = self.config.questFullCount
        var currentItems = self.config.itemFullCount
        
        var failedToGetJobCount = 0
        var failedCount = 0
        
        app.activate()
        
        print("[STATUS] Startup")
        
        while !shouldExit {
            
            if app.state != .runningForeground {
                startupCount = 0
                emptyGmoCount = 0
                noEncounterCount = 0
                noQuestCount = 0
                failedCount = 0
                isStarted = false
                isStartupCompleted = false
                app.launch()
                while app.state != .runningForeground {
                    sleep(1)
                    app.activate()
                    Log.debug("Waiting for App to run in foreground. Currently \(app.state).")
                }
            } else {
                app.coordinate(withNormalizedOffset: CGVector(dx: 0, dy: 0)).tap()
            }
            
            if isStarted {
                if !isStartupCompleted {
                    Log.debug("Performing Startup sequence")
                    currentLocation = config.startupLocation
                    deviceConfig.startup.toXCUICoordinate(app: app).tap()
                    sleep(2 * config.delayMultiplier)
                    
                    deviceConfig.closeNews.toXCUICoordinate(app: app).tap()
                    sleep(1 * config.delayMultiplier)
                    hasWarning = self.checkHasWarning()
                    if hasWarning {
                        if self.firstWarningDate == nil && config.enableAccountManager {
                            firstWarningDate = Date()
                            postRequest(url: backendControlerURL, data: ["uuid": config.uuid, "username": self.username as Any, "type": "account_warning"], blocking: true) { (result) in }
                        }
                        Log.info("Account has a warning!")
                        deviceConfig.closeWarning.toXCUICoordinate(app: app).tap()
                        sleep(1 * config.delayMultiplier)
                    }
                    
                    sleep(2 * config.delayMultiplier)
                    self.freeScreen()
                    deviceConfig.closeNews.toXCUICoordinate(app: app).tap()
                    sleep(1 * config.delayMultiplier)
                    self.freeScreen()
                    sleep(1 * config.delayMultiplier)
                    if zoomedOut {
                        deviceConfig.startup.toXCUICoordinate(app: app).tap()
                        app.swipeUp()
                        deviceConfig.startup.toXCUICoordinate(app: app).tap()
                        app.swipeUp()
                        deviceConfig.startup.toXCUICoordinate(app: app).tap()
                        app.swipeUp()
                    } else {
                        deviceConfig.startup.toXCUICoordinate(app: app).tap()
                        app.swipeDown()
                        deviceConfig.startup.toXCUICoordinate(app: app).tap()
                        app.swipeDown()
                        deviceConfig.startup.toXCUICoordinate(app: app).tap()
                        app.swipeDown()
                    }
                    sleep(1 * config.delayMultiplier)
                    
                    isStartupCompleted = true
                    
                    if needsLogout {
                        needsLogout = false
                        let success = self.logOut()
                        if !success {
                            return
                        }
                        
                        self.postRequest(url: self.backendControlerURL, data: ["uuid": self.config.uuid, "username": self.username as Any, "type": "logged_out"], blocking: true) { (result) in }
                        self.username = nil
                        self.isLoggedIn = false
                        UserDefaults.standard.synchronize()
                        sleep(7 * self.config.delayMultiplier)
                        self.shouldExit = true
                        return
                    }
                } else {
                    
                    // Work work work
                    postRequest(url: backendControlerURL, data: ["uuid": config.uuid, "username": self.username as Any, "type": "get_job"], blocking: true) { (result) in
                        
                        if result == nil {
                            if failedToGetJobCount == 10 {
                                Log.error("Failed to get a job 10 times in a row. Exiting...")
                                self.shouldExit = true
                                return
                            } else {
                                Log.error("Failed to get a job")
                                failedToGetJobCount += 1
                                sleep(5 * self.config.delayMultiplier)
                                return
                            }
                        } else if self.config.enableAccountManager == true, let data = result!["data"] as? [String: Any], let minLevel = data["min_level"] as? Int, let maxLevel = data["max_level"] as? Int {
                            self.minLevel = minLevel
                            self.maxLevel = maxLevel
                            if self.level != 0 && (self.level < minLevel || self.level > maxLevel) {
                                Log.info("Account is outside min/max Level. Current: \(self.level) Min/Max: \(minLevel)/\(maxLevel). Logging out!")
                                let success = self.logOut()
                                if !success {
                                    return
                                }
                                
                                self.postRequest(url: self.backendControlerURL, data: ["uuid": self.config.uuid, "username": self.username as Any, "type": "logged_out"], blocking: true) { (result) in }
                                self.username = nil
                                self.isLoggedIn = false
                                UserDefaults.standard.synchronize()
                                sleep(7 * self.config.delayMultiplier)
                                self.shouldExit = true
                                return
                            }
                        }
                        
                        failedToGetJobCount = 0
                        
                        if let data = result!["data"] as? [String: Any], let action = data["action"] as? String {
                            if action == "scan_pokemon" {
                                print("[STATUS] Pokemon")
                                if hasWarning && self.config.enableAccountManager {
                                    Log.info("Account has a warning and tried to scan for Pokemon. Logging out!")
                                    let success = self.logOut()
                                    if !success {
                                        return
                                    }
                                    
                                    self.postRequest(url: self.backendControlerURL, data: ["uuid": self.config.uuid, "username": self.username as Any, "type": "logged_out"], blocking: true) { (result) in }
                                    self.username = nil
                                    self.isLoggedIn = false
                                    UserDefaults.standard.synchronize()
                                    sleep(7 * self.config.delayMultiplier)
                                    self.shouldExit = true
                                    return
                                }
                                
                                let lat = data["lat"] as? Double ?? 0
                                let lon = data["lon"] as? Double ?? 0
                                Log.debug("Scanning for Pokemon at \(lat) \(lon)")
                                
                                let start = Date()
                                self.lock.lock()
                                self.waitRequiresPokemon = true
                                self.pokemonEncounterId = nil
                                self.targetMaxDistance = self.config.targetMaxDistance
                                self.currentLocation = (lat, lon)
                                self.waitForData = true
                                self.lock.unlock()
                                Log.debug("Scanning prepared")
                                
                                var locked = true
                                while locked {
                                    usleep(100000 * self.config.delayMultiplier)
                                    self.lock.lock()
                                    if Date().timeIntervalSince(start) >= self.config.pokemonMaxTime {
                                        locked = false
                                        self.waitForData = false
                                        failedCount += 1
                                        self.freeScreen()
                                        Log.debug("Pokemon loading timed out.")
                                        self.postRequest(url: self.backendControlerURL, data: ["uuid": self.config.uuid, "type": "job_failed", "action": action, "lat": lat, "lon": lon], blocking: true) { (result) in }
                                    } else {
                                        locked = self.waitForData
                                        if !locked {
                                            failedCount = 0
                                            Log.debug("Pokemon loaded after \(Date().timeIntervalSince(start)).")
                                        }
                                    }
                                    self.lock.unlock()
                                }
                                
                            } else if action == "scan_raid" {
                                print("[STATUS] Raid")
                                if hasWarning && self.firstWarningDate != nil && Int(Date().timeIntervalSince(self.firstWarningDate!)) >= self.config.maxWarningTimeRaid && self.config.enableAccountManager {
                                    Log.info("Account has a warning and is over maxWarningTimeRaid. Logging out!")
                                    let success = self.logOut()
                                    if !success {
                                        return
                                    }
                                    
                                    self.postRequest(url: self.backendControlerURL, data: ["uuid": self.config.uuid, "username": self.username as Any, "type": "logged_out"], blocking: true) { (result) in }
                                    self.username = nil
                                    self.isLoggedIn = false
                                    UserDefaults.standard.synchronize()
                                    sleep(7 * self.config.delayMultiplier)
                                    self.shouldExit = true
                                    return
                                }
                                
                                let lat = data["lat"] as? Double ?? 0
                                let lon = data["lon"] as? Double ?? 0
                                Log.debug("Scanning for Raid at \(lat) \(lon)")
                                
                                let start = Date()
                                self.lock.lock()
                                self.currentLocation = (lat, lon)
                                self.waitRequiresPokemon = false
                                self.targetMaxDistance = self.config.targetMaxDistance
                                self.waitForData = true
                                self.lock.unlock()
                                Log.debug("Scanning prepared")
                                
                                var locked = true
                                while locked {
                                    usleep(100000 * self.config.delayMultiplier)
                                    self.lock.lock()
                                    if Date().timeIntervalSince(start) >= self.config.raidMaxTime {
                                        locked = false
                                        self.waitForData = false
                                        failedCount += 1
                                        self.freeScreen()
                                        Log.debug("Raids loading timed out.")
                                        self.postRequest(url: self.backendControlerURL, data: ["uuid": self.config.uuid, "type": "job_failed", "action": action, "lat": lat, "lon": lon], blocking: true) { (result) in }
                                    } else {
                                        locked = self.waitForData
                                        if !locked {
                                            failedCount = 0
                                            Log.debug("Raids loaded after \(Date().timeIntervalSince(start)).")
                                        }
                                    }
                                    self.lock.unlock()
                                }
                            } else if action == "scan_quest" {
                                print("[STATUS] Quest")
                                
                                let lat = data["lat"] as? Double ?? 0
                                let lon = data["lon"] as? Double ?? 0
                                let delay = data["delay"] as? Double ?? 0
                                Log.debug("Scanning for Quest at \(lat) \(lon) in \(Int(delay))s")
                                
                                self.zoom(out: false, app: self.app, coordStartup: self.deviceConfig.startup.toXCUICoordinate(app: self.app))
                                
                                if hasWarning && self.firstWarningDate != nil && Int(Date().timeIntervalSince(self.firstWarningDate!)) >= self.config.maxWarningTimeRaid && self.config.enableAccountManager {
                                    Log.info("Account has a warning and is over maxWarningTimeRaid. Logging out!")
                                    let success = self.logOut()
                                    if !success {
                                        return
                                    }
                                    
                                    self.postRequest(url: self.backendControlerURL, data: ["uuid": self.config.uuid, "type": "logged_out"], blocking: true) { (result) in }
                                    self.username = nil
                                    self.isLoggedIn = false
                                    UserDefaults.standard.synchronize()
                                    sleep(7 * self.config.delayMultiplier)
                                    self.shouldExit = true
                                    return
                                }
                                
                                if delay >= self.config.minDelayLogout && self.config.enableAccountManager {
                                    Log.debug("Switching account. Delay too large.")
                                    let success = self.logOut()
                                    if !success {
                                        return
                                    }
                                    
                                    self.postRequest(url: self.backendControlerURL, data: ["uuid": self.config.uuid, "type": "job_failed", "action": action, "lat": lat, "lon": lon], blocking: true) { (result) in }
                                    self.postRequest(url: self.backendControlerURL, data: ["uuid": self.config.uuid, "type": "logged_out"], blocking: true) { (result) in }
                                    self.username = nil
                                    self.isLoggedIn = false
                                    UserDefaults.standard.synchronize()
                                    sleep(7 * self.config.delayMultiplier)
                                    self.shouldExit = true
                                    return
                                }
                                
                                if currentItems >= self.config.itemFullCount && !self.newCreated {
                                    self.freeScreen()
                                    Log.debug("Clearing Items")
                                    self.clearItems()
                                    currentItems = 2
                                } else {
                                    sleep(1)
                                }
                                
                                if currentQuests >= self.config.questFullCount && !self.newCreated {
                                    self.freeScreen()
                                    Log.debug("Clearing Quests")
                                    self.clearQuest()
                                    currentQuests = 0
                                } else {
                                    sleep(1)
                                }
                                
                                self.newCreated = false
                                
                                self.lock.lock()
                                self.currentLocation = (lat, lon)
                                self.waitRequiresPokemon = false
                                self.pokemonEncounterId = nil
                                self.targetMaxDistance = self.config.targetMaxDistance
                                self.waitForData = true
                                self.lock.unlock()
                                Log.debug("Scanning prepared")
                                self.freeScreen()
                                
                                let start = Date()
                                
                                self.app.swipeLeft()
                                
                                var success = false
                                var locked = true
                                while locked {
                                    usleep(100000 * self.config.delayMultiplier)
                                    if Date().timeIntervalSince(start) <= 5 {
                                        continue
                                    }
                                    if Date().timeIntervalSince(start) <= delay {
                                        let left =  delay - Date().timeIntervalSince(start)
                                        Log.debug("Delaying by \(left)s.")
                                        usleep(UInt32(min(10.0, left) * 1000000.0))
                                        continue
                                    }
                                    self.lock.lock()
                                    if Date().timeIntervalSince(start) >= self.config.raidMaxTime + delay {
                                        locked = false
                                        self.waitForData = false
                                        failedCount += 1
                                        Log.debug("Pokestop loading timed out.")
                                        self.postRequest(url: self.backendControlerURL, data: ["uuid": self.config.uuid, "type": "job_failed", "action": action, "lat": lat, "lon": lon], blocking: true) { (result) in }
                                    } else {
                                        locked = self.waitForData
                                        if !locked {
                                            success = true
                                            failedCount = 0
                                            Log.debug("Pokestop loaded after \(Date().timeIntervalSince(start)).")
                                        }
                                    }
                                    self.lock.unlock()
                                }
                                
                                // Check if previus spin had quest data
                                self.lock.lock()
                                if self.gotQuest {
                                    self.noQuestCount = 0
                                } else {
                                    self.noQuestCount += 1
                                }
                                self.gotQuest = false
                                
                                if self.noQuestCount >= self.config.maxNoQuestCount {
                                    self.lock.unlock()
                                    Log.debug("Stuck somewhere. Restarting")
                                    self.app.terminate()
                                    self.shouldExit = true
                                    return
                                }
                                self.lock.unlock()
                                
                                if success {
                                    self.freeScreen()
                                    Log.debug("Spinning Pokestop")
                                    self.spin()
                                    currentQuests += 1
                                    currentItems += self.config.itemsPerStop
                                }
                                
                            } else if action == "switch_account" {
                                let success = self.logOut()
                                if !success {
                                    return
                                }
                                
                                self.postRequest(url: self.backendControlerURL, data: ["uuid": self.config.uuid, "type": "logged_out"], blocking: true) { (result) in }
                                self.username = nil
                                self.isLoggedIn = false
                                UserDefaults.standard.synchronize()
                                sleep(7 * self.config.delayMultiplier)
                                self.shouldExit = true
                                return
                            } else if action == "scan_iv" {
                                print("[STATUS] IV")
                                if hasWarning && self.firstWarningDate != nil && Int(Date().timeIntervalSince(self.firstWarningDate!)) >= self.config.maxWarningTimeRaid && self.config.enableAccountManager {
                                    Log.info("Account has a warning and is over maxWarningTimeRaid. Logging out!")
                                    let success = self.logOut()
                                    if !success {
                                        return
                                    }
                                    
                                    self.postRequest(url: self.backendControlerURL, data: ["uuid": self.config.uuid, "username": self.username as Any, "type": "logged_out"], blocking: true) { (result) in }
                                    self.username = nil
                                    self.isLoggedIn = false
                                    UserDefaults.standard.synchronize()
                                    sleep(7 * self.config.delayMultiplier)
                                    self.shouldExit = true
                                    return
                                }
                                
                                if !self.config.ultraIV {
                                    self.zoom(out: true, app: self.app, coordStartup: self.deviceConfig.startup.toXCUICoordinate(app: self.app))
                                }
                                
                                let lat = data["lat"] as? Double ?? 0
                                let lon = data["lon"] as? Double ?? 0
                                let id = data["id"] as? String ?? ""
                                
                                Log.debug("Scanning for IV at \(lat) \(lon)")
                                
                                let start = Date()
                                self.lock.lock()
                                self.waitRequiresPokemon = true
                                self.pokemonEncounterId = id
                                self.targetMaxDistance = self.config.targetMaxDistance
                                self.currentLocation = (lat, lon)
                                self.waitForData = true
                                self.lock.unlock()
                                Log.debug("Scanning prepared")
                                sleep(1 * self.config.delayMultiplier)
                                if !self.config.ultraIV {
                                    self.freeScreen()
                                    if self.config.fastIV {
                                        self.app.swipeLeft()
                                    }
                                }
                                
                                var success = false
                                var locked = true
                                while locked {
                                    usleep(100000 * self.config.delayMultiplier)
                                    self.lock.lock()
                                    if Date().timeIntervalSince(start) >= self.config.pokemonMaxTime {
                                        locked = false
                                        self.waitForData = false
                                        failedCount += 1
                                        if !self.config.ultraIV {
                                            self.freeScreen()
                                        }
                                        Log.debug("Pokemon loading timed out.")
                                        self.postRequest(url: self.backendControlerURL, data: ["uuid": self.config.uuid, "type": "job_failed", "action": action, "lat": lat, "lon": lon], blocking: true) { (result) in }
                                    } else {
                                        locked = self.waitForData
                                        if !locked {
                                            failedCount = 0
                                            Log.debug("Pokemon loaded after \(Date().timeIntervalSince(start)).")
                                            success = true
                                        }
                                    }
                                    self.lock.unlock()
                                }
                                
                                if success && !self.config.ultraIV {
                                    
                                    self.lock.lock()
                                    let delay = 1.0 + (3 / 75 * self.encounterDistance)
                                    self.lock.unlock()
                                    usleep(UInt32(delay * 1000000.0 * Double(self.config.delayMultiplier)))
                                    
                                    if self.config.fastIV {
                                        
                                        // Check if previus spin had quest data
                                        self.lock.lock()
                                        if self.gotIV {
                                            self.noEncounterCount = 0
                                        } else {
                                            self.noEncounterCount += 1
                                        }
                                        self.gotIV = false
                                        self.lock.unlock()
                                        
                                        self.freeScreen()
                                        self.deviceConfig.encounterPokemonLower.toXCUICoordinate(app: self.app).tap()
                                        self.deviceConfig.encounterPokemonUpper.toXCUICoordinate(app: self.app).tap()
                                    } else {
                                        var count = 0
                                        var done = false
                                        while count < 3 && !done {
                                            self.freeScreen()
                                            if count != 0 {
                                                self.app.swipeLeft()
                                            }
                                            self.deviceConfig.encounterPokemonLower.toXCUICoordinate(app: self.app).tap()
                                            self.deviceConfig.encounterPokemonUpper.toXCUICoordinate(app: self.app).tap()
                                            sleep(2 * self.config.delayMultiplier)
                                            done = self.prepareEncounter()
                                            count += 1
                                        }
                                        self.lock.lock()
                                        if !done {
                                            self.noEncounterCount += 1
                                        } else {
                                            self.noEncounterCount = 0
                                        }
                                        self.lock.unlock()
                                    }
                                    
                                    if self.noEncounterCount >= self.config.maxNoEncounterCount {
                                        self.lock.unlock()
                                        Log.debug("Stuck somewhere. Restarting")
                                        self.app.terminate()
                                        self.shouldExit = true
                                        return
                                    }
                                }
                                
                            } else {
                                Log.error("Unkown Action: \(action)")
                            }
                            
                            if self.emptyGmoCount >= self.config.maxEmptyGMO {
                                Log.error("Got Emtpy GMO \(self.emptyGmoCount) times in a row. Restarting")
                                self.app.terminate()
                            }
                            
                            if failedCount >= self.config.maxFailedCount {
                                Log.error("Failed \(failedCount) times in a row. Restarting")
                                self.app.terminate()
                            }
                            
                        } else {
                            failedToGetJobCount = 0
                            Log.debug("no job left (Got result: \(result!)") // <- search harder, better, faster, stronger
                            sleep(5 * self.config.delayMultiplier)
                        }
                        
                    }
                    
                }
            } else {
                let screenshotComp = XCUIScreen.main.screenshot()
                
                if config.enableAccountManager && screenshotComp.rgbAtLocation(
                    pos: deviceConfig.startupLoggedOut,
                    min: (0.95, 0.75, 0.0),
                    max: (1.00, 0.85, 0.1)) {
                    Log.info("Not logged in. Restarting...")
                    self.postRequest(url: self.backendControlerURL, data: ["uuid": self.config.uuid, "username": self.username as Any, "type": "logged_out"], blocking: true) { (result) in }
                    self.username = nil
                    self.isLoggedIn = false
                    UserDefaults.standard.synchronize()
                    sleep(7 * config.delayMultiplier)
                    self.shouldExit = true
                    return
                } else if screenshotComp.rgbAtLocation(
                    pos: deviceConfig.startup,
                    min: (0.00, 0.75, 0.55),
                    max: (1.00, 0.90, 0.70)) {
                    Log.info("App Started")
                    isStarted = true
                    sleep(1 * config.delayMultiplier)
                } else {
                    Log.debug("App still in Startup")
                    if startupCount == 30 {
                        Log.info("App stuck in Startup. Restarting...")
                        app.terminate()
                    }
                    startupCount += 1
                    sleep(1 * config.delayMultiplier)
                }
            }
        }
        
    }
    
    func zoom(out: Bool, app: XCUIApplication, coordStartup: XCUICoordinate) {
        
        if out != zoomedOut {
            
            self.freeScreen()
            
            self.lock.lock()
            self.currentLocation = self.config.startupLocation
            self.lock.unlock()
            sleep(2 * self.config.delayMultiplier)
            if out {
                coordStartup.tap()
                app.swipeUp()
                coordStartup.tap()
                app.swipeUp()
                coordStartup.tap()
                app.swipeUp()
            } else {
                coordStartup.tap()
                app.swipeDown()
                coordStartup.tap()
                app.swipeDown()
                coordStartup.tap()
                app.swipeDown()
            }
            sleep(1 * self.config.delayMultiplier)
            self.zoomedOut = out
        }
        
    }
    
}
