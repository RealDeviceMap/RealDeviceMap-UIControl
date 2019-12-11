//
//  Misc.swift
//  RealDeviceMap-UIControlUITests
//
//  Created by Florian Kostenzer on 28.09.18.
//

import Foundation
import XCTest

extension UIImage {
    func getPixelColor(pos: CGPoint) -> UIColor {
        
        let pixelData = cgImage!.dataProvider!.data!
        let data: UnsafePointer<UInt8> = CFDataGetBytePtr(pixelData)

        if cgImage!.bitsPerComponent == 16 {
            let pixelInfo: Int = ((Int(cgImage!.width) * Int(pos.y)) + Int(pos.x)) * 8

            var rValue: UInt32 = 0
            var gValue: UInt32 = 0
            var bValue: UInt32 = 0
            var aValue: UInt32 = 0

            NSData(bytes: [data[pixelInfo], data[pixelInfo+1]], length: 2).getBytes(&rValue, length: 2)
            NSData(bytes: [data[pixelInfo+2], data[pixelInfo+3]], length: 2).getBytes(&gValue, length: 2)
            NSData(bytes: [data[pixelInfo+4], data[pixelInfo+5]], length: 2).getBytes(&bValue, length: 2)
            NSData(bytes: [data[pixelInfo+6], data[pixelInfo+7]], length: 2).getBytes(&aValue, length: 2)
            
            let r = CGFloat(rValue) / CGFloat(65535.0)
            let g = CGFloat(gValue) / CGFloat(65535.0)
            let b = CGFloat(bValue) / CGFloat(65535.0)
            let a = CGFloat(aValue) / CGFloat(65535.0)
            
            return UIColor(red: r, green: g, blue: b, alpha: a)
        } else {
            let pixelInfo: Int = ((Int(cgImage!.width) * Int(pos.y)) + Int(pos.x)) * 4
            
            let r = CGFloat(data[pixelInfo]) / CGFloat(255.0)
            let g = CGFloat(data[pixelInfo+1]) / CGFloat(255.0)
            let b = CGFloat(data[pixelInfo+2]) / CGFloat(255.0)
            let a = CGFloat(data[pixelInfo+3]) / CGFloat(255.0)
            
            return UIColor(red: r, green: g, blue: b, alpha: a)
        }
        
    }
    
    func getPixelColor(pos: DeviceCoordinate) -> UIColor {
        return self.getPixelColor(pos: CGPoint(x: pos.x, y: pos.y))
    }
}

extension XCUIScreenshot {
    
    func rgbAtLocation(pos: (x: Int, y: Int)) -> (red: CGFloat, green: CGFloat, blue: CGFloat){
        
        let color = self.image.getPixelColor(pos: CGPoint(x: pos.x, y: pos.y))
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0

        color.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        return (red, green, blue)
        
    }
    
    func rgbAtLocation(pos: DeviceCoordinate) -> (red: CGFloat, green: CGFloat, blue: CGFloat){
        return self.rgbAtLocation(pos: pos.toXY())
    }
    
    func rgbAtLocation(pos: (x: Int, y: Int), min: (red: CGFloat, green: CGFloat, blue: CGFloat), max: (red: CGFloat, green: CGFloat, blue: CGFloat)) -> Bool {

        let color = self.rgbAtLocation(pos: pos)
        
        return  color.red >= min.red && color.red <= max.red &&
                color.green >= min.green && color.green <= max.green &&
                color.blue >= min.blue && color.blue <= max.blue
    }
    
    func rgbAtLocation(pos: DeviceCoordinate, min: (red: CGFloat, green: CGFloat, blue: CGFloat), max: (red: CGFloat, green: CGFloat, blue: CGFloat)) -> Bool {
        return self.rgbAtLocation(pos: pos.toXY(), min: min, max: max)
    }
}

extension XCTestCase {
    
    internal var app: XCUIApplication { return XCUIApplication(bundleIdentifier: "com.nianticlabs.pokemongo") }
    internal var deviceConfig: DeviceConfigProtocol { return DeviceConfig.global }
    internal var config: Config { return Config.global }
    
    func postRequest(url: URL, data: [String: Any], blocking: Bool=false, completion: @escaping ([String: Any]?) -> Swift.Void) {
        
        var done = false
        var resultDict: [String: Any]?
        let jsonData = try! JSONSerialization.data(withJSONObject: data)
        
        var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 10)
        request.httpMethod = "POST"
        request.httpBody = jsonData
        if config.token != "" {
            request.addValue("Bearer \(config.token)", forHTTPHeaderField: "Authorization")
        }
        
        let task = URLSession.shared.dataTask(with: request) {(data, response, error) in
            if let data = data {
                let resultJSON = try? JSONSerialization.jsonObject(with: data)
                resultDict = resultJSON as? [String: Any]
                if !blocking {
                    completion(resultDict)
                }
            } else {
                if !blocking {
                    completion(nil)
                }
            }
            done = true
        }
        
        task.resume()
        if blocking {
            repeat {
                usleep(1000)
            } while !done
            completion(resultDict)
        }
    }
	
    func checkHasWarning(screenshot: XCUIScreenshot?=nil) -> Bool {
        
        let screenshotComp = screenshot ?? XCUIScreen.main.screenshot()

        if screenshotComp.rgbAtLocation(
            pos: deviceConfig.compareWarningL,
            min: (red: 0.03, green: 0.07, blue: 0.10),
            max: (red: 0.07, green: 0.11, blue: 0.14)) &&
           screenshotComp.rgbAtLocation(
            pos: deviceConfig.compareWarningR,
            min: (red: 0.03, green: 0.07, blue: 0.10),
            max: (red: 0.07, green: 0.11, blue: 0.14)) {
            return true
        } else {
            return false
        }
        
    }
    
    func isTutorial(screenshot: XCUIScreenshot?=nil) -> Bool {
        
        let screenshotComp = screenshot ?? XCUIScreen.main.screenshot()
        
        if screenshotComp.rgbAtLocation(
            pos: deviceConfig.compareTutorialL,
            min: (red: 0.3, green: 0.5, blue: 0.6),
            max: (red: 0.4, green: 0.6, blue: 0.7)) &&
           screenshotComp.rgbAtLocation(
            pos: deviceConfig.compareWarningR,
            min: (red: 0.3, green: 0.5, blue: 0.6),
            max: (red: 0.4, green: 0.6, blue: 0.7)) {
            return true
        } else {
            return false
        }
    
    }
    /*
    // Planned detection for partially completed reloads, but doesn't seem worth it now :shrug:
    func failedTutorialMethod1(screenshot: XCUIScreenshot?=nil) -> Bool {
        
        let screenshotComp = screenshot ?? XCUIScreen.main.screenshot()
        
        if screenshotComp.rgbAtLocation(
            pos: deviceConfig.compareTutorialL,
            min: (red: 0.3, green: 0.5, blue: 0.6),
            max: (red: 0.4, green: 0.6, blue: 0.7)) &&
            screenshotComp.rgbAtLocation(
                pos: deviceConfig.compareWarningR,
                min: (red: 0.3, green: 0.5, blue: 0.6),
                max: (red: 0.4, green: 0.6, blue: 0.7)) {
            return true
        } else {
            return false
        }
        
    }
    
    func failedTutorialMethod2(screenshot: XCUIScreenshot?=nil) -> Bool{
    
        //let screenshotComp = screenshot ?? XCUIScreen.main.screenshot()
        /*
        if screenshotComp.rgbAtLocation(
            pos: deviceConfig.tutorialProfessorCheck,
            min: (red: 0.85, green: 0.9, blue: 0.00),
            max: (red: 0.92, green: 1.0, blue: 0.03)) {
            return
        }
        */
        return true
        
    }
    
    func failedTutorialMethod3(screenshot: XCUIScreenshot?=nil) -> Bool{
        
        //let screenshotComp = screenshot ?? XCUIScreen.main.screenshot()
        
        /*if screenshotComp.rgbAtLocation(
            pos: deviceConfig.tutorialProfessorCheck,
            min: (red: 0.85, green: 0.9, blue: 0.00),
            max: (red: 0.92, green: 1.0, blue: 0.03)) {
            return
        }*/
        return true
    }
    
    func failedTutorialMethod4(screenshot: XCUIScreenshot?=nil) -> Bool {
        
        //let screenshotComp = screenshot ?? XCUIScreen.main.screenshot()
        
        /*if screenshotComp.rgbAtLocation(
            pos: deviceConfig.tutorialProfessorCheck,
            min: (red: 0.85, green: 0.9, blue: 0.00),
            max: (red: 0.92, green: 1.0, blue: 0.03)) {
            return
        }*/
        return true
    }
    */
    func tutorialGenderSelection() -> Bool {
        Log.tutorial("Calling tutorialGenderSelection()")
        
        let GenderBool = Bool.random()
        Log.tutorial("Gender Boolean is: \(GenderBool)")
        if GenderBool {
            Log.tutorial("Selecting Male Avatar")
            /** Gender Bool is true, chooses Male **/
            deviceConfig.tutorialBack.toXCUICoordinate(app: app).tap()
            usleep(UInt32(1500000 * config.delayMultiplier))
        } else {
            Log.tutorial("Selecting Female Avatar")
            /** Gender Bool is False, chooses Female **/
            deviceConfig.tutorialNext.toXCUICoordinate(app: app).tap()
            usleep(UInt32(1500000 * config.delayMultiplier))
        }
        
        deviceConfig.tutorialNext.toXCUICoordinate(app: app).tap()
        usleep(UInt32(1500000 * config.delayMultiplier))
        return GenderBool
    }
    
    func tutorialPhysicalFeature() {
        let tapMultiplier: Double
        if #available(iOS 13.0, *)
        {
            tapMultiplier = 0.5
        }
        else
        {
            tapMultiplier = 1.0
        }
        
        let normalized = app.coordinate(withNormalizedOffset: CGVector(dx:0,dy:0))
        
        Log.tutorial("Begin Random Physical Feature Selection")
        
        let i = Int.random(in: 0...2)
        
        let selectPhysical = normalized.withOffset(CGVector(dx: lround(Double(deviceConfig.tutorialPhysicalXs[i])*tapMultiplier), dy: lround(Double(deviceConfig.tutorialSelectY)*tapMultiplier)))
        selectPhysical.tap()
        usleep(UInt32(1500000 * config.delayMultiplier))
        // Break Off into switch to Handle the fact each features X array
        switch i {

        case 0:
            Log.tutorial("Choosing Random Hair Color")
            
            let randomInt = Int.random(in: 0...2)
            
            let newFeature = normalized.withOffset(CGVector(dx: lround(Double(deviceConfig.tutorialHairXs[randomInt])*tapMultiplier), dy: lround(Double(deviceConfig.tutorialSelectY)*tapMultiplier)))
            newFeature.tap()
            usleep(UInt32(1500000 * config.delayMultiplier))
            deviceConfig.tutorialStyleChange.toXCUICoordinate(app: app).tap()
            Log.tutorial("Accepting New Hair Color")
            usleep(UInt32(1500000 * config.delayMultiplier))
            deviceConfig.tutorialStyleBack.toXCUICoordinate(app: app).tap()
            usleep(UInt32(1500000 * config.delayMultiplier))
            deviceConfig.tutorialNext.toXCUICoordinate(app: app).tap()
            usleep(UInt32(1500000 * config.delayMultiplier))
            Log.tutorial("Completed Random Hair Color Selection")
            
        case 1:
            Log.tutorial("Choosing Random Eye Color")
            
            let randomInt = Int.random(in: 0...2)
            
            let newFeature = normalized.withOffset(CGVector(dx: lround(Double(deviceConfig.tutorialEyeXs[randomInt])*tapMultiplier), dy: lround(Double(deviceConfig.tutorialSelectY)*tapMultiplier)))
            newFeature.tap()
            
            usleep(UInt32(1500000 * config.delayMultiplier))
            deviceConfig.tutorialStyleChange.toXCUICoordinate(app: app).tap()
            Log.tutorial("Accepting New Eye Color")
            usleep(UInt32(1500000 * config.delayMultiplier))
            deviceConfig.tutorialStyleBack.toXCUICoordinate(app: app).tap()
            usleep(UInt32(1500000 * config.delayMultiplier))
            deviceConfig.tutorialNext.toXCUICoordinate(app: app).tap()
            usleep(UInt32(1500000 * config.delayMultiplier))
            Log.tutorial("Completed Random Eye Color Selection")
            
        case 2:
            Log.tutorial("Choosing Random Skin Color")
            
            let randomInt = Int.random(in: 0...2)
            
            let newFeature = normalized.withOffset(CGVector(dx: lround(Double(deviceConfig.tutorialSkinXs[randomInt])*tapMultiplier), dy: lround(Double(deviceConfig.tutorialSelectY)*tapMultiplier)))
            newFeature.tap()
            
            usleep(UInt32(1500000 * config.delayMultiplier))
            deviceConfig.tutorialStyleChange.toXCUICoordinate(app: app).tap()
            Log.tutorial("Accepting New Hair Color")
            usleep(UInt32(1500000 * config.delayMultiplier))
            deviceConfig.tutorialStyleBack.toXCUICoordinate(app: app).tap()
            usleep(UInt32(1500000 * config.delayMultiplier))
            deviceConfig.tutorialNext.toXCUICoordinate(app: app).tap()
            usleep(UInt32(1500000 * config.delayMultiplier))
            Log.tutorial("Completed Random Hair Color Selection")
            
        default:
            Log.error("Something Had Gone Terribly Fucking Wrong")
            app.launch()
        }
    }
    
    func tutorialStyleSelection(_ gender: Bool) {
        Log.info("Passed Modified Gender Bool and its now: \(gender)")
        
        Log.tutorial("Beginning Random Accessory Selection")

        let tapMultiplier: Double
        if #available(iOS 13.0, *)
        {
            tapMultiplier = 0.5
        }
        else
        {
            tapMultiplier = 1.0
        }
        
        var poseX: Int
        var hatX: Int
        var shirtX: Int
        var backpackX: Int
        
        switch gender {
        case true:
            poseX = deviceConfig.tutorialMaleStyleXs[0]
            hatX = deviceConfig.tutorialMaleStyleXs[1]
            shirtX = deviceConfig.tutorialMaleStyleXs[2]
            backpackX = deviceConfig.tutorialMaleStyleXs[3]
        case false:
            poseX = deviceConfig.tutorialFemaleStyleXs[0]
            hatX = deviceConfig.tutorialFemaleStyleXs[1]
            shirtX = deviceConfig.tutorialFemaleStyleXs[2]
            backpackX = deviceConfig.tutorialFemaleStyleXs[3]
        default:
            Log.error("SHITS FUCKED in gender switch Case in StyleSelection")
        }
        
        let normalized = app.coordinate(withNormalizedOffset: CGVector(dx: 0,dy: 0))
        let styleGroup = Int.random(in:0...3)
        let styleType = Int.random(in:0...3)
        
        switch styleGroup {
        case 0: //Poses
            
            Log.tutorial("Changing Pose")
            let select = normalized.withOffset(CGVector(dx: lround(Double(poseX)*tapMultiplier), dy: lround(Double(deviceConfig.tutorialSelectY)*tapMultiplier)))
            select.tap()
            usleep(UInt32(2000000 * config.delayMultiplier))
            let selectPose = normalized.withOffset(CGVector(dx: lround(Double(deviceConfig.tutorialPoseAndBackpackX)*tapMultiplier), dy: lround(Double(deviceConfig.tutorialSelectY)*tapMultiplier)))
            selectPose.tap()
            usleep(UInt32(2000000 * config.delayMultiplier))
            Log.tutorial("Accepting Item Style Change")
            deviceConfig.tutorialStyleChange.toXCUICoordinate(app: app).tap()
            usleep(UInt32(2000000 * config.delayMultiplier))
            deviceConfig.tutorialStyleBack.toXCUICoordinate(app: app).tap()
            usleep(UInt32(2000000 * config.delayMultiplier))
            deviceConfig.tutorialStyleBack.toXCUICoordinate(app: app).tap()
            usleep(UInt32(2000000 * config.delayMultiplier))
            deviceConfig.tutorialNext.toXCUICoordinate(app: app).tap()
            usleep(UInt32(2000000 * config.delayMultiplier))
        
        case 1: //Hats
            
            Log.tutorial("Randomly Selected Hat")
            let select = normalized.withOffset(CGVector(dx: lround(Double(hatX)*tapMultiplier), dy: lround(Double(deviceConfig.tutorialSelectY)*tapMultiplier)))
            select.tap()
            usleep(UInt32(2000000 * config.delayMultiplier))
            let selectShirt = normalized.withOffset(CGVector(dx: lround(Double(deviceConfig.tutorialSharedStyleXs[styleType])*tapMultiplier), dy: lround(Double(deviceConfig.tutorialSelectY)*tapMultiplier)))
            selectShirt.tap()
            usleep(UInt32(2000000 * config.delayMultiplier))
            Log.tutorial("Accepting Item Style Change")
            deviceConfig.tutorialStyleChange.toXCUICoordinate(app: app).tap()
            usleep(UInt32(2000000 * config.delayMultiplier))
            deviceConfig.tutorialStyleBack.toXCUICoordinate(app: app).tap()
            usleep(UInt32(2000000 * config.delayMultiplier))
            deviceConfig.tutorialStyleBack.toXCUICoordinate(app: app).tap()
            usleep(UInt32(2000000 * config.delayMultiplier))
            deviceConfig.tutorialNext.toXCUICoordinate(app: app).tap()
            usleep(UInt32(2000000 * config.delayMultiplier))
            
        case 2: //Shirts
            
            Log.tutorial("Randomly Selected Shirt")
            let select = normalized.withOffset(CGVector(dx: lround(Double(shirtX)*tapMultiplier), dy: lround(Double(deviceConfig.tutorialSelectY)*tapMultiplier)))
            select.tap()
            usleep(UInt32(2000000 * config.delayMultiplier))
            let selectShirt = normalized.withOffset(CGVector(dx: lround(Double(deviceConfig.tutorialSharedStyleXs[styleType])*tapMultiplier), dy: lround(Double(deviceConfig.tutorialSelectY)*tapMultiplier)))
            selectShirt.tap()
            usleep(UInt32(2000000 * config.delayMultiplier))
            Log.tutorial("Accepting Item Style Change")
            deviceConfig.tutorialStyleChange.toXCUICoordinate(app: app).tap()
            usleep(UInt32(2000000 * config.delayMultiplier))
            deviceConfig.tutorialStyleBack.toXCUICoordinate(app: app).tap()
            usleep(UInt32(2000000 * config.delayMultiplier))
            deviceConfig.tutorialStyleBack.toXCUICoordinate(app: app).tap()
            usleep(UInt32(2000000 * config.delayMultiplier))
            deviceConfig.tutorialNext.toXCUICoordinate(app: app).tap()
            usleep(UInt32(2000000 * config.delayMultiplier))
            
        case 3: //Backpack
            
            Log.tutorial("Changing Backpack")
            let select = normalized.withOffset(CGVector(dx: lround(Double(backpackX)*tapMultiplier), dy: lround(Double(deviceConfig.tutorialSelectY)*tapMultiplier)))
            select.tap()
            usleep(UInt32(2000000 * config.delayMultiplier))
            let selectBackpack = normalized.withOffset(CGVector(dx: lround(Double(deviceConfig.tutorialPoseAndBackpackX)*tapMultiplier), dy: lround(Double(deviceConfig.tutorialSelectY)*tapMultiplier)))
            selectBackpack.tap()
            usleep(UInt32(2000000 * config.delayMultiplier))
            Log.tutorial("Accepting Item Style Change")
            deviceConfig.tutorialStyleChange.toXCUICoordinate(app: app).tap()
            usleep(UInt32(2000000 * config.delayMultiplier))
            deviceConfig.tutorialStyleBack.toXCUICoordinate(app: app).tap()
            usleep(UInt32(2000000 * config.delayMultiplier))
            deviceConfig.tutorialStyleBack.toXCUICoordinate(app: app).tap()
            usleep(UInt32(2000000 * config.delayMultiplier))
            deviceConfig.tutorialNext.toXCUICoordinate(app: app).tap()
            usleep(UInt32(2000000 * config.delayMultiplier))
            
        default:
            Log.error("SHITS FUCKED in styleGroup switch Case in StyleSelection")
        }
        
        let screenshotComp = XCUIScreen.main.screenshot()
        
        while !screenshotComp.rgbAtLocation(
            pos: deviceConfig.tutorialStyleDone,
            min: (red: 0.40, green: 0.78, blue: 0.57),
            max: (red: 0.50 , green: 0.88 , blue: 0.67)
            ) {
                Log.tutorial("Missed a Click Somewhere, Try Upping ConfigDelay\nCorrecting by completing avatar selection")
                deviceConfig.tutorialNext.toXCUICoordinate(app: app).tap()
                usleep(UInt32(2000000 * config.delayMultiplier))
                
        }
        Log.tutorial("Accepting Avatar Customization")
        /* Accept Avatar Selection */
        deviceConfig.tutorialStyleDone.toXCUICoordinate(app: app).tap()
        sleep(3 * config.delayMultiplier)
        
    }
    
    func tutorialGenUsername(_ length: Int) -> String {
        let usableCharacters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0..<length).map{ _ in usableCharacters.randomElement()!})
    }
    
    func findAndClickPokemon(screenshot: XCUIScreenshot?=nil) -> Bool {
        
        let screenshotComp = screenshot ?? XCUIScreen.main.screenshot()
        
        let normalized = app.coordinate(withNormalizedOffset: CGVector(dx: 0, dy: 0))

        let tapMultiplier: Double
        if #available(iOS 13.0, *)
        {
            tapMultiplier = 0.5
        }
        else
        {
            tapMultiplier = 1.0
        }

        Log.debug("Searching Pokemon...")
        for x in 0...screenshotComp.image.cgImage!.width / 10  {
            for y in 0...screenshotComp.image.cgImage!.height / 10 {
                print("Comparing at \(x),\(y)")
                let color = screenshotComp.image.getPixelColor(pos: CGPoint(x: x * 10, y: y * 10))
                var red: CGFloat = 0
                var green: CGFloat = 0
                var blue: CGFloat = 0
                var alpha: CGFloat = 0
                color.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
                
                if (
                    red > 0.9 &&
                        green > 0.6 && green < 0.7 &&
                        blue > 0.3 && blue < 0.4
                    ) {
                    Log.debug("Pokemon Found!")
                    usleep(UInt32(1000000 * config.encounterDelay))
                    normalized.withOffset(CGVector(dx: lround(Double(x * 10)*tapMultiplier), dy: lround(Double(y * 10)*tapMultiplier))).tap()
                    return true
                }
                
            }
        }
        Log.debug("No Pokemon Found!")
        
        return false
    }
    
    func freeScreen(run: Bool=true) {
        
        let tapMultiplier: Double
        if #available(iOS 13.0, *)
        {
            tapMultiplier = 0.5
        }
        else
        {
            tapMultiplier = 1.0
        }
        
        var screenshot = clickPassengerWarning()
        
        if screenshot.rgbAtLocation(
            pos: deviceConfig.encounterNoAR,
            min: (red: 0.20, green: 0.70, blue: 0.55),
            max: (red: 0.35, green: 0.85, blue: 0.65)) {
            deviceConfig.encounterNoAR.toXCUICoordinate(app: app).tap()
            sleep(2 * config.delayMultiplier)
            deviceConfig.encounterNoARConfirm.toXCUICoordinate(app: app).tap()
            sleep(3 * config.delayMultiplier)
            deviceConfig.encounterTmp.toXCUICoordinate(app: app).tap()
            sleep(3 * config.delayMultiplier)
            screenshot = XCUIScreen.main.screenshot()
            sleep(1 * config.delayMultiplier)
        }
        
        if screenshot.rgbAtLocation(
            pos: deviceConfig.adventureSyncRewards,
            min: (red: 0.98, green: 0.3, blue: 0.45),
            max: (red: 1.00, green: 0.5, blue: 0.60)
        ) {
            
            if screenshot.rgbAtLocation(
                pos: deviceConfig.adventureSyncButton,
                min: (red: 0.40, green: 0.80, blue: 0.50),
                max: (red: 0.50, green: 0.90, blue: 0.70)
            ) {
                deviceConfig.adventureSyncButton.toXCUICoordinate(app: app).tap()
                sleep(2 * config.delayMultiplier)
                deviceConfig.adventureSyncButton.toXCUICoordinate(app: app).tap()
                sleep(2 * config.delayMultiplier)
                screenshot = clickPassengerWarning()
            } else if screenshot.rgbAtLocation(
                pos: deviceConfig.adventureSyncButton,
                min: (red: 0.05, green: 0.45, blue: 0.50),
                max: (red: 0.20, green: 0.60, blue: 0.65)
            ) {
                deviceConfig.adventureSyncButton.toXCUICoordinate(app: app).tap()
                sleep(2 * config.delayMultiplier)
                screenshot = clickPassengerWarning()
            }
        }
        
        if screenshot.rgbAtLocation(
            pos: deviceConfig.teamSelectBackgorundL,
            min: (red: 0.00, green: 0.20, blue: 0.25),
            max: (red: 0.05, green: 0.35, blue: 0.35)) &&
           screenshot.rgbAtLocation(
            pos: deviceConfig.teamSelectBackgorundR,
            min: (red: 0.00, green: 0.20, blue: 0.25),
            max: (red: 0.05, green: 0.35, blue: 0.35)
        ) {
            
            for _ in 1...6 {
                deviceConfig.teamSelectNext.toXCUICoordinate(app: app).tap()
                sleep(1 * config.delayMultiplier)
            }
            sleep(3 * config.delayMultiplier)
            
            for _ in 1...3 {
                for _ in 1...5 {
                    deviceConfig.teamSelectNext.toXCUICoordinate(app: app).tap()
                    sleep(1 * config.delayMultiplier)
                }
                sleep(4 * config.delayMultiplier)
            }
            
            let x = Int(arc4random_uniform(UInt32(app.frame.width)))
            let button = DeviceCoordinate(x: x, y: deviceConfig.teamSelectY, tapScaler: tapMultiplier).toXCUICoordinate(app: app)
            button.tap()
            sleep(3 * config.delayMultiplier)
            deviceConfig.teamSelectNext.toXCUICoordinate(app: app).tap()
            sleep(2 * config.delayMultiplier)
            deviceConfig.teamSelectWelcomeOk.toXCUICoordinate(app: app).tap()
            sleep(2 * config.delayMultiplier)
            screenshot = clickPassengerWarning()
        }
        
        if screenshot.rgbAtLocation(
            pos: deviceConfig.weather,
            min: (red: 0.23, green: 0.35, blue: 0.50),
            max: (red: 0.36, green: 0.47, blue: 0.65)
        ) {
            deviceConfig.closeWeather1.toXCUICoordinate(app: app).tap()
            sleep(1 * config.delayMultiplier)
            deviceConfig.closeWeather2.toXCUICoordinate(app: app).tap()
            sleep(1 * config.delayMultiplier)
            screenshot = clickPassengerWarning()
        }
        
        if run && screenshot.rgbAtLocation(
            pos: deviceConfig.encounterPokemonRun,
            min: (red: 0.98, green: 0.98, blue: 0.98),
            max: (red: 1.00, green: 1.00, blue: 1.00)
        ) {
            deviceConfig.encounterPokemonRun.toXCUICoordinate(app: app).tap()
            sleep(1 * config.delayMultiplier)
            screenshot = clickPassengerWarning()
        }

        if run && !screenshot.rgbAtLocation(
            pos: deviceConfig.closeMenu,
            min: (red: 0.98, green: 0.98, blue: 0.98),
            max: (red: 1.00, green: 1.00, blue: 1.00)) {
            deviceConfig.closeMenu.toXCUICoordinate(app: app).tap()
            sleep(1 * config.delayMultiplier)
            screenshot = clickPassengerWarning()
        }

    }
    
    func clickPassengerWarning(screenshot: XCUIScreenshot?=nil) -> XCUIScreenshot {

        let screenshotComp = screenshot ?? XCUIScreen.main.screenshot()
        if screenshotComp.rgbAtLocation(
            pos: deviceConfig.passenger,
            min: (red: 0.0, green: 0.75, blue: 0.55),
            max: (red: 1.0, green: 0.90, blue: 0.70)
        ) {
            deviceConfig.passenger.toXCUICoordinate(app: app).tap()
            sleep(1 * config.delayMultiplier)
            return XCUIScreen.main.screenshot()
        }

        return screenshotComp
    }
    
    func logOut() -> Bool {
        
        print("[STATUS] Logout")

        let tapMultiplier: Double
        if #available(iOS 13.0, *)
        {
            tapMultiplier = 0.5
        }
        else
        {
            tapMultiplier = 1.0
        }
        
        let normalized = app.coordinate(withNormalizedOffset: CGVector(dx: 0, dy: 0))
        
        var main_counter = 0
        while !isMainScreen() && main_counter < 5
        {
            freeScreen()
            sleep(1 * config.delayMultiplier)
            main_counter = main_counter + 1
        }
        
        if main_counter == 5
        {
            Log.error("Failed to get Main Play Screen. Logging out failed. Restarting...")
            app.terminate()
            sleep(1 * config.delayMultiplier)
            return false
        }
        
        var settingpage_counter = 0
        while !isSettingPage() && settingpage_counter < 5
        {
            deviceConfig.closeMenu.toXCUICoordinate(app: app).tap()
            sleep(1 * config.delayMultiplier)
            settingpage_counter = settingpage_counter + 1
        }
        if settingpage_counter == 5
        {
            Log.error("Failed to open setting page. Logging out failed. Restarting...")
            app.terminate()
            sleep(1 * config.delayMultiplier)
            return false
        }
        
        var scrollpage_counter = 0
        while !isLogoutScrollPage() && scrollpage_counter < 5 {
            deviceConfig.settingsButton.toXCUICoordinate(app: app).tap()
            scrollpage_counter = scrollpage_counter + 1
            sleep(1)
        }

        if scrollpage_counter == 5
        {
            Log.error("Logging out failed. Restarting...")
            app.terminate()
            sleep(1 * config.delayMultiplier)
            return false
        }
        
        deviceConfig.logoutDragStart.toXCUICoordinate(app: app).press(forDuration: 0.1, thenDragTo: deviceConfig.logoutDragEnd.toXCUICoordinate(app: app))
        sleep(2 * config.delayMultiplier)

        var signoutFound = false
        let screenshot = XCUIScreen.main.screenshot()
        // Not to scan 10% from bottom
        let heightmax = screenshot.image.cgImage!.height - lround(Double(screenshot.image.cgImage!.height)*0.15)
        let heightmax_x01 = lround(Double(heightmax)*0.1)
        for y in 0...heightmax_x01 {
            if screenshot.rgbAtLocation(
                pos: (x: deviceConfig.logoutCompareX, y: y * 10),
                min: (red: 0.60, green: 0.9, blue: 0.6),
                max: (red: 0.75, green: 1.0, blue: 0.7)) {
                Log.debug("Signed out button found at \(y * 10)")
                normalized.withOffset(CGVector(dx: lround(Double(deviceConfig.logoutCompareX)*tapMultiplier), dy: lround(Double(y * 10)*tapMultiplier))).tap()
                sleep(1)
                signoutFound = true
                break
            }
        }
        
        var scroll_counter = 2
        while signoutFound == false && scroll_counter < 7 {
            Log.debug("Failed to find signed out button. Scroll again. \(scroll_counter)")
            deviceConfig.logoutDragStart2.toXCUICoordinate(app: app).press(forDuration: 1.0, thenDragTo: deviceConfig.logoutDragEnd2.toXCUICoordinate(app: app))            
            sleep(2 * config.delayMultiplier)
            let screenshot = XCUIScreen.main.screenshot()
            for y in 0...heightmax_x01 {
                if screenshot.rgbAtLocation(
                    pos: (x: deviceConfig.logoutCompareX, y: y * 10),
                    min: (red: 0.60, green: 0.9, blue: 0.6),
                    max: (red: 0.75, green: 1.0, blue: 0.7)) {
                    Log.debug("Signed out button found at \(y * 10)")
                    normalized.withOffset(CGVector(dx: lround(Double(deviceConfig.logoutCompareX)*tapMultiplier), dy: lround(Double(y * 10)*tapMultiplier))).tap()
                    sleep(1)
                    signoutFound = true
                    break
                }
            }
            scroll_counter = scroll_counter + 1
        }

        if signoutFound == false
        {
            Log.error("Can't find sign out button. Logging out failed. Restarting...")
            app.terminate()
            sleep(1 * config.delayMultiplier)
            return false
        }

        sleep(2 * config.delayMultiplier)
        deviceConfig.logoutConfirm.toXCUICoordinate(app: app).tap()

        for index in 1...20 {
            let screenshotComp = XCUIScreen.main.screenshot()

            if screenshotComp.rgbAtLocation(
                pos: deviceConfig.startupLoggedOut,
                min: (0.95, 0.75, 0.0),
                max: (1.00, 0.85, 0.1)
            ) {
                Log.debug("Logged out sucesfully")
                return true
            }
            sleep(1 * config.delayMultiplier)
        }

        Log.error("Logging out is taking too long. Restarting...")
        app.terminate()
        sleep(1 * config.delayMultiplier)
        return false
    }
    
    func spin() {
        deviceConfig.openPokestop.toXCUICoordinate(app: app).tap()
        sleep(1 * config.delayMultiplier)
        app.swipeLeft()
        sleep(1 * config.delayMultiplier)
        deviceConfig.closeMenu.toXCUICoordinate(app: app).tap()
        sleep(1 * config.delayMultiplier)
        
        let screenshotComp = XCUIScreen.main.screenshot()
        
        // Rocket invasion detection
        if screenshotComp.rgbAtLocation(
            pos: deviceConfig.rocketLogoGirl,
            min: (red: 0.76, green: 0.30, blue: 0.15),
            max: (red: 0.87, green: 0.38, blue: 0.22)) ||
           screenshotComp.rgbAtLocation(
            pos: deviceConfig.rocketLogoGuy,
            min: (red: 0.76, green: 0.30, blue: 0.15),
            max: (red: 0.87, green: 0.38, blue: 0.22))
        {
            Log.info("Rocket invasion encountered")
        
            // Tap through dialog 4 times and wait 3 seconds between each
            for _ in 1...4 {
                deviceConfig.openPokestop.toXCUICoordinate(app: app).tap()
                sleep(3 * config.delayMultiplier)
            }
            
            // Close battle invasion screen
            deviceConfig.closeInvasion.toXCUICoordinate(app: app).tap()
            sleep(1 * config.delayMultiplier)
        }
    }
    
    func clearQuest() {
        Log.test("Starting ClearQuest()")
        let start = Date()
        deviceConfig.openQuest.toXCUICoordinate(app: app).tap()
        sleep(1 * config.delayMultiplier)
        
        var screenshotComp = XCUIScreen.main.screenshot()
        while screenshotComp.rgbAtLocation(pos: deviceConfig.questWillow,
            min: (red: 0.50, green: 0.00, blue: 0.00),
            max: (red: 0.55, green: 0.02, blue: 0.02)) {
                Log.test("Clearing Prof Willow")
                deviceConfig.openPokestop.toXCUICoordinate(app: app).tap()
                sleep(1 * config.delayMultiplier)
                screenshotComp = XCUIScreen.main.screenshot()
        }
        
        app.swipeRight()
        sleep(1 * config.delayMultiplier)
        
        if screenshotComp.rgbAtLocation(pos: deviceConfig.questDelete, min: (red: 0.98, green: 0.60, blue: 0.22),max: (red: 1.0, green: 0.65, blue: 0.27))
        {//If the top quest is orange, might be clearing stacked quests
            //Theres a chance that we have a normal completed quests on top
            //We will eventually have a stack so I did not add logic for this check
            
            Log.test("Clearing stacked quests")
            
            for n in 0...3 {
                if screenshotComp.rgbAtLocation(pos: deviceConfig.questDeleteWithStack, min: (red: 0.80, green: 0.80, blue: 0.80),max: (red: 1.0, green: 1.0, blue: 1.0)) {
                    //second slot is normal quest. delete it.
                    Log.test("Clearing stacked quests: clearing a normal quest (slot 2).")
                    deviceConfig.questDeleteWithStack.toXCUICoordinate(app: app).tap()
                    sleep(1 * config.delayMultiplier)
                    deviceConfig.questDeleteConfirm.toXCUICoordinate(app: app).tap()
                    sleep(1 * config.delayMultiplier)
                    if n < 3 {
                        screenshotComp = XCUIScreen.main.screenshot()
                    }
                }
                else if screenshotComp.rgbAtLocation(pos: deviceConfig.questDeleteWithStack, min: (red: 0.90, green: 0.56, blue: 0.21),max: (red: 1.0, green: 0.65, blue: 0.27)) {
                    //second slot is a completed quest. Check the next one so we dont leave the quest log. Then click on the quests to initiate the encounter
                    if screenshotComp.rgbAtLocation(pos: deviceConfig.questDeleteThirdSlot, min: (red: 0.80, green: 0.80, blue: 0.80),max: (red: 1.0, green: 1.0, blue: 1.0)) {
                        //third slot is normal quest. delete it.
                        Log.test("Clearing stacked quests: clearing a normal quest (slot 3).")
                        deviceConfig.questDeleteThirdSlot.toXCUICoordinate(app: app).tap()
                        sleep(1 * config.delayMultiplier)
                        deviceConfig.questDeleteConfirm.toXCUICoordinate(app: app).tap()
                        sleep(1 * config.delayMultiplier)
                        screenshotComp = XCUIScreen.main.screenshot()
                    }
                    else if screenshotComp.rgbAtLocation(pos: deviceConfig.questDeleteThirdSlot, min: (red: 0.98, green: 0.60, blue: 0.22),max: (red: 1.0, green: 0.65, blue: 0.27)) {
                        //third slot is a completed quest
                        Log.test("Clearing stacked quests: clearing a completed quest (slot 3).")
                        deviceConfig.questDeleteThirdSlot.toXCUICoordinate(app: app).tap()
                        sleep(1 * config.delayMultiplier)
                        self.freeScreen() //run from the encounter
                        self.clearQuest() //to finish clearing the quests since we exited the quest log
                    }
                    else {
                        //tap the second slot if nothing is in the third slot
                        Log.test("Clearing stacked quests: clearing a completed quest (slot 2). RGB for quest slot: " + screenshotComp.rgbAtLocation(pos: deviceConfig.questDelete).red.description + ", " + screenshotComp.rgbAtLocation(pos: deviceConfig.questDelete).green.description + ", " + screenshotComp.rgbAtLocation(pos: deviceConfig.questDelete).blue.description)
                        deviceConfig.questDeleteWithStack.toXCUICoordinate(app: app).tap()
                        sleep(1 * config.delayMultiplier)
                        self.freeScreen() //run from the encounter
                    }
                }
                else {
                    //top slot is empty. No more quests to delete, so exit.
                    deviceConfig.closeMenu.toXCUICoordinate(app: app).tap()
                    Log.test("No more quests detected. RGB for quest slot: " + screenshotComp.rgbAtLocation(pos: deviceConfig.questDelete).red.description + ", " + screenshotComp.rgbAtLocation(pos: deviceConfig.questDelete).green.description + ", " + screenshotComp.rgbAtLocation(pos: deviceConfig.questDelete).blue.description)
                    break
                }
            }
        } else {//else we are clearing non-stacked quests because the top spot had the delete icon
            Log.test("Clearing unstacked quests. RGB for quest slot: " + screenshotComp.rgbAtLocation(pos: deviceConfig.questDelete).red.description + ", " + screenshotComp.rgbAtLocation(pos: deviceConfig.questDelete).green.description + ", " + screenshotComp.rgbAtLocation(pos: deviceConfig.questDelete).blue.description)
            for n in 0...2 {
                if screenshotComp.rgbAtLocation(pos: deviceConfig.questDelete, min: (red: 0.80, green: 0.80, blue: 0.80),max: (red: 1.0, green: 1.0, blue: 1.0)) {
                    //top slot is normal quest. delete it.
                    Log.test("Clearing unstacked quests: clearing a normal quest (slot 1).")
                    deviceConfig.questDelete.toXCUICoordinate(app: app).tap()
                    sleep(1 * config.delayMultiplier)
                    deviceConfig.questDeleteConfirm.toXCUICoordinate(app: app).tap()
                    sleep(1 * config.delayMultiplier)
                    if n < 2 {
                        screenshotComp = XCUIScreen.main.screenshot()
                    }
                }
                else if screenshotComp.rgbAtLocation(pos: deviceConfig.questDelete, min: (red: 0.98, green: 0.60, blue: 0.22),max: (red: 1.0, green: 0.65, blue: 0.27)) {
                    //top slot is a completed quest. Check the next one so we dont leave the quest log. Then click on the quests to initiate the encounter
                    if screenshotComp.rgbAtLocation(pos: deviceConfig.questDeleteWithStack, min: (red: 0.80, green: 0.80, blue: 0.80),max: (red: 1.0, green: 1.0, blue: 1.0)) {
                        //second slot is normal quest. delete it.
                        Log.test("Clearing unstacked quests: clearing a normal quest (slot 2).")
                        deviceConfig.questDeleteWithStack.toXCUICoordinate(app: app).tap()
                        sleep(1 * config.delayMultiplier)
                        deviceConfig.questDeleteConfirm.toXCUICoordinate(app: app).tap()
                        sleep(1 * config.delayMultiplier)
                        screenshotComp = XCUIScreen.main.screenshot()
                    }
                    else if screenshotComp.rgbAtLocation(pos: deviceConfig.questDeleteWithStack, min: (red: 0.98, green: 0.60, blue: 0.22),max: (red: 1.0, green: 0.65, blue: 0.27)) {
                        //second slot is a completed quest
                        Log.test("Clearing unstacked quests: clearing a completed quest (slot 2).")
                        deviceConfig.questDeleteWithStack.toXCUICoordinate(app: app).tap()
                        sleep(1 * config.delayMultiplier)
                        self.freeScreen() //run from the encounter
                        self.clearQuest() //to finish clearing the last quest since we exited the quest log
                    }
                }
                else {
                    //top slot is empty. No more quests to delete, so exit.
                    deviceConfig.closeMenu.toXCUICoordinate(app: app).tap()
                    Log.test("No more quests detected. RGB for quest slot: " + screenshotComp.rgbAtLocation(pos: deviceConfig.questDelete).red.description + ", " + screenshotComp.rgbAtLocation(pos: deviceConfig.questDelete).green.description + ", " + screenshotComp.rgbAtLocation(pos: deviceConfig.questDelete).blue.description)
                    break
                }
            }
        }
        
        self.freeScreen()
        Log.test("Clearing quests Time to Complete: \(String(format: "%.3f", Date().timeIntervalSince(start)))s")
        sleep(1 * config.delayMultiplier)
    }
    
    func clearItems() {
        Log.test("Starting ClearItems()")
        
        let tapMultiplier: Double
        if #available(iOS 13.0, *)
        {
            tapMultiplier = 0.5
        }
        else
        {
            tapMultiplier = 1.0
        }
        
        let normalized = app.coordinate(withNormalizedOffset: CGVector(dx: 0, dy: 0))
        var index = 0
        var done = false
        
        deviceConfig.closeMenu.toXCUICoordinate(app: app).tap()
        sleep(1 * config.delayMultiplier)
        deviceConfig.openItems.toXCUICoordinate(app: app).tap()
        sleep(1 * config.delayMultiplier)
        
        while !done && deviceConfig.itemDeleteYs.count != 0 {
            let screenshot = XCUIScreen.main.screenshot()
            
            if screenshot.rgbAtLocation(pos: deviceConfig.itemFreePass, min: (red: 0.42, green: 0.81, blue: 0.59),max: (red: 0.46, green: 0.85, blue: 0.63)) {
                Log.test("Closing free raid pass popup")
                deviceConfig.itemFreePass.toXCUICoordinate(app: app).tap()
                sleep(1 * config.delayMultiplier)
            }
            if screenshot.rgbAtLocation(pos: deviceConfig.itemGiftInfo, min: (red: 0.42, green: 0.81, blue: 0.59),max: (red: 0.46, green: 0.85, blue: 0.63)) {
                Log.test("Closing gift info popup")
                deviceConfig.itemGiftInfo.toXCUICoordinate(app: app).tap()
                sleep(1 * config.delayMultiplier)
            }
            
            if itemHasDelete(screenshot, x: deviceConfig.itemDeleteX, y: deviceConfig.itemDeleteYs[index]) && !itemIsGift(screenshot, x: deviceConfig.itemGiftX, y: deviceConfig.itemDeleteYs[index]) && !itemIsEgg(screenshot, x: deviceConfig.itemEggX, y: deviceConfig.itemDeleteYs[index]) && !itemIsEggActive(screenshot, x: deviceConfig.itemEggX, y: deviceConfig.itemDeleteYs[index]) || itemIsPokeball(screenshot, x: deviceConfig.itemGiftX, y: deviceConfig.itemDeleteYs[index]) || itemIsIncense(screenshot, x: deviceConfig.itemGiftX, y: deviceConfig.itemIncenseYs[index]) {
                
                let delete = normalized.withOffset(CGVector(dx: lround(Double(deviceConfig.itemDeleteX)*tapMultiplier), dy: lround(Double(deviceConfig.itemDeleteYs[index])*tapMultiplier)))
                delete.tap()
                sleep(1 * config.delayMultiplier)
                deviceConfig.itemDeleteIncrease.toXCUICoordinate(app: app).press(forDuration: 3)
                deviceConfig.itemDeleteConfirm.toXCUICoordinate(app: app).tap()
                sleep(1 * config.delayMultiplier)
            } else if index + 1 < deviceConfig.itemDeleteYs.count {
                index += 1
            } else {
                done = true
            }
        }
        sleep(1 * config.delayMultiplier)
    }
    
    func eggDeploy() -> Bool {
        Log.test("Starting eggDeploy()")
        let tapMultiplier: Double
        if #available(iOS 13.0, *)
        {tapMultiplier = 0.5}
        else
        {tapMultiplier = 1.0}
        
        let normalized = app.coordinate(withNormalizedOffset: CGVector(dx: 0, dy: 0))
        var index = 0
        var hasEgg = false
        
        deviceConfig.closeMenu.toXCUICoordinate(app: app).tap()
        sleep(1 * config.delayMultiplier)
        deviceConfig.openItems.toXCUICoordinate(app: app).tap()
        sleep(1 * config.delayMultiplier)
        
        while index < deviceConfig.itemDeleteYs.count {
            let screenshot = XCUIScreen.main.screenshot()
            if itemIsEgg(screenshot, x: deviceConfig.itemEggX, y: deviceConfig.itemDeleteYs[index]) {
                hasEgg = true
                break
            }
            index += 1
        }
        
        if hasEgg {
            Log.test("New egg found. Deploying it.")
            let itemEggMenuItem = normalized.withOffset(CGVector(dx: lround(Double(deviceConfig.itemEggX)*tapMultiplier), dy: lround(Double(deviceConfig.itemDeleteYs[index])*tapMultiplier)))
            itemEggMenuItem.tap()
            sleep(1 * config.delayMultiplier)
            deviceConfig.itemEggDeploy.toXCUICoordinate(app: app).tap()
            sleep(2 * config.delayMultiplier)
            return true
        } else {
            Log.test("No egg found or there's already has an active egg. Closing Menu.")
            deviceConfig.closeMenu.toXCUICoordinate(app: app).tap()
            sleep(1 * config.delayMultiplier)
            return false
        }
    }
    
    func itemHasDelete(_ screenshot: XCUIScreenshot, x: Int, y: Int) -> Bool {
        return screenshot.rgbAtLocation(
            pos: (x: x, y: y),
            min: (red: 0.50, green: 0.50, blue: 0.50),
            max: (red: 0.75, green: 0.80, blue: 0.75)
        )
    }
    
    func itemIsPokeball(_ screenshot: XCUIScreenshot, x: Int, y: Int) -> Bool {
        return screenshot.rgbAtLocation(
            pos: (x: x, y: y),
            min: (red: 0.9, green: 0.7, blue: 0.7),
            max: (red: 0.99, green: 0.8, blue: 0.8)
        )
    }
    
    func itemIsIncense(_ screenshot: XCUIScreenshot, x: Int, y: Int) -> Bool {
        return screenshot.rgbAtLocation(
            pos: (x: x, y: y),
            min: (red: 0.01, green: 0.9, blue: 0.4),
            max: (red: 0.09, green: 1.0, blue: 0.5)
        )
    }
    
    func itemIsGift(_ screenshot: XCUIScreenshot, x: Int, y: Int) -> Bool {
        return screenshot.rgbAtLocation(
            pos: (x: x, y: y),
            min: (red: 0.6, green: 0.05, blue: 0.5),
            max: (red: 0.7, green: 0.15, blue: 0.6)
        )
    }
    
    func itemIsEgg(_ screenshot: XCUIScreenshot, x: Int, y: Int) -> Bool {
        return screenshot.rgbAtLocation(
            pos: (x: x, y: y),
            min: (red: 0.45, green: 0.6, blue: 0.65),
            max: (red: 0.60, green: 0.7, blue: 0.75)
        )
    }
    
    func itemIsEggActive(_ screenshot: XCUIScreenshot, x: Int, y: Int) -> Bool {
        return screenshot.rgbAtLocation(
            pos: (x: x, y: y),
            min: (red: 0.8, green: 0.88, blue: 0.87),
            max: (red: 0.9, green: 0.93, blue: 0.93)
        )
    }
    
    func prepareEncounter() -> Bool {
        
        let start = Date()
        while UInt32(Date().timeIntervalSince(start)) <= (config.encounterMaxWait * config.delayMultiplier) {
            
            self.freeScreen(run: false)
            
            let screenshot = XCUIScreen.main.screenshot()
            if screenshot.rgbAtLocation(
                pos: deviceConfig.encounterPokemonRun,
                min: (red: 0.98, green: 0.98, blue: 0.98),
                max: (red: 1.00, green: 1.00, blue: 1.00)) &&
               screenshot.rgbAtLocation(
                pos: deviceConfig.encounterPokeball,
                min: (red: 0.70, green: 0.05, blue: 0.05),
                max: (red: 0.95, green: 0.30, blue: 0.35)) {
                deviceConfig.encounterPokemonRun.toXCUICoordinate(app: app).tap()
                return true
            }
            usleep(100000)
            
        }
        return false
        
    }
    
    func isMainScreen(screenshot: XCUIScreenshot?=nil) -> Bool {
        let screenshotComp = screenshot ?? XCUIScreen.main.screenshot()
        Log.debug("MainScreen")
        Log.debug("\(screenshotComp.rgbAtLocation(pos: deviceConfig.closeMenu))")
        Log.debug("\(screenshotComp.rgbAtLocation(pos: deviceConfig.mainScreenPokeballRed))")
        if screenshotComp.rgbAtLocation(
            pos: deviceConfig.closeMenu,
            min: (red: 0.98, green: 0.98, blue: 0.98),
            max: (red: 1.00, green: 1.00, blue: 1.00)) &&
            screenshotComp.rgbAtLocation(
                pos: deviceConfig.mainScreenPokeballRed,
                min: (red: 0.80, green: 0.10, blue: 0.17),
                max: (red: 1.00, green: 0.34, blue: 0.37)) {
            return true
        }
        return false
    }

    func isSettingPage(screenshot: XCUIScreenshot?=nil) -> Bool {
        let screenshotComp = screenshot ?? XCUIScreen.main.screenshot()
        Log.debug("SettingPageCheck")
        Log.debug("\(screenshotComp.rgbAtLocation(pos: deviceConfig.settingPageCloseButton))")
        if screenshotComp.rgbAtLocation(
            pos: deviceConfig.settingPageCloseButton,
            min: (red: 0.90, green: 0.90, blue: 0.90),
            max: (red: 1.00, green: 1.00, blue: 1.00)){
            return true
        }
        return false
    }

    func isLogoutScrollPage(screenshot: XCUIScreenshot?=nil) -> Bool {
        let screenshotComp = screenshot ?? XCUIScreen.main.screenshot()
        Log.debug("ScrollPage Check")
        Log.debug("\(screenshotComp.rgbAtLocation(pos: deviceConfig.logoutDarkBluePageBottomLeft))")
        Log.debug("\(screenshotComp.rgbAtLocation(pos: deviceConfig.logoutDarkBluePageTopRight))")
        if screenshotComp.rgbAtLocation(
            pos: deviceConfig.logoutDarkBluePageBottomLeft,
            min: (red: 0.00, green: 0.17, blue: 0.25),
            max: (red: 0.10, green: 0.37, blue: 0.47)) &&
            screenshotComp.rgbAtLocation(
                pos: deviceConfig.logoutDarkBluePageTopRight,
                min: (red: 0.00, green: 0.17, blue: 0.25),
                max: (red: 0.10, green: 0.37, blue: 0.47)) {
            return true
        }
        return false
    }

}

extension String {
    
    func toBool() -> Bool? {
        if self == "1" {
            return true
        }
        return Bool(self)
    }
    
    func toInt() -> Int? {
        return Int(self)
    }
    
    func toUInt32() -> UInt32? {
        return UInt32(self)
    }
    
    func toDouble() -> Double? {
        return Double(self)
    }
    
}
