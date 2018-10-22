//
//  RealDeviceMap_UIControlUITests.swift
//  RealDeviceMap-UIControlUITests
//
//  Created by Florian Kostenzer on 28.09.18.
//

// DON'T EDIT!

import Foundation
import XCTest
import Embassy
import EnvoyAmbassador

class RealDeviceMap_UIControlUITests: XCTestCase {
    
    let conf = Config.global
    
    var backendControlerURL: URL!
    var backendJSONURL: URL!
    var backendRawURL: URL!
    var isStarted = false
    var currentLocation: (lat: Double, lon: Double)?
    var waitRequiresPokemon = false
    var waitForData = false
    var lock = NSLock()
    var lastDataTime = Date()
    var firstWarningDate: Date?
    
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

    override func setUp() {
        super.setUp()
        
        backendControlerURL = URL(string: conf.backendURLBaseString + "/controler")!
        backendJSONURL = URL(string: conf.backendURLBaseString + "/json")!
        backendRawURL = URL(string: conf.backendURLBaseString + "/raw")!
        continueAfterFailure = false
    }
    
    func test0Setup() {
        
        shouldExit = false
        
        // Register on backend
        postRequest(url: backendControlerURL, data: ["uuid": conf.uuid, "type": "init"], blocking: true) { (result) in
            if result == nil {
                print("[ERROR] Failed to connect to Backend!")
                self.shouldExit = true
                return
            } else if result!["status"] as? String != "ok" {
                let error = result!["error"] ?? "? (no error sent)"
                print("[ERROR] Backend returned a error: \(error)")
                self.shouldExit = true
                return
            }
            let data = result!["data"] as? [String: Any]
            if data == nil {
                print("[ERROR] Backend did not include data!")
                self.shouldExit = true
                return
            }
            if data!["assigned"] as? Bool == false {
                print("[ERROR] Device is not assigned to an instance!")
                self.shouldExit = true
                return
            }
            if let firstWarningTimestamp = data!["first_warning_timestamp"] as? Int {
                self.firstWarningDate = Date(timeIntervalSince1970: Double(firstWarningTimestamp))
            }
            print("[INFO] Connected to Backend sucesfully")
            
        }
        
        if shouldExit {
            return   
        }
        
        if username == nil && conf.enableAccountManager {
            postRequest(url: backendControlerURL, data: ["uuid": conf.uuid, "type": "get_account"], blocking: true) { (result) in
                guard
                    let data = result!["data"] as? [String: Any],
                    let username = data["username"] as? String,
                    let password = data["password"] as? String
                else {
                    print("[ERROR] Failed to get account and not logged in.")
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
                
                print("[INFO] Got account \(username) from backend.")
            }
        }
        
        let app = XCUIApplication(bundleIdentifier: "com.nianticlabs.pokemongo")
        
        app.terminate()
        app.activate()
        sleep(1 * conf.delayMultiplier)
        
    }
    
    func test1LoginSetup() {
        
        if shouldExit || !conf.enableAccountManager {
            return
        }

        if username != nil && !isLoggedIn {
            
            let app = XCUIApplication(bundleIdentifier: "com.nianticlabs.pokemongo")
            let normalized = app.coordinate(withNormalizedOffset: CGVector(dx: 0, dy: 0))
            
            let compareStartLogin: (x: Int, y: Int)
            let newPlayerButton: XCUICoordinate
            let ptcButton: XCUICoordinate
            if app.frame.size.width == 375 { //iPhone Normal (6, 7, ...)
                newPlayerButton = normalized.withOffset(CGVector(dx: 375, dy: 750))
                ptcButton = normalized.withOffset(CGVector(dx: 375, dy: 950))
                compareStartLogin = (0, 0)
            } else if app.frame.size.width == 320 { //iPhone Small (5S, SE, ...)
                newPlayerButton = normalized.withOffset(CGVector(dx: 320, dy: 785))
                ptcButton = normalized.withOffset(CGVector(dx: 375, dy: 800))
                compareStartLogin = (320, 616)
            } else {
                print("Unsupported iOS modell. Please report this in our Discord!")
                shouldExit = true
                return
            }
            
            var loaded = false
            var count = 0
            while !loaded {
                let screenshotComp = XCUIScreen.main.screenshot()
                let color = screenshotComp.image.getPixelColor(pos: CGPoint(x: compareStartLogin.x, y: compareStartLogin.y))
                var red: CGFloat = 0
                var green: CGFloat = 0
                var blue: CGFloat = 0
                var alpha: CGFloat = 0
                color.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
                if (green > 0.75 && green < 0.9 && blue > 0.55 && blue < 0.7) {
                    print("[DEBUG] App Started in login screen.")
                    loaded = true
                }
                
                count += 1
                if count == 60 && !loaded {
                    count = 0
                    app.terminate()
                    app.activate()
                    sleep(1 * conf.delayMultiplier)
                }
                sleep(1 * conf.delayMultiplier)
            }
            
            sleep(1 * conf.delayMultiplier)
            newPlayerButton.tap()
            sleep(1 * conf.delayMultiplier)
            ptcButton.tap()
        }
    }
    
    func test2LoginUsername() {
        
        if shouldExit || !conf.enableAccountManager {
            return
        }
        
        if username != nil && !isLoggedIn {
            
            let app = XCUIApplication(bundleIdentifier: "com.nianticlabs.pokemongo")
            let normalized = app.coordinate(withNormalizedOffset: CGVector(dx: 0, dy: 0))
            
            let loginUsernameTextField: XCUICoordinate
            if app.frame.size.width == 375 { //iPhone Normal (6, 7, ...)
                loginUsernameTextField = normalized.withOffset(CGVector(dx: 375, dy: 600))
            } else if app.frame.size.width == 320 { //iPhone Small (5S, SE, ...)
                loginUsernameTextField = normalized.withOffset(CGVector(dx: 320, dy: 500))
            } else {
                print("Unsupported iOS modell. Please report this in our Discord!")
                shouldExit = true
                return
            }
            
            sleep(1 * conf.delayMultiplier)
            loginUsernameTextField.tap()
            sleep(1 * conf.delayMultiplier)
            continueAfterFailure = true
            app.typeText(username!)
        }
        
    }
    
    func test3LoginPassword() {
        
        if shouldExit || !conf.enableAccountManager {
            return
        }
        
        if username != nil && !isLoggedIn {
            
            let app = XCUIApplication(bundleIdentifier: "com.nianticlabs.pokemongo")
            let normalized = app.coordinate(withNormalizedOffset: CGVector(dx: 0, dy: 0))
            
            let loginPasswordTextField: XCUICoordinate
            if app.frame.size.width == 375 { //iPhone Normal (6, 7, ...)
                loginPasswordTextField = normalized.withOffset(CGVector(dx: 375, dy: 700))
            } else if app.frame.size.width == 320 { //iPhone Small (5S, SE, ...)
                loginPasswordTextField = normalized.withOffset(CGVector(dx: 320, dy: 600))
            } else {
                print("Unsupported iOS modell. Please report this in our Discord!")
                shouldExit = true
                return
            }
            
            sleep(1 * conf.delayMultiplier)
            loginPasswordTextField.tap()
            sleep(1 * conf.delayMultiplier)
            continueAfterFailure = true
            app.typeText(password!)
            
        }
        
    }
    
    func test4LoginEnd() {
        
        if shouldExit || !conf.enableAccountManager {
            return
        }
        
        if username != nil && !isLoggedIn {
            
            let app = XCUIApplication(bundleIdentifier: "com.nianticlabs.pokemongo")
            let normalized = app.coordinate(withNormalizedOffset: CGVector(dx: 0, dy: 0))
            
            let compareStart: (x: Int, y: Int)
            let compareFailed: (x: Int, y: Int)
            let compareTerms: (x: Int, y: Int)
            let comparePrivacy: (x: Int, y: Int)
            let compareBannedText: (x: Int, y: Int)
            let compareBanned: (x: Int, y: Int)
            
            let compareTutorialL: (x: Int, y: Int)
            let compareTutorialR: (x: Int, y: Int)
            
            let loginConfirmButton: XCUICoordinate
            let acceptTermsButton: XCUICoordinate
            let acceptPrivacyButton: XCUICoordinate
            let bannedButton: XCUICoordinate
            
            if app.frame.size.width == 320 { //iPhone Small (5S, SE, ...)
                compareStart = (320, 620)
                compareFailed = (320, 660)
                compareTerms = (115, 615)
                comparePrivacy = (320, 725)
                compareBanned = (320, 575)
                compareBannedText = (100, 900)
                compareTutorialL = (100, 900)
                compareTutorialR = (550, 900)
                loginConfirmButton = normalized.withOffset(CGVector(dx: 375, dy: 680))
                acceptTermsButton = normalized.withOffset(CGVector(dx: 320, dy: 615))
                acceptPrivacyButton = normalized.withOffset(CGVector(dx: 320, dy: 670))
                bannedButton = normalized.withOffset(CGVector(dx: 320, dy: 710))
            } else {
                print("Unsupported iOS modell. Please report this in our Discord!")
                shouldExit = true
                return
            }
            
            sleep(1 * conf.delayMultiplier)
            loginConfirmButton.tap()
            sleep(1 * conf.delayMultiplier)
            
            var loggedIn = false
            var count = 0
            
            while !loggedIn {
            
                if app.state != .runningForeground {
                    app.activate()
                    sleep(10 * conf.delayMultiplier)
                }
                
                let screenshotComp = XCUIScreen.main.screenshot()
                
                let colorS = screenshotComp.image.getPixelColor(pos: CGPoint(x: compareStart.x, y: compareStart.y))
                var redS: CGFloat = 0
                var greenS: CGFloat = 0
                var blueS: CGFloat = 0
                var alphaS: CGFloat = 0
                colorS.getRed(&redS, green: &greenS, blue: &blueS, alpha: &alphaS)
                
                let colorF = screenshotComp.image.getPixelColor(pos: CGPoint(x: compareFailed.x, y: compareFailed.y))
                var redF: CGFloat = 0
                var greenF: CGFloat = 0
                var blueF: CGFloat = 0
                var alphaF: CGFloat = 0
                colorF.getRed(&redF, green: &greenF, blue: &blueF, alpha: &alphaF)
                
                let colorT = screenshotComp.image.getPixelColor(pos: CGPoint(x: compareTerms.x, y: compareTerms.y))
                var redT: CGFloat = 0
                var greenT: CGFloat = 0
                var blueT: CGFloat = 0
                var alphaT: CGFloat = 0
                colorT.getRed(&redT, green: &greenT, blue: &blueT, alpha: &alphaT)
            
                let colorP = screenshotComp.image.getPixelColor(pos: CGPoint(x: comparePrivacy.x, y: comparePrivacy.y))
                var redP: CGFloat = 0
                var greenP: CGFloat = 0
                var blueP: CGFloat = 0
                var alphaP: CGFloat = 0
                colorP.getRed(&redP, green: &greenP, blue: &blueP, alpha: &alphaP)
                
                let colorB = screenshotComp.image.getPixelColor(pos: CGPoint(x: compareBanned.x, y: compareBanned.y))
                var redB: CGFloat = 0
                var greenB: CGFloat = 0
                var blueB: CGFloat = 0
                var alphaB: CGFloat = 0
                colorB.getRed(&redB, green: &greenB, blue: &blueB, alpha: &alphaB)
                
                let colorBT = screenshotComp.image.getPixelColor(pos: CGPoint(x: compareBannedText.x, y: compareBannedText.y))
                var redBT: CGFloat = 0
                var greenBT: CGFloat = 0
                var blueBT: CGFloat = 0
                var alphaBT: CGFloat = 0
                colorBT.getRed(&redBT, green: &greenBT, blue: &blueBT, alpha: &alphaBT)
                
                if (redBT < 0.05 && greenBT > 0.2 && greenBT < 0.3 && blueBT > 0.3 && blueBT < 0.4) {
                    print("[DEBUG] Got ban. Restarting...")
                    app.terminate()
                    app.activate()
                    sleep(10 * conf.delayMultiplier)
                } else if (greenT > 0.75 && greenT < 0.9 && blueT > 0.55 && blueT < 0.7) {
                    print("[DEBUG] Accepting Terms.")
                    acceptTermsButton.tap()
                    sleep(1 * conf.delayMultiplier)
                } else if (greenP > 0.75 && greenP < 0.9 && blueP > 0.55 && blueP < 0.7) {
                    print("[DEBUG] Accepting Privacy.")
                    acceptPrivacyButton.tap()
                    sleep(1 * conf.delayMultiplier)
                } else if (greenB > 0.75 && greenB < 0.9 && blueB > 0.55 && blueB < 0.7) {
                    print("[ERROR] Account \(username!) is banned.")
                    username = nil
                    isLoggedIn = false
                    bannedButton.tap()
                    postRequest(url: backendControlerURL, data: ["uuid": conf.uuid, "type": "account_banned"], blocking: true) { (result) in }
                    sleep(5 * conf.delayMultiplier)
                    shouldExit = true
                    return
                } else if (greenS > 0.75 && greenS < 0.9 && blueS > 0.55 && blueS < 0.7) || isTutorial(compareL: compareTutorialL, compareR: compareTutorialR) {
                    loggedIn = true
                    isLoggedIn = true
                    print("[INFO] Logged in as \(username!)")
                } else if (greenF > 0.75 && greenF < 0.9 && blueF > 0.55 && blueF < 0.7) {
                    print("[ERROR] Invalid credentials for \(username!)")
                    username = nil
                    isLoggedIn = false
                    postRequest(url: backendControlerURL, data: ["uuid": conf.uuid, "type": "account_invalid_credentials"], blocking: true) { (result) in }
                    sleep(5 * conf.delayMultiplier)
                    shouldExit = true
                    return
                } else {
                    count += 1
                    if count == 60 {
                        print("[ERROR] Login timed out. Restarting...")
                        shouldExit = true
                        return
                    }
                    sleep(1 * conf.delayMultiplier)
                }
                
            }
            
        }
    }
    
    func test5TutorialStart() {
        
        if shouldExit || username == nil || !isLoggedIn || !conf.enableAccountManager {
            return
        }
        
        if newLogIn {
            
            sleep(4 * conf.delayMultiplier)
            
            let app = XCUIApplication(bundleIdentifier: "com.nianticlabs.pokemongo")
            let normalized = app.coordinate(withNormalizedOffset: CGVector(dx: 0, dy: 0))
            
            let compareTutorialL: (x: Int, y: Int)
            let compareTutorialR: (x: Int, y: Int)
            
            let nextButton: XCUICoordinate
            let styleYesButton: XCUICoordinate
            let noARButton: XCUICoordinate
            let noARButtonConfirm: XCUICoordinate
            let catchOKButton: XCUICoordinate
            let catchCloseButton: XCUICoordinate

            
            if app.frame.size.width == 320 { //iPhone Small (5S, SE, ...)
                nextButton = normalized.withOffset(CGVector(dx: 565, dy: 1085))
                styleYesButton = normalized.withOffset(CGVector(dx: 320, dy: 610))
                noARButton = normalized.withOffset(CGVector(dx: 320, dy: 1070))
                noARButtonConfirm = normalized.withOffset(CGVector(dx: 320, dy: 645))
                catchOKButton = normalized.withOffset(CGVector(dx: 320, dy: 750))
                catchCloseButton = normalized.withOffset(CGVector(dx: 320, dy: 1050))
                compareTutorialL = (100, 900)
                compareTutorialR = (550, 900)
            } else {
                print("Unsupported iOS modell. Please report this in our Discord!")
                shouldExit = true
                return
            }
            
            if !isTutorial(compareL: compareTutorialL, compareR: compareTutorialR) {
                print("[INFO] Tutorial allready done. Restarting...")
                newLogIn = false
                app.terminate()
                app.activate()
                sleep(1 * conf.delayMultiplier)

                return
            }
            
            for _ in 1...9 {
                nextButton.tap()
                sleep(1 * conf.delayMultiplier)
            }
            sleep(2 * conf.delayMultiplier)
            for _ in 1...4 {
                nextButton.tap()
                sleep(1 * conf.delayMultiplier)
            }
            
            styleYesButton.tap()
            sleep(2 * conf.delayMultiplier)
            nextButton.tap()
            sleep(1 * conf.delayMultiplier)
            nextButton.tap()
            sleep(2 * conf.delayMultiplier)

            while !findAndClickPokemon(app: app) {
                app.swipeLeft()
            }
            
            sleep(4 * conf.delayMultiplier)
            noARButton.tap()
            sleep(1 * conf.delayMultiplier)
            noARButtonConfirm.tap()
            sleep(4 * conf.delayMultiplier)
            for _ in 1...5 {
                app.swipeUp()
                sleep(3 * conf.delayMultiplier)
            }
            sleep(10 * conf.delayMultiplier)
            catchOKButton.tap()
            sleep(7 * conf.delayMultiplier)
            catchCloseButton.tap()
            sleep(3 * conf.delayMultiplier)
            for _ in 1...2 {
                nextButton.tap()
                sleep(1 * conf.delayMultiplier)
            }

        }
        
    }

    func test6TutorialUsername() {
        
        if shouldExit || username == nil || !isLoggedIn || !conf.enableAccountManager {
            return
        }
        
        if newLogIn {
            
            continueAfterFailure = true
            let app = XCUIApplication(bundleIdentifier: "com.nianticlabs.pokemongo")
            app.typeText(username!)
            
        }
        
    }

    func test7TutorialEnd() {
        
        if shouldExit || username == nil || !isLoggedIn || !conf.enableAccountManager {
            return
        }
        
        if newLogIn {
            
            let app = XCUIApplication(bundleIdentifier: "com.nianticlabs.pokemongo")
            let normalized = app.coordinate(withNormalizedOffset: CGVector(dx: 0, dy: 0))
            
            let keybordDoneButton: XCUICoordinate
            let usernameOKButton: XCUICoordinate
            let usernameConfirmButton: XCUICoordinate
            
            if app.frame.size.width == 320 { //iPhone Small (5S, SE, ...)
                keybordDoneButton = normalized.withOffset(CGVector(dx: 550, dy: 1075))
                usernameOKButton = normalized.withOffset(CGVector(dx: 320, dy: 770))
                usernameConfirmButton = normalized.withOffset(CGVector(dx: 320, dy: 620))
            } else {
                print("Unsupported iOS modell. Please report this in our Discord!")
                shouldExit = true
                return
            }
            
            sleep(2 * conf.delayMultiplier)
            keybordDoneButton.tap()
            sleep(1 * conf.delayMultiplier)
            usernameOKButton.tap()
            sleep(1 * conf.delayMultiplier)
            usernameConfirmButton.tap()
            sleep(4 * conf.delayMultiplier)
            
            for _ in 1...6 {
                keybordDoneButton.tap()
                sleep(1 * conf.delayMultiplier)
            }
            sleep(1 * conf.delayMultiplier)
            keybordDoneButton.tap()
            
            print("[INFO] Tutorial Done. Restarting...")
            newLogIn = false
            app.terminate()
            app.activate()
            sleep(1 * conf.delayMultiplier)
        }
        
    }
    
    func test999Main() {
        
        if shouldExit || username == nil || isLoggedIn == false {
            return
        }
        
        let loop = try! SelectorEventLoop(selector: try! KqueueSelector())
        let router = Router()
        let server = DefaultHTTPServer(eventLoop: loop, interface: "0.0.0.0", port: conf.port, app: router.app)
        
        router["/loc"] = DelayResponse(JSONResponse(handler: { environ -> Any in
            if self.currentLocation != nil {
                
                if self.waitRequiresPokemon {
                    let jitterLat = Double(arc4random_uniform(5000)) / Double(10000000) - 0.00025
                    let jitterLon = Double(arc4random_uniform(5000)) / Double(10000000) - 0.00025
                    return [
                        "latitude": self.currentLocation!.lat + jitterLat,
                        "longitude": self.currentLocation!.lon + jitterLon,
                        "lat": self.currentLocation!.lat + jitterLat,
                        "lng": self.currentLocation!.lon + jitterLon
                    ]
                } else {
                    return [
                        "latitude": self.currentLocation!.lat,
                        "longitude": self.currentLocation!.lon,
                        "lat": self.currentLocation!.lat,
                        "lng": self.currentLocation!.lon
                    ]
                }
            } else {
                return []
            }
        }), delay: .delay(seconds: 0.1))
        
        router["/data"] = DelayResponse(JSONResponse(handler: { environ -> Any in
            let input = environ["swsgi.input"] as! SWSGIInput
            DataReader.read(input) { data in
                
                self.lastDataTime = Date()
                
                let jsonData: [String: Any]?
                do {
                    jsonData = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                } catch {
                    return
                }
                
                if jsonData != nil {
                    if jsonData!["gmo"] != nil {
                        self.postRequest(url: self.backendRawURL, data: jsonData!, blocking: true, completion: { (resultJson) in
                            if self.waitRequiresPokemon {
                                if (resultJson!["data"] as! [String: Any])["nearby"] as? Int ?? 0 > 0 {
                                    self.lock.lock()
                                    self.waitForData = false
                                    self.lock.unlock()
                                }
                            } else {
                                self.lock.lock()
                                self.waitForData = false
                                self.lock.unlock()
                            }
                        })
                        
                    } else {
                        let pokeCount: Int
                        if let pokemon = jsonData!["nearby_pokemon"] as? [[String: Any]] {
                            pokeCount = pokemon.count
                        } else {
                            pokeCount = 0
                        }
                        
                        self.postRequest(url: self.backendJSONURL, data: jsonData!, completion: { (_) in })
                        if self.waitRequiresPokemon {
                            if pokeCount != 0 {
                                self.lock.lock()
                                self.waitForData = false
                                self.lock.unlock()
                            }
                        } else {
                            self.lock.lock()
                            self.waitForData = false
                            self.lock.unlock()
                        }
                    }
                }
            }
            return []
        }), delay: .delay(seconds: 0.1))
        
        // Start HTTP server to listen on the port
        try! server.start()
        
        // Run event loop
        DispatchQueue(label: "http_server").async {
            loop.runForever()
        }
        
        print("[INFO] Server running at localhost:\(conf.port)")

        
        // Start Heartbeat
        DispatchQueue(label: "heartbeat_sender").async {
            while true {
                sleep(5)
                self.postRequest(url: self.backendControlerURL, data: ["uuid": self.conf.uuid, "type": "heartbeat"]) { (cake) in /* The cake is a lie! */ }
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
        
        let app = XCUIApplication(bundleIdentifier: "com.nianticlabs.pokemongo")
        
        // State vars
        var startupCount = 0
        var isStartupCompleted = false
        var hasWarning = false
        
        // Setup coords
        let normalized = app.coordinate(withNormalizedOffset: CGVector(dx: 0, dy: 0))
        
        let coordStartup: XCUICoordinate
        let coordPassenger: XCUICoordinate
        let coordWeather1: XCUICoordinate
        let coordWeather2: XCUICoordinate
        let coordWarning: XCUICoordinate
        let coordCloseNews: XCUICoordinate
        
        let closeMenuButton: XCUICoordinate
        let settingsButton: XCUICoordinate
        let logoutDragStart: XCUICoordinate
        let logoutDragEnd: XCUICoordinate
        let logoutButton: XCUICoordinate
        let logoutConfirmButton: XCUICoordinate

        let compareStart: (x: Int, y: Int)
        let compareStartLoggedOut: (x: Int, y: Int)
        let compareWarningL: (x: Int, y: Int)
        let compareWarningR: (x: Int, y: Int)
        let compareWeather: (x: Int, y: Int)
        let comparePassenger: (x: Int, y: Int)

        if app.frame.size.width == 375 { //iPhone Normal (6, 7, ...)
            coordStartup = normalized.withOffset(CGVector(dx: 375, dy: 800))
            coordPassenger = normalized.withOffset(CGVector(dx: 275, dy: 950))
            coordWeather1 = normalized.withOffset(CGVector(dx: 225, dy: 1145))
            coordWeather2 = normalized.withOffset(CGVector(dx: 225, dy: 1270))
            coordWarning = normalized.withOffset(CGVector(dx: 375, dy: 1125))
            coordCloseNews = normalized.withOffset(CGVector(dx: 375, dy: 1125))
            closeMenuButton = normalized.withOffset(CGVector(dx: 375, dy: 1215))
            settingsButton = normalized.withOffset(CGVector(dx: 700, dy: 215))
            logoutDragStart = normalized.withOffset(CGVector(dx: 375, dy: 1000))
            logoutDragEnd = normalized.withOffset(CGVector(dx: 375, dy: 100))
            logoutButton = normalized.withOffset(CGVector(dx: 500, dy: 575))
            logoutConfirmButton = normalized.withOffset(CGVector(dx: 375, dy: 725))
            
            compareStart = (375, 800)
            compareStartLoggedOut = (0, 0)
            compareWeather = (375, 916)
            comparePassenger = (275, 950)
            compareWarningL = (0, 0)
            compareWarningR = (0, 0)
        } else if app.frame.size.width == 768 { //iPad 9,7 (Air, Air2, ...)
            coordStartup = normalized.withOffset(CGVector(dx: 768, dy: 1234))
            coordPassenger = normalized.withOffset(CGVector(dx: 768, dy: 1567))
            coordWeather1 = normalized.withOffset(CGVector(dx: 1300, dy: 1700))
            coordWeather2 = normalized.withOffset(CGVector(dx: 768, dy: 2000))
            coordWarning = normalized.withOffset(CGVector(dx: 768, dy: 1700))
            coordCloseNews = normalized.withOffset(CGVector(dx: 768, dy: 1700))
            closeMenuButton = normalized.withOffset(CGVector(dx: 0, dy: 0))
            settingsButton = normalized.withOffset(CGVector(dx: 0, dy: 0))
            logoutDragStart = normalized.withOffset(CGVector(dx: 0, dy: 0))
            logoutDragEnd = normalized.withOffset(CGVector(dx: 0, dy: 0))
            logoutButton = normalized.withOffset(CGVector(dx: 0, dy: 0))
            logoutConfirmButton = normalized.withOffset(CGVector(dx: 0, dy: 0))
            
            compareStart = (768, 1234)
            compareStartLoggedOut = (0, 0)
            compareWarningL = (0, 0)
            compareWarningR = (0, 0)
            compareWeather = (768, 1360)
            comparePassenger = (768, 1567)
        } else if app.frame.size.width == 320 { //iPhone Small (5S, SE, ...)
            coordStartup = normalized.withOffset(CGVector(dx: 320, dy: 655))
            coordPassenger = normalized.withOffset(CGVector(dx: 230, dy: 790))
            coordWeather1 = normalized.withOffset(CGVector(dx: 240, dy: 975))
            coordWeather2 = normalized.withOffset(CGVector(dx: 220, dy: 1080))
            coordWarning = normalized.withOffset(CGVector(dx: 320, dy: 960))
            coordCloseNews = normalized.withOffset(CGVector(dx: 320, dy: 960))
            closeMenuButton = normalized.withOffset(CGVector(dx: 320, dy: 1035))
            settingsButton = normalized.withOffset(CGVector(dx: 600, dy: 183))
            logoutDragStart = normalized.withOffset(CGVector(dx: 320, dy: 900))
            logoutDragEnd = normalized.withOffset(CGVector(dx: 320, dy: 100))
            logoutButton = normalized.withOffset(CGVector(dx: 430, dy: 435))
            logoutConfirmButton = normalized.withOffset(CGVector(dx: 315, dy: 610))
            
            compareStart = (320, 655)
            compareStartLoggedOut = (320, 175)
            compareWeather = (320, 780)
            comparePassenger = (230, 790)
            compareWarningL = (90, 950)
            compareWarningR = (550, 950)
        } else if app.frame.size.width == 414 { //iPhone Large (6+, 7+, ...)
            coordStartup = normalized.withOffset(CGVector(dx: 621, dy: 1275))
            coordPassenger = normalized.withOffset(CGVector(dx: 820, dy: 1540))
            coordWeather1 = normalized.withOffset(CGVector(dx: 621, dy: 1890))
            coordWeather2 = normalized.withOffset(CGVector(dx: 621, dy: 2161))
            coordWarning = normalized.withOffset(CGVector(dx: 621, dy: 1865))
            coordCloseNews = normalized.withOffset(CGVector(dx: 621, dy: 1865))
            closeMenuButton = normalized.withOffset(CGVector(dx: 0, dy: 0))
            settingsButton = normalized.withOffset(CGVector(dx: 0, dy: 0))
            logoutDragStart = normalized.withOffset(CGVector(dx: 0, dy: 0))
            logoutDragEnd = normalized.withOffset(CGVector(dx: 0, dy: 0))
            logoutButton = normalized.withOffset(CGVector(dx: 0, dy: 0))
            logoutConfirmButton = normalized.withOffset(CGVector(dx: 0, dy: 0))
            
            compareStart = (621, 1275)
            compareStartLoggedOut = (0, 0)
            compareWeather = (621, 1512)
            comparePassenger = (820, 1540)
            compareWarningL = (0, 0)
            compareWarningR = (0, 0)
        } else {
            print("[ERROR] Unsupported iOS modell. Please report this in our Discord!")
            shouldExit = true
            return
        }
        
        while true {
            
            if app.state != .runningForeground {
                app.terminate()
                startupCount = 0
                isStarted = false
                isStartupCompleted = false
                app.activate()
                sleep(1 * conf.delayMultiplier)
            } else {
                normalized.tap()
            }
            
            if isStarted {
                if !isStartupCompleted {
                    print("[DEBUG] Performing Startup sequence")
                    coordStartup.tap()
                    sleep(1 * conf.delayMultiplier)
                    self.freeScreen(app: app, comparePassenger: comparePassenger, compareWeather: compareWeather, coordWeather1: coordWeather1, coordWeather2: coordWeather2, coordPassenger: coordPassenger, delayMultiplier: conf.delayMultiplier)
                    
                    hasWarning = self.checkHasWarning(compareL: compareWarningL, compareR: compareWarningR)
                    if hasWarning {
                        if self.firstWarningDate == nil && conf.enableAccountManager {
                            firstWarningDate = Date()
                            postRequest(url: backendControlerURL, data: ["uuid": conf.uuid, "type": "account_warning"], blocking: true) { (result) in }
                        }
                        print("[INFO] Account has a warning!")
                        coordWarning.tap()
                        sleep(1 * conf.delayMultiplier)
                    }
                    coordCloseNews.tap()
                    sleep(1 * conf.delayMultiplier)
                    isStartupCompleted = true
                } else {
                    
                    // Work work work
                    postRequest(url: backendControlerURL, data: ["uuid": conf.uuid, "type": "get_job"], blocking: true) { (result) in
                        
                        if result == nil {
                            print("[ERROR] Failed to get a job") // <- search harder, better, faster, stronger
                            sleep(1 * self.conf.delayMultiplier)
                        } else if let data = result!["data"] as? [String: Any], let action = data["action"] as? String {
                            
                            if action == "scan_pokemon" {
                                if hasWarning && self.conf.enableAccountManager {
                                    print("[INFO] Account has a warning and tried to scan for Pokemon. Logging out!")
                                    let success = self.logOut(app: app, closeMenuButton: closeMenuButton, settingsButton: settingsButton, dragStart: logoutDragStart, dragEnd: logoutDragEnd, logoutButton: logoutButton, logoutConfirmButton: logoutConfirmButton, compareStartLoggedOut: compareStartLoggedOut, delayMultiplier: self.conf.delayMultiplier)
                                    if !success {
                                        return
                                    }
                                    
                                    self.postRequest(url: self.backendControlerURL, data: ["uuid": self.conf.uuid, "type": "logged_out"], blocking: true) { (result) in }
                                    self.username = nil
                                    self.isLoggedIn = false
                                    UserDefaults.standard.synchronize()
                                    sleep(5 * self.conf.delayMultiplier)
                                    self.shouldExit = true
                                    return
                                }
                                
                                print("[DEBUG] Scanning for Pokemon")
                                
                                let lat = data["lat"] as? Double ?? 0
                                let lon = data["lon"] as? Double ?? 0
                                self.currentLocation = (lat, lon)
                                let start = Date()
                                self.waitRequiresPokemon = true
                                self.lock.lock()
                                self.waitForData = true
                                self.lock.unlock()
                                sleep(3 * self.conf.delayMultiplier)
                                var locked = true
                                while locked {
                                    usleep(100000 * self.conf.delayMultiplier)
                                    self.lock.lock()
                                    if Date().timeIntervalSince(start) >= self.conf.pokemonMaxTime {
                                        locked = false
                                        self.waitForData = false
                                        print("[DEBUG] Pokemon loading timed out.")
                                    } else {
                                        locked = self.waitForData
                                        if !locked {
                                            print("[DEBUG] Pokemon loaded after \(Date().timeIntervalSince(start)).")
                                        }
                                    }
                                    self.lock.unlock()
                                }

                            } else if action == "scan_raid" {
                                
                                if hasWarning && self.firstWarningDate != nil && Int(Date().timeIntervalSince(self.firstWarningDate!)) >= self.conf.maxWarningTimeRaid && self.conf.enableAccountManager {
                                    print("[INFO] Account has a warning and is over maxWarningTimeRaid. Logging out!")
                                    let success = self.logOut(app: app, closeMenuButton: closeMenuButton, settingsButton: settingsButton, dragStart: logoutDragStart, dragEnd: logoutDragEnd, logoutButton: logoutButton, logoutConfirmButton: logoutConfirmButton, compareStartLoggedOut: compareStartLoggedOut, delayMultiplier: self.conf.delayMultiplier)
                                    if !success {
                                        return
                                    }
                                    
                                    self.postRequest(url: self.backendControlerURL, data: ["uuid": self.conf.uuid, "type": "logged_out"], blocking: true) { (result) in }
                                    self.username = nil
                                    self.isLoggedIn = false
                                    UserDefaults.standard.synchronize()
                                    sleep(5 * self.conf.delayMultiplier)
                                    self.shouldExit = true
                                    return
                                }
                                
                                print("[DEBUG] Scanning for Raid")

                                let lat = data["lat"] as? Double ?? 0
                                let lon = data["lon"] as? Double ?? 0
                                self.currentLocation = (lat, lon)
                                let start = Date()
                                self.waitRequiresPokemon = false
                                self.lock.lock()
                                self.waitForData = true
                                self.lock.unlock()
                                sleep(3 * self.conf.delayMultiplier)
                                var locked = true
                                while locked {
                                    usleep(100000 * self.conf.delayMultiplier)
                                    self.lock.lock()
                                    if Date().timeIntervalSince(start) >= self.conf.raidMaxTime {
                                        locked = false
                                        self.waitForData = false
                                        print("[DEBUG] Raids loading timed out.")
                                    } else {
                                        locked = self.waitForData
                                        if !locked {
                                            print("[DEBUG] Raids loaded after \(Date().timeIntervalSince(start)).")
                                        }
                                    }
                                    self.lock.unlock()
                                }
                            }
                            
                            if Date().timeIntervalSince(self.lastDataTime) >= 60 {
                                app.terminate()
                            }
                            
                        } else {
                            print("[DEBUG] no job left") // <- search harder, better, faster, stronger
                            sleep(1 * self.conf.delayMultiplier)
                        }
                        
                    }
                    
                }
            } else {
                let screenshotComp = XCUIScreen.main.screenshot()
                if compareStart.x != 0 && compareStart.y != 0 {
                    let color = screenshotComp.image.getPixelColor(pos: CGPoint(x: compareStart.x, y: compareStart.y))
                    var red: CGFloat = 0
                    var green: CGFloat = 0
                    var blue: CGFloat = 0
                    var alpha: CGFloat = 0
                    color.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
                    
                    let colorL = screenshotComp.image.getPixelColor(pos: CGPoint(x: compareStartLoggedOut.x, y: compareStartLoggedOut.y))
                    var redL: CGFloat = 0
                    var greenL: CGFloat = 0
                    var blueL: CGFloat = 0
                    var alphaL: CGFloat = 0
                    colorL.getRed(&redL, green: &greenL, blue: &blueL, alpha: &alphaL)
                    
                    if (redL == 1 && greenL > 0.75 && greenL < 0.85 && blueL < 0.1) {
                        print("[INFO] Not logged in. Restarting...")
                        self.username = nil
                        self.isLoggedIn = false
                        UserDefaults.standard.synchronize()
                        sleep(5 * conf.delayMultiplier)
                        self.shouldExit = true
                        return
                    } else if (green > 0.75 && green < 0.9 && blue > 0.55 && blue < 0.7) {
                        print("[DEBUG] App Started")
                        isStarted = true
                    } else {
                        print("[DEBUG] App still in Startup")
                        if startupCount == 30 {
                            print("[DEBUG] App stuck in Startup. Restarting...")
                            app.terminate() // Retry
                        }
                        startupCount += 1
                        sleep(1 * conf.delayMultiplier)
                    }
                } else {
                    print("[ERROR] CompareStart not set")
                    shouldExit = true
                    return
                }
            }
        }
        
    }
    
}
