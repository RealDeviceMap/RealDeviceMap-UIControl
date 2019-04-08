//
//  RealDeviceMap_UIControlUITests.swift
//  RealDeviceMap-UIControlUITests
//
//  Created by Florian Kostenzer on 28.09.18.
//

import Foundation
import XCTest
import Telegraph
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
    var encounterDelay = 1.0
    
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
    
    var lastTestIndex: Int {
        get {
            if UserDefaults.standard.object(forKey: "last_test_index") == nil {
                return 0
            }
            return UserDefaults.standard.integer(forKey: "last_test_index")
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "last_test_index")
            UserDefaults.standard.synchronize()
        }
    }
    
    override func setUp() {
        super.setUp()
        
        backendControlerURL = URL(string: config.backendURLBaseString + "/controler")!
        backendRawURL = URL(string: config.backendURLBaseString + "/raw")!
        continueAfterFailure = true
        
    }
    
    func part0Setup() {
        
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
                sleep(1 * self.config.delayMultiplier)
                return
            } else if result!["status"] as? String != "ok" {
                let error = result!["error"] ?? "? (no error sent)"
                Log.error("Backend returned a error: \(error)")
                self.shouldExit = true
                sleep(1 * self.config.delayMultiplier)
                return
            }
            let data = result!["data"] as? [String: Any]
            if data == nil {
                Log.error("Backend did not include data!")
                self.shouldExit = true
                sleep(1 * self.config.delayMultiplier)
                return
            }
            if data!["assigned"] as? Bool == false {
                Log.error("Device is not assigned to an instance!")
                self.shouldExit = true
                sleep(1 * self.config.delayMultiplier)
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
    
    func part1LoginSetup() {
        
        if shouldExit || !config.enableAccountManager {
            return
        }
        
        if username != nil && !isLoggedIn {
            
            print("[STATUS] Login")
            
            var loaded = false
            var count = 0
            while !loaded {
                let screenshotComp = XCUIScreen.main.screenshot()
                if screenshotComp.rgbAtLocation(
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
    
    func part2LoginUsername() {
        
        if shouldExit || !config.enableAccountManager {
            return
        }
        
        if username != nil && !isLoggedIn {
            
            sleep(1 * config.delayMultiplier)
            deviceConfig.loginUsernameTextfield.toXCUICoordinate(app: app).tap()
            sleep(1 * config.delayMultiplier)
            app.typeText(username!)
        }
        
    }
    
    func part3LoginPassword() {
        
        if shouldExit || !config.enableAccountManager {
            return
        }
        
        if username != nil && !isLoggedIn {
            
            sleep(1 * config.delayMultiplier)
            deviceConfig.loginPasswordTextfield.toXCUICoordinate(app: app).tap()
            sleep(1 * config.delayMultiplier)
            app.typeText(password!)
            
        }
        
    }
    
    func part4LoginEnd() {
        
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
                            min: (red: 0.0, green: 0.0, blue: 0.0),
                            max: (red: 0.3, green: 0.5, blue: 0.5))
                    ) {
                    Log.error("Account \(username!) is banned.")
                    deviceConfig.loginBannedSwitchAccount.toXCUICoordinate(app: app).tap()
                    postRequest(url: backendControlerURL, data: ["uuid": config.uuid, "username": self.username as Any, "type": "account_banned"], blocking: true) { (result) in }
                    username = nil
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
    
    func part5TutorialStart() {
        
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
    
    func part6TutorialUsername() {
        
        if shouldExit || username == nil || !isLoggedIn || !config.enableAccountManager {
            return
        }
        
        if newLogIn {
            
            app.typeText(username!)
            
        }
        
    }
    
    func part7TutorialEnd() {
        
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
    
    func handleLocRequest(request: HTTPRequest) -> HTTPResponse  {
        
        var responseData = [String: Any]()
        
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
                
                responseData = [
                    "latitude": currentLocation!.lat + jitterLat,
                    "longitude": currentLocation!.lon + jitterLon,
                    "lat": currentLocation!.lat + jitterLat,
                    "lng": currentLocation!.lon + jitterLon
                ]
            } else {
                self.lock.unlock()
                responseData = [
                    "latitude": currentLocation!.lat,
                    "longitude": currentLocation!.lon,
                    "lat": currentLocation!.lat,
                    "lng": currentLocation!.lon
                ]
            }
        } else {
            self.lock.unlock()
            responseData = [String: Any]()
        }
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: responseData, options: .prettyPrinted)
            let jsonString = String(data: jsonData, encoding: .utf8) ?? ""
            
            let repsonse = HTTPResponse(content: jsonString)
            repsonse.headers = ["Content-Type": "application/json"]
            return repsonse
        } catch {
            return HTTPResponse(.internalServerError)
        }
    }
    
    func handleDataRequest(request: HTTPRequest) -> HTTPResponse  {
        
        let data = request.body
        
        self.lock.lock()
        let currentLocation = self.currentLocation
        let targetMaxDistance = self.targetMaxDistance
        let pokemonEncounterId = self.pokemonEncounterId
        self.lock.unlock()
        
        var jsonData: [String: Any]?
        do {
            jsonData = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        } catch {
            return HTTPResponse(.badRequest)
        }
        
        if jsonData != nil && currentLocation != nil {
            jsonData!["lat_target"] = currentLocation!.lat
            jsonData!["lon_target"] = currentLocation!.lon
            jsonData!["target_max_distnace"] = targetMaxDistance
            jsonData!["username"] = self.username
            jsonData!["pokemon_encounter_id"] = pokemonEncounterId
            
            let url = self.backendRawURL
            
            self.postRequest(url: url!, data: jsonData!, blocking: false, completion: { (resultJson) in
                
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
                let containsGmos = data?["contains_gmos"] as? Bool ?? true
                
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
                } else if containsGmos {
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
                } else {
                    toPrint = "[DEBUG] Got Data without GMO"
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
        
        return HTTPResponse(.ok)
    }
    
    func part8Main() {
        
        if shouldExit || ((username == nil || isLoggedIn == false) && config.enableAccountManager) {
            return
        }
        
        let server = Server()
        try! server.start(onPort: UInt16(self.config.port))
        server.route(.get, "loc", handleLocRequest)
        server.route(.post, "loc", handleLocRequest)
        server.route(.get, "data", handleDataRequest)
        server.route(.post, "data", handleDataRequest)
    
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
        emptyGmoCount = 0
        noEncounterCount = 0
        noQuestCount = 0
        
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
                                self.encounterDelay = self.config.encounterDelay
                                self.lock.unlock()
                                Log.debug("Scanning prepared")
                                sleep(1 * self.config.delayMultiplier)
                                if !self.config.ultraIV {
                                    self.freeScreen()
                                    if self.config.fastIV {
                                        usleep(UInt32(1000000.0 * Double(self.config.encounterDelay)))
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
                                        usleep(300000)
                                        self.deviceConfig.encounterPokemonUpper.toXCUICoordinate(app: self.app).tap()
	                                    usleep(300000)
	                                    self.deviceConfig.encounterPokemonUpperHigher.toXCUICoordinate(app: self.app).tap()
                                    } else {
                                        var count = 0
                                        var done = false
                                        while count < 3 && !done {
                                            self.freeScreen()
                                            if count != 0 {
                                                self.app.swipeLeft()
                                            }
                                            self.deviceConfig.encounterPokemonLower.toXCUICoordinate(app: self.app).tap()
                                            usleep(300000)
                                            self.deviceConfig.encounterPokemonUpper.toXCUICoordinate(app: self.app).tap()
	                                        usleep(300000)
	                                        self.deviceConfig.encounterPokemonUpperHigher.toXCUICoordinate(app: self.app).tap()
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
                    self.shouldExit = true
                    return
                } else if (
                    screenshotComp.rgbAtLocation(
                        pos: deviceConfig.loginBanned,
                        min: (red: 0.0, green: 0.75, blue: 0.55),
                        max: (red: 1.0, green: 0.90, blue: 0.70)) &&
                    screenshotComp.rgbAtLocation(
                        pos: deviceConfig.loginBannedText,
                        min: (red: 0.0, green: 0.0, blue: 0.0),
                        max: (red: 0.3, green: 0.5, blue: 0.5))
                    ) {
                        Log.info("Clicking \"try again\" on failed login screen")
                        deviceConfig.loginBannedSwitchAccount.toXCUICoordinate(app: app).tap()
                        username = nil
                        isLoggedIn = false
                        sleep(7 * config.delayMultiplier)
                        shouldExit = true
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
    
    func runAll() {
        
        while true {
            switch lastTestIndex {
            case 0:
                lastTestIndex = 1
                part1LoginSetup()
            case 1:
                lastTestIndex = 2
                part2LoginUsername()
            case 2:
                lastTestIndex = 3
                part3LoginPassword()
            case 3:
                lastTestIndex = 4
                part4LoginEnd()
            case 4:
                lastTestIndex = 5
                part5TutorialStart()
            case 5:
                lastTestIndex = 6
                part6TutorialUsername()
            case 6:
                lastTestIndex = 7
                part7TutorialEnd()
            case 7:
                lastTestIndex = 8
                part8Main()
            default:
                lastTestIndex = 0
                part0Setup()
            }
        }
        
    }
    
    // MARK: - Tests
    
    func test0() {
        lastTestIndex = -1
    }
    
    // Yes this is stupid but it works
    func test1() { runAll() }
    func test2() { runAll() }
    func test3() { runAll() }
    func test4() { runAll() }
    func test5() { runAll() }
    func test6() { runAll() }
    func test7() { runAll() }
    func test8() { runAll() }
    func test9() { runAll() }
    func test10() { runAll() }
    func test11() { runAll() }
    func test12() { runAll() }
    func test13() { runAll() }
    func test14() { runAll() }
    func test15() { runAll() }
    func test16() { runAll() }
    func test17() { runAll() }
    func test18() { runAll() }
    func test19() { runAll() }
    func test20() { runAll() }
    func test21() { runAll() }
    func test22() { runAll() }
    func test23() { runAll() }
    func test24() { runAll() }
    func test25() { runAll() }
    func test26() { runAll() }
    func test27() { runAll() }
    func test28() { runAll() }
    func test29() { runAll() }
    func test30() { runAll() }
    func test31() { runAll() }
    func test32() { runAll() }
    func test33() { runAll() }
    func test34() { runAll() }
    func test35() { runAll() }
    func test36() { runAll() }
    func test37() { runAll() }
    func test38() { runAll() }
    func test39() { runAll() }
    func test40() { runAll() }
    func test41() { runAll() }
    func test42() { runAll() }
    func test43() { runAll() }
    func test44() { runAll() }
    func test45() { runAll() }
    func test46() { runAll() }
    func test47() { runAll() }
    func test48() { runAll() }
    func test49() { runAll() }
    func test50() { runAll() }
    func test51() { runAll() }
    func test52() { runAll() }
    func test53() { runAll() }
    func test54() { runAll() }
    func test55() { runAll() }
    func test56() { runAll() }
    func test57() { runAll() }
    func test58() { runAll() }
    func test59() { runAll() }
    func test60() { runAll() }
    func test61() { runAll() }
    func test62() { runAll() }
    func test63() { runAll() }
    func test64() { runAll() }
    func test65() { runAll() }
    func test66() { runAll() }
    func test67() { runAll() }
    func test68() { runAll() }
    func test69() { runAll() }
    func test70() { runAll() }
    func test71() { runAll() }
    func test72() { runAll() }
    func test73() { runAll() }
    func test74() { runAll() }
    func test75() { runAll() }
    func test76() { runAll() }
    func test77() { runAll() }
    func test78() { runAll() }
    func test79() { runAll() }
    func test80() { runAll() }
    func test81() { runAll() }
    func test82() { runAll() }
    func test83() { runAll() }
    func test84() { runAll() }
    func test85() { runAll() }
    func test86() { runAll() }
    func test87() { runAll() }
    func test88() { runAll() }
    func test89() { runAll() }
    func test90() { runAll() }
    func test91() { runAll() }
    func test92() { runAll() }
    func test93() { runAll() }
    func test94() { runAll() }
    func test95() { runAll() }
    func test96() { runAll() }
    func test97() { runAll() }
    func test98() { runAll() }
    func test99() { runAll() }
    func test100() { runAll() }
    func test101() { runAll() }
    func test102() { runAll() }
    func test103() { runAll() }
    func test104() { runAll() }
    func test105() { runAll() }
    func test106() { runAll() }
    func test107() { runAll() }
    func test108() { runAll() }
    func test109() { runAll() }
    func test110() { runAll() }
    func test111() { runAll() }
    func test112() { runAll() }
    func test113() { runAll() }
    func test114() { runAll() }
    func test115() { runAll() }
    func test116() { runAll() }
    func test117() { runAll() }
    func test118() { runAll() }
    func test119() { runAll() }
    func test120() { runAll() }
    func test121() { runAll() }
    func test122() { runAll() }
    func test123() { runAll() }
    func test124() { runAll() }
    func test125() { runAll() }
    func test126() { runAll() }
    func test127() { runAll() }
    func test128() { runAll() }
    func test129() { runAll() }
    func test130() { runAll() }
    func test131() { runAll() }
    func test132() { runAll() }
    func test133() { runAll() }
    func test134() { runAll() }
    func test135() { runAll() }
    func test136() { runAll() }
    func test137() { runAll() }
    func test138() { runAll() }
    func test139() { runAll() }
    func test140() { runAll() }
    func test141() { runAll() }
    func test142() { runAll() }
    func test143() { runAll() }
    func test144() { runAll() }
    func test145() { runAll() }
    func test146() { runAll() }
    func test147() { runAll() }
    func test148() { runAll() }
    func test149() { runAll() }
    func test150() { runAll() }
    func test151() { runAll() }
    func test152() { runAll() }
    func test153() { runAll() }
    func test154() { runAll() }
    func test155() { runAll() }
    func test156() { runAll() }
    func test157() { runAll() }
    func test158() { runAll() }
    func test159() { runAll() }
    func test160() { runAll() }
    func test161() { runAll() }
    func test162() { runAll() }
    func test163() { runAll() }
    func test164() { runAll() }
    func test165() { runAll() }
    func test166() { runAll() }
    func test167() { runAll() }
    func test168() { runAll() }
    func test169() { runAll() }
    func test170() { runAll() }
    func test171() { runAll() }
    func test172() { runAll() }
    func test173() { runAll() }
    func test174() { runAll() }
    func test175() { runAll() }
    func test176() { runAll() }
    func test177() { runAll() }
    func test178() { runAll() }
    func test179() { runAll() }
    func test180() { runAll() }
    func test181() { runAll() }
    func test182() { runAll() }
    func test183() { runAll() }
    func test184() { runAll() }
    func test185() { runAll() }
    func test186() { runAll() }
    func test187() { runAll() }
    func test188() { runAll() }
    func test189() { runAll() }
    func test190() { runAll() }
    func test191() { runAll() }
    func test192() { runAll() }
    func test193() { runAll() }
    func test194() { runAll() }
    func test195() { runAll() }
    func test196() { runAll() }
    func test197() { runAll() }
    func test198() { runAll() }
    func test199() { runAll() }
    func test200() { runAll() }
    func test201() { runAll() }
    func test202() { runAll() }
    func test203() { runAll() }
    func test204() { runAll() }
    func test205() { runAll() }
    func test206() { runAll() }
    func test207() { runAll() }
    func test208() { runAll() }
    func test209() { runAll() }
    func test210() { runAll() }
    func test211() { runAll() }
    func test212() { runAll() }
    func test213() { runAll() }
    func test214() { runAll() }
    func test215() { runAll() }
    func test216() { runAll() }
    func test217() { runAll() }
    func test218() { runAll() }
    func test219() { runAll() }
    func test220() { runAll() }
    func test221() { runAll() }
    func test222() { runAll() }
    func test223() { runAll() }
    func test224() { runAll() }
    func test225() { runAll() }
    func test226() { runAll() }
    func test227() { runAll() }
    func test228() { runAll() }
    func test229() { runAll() }
    func test230() { runAll() }
    func test231() { runAll() }
    func test232() { runAll() }
    func test233() { runAll() }
    func test234() { runAll() }
    func test235() { runAll() }
    func test236() { runAll() }
    func test237() { runAll() }
    func test238() { runAll() }
    func test239() { runAll() }
    func test240() { runAll() }
    func test241() { runAll() }
    func test242() { runAll() }
    func test243() { runAll() }
    func test244() { runAll() }
    func test245() { runAll() }
    func test246() { runAll() }
    func test247() { runAll() }
    func test248() { runAll() }
    func test249() { runAll() }
    func test250() { runAll() }
    func test251() { runAll() }
    func test252() { runAll() }
    func test253() { runAll() }
    func test254() { runAll() }
    func test255() { runAll() }
    func test256() { runAll() }
    func test257() { runAll() }
    func test258() { runAll() }
    func test259() { runAll() }
    func test260() { runAll() }
    func test261() { runAll() }
    func test262() { runAll() }
    func test263() { runAll() }
    func test264() { runAll() }
    func test265() { runAll() }
    func test266() { runAll() }
    func test267() { runAll() }
    func test268() { runAll() }
    func test269() { runAll() }
    func test270() { runAll() }
    func test271() { runAll() }
    func test272() { runAll() }
    func test273() { runAll() }
    func test274() { runAll() }
    func test275() { runAll() }
    func test276() { runAll() }
    func test277() { runAll() }
    func test278() { runAll() }
    func test279() { runAll() }
    func test280() { runAll() }
    func test281() { runAll() }
    func test282() { runAll() }
    func test283() { runAll() }
    func test284() { runAll() }
    func test285() { runAll() }
    func test286() { runAll() }
    func test287() { runAll() }
    func test288() { runAll() }
    func test289() { runAll() }
    func test290() { runAll() }
    func test291() { runAll() }
    func test292() { runAll() }
    func test293() { runAll() }
    func test294() { runAll() }
    func test295() { runAll() }
    func test296() { runAll() }
    func test297() { runAll() }
    func test298() { runAll() }
    func test299() { runAll() }
    func test300() { runAll() }
    func test301() { runAll() }
    func test302() { runAll() }
    func test303() { runAll() }
    func test304() { runAll() }
    func test305() { runAll() }
    func test306() { runAll() }
    func test307() { runAll() }
    func test308() { runAll() }
    func test309() { runAll() }
    func test310() { runAll() }
    func test311() { runAll() }
    func test312() { runAll() }
    func test313() { runAll() }
    func test314() { runAll() }
    func test315() { runAll() }
    func test316() { runAll() }
    func test317() { runAll() }
    func test318() { runAll() }
    func test319() { runAll() }
    func test320() { runAll() }
    func test321() { runAll() }
    func test322() { runAll() }
    func test323() { runAll() }
    func test324() { runAll() }
    func test325() { runAll() }
    func test326() { runAll() }
    func test327() { runAll() }
    func test328() { runAll() }
    func test329() { runAll() }
    func test330() { runAll() }
    func test331() { runAll() }
    func test332() { runAll() }
    func test333() { runAll() }
    func test334() { runAll() }
    func test335() { runAll() }
    func test336() { runAll() }
    func test337() { runAll() }
    func test338() { runAll() }
    func test339() { runAll() }
    func test340() { runAll() }
    func test341() { runAll() }
    func test342() { runAll() }
    func test343() { runAll() }
    func test344() { runAll() }
    func test345() { runAll() }
    func test346() { runAll() }
    func test347() { runAll() }
    func test348() { runAll() }
    func test349() { runAll() }
    func test350() { runAll() }
    func test351() { runAll() }
    func test352() { runAll() }
    func test353() { runAll() }
    func test354() { runAll() }
    func test355() { runAll() }
    func test356() { runAll() }
    func test357() { runAll() }
    func test358() { runAll() }
    func test359() { runAll() }
    func test360() { runAll() }
    func test361() { runAll() }
    func test362() { runAll() }
    func test363() { runAll() }
    func test364() { runAll() }
    func test365() { runAll() }
    func test366() { runAll() }
    func test367() { runAll() }
    func test368() { runAll() }
    func test369() { runAll() }
    func test370() { runAll() }
    func test371() { runAll() }
    func test372() { runAll() }
    func test373() { runAll() }
    func test374() { runAll() }
    func test375() { runAll() }
    func test376() { runAll() }
    func test377() { runAll() }
    func test378() { runAll() }
    func test379() { runAll() }
    func test380() { runAll() }
    func test381() { runAll() }
    func test382() { runAll() }
    func test383() { runAll() }
    func test384() { runAll() }
    func test385() { runAll() }
    func test386() { runAll() }
    func test387() { runAll() }
    func test388() { runAll() }
    func test389() { runAll() }
    func test390() { runAll() }
    func test391() { runAll() }
    func test392() { runAll() }
    func test393() { runAll() }
    func test394() { runAll() }
    func test395() { runAll() }
    func test396() { runAll() }
    func test397() { runAll() }
    func test398() { runAll() }
    func test399() { runAll() }
    func test400() { runAll() }
    func test401() { runAll() }
    func test402() { runAll() }
    func test403() { runAll() }
    func test404() { runAll() }
    func test405() { runAll() }
    func test406() { runAll() }
    func test407() { runAll() }
    func test408() { runAll() }
    func test409() { runAll() }
    func test410() { runAll() }
    func test411() { runAll() }
    func test412() { runAll() }
    func test413() { runAll() }
    func test414() { runAll() }
    func test415() { runAll() }
    func test416() { runAll() }
    func test417() { runAll() }
    func test418() { runAll() }
    func test419() { runAll() }
    func test420() { runAll() }
    func test421() { runAll() }
    func test422() { runAll() }
    func test423() { runAll() }
    func test424() { runAll() }
    func test425() { runAll() }
    func test426() { runAll() }
    func test427() { runAll() }
    func test428() { runAll() }
    func test429() { runAll() }
    func test430() { runAll() }
    func test431() { runAll() }
    func test432() { runAll() }
    func test433() { runAll() }
    func test434() { runAll() }
    func test435() { runAll() }
    func test436() { runAll() }
    func test437() { runAll() }
    func test438() { runAll() }
    func test439() { runAll() }
    func test440() { runAll() }
    func test441() { runAll() }
    func test442() { runAll() }
    func test443() { runAll() }
    func test444() { runAll() }
    func test445() { runAll() }
    func test446() { runAll() }
    func test447() { runAll() }
    func test448() { runAll() }
    func test449() { runAll() }
    func test450() { runAll() }
    func test451() { runAll() }
    func test452() { runAll() }
    func test453() { runAll() }
    func test454() { runAll() }
    func test455() { runAll() }
    func test456() { runAll() }
    func test457() { runAll() }
    func test458() { runAll() }
    func test459() { runAll() }
    func test460() { runAll() }
    func test461() { runAll() }
    func test462() { runAll() }
    func test463() { runAll() }
    func test464() { runAll() }
    func test465() { runAll() }
    func test466() { runAll() }
    func test467() { runAll() }
    func test468() { runAll() }
    func test469() { runAll() }
    func test470() { runAll() }
    func test471() { runAll() }
    func test472() { runAll() }
    func test473() { runAll() }
    func test474() { runAll() }
    func test475() { runAll() }
    func test476() { runAll() }
    func test477() { runAll() }
    func test478() { runAll() }
    func test479() { runAll() }
    func test480() { runAll() }
    func test481() { runAll() }
    func test482() { runAll() }
    func test483() { runAll() }
    func test484() { runAll() }
    func test485() { runAll() }
    func test486() { runAll() }
    func test487() { runAll() }
    func test488() { runAll() }
    func test489() { runAll() }
    func test490() { runAll() }
    func test491() { runAll() }
    func test492() { runAll() }
    func test493() { runAll() }
    func test494() { runAll() }
    func test495() { runAll() }
    func test496() { runAll() }
    func test497() { runAll() }
    func test498() { runAll() }
    func test499() { runAll() }
    func test500() { runAll() }
    func test501() { runAll() }
    func test502() { runAll() }
    func test503() { runAll() }
    func test504() { runAll() }
    func test505() { runAll() }
    func test506() { runAll() }
    func test507() { runAll() }
    func test508() { runAll() }
    func test509() { runAll() }
    func test510() { runAll() }
    func test511() { runAll() }
    func test512() { runAll() }
    func test513() { runAll() }
    func test514() { runAll() }
    func test515() { runAll() }
    func test516() { runAll() }
    func test517() { runAll() }
    func test518() { runAll() }
    func test519() { runAll() }
    func test520() { runAll() }
    func test521() { runAll() }
    func test522() { runAll() }
    func test523() { runAll() }
    func test524() { runAll() }
    func test525() { runAll() }
    func test526() { runAll() }
    func test527() { runAll() }
    func test528() { runAll() }
    func test529() { runAll() }
    func test530() { runAll() }
    func test531() { runAll() }
    func test532() { runAll() }
    func test533() { runAll() }
    func test534() { runAll() }
    func test535() { runAll() }
    func test536() { runAll() }
    func test537() { runAll() }
    func test538() { runAll() }
    func test539() { runAll() }
    func test540() { runAll() }
    func test541() { runAll() }
    func test542() { runAll() }
    func test543() { runAll() }
    func test544() { runAll() }
    func test545() { runAll() }
    func test546() { runAll() }
    func test547() { runAll() }
    func test548() { runAll() }
    func test549() { runAll() }
    func test550() { runAll() }
    func test551() { runAll() }
    func test552() { runAll() }
    func test553() { runAll() }
    func test554() { runAll() }
    func test555() { runAll() }
    func test556() { runAll() }
    func test557() { runAll() }
    func test558() { runAll() }
    func test559() { runAll() }
    func test560() { runAll() }
    func test561() { runAll() }
    func test562() { runAll() }
    func test563() { runAll() }
    func test564() { runAll() }
    func test565() { runAll() }
    func test566() { runAll() }
    func test567() { runAll() }
    func test568() { runAll() }
    func test569() { runAll() }
    func test570() { runAll() }
    func test571() { runAll() }
    func test572() { runAll() }
    func test573() { runAll() }
    func test574() { runAll() }
    func test575() { runAll() }
    func test576() { runAll() }
    func test577() { runAll() }
    func test578() { runAll() }
    func test579() { runAll() }
    func test580() { runAll() }
    func test581() { runAll() }
    func test582() { runAll() }
    func test583() { runAll() }
    func test584() { runAll() }
    func test585() { runAll() }
    func test586() { runAll() }
    func test587() { runAll() }
    func test588() { runAll() }
    func test589() { runAll() }
    func test590() { runAll() }
    func test591() { runAll() }
    func test592() { runAll() }
    func test593() { runAll() }
    func test594() { runAll() }
    func test595() { runAll() }
    func test596() { runAll() }
    func test597() { runAll() }
    func test598() { runAll() }
    func test599() { runAll() }
    func test600() { runAll() }
    func test601() { runAll() }
    func test602() { runAll() }
    func test603() { runAll() }
    func test604() { runAll() }
    func test605() { runAll() }
    func test606() { runAll() }
    func test607() { runAll() }
    func test608() { runAll() }
    func test609() { runAll() }
    func test610() { runAll() }
    func test611() { runAll() }
    func test612() { runAll() }
    func test613() { runAll() }
    func test614() { runAll() }
    func test615() { runAll() }
    func test616() { runAll() }
    func test617() { runAll() }
    func test618() { runAll() }
    func test619() { runAll() }
    func test620() { runAll() }
    func test621() { runAll() }
    func test622() { runAll() }
    func test623() { runAll() }
    func test624() { runAll() }
    func test625() { runAll() }
    func test626() { runAll() }
    func test627() { runAll() }
    func test628() { runAll() }
    func test629() { runAll() }
    func test630() { runAll() }
    func test631() { runAll() }
    func test632() { runAll() }
    func test633() { runAll() }
    func test634() { runAll() }
    func test635() { runAll() }
    func test636() { runAll() }
    func test637() { runAll() }
    func test638() { runAll() }
    func test639() { runAll() }
    func test640() { runAll() }
    func test641() { runAll() }
    func test642() { runAll() }
    func test643() { runAll() }
    func test644() { runAll() }
    func test645() { runAll() }
    func test646() { runAll() }
    func test647() { runAll() }
    func test648() { runAll() }
    func test649() { runAll() }
    func test650() { runAll() }
    func test651() { runAll() }
    func test652() { runAll() }
    func test653() { runAll() }
    func test654() { runAll() }
    func test655() { runAll() }
    func test656() { runAll() }
    func test657() { runAll() }
    func test658() { runAll() }
    func test659() { runAll() }
    func test660() { runAll() }
    func test661() { runAll() }
    func test662() { runAll() }
    func test663() { runAll() }
    func test664() { runAll() }
    func test665() { runAll() }
    func test666() { runAll() }
    func test667() { runAll() }
    func test668() { runAll() }
    func test669() { runAll() }
    func test670() { runAll() }
    func test671() { runAll() }
    func test672() { runAll() }
    func test673() { runAll() }
    func test674() { runAll() }
    func test675() { runAll() }
    func test676() { runAll() }
    func test677() { runAll() }
    func test678() { runAll() }
    func test679() { runAll() }
    func test680() { runAll() }
    func test681() { runAll() }
    func test682() { runAll() }
    func test683() { runAll() }
    func test684() { runAll() }
    func test685() { runAll() }
    func test686() { runAll() }
    func test687() { runAll() }
    func test688() { runAll() }
    func test689() { runAll() }
    func test690() { runAll() }
    func test691() { runAll() }
    func test692() { runAll() }
    func test693() { runAll() }
    func test694() { runAll() }
    func test695() { runAll() }
    func test696() { runAll() }
    func test697() { runAll() }
    func test698() { runAll() }
    func test699() { runAll() }
    func test700() { runAll() }
    func test701() { runAll() }
    func test702() { runAll() }
    func test703() { runAll() }
    func test704() { runAll() }
    func test705() { runAll() }
    func test706() { runAll() }
    func test707() { runAll() }
    func test708() { runAll() }
    func test709() { runAll() }
    func test710() { runAll() }
    func test711() { runAll() }
    func test712() { runAll() }
    func test713() { runAll() }
    func test714() { runAll() }
    func test715() { runAll() }
    func test716() { runAll() }
    func test717() { runAll() }
    func test718() { runAll() }
    func test719() { runAll() }
    func test720() { runAll() }
    func test721() { runAll() }
    func test722() { runAll() }
    func test723() { runAll() }
    func test724() { runAll() }
    func test725() { runAll() }
    func test726() { runAll() }
    func test727() { runAll() }
    func test728() { runAll() }
    func test729() { runAll() }
    func test730() { runAll() }
    func test731() { runAll() }
    func test732() { runAll() }
    func test733() { runAll() }
    func test734() { runAll() }
    func test735() { runAll() }
    func test736() { runAll() }
    func test737() { runAll() }
    func test738() { runAll() }
    func test739() { runAll() }
    func test740() { runAll() }
    func test741() { runAll() }
    func test742() { runAll() }
    func test743() { runAll() }
    func test744() { runAll() }
    func test745() { runAll() }
    func test746() { runAll() }
    func test747() { runAll() }
    func test748() { runAll() }
    func test749() { runAll() }
    func test750() { runAll() }
    func test751() { runAll() }
    func test752() { runAll() }
    func test753() { runAll() }
    func test754() { runAll() }
    func test755() { runAll() }
    func test756() { runAll() }
    func test757() { runAll() }
    func test758() { runAll() }
    func test759() { runAll() }
    func test760() { runAll() }
    func test761() { runAll() }
    func test762() { runAll() }
    func test763() { runAll() }
    func test764() { runAll() }
    func test765() { runAll() }
    func test766() { runAll() }
    func test767() { runAll() }
    func test768() { runAll() }
    func test769() { runAll() }
    func test770() { runAll() }
    func test771() { runAll() }
    func test772() { runAll() }
    func test773() { runAll() }
    func test774() { runAll() }
    func test775() { runAll() }
    func test776() { runAll() }
    func test777() { runAll() }
    func test778() { runAll() }
    func test779() { runAll() }
    func test780() { runAll() }
    func test781() { runAll() }
    func test782() { runAll() }
    func test783() { runAll() }
    func test784() { runAll() }
    func test785() { runAll() }
    func test786() { runAll() }
    func test787() { runAll() }
    func test788() { runAll() }
    func test789() { runAll() }
    func test790() { runAll() }
    func test791() { runAll() }
    func test792() { runAll() }
    func test793() { runAll() }
    func test794() { runAll() }
    func test795() { runAll() }
    func test796() { runAll() }
    func test797() { runAll() }
    func test798() { runAll() }
    func test799() { runAll() }
    func test800() { runAll() }
    func test801() { runAll() }
    func test802() { runAll() }
    func test803() { runAll() }
    func test804() { runAll() }
    func test805() { runAll() }
    func test806() { runAll() }
    func test807() { runAll() }
    func test808() { runAll() }
    func test809() { runAll() }
    func test810() { runAll() }
    func test811() { runAll() }
    func test812() { runAll() }
    func test813() { runAll() }
    func test814() { runAll() }
    func test815() { runAll() }
    func test816() { runAll() }
    func test817() { runAll() }
    func test818() { runAll() }
    func test819() { runAll() }
    func test820() { runAll() }
    func test821() { runAll() }
    func test822() { runAll() }
    func test823() { runAll() }
    func test824() { runAll() }
    func test825() { runAll() }
    func test826() { runAll() }
    func test827() { runAll() }
    func test828() { runAll() }
    func test829() { runAll() }
    func test830() { runAll() }
    func test831() { runAll() }
    func test832() { runAll() }
    func test833() { runAll() }
    func test834() { runAll() }
    func test835() { runAll() }
    func test836() { runAll() }
    func test837() { runAll() }
    func test838() { runAll() }
    func test839() { runAll() }
    func test840() { runAll() }
    func test841() { runAll() }
    func test842() { runAll() }
    func test843() { runAll() }
    func test844() { runAll() }
    func test845() { runAll() }
    func test846() { runAll() }
    func test847() { runAll() }
    func test848() { runAll() }
    func test849() { runAll() }
    func test850() { runAll() }
    func test851() { runAll() }
    func test852() { runAll() }
    func test853() { runAll() }
    func test854() { runAll() }
    func test855() { runAll() }
    func test856() { runAll() }
    func test857() { runAll() }
    func test858() { runAll() }
    func test859() { runAll() }
    func test860() { runAll() }
    func test861() { runAll() }
    func test862() { runAll() }
    func test863() { runAll() }
    func test864() { runAll() }
    func test865() { runAll() }
    func test866() { runAll() }
    func test867() { runAll() }
    func test868() { runAll() }
    func test869() { runAll() }
    func test870() { runAll() }
    func test871() { runAll() }
    func test872() { runAll() }
    func test873() { runAll() }
    func test874() { runAll() }
    func test875() { runAll() }
    func test876() { runAll() }
    func test877() { runAll() }
    func test878() { runAll() }
    func test879() { runAll() }
    func test880() { runAll() }
    func test881() { runAll() }
    func test882() { runAll() }
    func test883() { runAll() }
    func test884() { runAll() }
    func test885() { runAll() }
    func test886() { runAll() }
    func test887() { runAll() }
    func test888() { runAll() }
    func test889() { runAll() }
    func test890() { runAll() }
    func test891() { runAll() }
    func test892() { runAll() }
    func test893() { runAll() }
    func test894() { runAll() }
    func test895() { runAll() }
    func test896() { runAll() }
    func test897() { runAll() }
    func test898() { runAll() }
    func test899() { runAll() }
    func test900() { runAll() }
    func test901() { runAll() }
    func test902() { runAll() }
    func test903() { runAll() }
    func test904() { runAll() }
    func test905() { runAll() }
    func test906() { runAll() }
    func test907() { runAll() }
    func test908() { runAll() }
    func test909() { runAll() }
    func test910() { runAll() }
    func test911() { runAll() }
    func test912() { runAll() }
    func test913() { runAll() }
    func test914() { runAll() }
    func test915() { runAll() }
    func test916() { runAll() }
    func test917() { runAll() }
    func test918() { runAll() }
    func test919() { runAll() }
    func test920() { runAll() }
    func test921() { runAll() }
    func test922() { runAll() }
    func test923() { runAll() }
    func test924() { runAll() }
    func test925() { runAll() }
    func test926() { runAll() }
    func test927() { runAll() }
    func test928() { runAll() }
    func test929() { runAll() }
    func test930() { runAll() }
    func test931() { runAll() }
    func test932() { runAll() }
    func test933() { runAll() }
    func test934() { runAll() }
    func test935() { runAll() }
    func test936() { runAll() }
    func test937() { runAll() }
    func test938() { runAll() }
    func test939() { runAll() }
    func test940() { runAll() }
    func test941() { runAll() }
    func test942() { runAll() }
    func test943() { runAll() }
    func test944() { runAll() }
    func test945() { runAll() }
    func test946() { runAll() }
    func test947() { runAll() }
    func test948() { runAll() }
    func test949() { runAll() }
    func test950() { runAll() }
    func test951() { runAll() }
    func test952() { runAll() }
    func test953() { runAll() }
    func test954() { runAll() }
    func test955() { runAll() }
    func test956() { runAll() }
    func test957() { runAll() }
    func test958() { runAll() }
    func test959() { runAll() }
    func test960() { runAll() }
    func test961() { runAll() }
    func test962() { runAll() }
    func test963() { runAll() }
    func test964() { runAll() }
    func test965() { runAll() }
    func test966() { runAll() }
    func test967() { runAll() }
    func test968() { runAll() }
    func test969() { runAll() }
    func test970() { runAll() }
    func test971() { runAll() }
    func test972() { runAll() }
    func test973() { runAll() }
    func test974() { runAll() }
    func test975() { runAll() }
    func test976() { runAll() }
    func test977() { runAll() }
    func test978() { runAll() }
    func test979() { runAll() }
    func test980() { runAll() }
    func test981() { runAll() }
    func test982() { runAll() }
    func test983() { runAll() }
    func test984() { runAll() }
    func test985() { runAll() }
    func test986() { runAll() }
    func test987() { runAll() }
    func test988() { runAll() }
    func test989() { runAll() }
    func test990() { runAll() }
    func test991() { runAll() }
    func test992() { runAll() }
    func test993() { runAll() }
    func test994() { runAll() }
    func test995() { runAll() }
    func test996() { runAll() }
    func test997() { runAll() }
    func test998() { runAll() }
    func test999() { runAll() }
    
    func test9999() {
        sleep(10 * self.config.delayMultiplier)
    }
    
}
