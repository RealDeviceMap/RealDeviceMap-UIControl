//
//  Misc.swift
//  RealDeviceMap-UIControlUITests
//
//  Created by Florian Kostenzer on 28.09.18.
//
//  swiftlint:disable large_tuple function_body_length cyclomatic_complexity file_length
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

            let red = CGFloat(rValue) / CGFloat(65535.0)
            let green = CGFloat(gValue) / CGFloat(65535.0)
            let blue = CGFloat(bValue) / CGFloat(65535.0)
            let alpha = CGFloat(aValue) / CGFloat(65535.0)

            return UIColor(red: red, green: green, blue: blue, alpha: alpha)
        } else {
            let pixelInfo: Int = ((Int(cgImage!.width) * Int(pos.y)) + Int(pos.x)) * 4

            let red = CGFloat(data[pixelInfo]) / CGFloat(255.0)
            let green = CGFloat(data[pixelInfo+1]) / CGFloat(255.0)
            let blue = CGFloat(data[pixelInfo+2]) / CGFloat(255.0)
            let alpha = CGFloat(data[pixelInfo+3]) / CGFloat(255.0)

            return UIColor(red: red, green: green, blue: blue, alpha: alpha)
        }

    }

    func getPixelColor(pos: DeviceCoordinate) -> UIColor {
        return self.getPixelColor(pos: CGPoint(x: pos.x, y: pos.y))
    }
}

extension XCUIScreenshot {

    func rgbAtLocation(pos: (x: Int, y: Int))
            -> (red: CGFloat, green: CGFloat, blue: CGFloat) {

        let color = self.image.getPixelColor(pos: CGPoint(x: pos.x, y: pos.y))
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0

        color.getRed(&red, green: &green, blue: &blue, alpha: &alpha)

        return (red, green, blue)

    }

    func rgbAtLocation(pos: DeviceCoordinate) -> (red: CGFloat, green: CGFloat, blue: CGFloat) {
        return self.rgbAtLocation(pos: pos.toXY())
    }

    func rgbAtLocation(
        pos: (x: Int, y: Int),
        min: (red: CGFloat, green: CGFloat, blue: CGFloat),
        max: (red: CGFloat, green: CGFloat, blue: CGFloat)
    ) -> Bool {
        let color = self.rgbAtLocation(pos: pos)

        return  color.red >= min.red && color.red <= max.red &&
                color.green >= min.green && color.green <= max.green &&
                color.blue >= min.blue && color.blue <= max.blue
    }

    func rgbAtLocation(
        pos: DeviceCoordinate,
        min: (red: CGFloat, green: CGFloat, blue: CGFloat),
        max: (red: CGFloat, green: CGFloat, blue: CGFloat)
    ) -> Bool {
        return self.rgbAtLocation(pos: pos.toXY(), min: min, max: max)
    }
}

extension XCTestCase {

    internal var app: XCUIApplication { return XCUIApplication(bundleIdentifier: "com.nianticlabs.pokemongo") }
    internal var deviceConfig: DeviceConfigProtocol { return DeviceConfig.global }
    internal var config: Config { return Config.global }

    func getScreenshot(file: String = #file, function: String = #function,
                       line: Int = #line, tag: String = "") -> XCUIScreenshot {
        let screenshot = XCUIScreen.main.screenshot()
        if config.attachScreenshots {
            let attach = XCTAttachment(screenshot: screenshot)
            let filename = URL(fileURLWithPath: file).deletingPathExtension().lastPathComponent
            let functionTrimmed = function.replacingOccurrences(of: "\\(\\)", with: "", options: .regularExpression)
            attach.name = "\(filename)-\(functionTrimmed)-\(line).png"
            attach.lifetime = .keepAlways
            add(attach)
        }

        return screenshot
    }

    func postRequest(url: URL, data: [String: Any], blocking: Bool=false,
                     completion: @escaping ([String: Any]?) -> Swift.Void) {

        var done = false
        var resultDict: [String: Any]?
        let jsonData: Data
        do {
            jsonData = try JSONSerialization.data(withJSONObject: data)
        } catch {
            return
        }

        var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 10)
        request.httpMethod = "POST"
        request.httpBody = jsonData
        if config.token != "" {
            request.addValue("Bearer \(config.token)", forHTTPHeaderField: "Authorization")
        }

        let task = URLSession.shared.dataTask(with: request) {(data, _, _) in
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
        Log.debug("Checking for the warning pop-up")
        let screenshotComp = screenshot ?? getScreenshot()
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

    func acceptTOS() -> Bool {
        Log.debug("Checking for the first TOS pop-up")
        let screenshotComp = XCUIScreen.main.screenshot()
        if screenshotComp.rgbAtLocation(
            pos: deviceConfig.loginTerms,
            min: (red: 0.00, green: 0.75, blue: 0.55),
            max: (red: 1.00, green: 0.90, blue: 0.70)) &&
            screenshotComp.rgbAtLocation(
                pos: deviceConfig.loginTermsText,
                min: (red: 0.00, green: 0.00, blue: 0.00),
                max: (red: 0.30, green: 0.50, blue: 0.50)) {
            return true
        } else {
            return false
        }
    }

    func acceptTOSUpdate() -> Bool {
        Log.debug("Checking for the updated TOS pop-up")
        let screenshotComp = XCUIScreen.main.screenshot()
        if screenshotComp.rgbAtLocation(
            pos: deviceConfig.loginTerms2,
            min: (red: 0.40, green: 0.80, blue: 0.57),
            max: (red: 0.48, green: 0.87, blue: 0.65)) &&
            screenshotComp.rgbAtLocation(
                pos: deviceConfig.loginTerms2Text,
                min: (red: 0.11, green: 0.35, blue: 0.44),
                max: (red: 0.18, green: 0.42, blue: 0.51)) {
            return true
        } else {
            return false
        }
    }

    func acceptPrivacy() -> Bool {
        Log.debug("Checking for the privacy pop-up")
        let screenshotComp = XCUIScreen.main.screenshot()
        if screenshotComp.rgbAtLocation(
            pos: deviceConfig.loginPrivacy,
            min: (red: 0.40, green: 0.80, blue: 0.60),
            max: (red: 0.50, green: 0.85, blue: 0.65)) &&
            screenshotComp.rgbAtLocation(
                pos: deviceConfig.loginPrivacyText,
                min: (red: 0.40, green: 0.80, blue: 0.60),
                max: (red: 0.50, green: 0.85, blue: 0.65)) {
            return true
        } else {
            return false
        }
    }

    func acceptPrivacyUpdate() -> Bool {
        Log.debug("Checking for the privacy update pop-up")
        let screenshotComp = XCUIScreen.main.screenshot()
        if screenshotComp.rgbAtLocation(
            pos: deviceConfig.loginPrivacyUpdate,
            min: (red: 0.40, green: 0.80, blue: 0.60),
            max: (red: 0.50, green: 0.85, blue: 0.65)) &&
            screenshotComp.rgbAtLocation(
                pos: deviceConfig.loginPrivacyUpdateText,
                min: (red: 0.22, green: 0.36, blue: 0.37),
                max: (red: 0.32, green: 0.46, blue: 0.47)) {
            return true
        } else {
            return false
        }
    }

    func unableAuth() -> Bool {
        Log.debug("Checking for the unable to authenticate pop-up")
        let screenshotComp = XCUIScreen.main.screenshot()
        if screenshotComp.rgbAtLocation(
            pos: deviceConfig.unableAuthButton,
            min: (red: 0.40, green: 0.78, blue: 0.56),
            max: (red: 0.50, green: 0.88, blue: 0.66)) &&
            screenshotComp.rgbAtLocation(
                pos: deviceConfig.unableAuthText,
                min: (red: 0.29, green: 0.42, blue: 0.43),
                max: (red: 0.39, green: 0.52, blue: 0.53)) {

            return true
        } else {
            return false
        }
    }

    func failedLogin() -> Bool {
        Log.debug("Checking for the failed to login pop-up")
        let screenshotComp = XCUIScreen.main.screenshot()
        if screenshotComp.rgbAtLocation(
            pos: deviceConfig.loginBanned,
            min: (red: 0.39, green: 0.75, blue: 0.55),
            max: (red: 0.49, green: 0.90, blue: 0.70)) &&
            screenshotComp.rgbAtLocation(
                pos: deviceConfig.loginBannedText,
                min: (red: 0.26, green: 0.39, blue: 0.40),
                max: (red: 0.36, green: 0.49, blue: 0.50)) {
            return true
        } else {
            return false
        }
    }

    func isTutorial(screenshot: XCUIScreenshot?=nil) -> Bool {

        let screenshotComp = screenshot ?? getScreenshot()

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

    func isStartup(screenshot: XCUIScreenshot?=nil) -> Bool {

        let screenshotComp = screenshot ?? XCUIScreen.main.screenshot()

        if screenshotComp.rgbAtLocation(
            pos: deviceConfig.startupNewCautionSign,
            min: (red: 1.00, green: 0.97, blue: 0.60),
            max: (red: 1.00, green: 1.00, blue: 0.65)
           ) && screenshotComp.rgbAtLocation(
            pos: deviceConfig.startupNewButton,
            min: (red: 0.28, green: 0.79, blue: 0.62),
            max: (red: 0.33, green: 0.85, blue: 0.68)
        ) {
            Log.startup("Should be clearing Caution Sign new startup prompt")
            deviceConfig.startupNewButton.toXCUICoordinate(app: app).tap()
            return true
        } else if screenshotComp.rgbAtLocation(
            pos: deviceConfig.startupOldOkButton,
            min: (red: 0.42, green: 0.82, blue: 0.60),
            max: (red: 0.47, green: 0.86, blue: 0.63)
           ) && screenshotComp.rgbAtLocation(
            pos: deviceConfig.startupOldCornerTest,
            min: (red: 0.15, green: 0.41, blue: 0.45),
            max: (red: 0.19, green: 0.46, blue: 0.49)
        ) {
            Log.startup("Should be Clearing the 2 line long, old style startup prompt")
            deviceConfig.startupOldOkButton.toXCUICoordinate(app: app).tap()
            return true
        } else if screenshotComp.rgbAtLocation(
            pos: deviceConfig.startupOldOkButton,
            min: (red: 0.42, green: 0.82, blue: 0.60),
            max: (red: 0.47, green: 0.86, blue: 0.63)
         ) && screenshotComp.rgbAtLocation(
            pos: deviceConfig.startupOldCornerTest,
            min: (red: 0.99, green: 0.99, blue: 0.99),
            max: (red: 1.01, green: 1.01, blue: 1.01)
        ) {
            Log.startup("Should be clearing the 3 line long, old school style prompt")
            deviceConfig.startupOldOkButton.toXCUICoordinate(app: app).tap()
            return true
        }

        return false
    }
    /*
    // Planned detection for partially completed reloads, but doesn't seem worth it now :shrug:
    func failedTutorialMethod1(screenshot: XCUIScreenshot?=nil) -> Bool {
        
        let screenshotComp = screenshot ?? getScreenshot()
        
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
    
        //let screenshotComp = screenshot ?? getScreenshot()
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
        
        //let screenshotComp = screenshot ?? getScreenshot()
        
        /*if screenshotComp.rgbAtLocation(
            pos: deviceConfig.tutorialProfessorCheck,
            min: (red: 0.85, green: 0.9, blue: 0.00),
            max: (red: 0.92, green: 1.0, blue: 0.03)) {
            return
        }*/
        return true
    }
    
    func failedTutorialMethod4(screenshot: XCUIScreenshot?=nil) -> Bool {
        
        //let screenshotComp = screenshot ?? getScreenshot()
        
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

        let gender = Bool.random()
        Log.tutorial("Gender Boolean is: \(gender)")
        if gender {
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
        return gender
    }

    func tutorialPhysicalFeature() {
        let tapMultiplier: Double
        if #available(iOS 13.0, *) {
            tapMultiplier = 0.5
        } else {
            tapMultiplier = 1.0
        }

        let normalized = app.coordinate(withNormalizedOffset: CGVector(dx: 0, dy: 0))

        Log.tutorial("Begin Random Physical Feature Selection")

        let i = Int.random(in: 0...2)

        let selectPhysical = normalized.withOffset(
            CGVector(dx: lround(Double(deviceConfig.tutorialPhysicalXs[i])*tapMultiplier),
                     dy: lround(Double(deviceConfig.tutorialSelectY)*tapMultiplier))
        )
        selectPhysical.tap()
        usleep(UInt32(1500000 * config.delayMultiplier))
        // Break Off into switch to Handle the fact each features X array
        switch i {

        case 0:
            Log.tutorial("Choosing Random Hair Color")

            let randomInt = Int.random(in: 0...2)

            let newFeature = normalized.withOffset(
                CGVector(dx: lround(Double(deviceConfig.tutorialHairXs[randomInt])*tapMultiplier),
                         dy: lround(Double(deviceConfig.tutorialSelectY)*tapMultiplier))
            )
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

            let newFeature = normalized.withOffset(
                CGVector(dx: lround(Double(deviceConfig.tutorialEyeXs[randomInt])*tapMultiplier),
                         dy: lround(Double(deviceConfig.tutorialSelectY)*tapMultiplier))
            )
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

            let newFeature = normalized.withOffset(
                CGVector(dx: lround(Double(deviceConfig.tutorialSkinXs[randomInt])*tapMultiplier),
                         dy: lround(Double(deviceConfig.tutorialSelectY)*tapMultiplier))
            )
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
        if #available(iOS 13.0, *) {
            tapMultiplier = 0.5
        } else {
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

        let normalized = app.coordinate(withNormalizedOffset: CGVector(dx: 0, dy: 0))
        let styleGroup = Int.random(in: 0...3)
        let styleType = Int.random(in: 0...3)

        switch styleGroup {
        case 0: //Poses

            Log.tutorial("Changing Pose")
            let select = normalized.withOffset(
                CGVector(dx: lround(Double(poseX)*tapMultiplier),
                         dy: lround(Double(deviceConfig.tutorialSelectY)*tapMultiplier))
            )
            select.tap()
            usleep(UInt32(2000000 * config.delayMultiplier))
            let selectPose = normalized.withOffset(
                CGVector(dx: lround(Double(deviceConfig.tutorialPoseAndBackpackX)*tapMultiplier),
                         dy: lround(Double(deviceConfig.tutorialSelectY)*tapMultiplier))
            )
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
            let select = normalized.withOffset(
                CGVector(dx: lround(Double(hatX)*tapMultiplier),
                         dy: lround(Double(deviceConfig.tutorialSelectY)*tapMultiplier))
            )
            select.tap()
            usleep(UInt32(2000000 * config.delayMultiplier))
            let selectShirt = normalized.withOffset(
                CGVector(dx: lround(Double(deviceConfig.tutorialSharedStyleXs[styleType])*tapMultiplier),
                         dy: lround(Double(deviceConfig.tutorialSelectY)*tapMultiplier))
            )
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
            let select = normalized.withOffset(
                CGVector(dx: lround(Double(shirtX)*tapMultiplier),
                         dy: lround(Double(deviceConfig.tutorialSelectY)*tapMultiplier))
            )
            select.tap()
            usleep(UInt32(2000000 * config.delayMultiplier))
            let selectShirt = normalized.withOffset(
                CGVector(dx: lround(Double(deviceConfig.tutorialSharedStyleXs[styleType])*tapMultiplier),
                         dy: lround(Double(deviceConfig.tutorialSelectY)*tapMultiplier))
            )
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
            let select = normalized.withOffset(
                CGVector(dx: lround(Double(backpackX)*tapMultiplier),
                         dy: lround(Double(deviceConfig.tutorialSelectY)*tapMultiplier))
            )
            select.tap()
            usleep(UInt32(2000000 * config.delayMultiplier))
            let selectBackpack = normalized.withOffset(
                CGVector(dx: lround(Double(deviceConfig.tutorialPoseAndBackpackX)*tapMultiplier),
                         dy: lround(Double(deviceConfig.tutorialSelectY)*tapMultiplier))
            )
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

        let screenshotComp = getScreenshot()

        while !screenshotComp.rgbAtLocation(
            pos: deviceConfig.tutorialStyleDone,
            min: (red: 0.40, green: 0.78, blue: 0.57),
            max: (red: 0.50, green: 0.88, blue: 0.67)
            ) {
                Log.tutorial("Missed a Click Somewhere, Try Upping ConfigDelay\n" +
                             "Correcting by completing avatar selection")
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
        return String((0..<length).map { _ in usableCharacters.randomElement()!})
    }

    func findAndClickPokemon(screenshot: XCUIScreenshot?=nil) -> Bool {

        let screenshotComp = screenshot ?? getScreenshot()

        let normalized = app.coordinate(withNormalizedOffset: CGVector(dx: 0, dy: 0))

        let tapMultiplier: Double
        if #available(iOS 13.0, *) {
            tapMultiplier = 0.5
        } else {
            tapMultiplier = 1.0
        }

        Log.debug("Searching Pokemon...")
        for x in 0...screenshotComp.image.cgImage!.width / 10 {
            for y in 0...screenshotComp.image.cgImage!.height / 10 {
                print("Comparing at \(x),\(y)")
                let color = screenshotComp.image.getPixelColor(pos: CGPoint(x: x * 10, y: y * 10))
                var red: CGFloat = 0
                var green: CGFloat = 0
                var blue: CGFloat = 0
                var alpha: CGFloat = 0
                color.getRed(&red, green: &green, blue: &blue, alpha: &alpha)

                if red > 0.9 &&
                   green > 0.6 && green < 0.7 &&
                   blue > 0.3 && blue < 0.4 {
                    Log.debug("Pokemon Found!")
                    usleep(UInt32(1000000 * config.encounterDelay))
                    normalized.withOffset(CGVector(
                        dx: lround(Double(x * 10)*tapMultiplier),
                        dy: lround(Double(y * 10)*tapMultiplier))
                    ).tap()
                    return true
                }

            }
        }
        Log.debug("No Pokemon Found!")

        return false
    }

    func freeScreen(run: Bool=true) {

        let tapMultiplier: Double
        if #available(iOS 13.0, *) {
            tapMultiplier = 0.5
        } else {
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
            screenshot = getScreenshot()
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
            let button = DeviceCoordinate(x: x, y: deviceConfig.teamSelectY,
                                          tapScaler: tapMultiplier).toXCUICoordinate(app: app)
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

        let screenshotComp = screenshot ?? getScreenshot()
        if screenshotComp.rgbAtLocation(
            pos: deviceConfig.passenger,
            min: (red: 0.0, green: 0.75, blue: 0.55),
            max: (red: 1.0, green: 0.90, blue: 0.70)
        ) {
            deviceConfig.passenger.toXCUICoordinate(app: app).tap()
            sleep(1 * config.delayMultiplier)
            return getScreenshot()
        }

        return screenshotComp
    }

    func logOut() -> Bool {

        print("[STATUS] Logout")

        var mainCounter = 0
        while !isMainScreen() && mainCounter < 5 {
            freeScreen()
            sleep(1 * config.delayMultiplier)
            mainCounter += 1
        }

        if mainCounter == 5 {
            Log.error("Failed to get Main Play Screen. Logging out failed. Restarting...")
            app.terminate()
            sleep(1 * config.delayMultiplier)
            return false
        }

        var settingpageCounter = 0
        while !isSettingPage() && settingpageCounter < 5 {
            deviceConfig.closeMenu.toXCUICoordinate(app: app).tap()
            sleep(1 * config.delayMultiplier)
            settingpageCounter += 1
        }
        if settingpageCounter == 5 {
            Log.error("Failed to open setting page. Logging out failed. Restarting...")
            app.terminate()
            sleep(1 * config.delayMultiplier)
            return false
        }

        var scrollpageCounter = 0
        while !isLogoutScrollPage() && scrollpageCounter < 5 {
            deviceConfig.settingsButton.toXCUICoordinate(app: app).tap()
            scrollpageCounter += 1
            sleep(1)
        }

        if scrollpageCounter == 5 {
            Log.error("Logging out failed. Restarting...")
            app.terminate()
            sleep(1 * config.delayMultiplier)
            return false
        }

        var signoutFound = false
        var scrollCounter = 1
        let temp = logOutScroll(signoutFound: signoutFound, scroll_counter: scrollCounter, signoutRetry: false)
        signoutFound = temp.0
        scrollCounter = temp.1

        if signoutFound == false {
            Log.error("Can't find sign out button. Logging out failed. Restarting...")
            app.terminate()
            sleep(1 * config.delayMultiplier)
            return false
        } else {
            while signoutFound == true && scrollCounter < 7 {
                sleep(2 * config.delayMultiplier)
                let screenshot = XCUIScreen.main.screenshot()
                if screenshot.rgbAtLocation(pos: deviceConfig.logoutConfirm,
                                            min: (red: 0.42, green: 0.80, blue: 0.58),
                                            max: (red: 0.48, green: 0.87, blue: 0.65)) {
                    Log.debug("Log out confirmation button found")
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
                } else {
                    Log.error("Can't find log out confirmation button. Retrying.")
                    signoutFound = false
                    let temp = logOutScroll(signoutFound: signoutFound,
                                            scrollCounter: scrollCounter,
                                            signoutRetry: true)
                    signoutFound = temp.0
                    scrollCounter = temp.1
                }
            }
            Log.error("Can't find log out confirmation button. Logging out failed. Restarting...")
            app.terminate()
            sleep(1 * config.delayMultiplier)
            return false
        }
    }

    func logOutScroll(signoutFound: Bool, scrollCounter: Int, signoutRetry: Bool) -> (Bool, Int) {
        let tapMultiplier: Double
        if #available(iOS 13.0, *) { tapMultiplier = 0.5 } else { tapMultiplier = 1.0 }

        var signoutFound = signoutFound
        var scrollCounter = scrollCounter
        let normalized = app.coordinate(withNormalizedOffset: CGVector(dx: 0, dy: 0))
        while signoutFound == false && scrollCounter < 7 {
            if !signoutRetry {
                deviceConfig.logoutDragStart2.toXCUICoordinate(app: app).press(
                    forDuration: 1.0,
                    thenDragTo: deviceConfig.logoutDragEnd2.toXCUICoordinate(app: app)
                )
            } else {
                deviceConfig.logoutDragStart2.toXCUICoordinate(app: app).press(
                    orDuration: 1.0,
                    thenDragTo: normalized.withOffset(
                        CGVector(dx: 320.0*tapMultiplier, dy: 650.0*tapMultiplier)
                    )
                )
            }
            scrollCounter += 1
            sleep(2 * config.delayMultiplier)
            let screenshot = XCUIScreen.main.screenshot()
            // Not to scan 15% from bottom to avoid the close button
            let heightmax = screenshot.image.cgImage!.height - lround(Double(screenshot.image.cgImage!.height)*0.15)
            let heightmaxX1 = lround(Double(heightmax)*0.1)
            for y in 0...heightmaxX1 {
                if screenshot.rgbAtLocation(
                    pos: (x: deviceConfig.logoutCompareX, y: y * 10),
                    min: (red: 0.55, green: 0.84, blue: 0.58),
                    max: (red: 0.75, green: 1.00, blue: 0.70)) {
                    Log.debug("Signed out button found at \(y * 10)")
                    normalized.withOffset(
                        CGVector(dx: lround(Double(deviceConfig.logoutCompareX)*tapMultiplier),
                                 dy: lround(Double(y * 10)*tapMultiplier))
                    ).tap()
                    sleep(1 * config.delayMultiplier)
                    signoutFound = true
                    return (signoutFound, scrollCounter)
                }
            }
            Log.debug("Failed to find signed out button. Scroll again. \(scrollCounter)")
        }
        return (signoutFound, scrollCounter)
    }

    func spin() {
        deviceConfig.openPokestop.toXCUICoordinate(app: app).tap()
        sleep(1 * config.delayMultiplier)
        app.swipeLeft()
        sleep(1 * config.delayMultiplier)
        deviceConfig.closeMenu.toXCUICoordinate(app: app).tap()
        sleep(1 * config.delayMultiplier)

        let screenshotComp = getScreenshot()

        // Rocket invasion detection
        if screenshotComp.rgbAtLocation(
            pos: deviceConfig.rocketLogoGirl,
            min: (red: 0.62, green: 0.24, blue: 0.13),
            max: (red: 0.87, green: 0.36, blue: 0.20)) ||
           screenshotComp.rgbAtLocation(
            pos: deviceConfig.rocketLogoGuy,
            min: (red: 0.62, green: 0.24, blue: 0.13),
            max: (red: 0.87, green: 0.36, blue: 0.20)) {
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
        let start = Date()
        deviceConfig.openQuest.toXCUICoordinate(app: app).tap()
        sleep(1 * config.delayMultiplier)
        app.swipeRight()
        sleep(1 * config.delayMultiplier)

        var screenshotComp = getScreenshot()

        if screenshotComp.rgbAtLocation(
            pos: deviceConfig.questDelete,
            min: (red: 0.98, green: 0.60, blue: 0.22),
            max: (red: 1.0, green: 0.65, blue: 0.27)
        ) {
            Log.test("Clearing stacked quests")

            for i in 0...2 {
                if screenshotComp.rgbAtLocation(
                    pos: deviceConfig.questFilledColorWithStack1,
                    min: (red: 0.98, green: 0.98, blue: 0.98),
                    max: (red: 1.0, green: 1.0, blue: 1.0)
                ) {
                    //top slot is normal quest. delete it.
                    deviceConfig.questDeleteWithStack.toXCUICoordinate(app: app).tap()
                    sleep(1 * config.delayMultiplier)
                    deviceConfig.questDeleteConfirm.toXCUICoordinate(app: app).tap()
                    sleep(1 * config.delayMultiplier)
                    if i < 2 {
                        screenshotComp = getScreenshot()
                    }
                } else if screenshotComp.rgbAtLocation(
                    pos: deviceConfig.questFilledColorWithStack1,
                    min: (red: 0.98, green: 0.60, blue: 0.22),
                    max: (red: 1.0, green: 0.65, blue: 0.27)
                ) {
                    //top slot is a completed quest. Click on the quest to initiate the encounter
                    deviceConfig.questDeleteWithStack.toXCUICoordinate(app: app).tap()
                    sleep(1 * config.delayMultiplier)
                    self.freeScreen() //run from the encounter
                } else {
                    //top slot is empty. No more quests to delete, so exit.
                    break
                }
            }
        } else {
            Log.test("Clearing unstacked quests")
            for i in 0...2 {
                if screenshotComp.rgbAtLocation(
                    pos: deviceConfig.questFilledColor1,
                    min: (red: 0.98, green: 0.98, blue: 0.98),
                    max: (red: 1.0, green: 1.0, blue: 1.0)
                ) {
                    //top slot is normal quest. delete it.
                    deviceConfig.questDelete.toXCUICoordinate(app: app).tap()
                    sleep(1 * config.delayMultiplier)
                    deviceConfig.questDeleteConfirm.toXCUICoordinate(app: app).tap()
                    sleep(1 * config.delayMultiplier)
                    if i < 2 {
                        screenshotComp = getScreenshot()
                    }
                } else if screenshotComp.rgbAtLocation(
                    pos: deviceConfig.questFilledColor1,
                    min: (red: 0.98, green: 0.60, blue: 0.22),
                    max: (red: 1.0, green: 0.65, blue: 0.27)
                ) {
                    //top slot is a completed quest.  Click on the quest to initiate the encounter
                    deviceConfig.questDeleteWithStack.toXCUICoordinate(app: app).tap()
                    sleep(1 * config.delayMultiplier)
                    self.freeScreen() //run from the encounter
                } else {
                    //top slot is empty. No more quests to delete, so exit.
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
        if #available(iOS 13.0, *) {
            tapMultiplier = 0.5
        } else {
            tapMultiplier = 1.0
        }

        let normalized = app.coordinate(withNormalizedOffset: CGVector(dx: 0, dy: 0))
        var index = 0
        var done = false
        var hasEgg = false

        deviceConfig.closeMenu.toXCUICoordinate(app: app).tap()
        sleep(1 * config.delayMultiplier)
        deviceConfig.openItems.toXCUICoordinate(app: app).tap()
        sleep(1 * config.delayMultiplier)

        while !done && deviceConfig.itemDeleteYs.count != 0 {
            let screenshot = getScreenshot()

            if itemIsEgg(screenshot, x: deviceConfig.itemEggX, y: deviceConfig.itemDeleteYs[index]) {
                hasEgg = true
            }

            if itemHasDelete(
                screenshot,
                x: deviceConfig.itemDeleteX,
                y: deviceConfig.itemDeleteYs[index]
               ) && !itemIsGift(
                screenshot,
                x: deviceConfig.itemGiftX,
                y: deviceConfig.itemDeleteYs[index]
               ) && !itemIsEgg(
                screenshot,
                x: deviceConfig.itemEggX,
                y: deviceConfig.itemDeleteYs[index]
               ) && !itemIsEggActive(
                screenshot,
                x: deviceConfig.itemEggX,
                y: deviceConfig.itemDeleteYs[index]
               ) {

                let delete = normalized.withOffset(
                    CGVector(dx: lround(Double(deviceConfig.itemDeleteX)*tapMultiplier),
                             dy: lround(Double(deviceConfig.itemDeleteYs[index])*tapMultiplier))
                )
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

        let deployEnabled: Bool = config.deployEggs
        Log.test("deployEnabled: \(deployEnabled)")
        if hasEgg && deployEnabled {
            deviceConfig.itemEggMenuItem.toXCUICoordinate(app: app).tap()
            sleep(1 * config.delayMultiplier)
            deviceConfig.itemEggDeploy.toXCUICoordinate(app: app).tap()
            sleep(2 * config.delayMultiplier)
        } else {
            deviceConfig.closeMenu.toXCUICoordinate(app: app).tap()
            Log.test("Closing Menu")
        }
        sleep(1 * config.delayMultiplier)

    }

    func itemHasDelete(_ screenshot: XCUIScreenshot, x: Int, y: Int) -> Bool {

        return screenshot.rgbAtLocation(
            pos: (x: x, y: y),
            min: (red: 0.50, green: 0.50, blue: 0.50),
            max: (red: 0.75, green: 0.80, blue: 0.75)
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

            let screenshot = getScreenshot()
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
            max: (red: 1.00, green: 1.00, blue: 1.00)) {
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
