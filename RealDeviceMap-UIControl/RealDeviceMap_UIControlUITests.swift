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

class RealDeviceMap_UIControlUITests: XCTestCase {
    
    // EDIT ME
    let uuid = "DEVICE_UUID"
    let backendURLBaseString = "http://RDM_UO:9001"
    
    // EDIT ME OPTIONALLY
    let port = 8080
    let pokemonMaxTime = 45.0
    let raidMaxTime = 15.0


    // DON'T EDIT ME
    var backendControlerURL: URL!
    var backendJSONURL: URL!
    var backendRawURL: URL!
    var isStarted = false
    var currentLocation: (lat: Double, lon: Double)?
    var waitRequiresPokemon = false
    var waitForData = false
    var lock = NSLock()
    var lastDataTime = Date()

    override func setUp() {
        super.setUp()
        
        backendControlerURL = URL(string: backendURLBaseString + "/controler")!
        backendJSONURL = URL(string: backendURLBaseString + "/json")!
        backendRawURL = URL(string: backendURLBaseString + "/raw")!
        continueAfterFailure = true
    }

    func test0Main() {
        
        // Register on backend
        postRequest(url: backendControlerURL, data: ["uuid": uuid, "type": "init"], blocking: true) { (result) in
            if result == nil {
                print("[ERROR] Failed to connect to Backend!")
                fatalError("[ERROR] Failed to connect to Backend!")
            } else if result!["status"] as? String != "ok" {
                let error = result!["error"] ?? "? (no error sent)"
                print("[ERROR] Backend returned a error: \(error)")
                fatalError("[ERROR] Backend returned a error: \(error)")
            }
            let data = result!["data"] as? [String: Any]
            if data == nil {
                print("[ERROR] Backend did not include data!")
                fatalError("[ERROR] Backend did not include data!")
            }
            if data!["asigned"] as? Bool == false {
                print("[ERROR] Device is not asigned to an instance!")
                fatalError("[ERROR] Device is not asigned to an instance!")
            }
            print("[INFO] Connected to Backend sucesfully")

        }
        

        let loop = try! SelectorEventLoop(selector: try! KqueueSelector())
        let router = Router()
        let server = DefaultHTTPServer(eventLoop: loop, interface: "0.0.0.0", port: port, app: router.app)
        
        router["/loc"] = DelayResponse(JSONResponse(handler: { environ -> Any in
            if self.currentLocation != nil {
                
                let jitterLat = Double(arc4random_uniform(5000)) / Double(10000000) - 0.00025
                let jitterLon = Double(arc4random_uniform(5000)) / Double(10000000) - 0.00025
                return [
                    "latitude": self.currentLocation!.lat + jitterLat,
                    "longitude": self.currentLocation!.lon + jitterLon
                ]
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
        
        print("[INFO] Server running at localhost:\(port)")

        
        // Start Heartbeat
        DispatchQueue(label: "heartbeat_sender").async {
            while true {
                sleep(5)
                self.postRequest(url: self.backendControlerURL, data: ["uuid": self.uuid, "type": "heartbeat"]) { (cake) in /* The cake is a lie! */ }
            }
        }
        

        // Time to start the actuall work
        runLoop()
        
    }
    
    func runLoop() {
        
        let app = XCUIApplication(bundleIdentifier: "com.nianticlabs.pokemongo")
        app.terminate()
        app.activate()
        
        // State vars
        var startupCount = 0
        //var lastStuck = false
        var isStartupCompleted = false
        
        // Setup coords
        let normalized = app.coordinate(withNormalizedOffset: CGVector(dx: 0, dy: 0))
        
        //let coordStartup: XCUICoordinate
        //let coordPassenger: XCUICoordinate
        //let coordNearby: XCUICoordinate
        //let coordWeather1: XCUICoordinate
        //let coordWeather2: XCUICoordinate
        //let coordWarning: XCUICoordinate
        //let compareStuck: (x: Int, y: Int)
        let compareStart: (x: Int, y: Int)
        //let compareWeather: (x: Int, y: Int)
        //let comparePassenger: (x: Int, y: Int)

        if app.frame.size.width == 375 { //iPhone Normal (6, 7, ...)
            //coordStartup = normalized.withOffset(CGVector(dx: 375, dy: 800))
            //coordPassenger = normalized.withOffset(CGVector(dx: 275, dy: 950))
            //coordNearby = normalized.withOffset(CGVector(dx: 600, dy: 1200))
            //coordWeather1 = normalized.withOffset(CGVector(dx: 225, dy: 1145))
            //coordWeather2 = normalized.withOffset(CGVector(dx: 225, dy: 1270))
            //coordWarning = normalized.withOffset(CGVector(dx: 375, dy: 1125))
            //compareStuck = (50, 1200)
            compareStart = (375, 800)
            //compareWeather = (375, 916)
            //comparePassenger = (275, 950)
        } else if app.frame.size.width == 768 { //iPad 9,7 (Air, Air2, ...)
            //coordStartup = normalized.withOffset(CGVector(dx: 768, dy: 1234))
            //coordPassenger = normalized.withOffset(CGVector(dx: 768, dy: 1567))
            //coordNearby = normalized.withOffset(CGVector(dx: 1387, dy: 1873))
            //coordWeather1 = normalized.withOffset(CGVector(dx: 1300, dy: 1700))
            //coordWeather2 = normalized.withOffset(CGVector(dx: 768, dy: 2000))
            //coordWarning = normalized.withOffset(CGVector(dx: 768, dy: 1700))
            //compareStuck = (102, 1873)
            compareStart = (768, 1234)
            //compareWeather = (768, 1360)
            //comparePassenger = (768, 1567)
        } else if app.frame.size.width == 320 { //iPhone Small (5S, SE, ...)
            //coordStartup = normalized.withOffset(CGVector(dx: 320, dy: 655))
            //coordPassenger = normalized.withOffset(CGVector(dx: 230, dy: 790))
            //coordNearby = normalized.withOffset(CGVector(dx: 550, dy: 1040))
            //coordWeather1 = normalized.withOffset(CGVector(dx: 240, dy: 975))
            //coordWeather2 = normalized.withOffset(CGVector(dx: 220, dy: 1080))
            //coordWarning = normalized.withOffset(CGVector(dx: 320, dy: 960))
            //compareStuck = (42, 1040)
            compareStart = (320, 655)
            //compareWeather = (320, 780)
            //comparePassenger = (230, 790)
        } else if app.frame.size.width == 414 { //iPhone Large (6+, 7+, ...)
            //coordStartup = normalized.withOffset(CGVector(dx: 621, dy: 1275))
            //coordPassenger = normalized.withOffset(CGVector(dx: 820, dy: 1540))
            //coordNearby = normalized.withOffset(CGVector(dx: 1060, dy: 2020))
            //coordWeather1 = normalized.withOffset(CGVector(dx: 621, dy: 1890))
            //coordWeather2 = normalized.withOffset(CGVector(dx: 621, dy: 2161))
            //coordWarning = normalized.withOffset(CGVector(dx: 621, dy: 1865))
            //compareStuck = (55, 2020)
            compareStart = (621, 1275)
            //compareWeather = (621, 1512)
            //comparePassenger = (820, 1540)
        } else {
            print("[ERROR] Unsupported iOS modell. Please report this in our Discord!")
            XCTFail()
            return
        }
        
        while true {
            
            if app.state != .runningForeground {
                app.terminate()
                startupCount = 0
                isStarted = false
                //lastStuck = false
                isStartupCompleted = false
                app.activate()
                sleep(1)
            } else {
                normalized.tap()
            }
            
            if isStarted {
                if !isStartupCompleted {
                    /*print("[DEBUG] Performing Startup sequence")
                    coordStartup.tap()
                    sleep(2)
                    coordWarning.tap()
                    sleep(2)
                    if compareWeather.x != 0 && compareWeather.y != 0 {
                        let screenshot = XCUIScreen.main.screenshot()
                        let color = screenshot.image.getPixelColor(pos: CGPoint(x: compareWeather.x, y: compareWeather.y))
                        var red: CGFloat = 0
                        var green: CGFloat = 0
                        var blue: CGFloat = 0
                        var alpha: CGFloat = 0
                        color.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
                        if red > 0.235 && red < 0.353 && green > 0.353 && green < 0.47 && blue > 0.5 && blue < 0.63 {
                            print("[DEBUG] Clicking Weather Warning")
                            coordWeather1.tap()
                            sleep(2)
                            coordWeather2.tap()
                            sleep(2)
                        }
                    }
                    _ = clickPassengerWarning(coord: coordPassenger, compare: comparePassenger)*/
                    isStartupCompleted = true
                } else {
                    
                    // Work work work
                    postRequest(url: backendControlerURL, data: ["uuid": uuid, "type": "get_job"], blocking: true) { (result) in
                        
                        if result == nil {
                            print("[ERROR] Failed to get a job") // <- search harder, better, faster, stronger
                            sleep(1)
                        } else if let data = result!["data"] as? [String: Any], let action = data["action"] as? String {
                            
                            if action == "scan_pokemon" {
                                print("[DEBUG] Scanning for Pokemon")
                                
                                let lat = data["lat"] as? Double ?? 0
                                let lon = data["lon"] as? Double ?? 0
                                self.currentLocation = (lat, lon)
                                let start = Date()
                                self.waitRequiresPokemon = true
                                self.lock.lock()
                                self.waitForData = true
                                self.lock.unlock()
                                sleep(3)
                                var locked = true
                                while locked {
                                    usleep(100000)
                                    self.lock.lock()
                                    if Date().timeIntervalSince(start) >= self.pokemonMaxTime {
                                        locked = false
                                        self.waitForData = false
                                    } else {
                                        locked = self.waitForData
                                    }
                                    self.lock.unlock()
                                }
                                print("[DEBUG] Pokemon loaded after \(Date().timeIntervalSince(start))")

                            } else if action == "scan_raid" {
                                print("[DEBUG] Scanning for Raid")

                                let lat = data["lat"] as? Double ?? 0
                                let lon = data["lon"] as? Double ?? 0
                                self.currentLocation = (lat, lon)
                                let start = Date()
                                self.waitRequiresPokemon = false
                                self.lock.lock()
                                self.waitForData = true
                                self.lock.unlock()
                                sleep(3)
                                var locked = true
                                while locked {
                                    usleep(100000)
                                    self.lock.lock()
                                    if Date().timeIntervalSince(start) >= self.raidMaxTime {
                                        locked = false
                                        self.waitForData = false
                                    } else {
                                        locked = self.waitForData
                                    }
                                    self.lock.unlock()
                                }
                                print("[DEBUG] Raids loaded after \(Date().timeIntervalSince(start))")
                            }
                            
                            if Date().timeIntervalSince(self.lastDataTime) >= 60 {
                                app.terminate()
                            }
                            
                        } else {
                            print("[DEBUG] no job left") // <- search harder, better, faster, stronger
                            sleep(1)
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
                    if (green > 0.75 && green < 0.9 && blue > 0.55 && blue < 0.7) {
                        print("[DEBUG] App Started")
                        isStarted = true
                    } else {
                        print("[DEBUG] App still in Startup")
                        if startupCount == 30 {
                            print("[DEBUG] App stuck in Startup. Restarting...")
                            app.terminate() // Retry
                        }
                        startupCount += 1
                        sleep(1)
                    }
                } else {
                    print("[ERROR] CompareStart not set")
                    fatalError("[ERROR] CompareStart not set")
                }
            }
        }
        
    }
    
    func clickPassengerWarning(coord: XCUICoordinate, compare: (x: Int, y: Int), screenshot: XCUIScreenshot?=nil) -> XCUIScreenshot {
        var shouldClick = false
        let screenshotComp = screenshot ?? XCUIScreen.main.screenshot()
        if compare.x != 0 && compare.y != 0 {
            let color = screenshotComp.image.getPixelColor(pos: CGPoint(x: compare.x, y: compare.y))
            var red: CGFloat = 0
            var green: CGFloat = 0
            var blue: CGFloat = 0
            var alpha: CGFloat = 0
            color.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
            if (green > 0.75 && green < 0.9 && blue > 0.55 && blue < 0.7) {
                shouldClick = true
            }
        } else {
            shouldClick = true
        }
        if shouldClick {
            coord.tap()
            sleep(1)
        }
        if screenshot != nil {
            return XCUIScreen.main.screenshot()
        }
        else {
            return screenshotComp
        }
    }
    
    func freeScreen(app: XCUIApplication, comparePassenger: (x: Int, y: Int), compareWeather: (x: Int, y: Int), compareStuck: (x: Int, y: Int), coordWeather1: XCUICoordinate, coordWeather2: XCUICoordinate, coordPassenger: XCUICoordinate, lastStuck: inout Bool) -> Bool {
        var screenshot = XCUIScreen.main.screenshot()
        screenshot = clickPassengerWarning(coord: coordPassenger, compare: comparePassenger, screenshot: screenshot)
        if compareWeather.x != 0 && compareWeather.y != 0 {
            let color = screenshot.image.getPixelColor(pos: CGPoint(x: compareWeather.x, y: compareWeather.y))
            var red: CGFloat = 0
            var green: CGFloat = 0
            var blue: CGFloat = 0
            var alpha: CGFloat = 0
            color.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
            if red > 0.235 && red < 0.353 && green > 0.353 && green < 0.47 && blue > 0.5 && blue < 0.63 {
                print("[DEBUG] Clicking Weather Warning")
                coordWeather1.tap()
                sleep(2)
                coordWeather2.tap()
                sleep(2)
                screenshot = XCUIScreen.main.screenshot()
                screenshot = clickPassengerWarning(coord: coordPassenger, compare: comparePassenger, screenshot: screenshot)
            }
        }
        if compareStuck.x != 0 && compareStuck.y != 0 {
            let color = screenshot.image.getPixelColor(pos: CGPoint(x: compareStuck.x, y: compareStuck.y))
            var red: CGFloat = 0
            var green: CGFloat = 0
            var blue: CGFloat = 0
            var alpha: CGFloat = 0
            color.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
            if red < 0.9 || green < 0.9 || blue < 0.9 {
                if lastStuck {
                    print("[DEBUG] We are stuck somewhere. Restarting...")
                    app.terminate()
                    return true
                } else {
                    lastStuck = true
                }
            } else {
                lastStuck = false
            }
        }
        return false
    }
    }
