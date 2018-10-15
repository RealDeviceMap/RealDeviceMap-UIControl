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
        
        let pixelInfo: Int = ((Int(cgImage!.width) * Int(pos.y)) + Int(pos.x)) * 4
        
        let r = CGFloat(data[pixelInfo]) / CGFloat(255.0)
        let g = CGFloat(data[pixelInfo+1]) / CGFloat(255.0)
        let b = CGFloat(data[pixelInfo+2]) / CGFloat(255.0)
        let a = CGFloat(data[pixelInfo+3]) / CGFloat(255.0)
        
        return UIColor(red: r, green: g, blue: b, alpha: a)
    }
}

extension XCTestCase {
    
    func postRequest(url: URL, data: [String: Any], blocking: Bool=false, completion: @escaping ([String: Any]?) -> Swift.Void) {
        
        var done = false
        var resultDict: [String: Any]?
        let jsonData = try! JSONSerialization.data(withJSONObject: data)
        
        var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 10)
        request.httpMethod = "POST"
        request.httpBody = jsonData
        
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
                usleep(1000 * delayMultiplier)
            } while !done
            completion(resultDict)
        }
    }
    
    func checkHasWarning(compareL: (x: Int, y: Int), compareR: (x: Int, y: Int), screenshot: XCUIScreenshot?=nil) -> Bool {
        
        var hasWarning = false
        let screenshotComp = screenshot ?? XCUIScreen.main.screenshot()
        if compareL.x != 0 && compareL.y != 0 && compareR.x != 0 && compareR.y != 0 {
            let colorL = screenshotComp.image.getPixelColor(pos: CGPoint(x: compareL.x, y: compareL.y))
            var redL: CGFloat = 0
            var greenL: CGFloat = 0
            var blueL: CGFloat = 0
            var alphaL: CGFloat = 0
            colorL.getRed(&redL, green: &greenL, blue: &blueL, alpha: &alphaL)
            
            let colorR = screenshotComp.image.getPixelColor(pos: CGPoint(x: compareR.x, y: compareR.y))
            var redR: CGFloat = 0
            var greenR: CGFloat = 0
            var blueR: CGFloat = 0
            var alphaR: CGFloat = 0
            colorR.getRed(&redR, green: &greenR, blue: &blueR, alpha: &alphaR)
            
            if (
                redL <= 0.07 && redR <= 0.07 &&
                    redL >= 0.03 && redR >= 0.03 &&
                    greenL <= 0.11 && greenR <= 0.11 &&
                    greenL >= 0.7 && greenR >= 0.7 &&
                    blueL <= 0.14 && blueR <= 0.14 &&
                    blueL >= 0.10 && blueR >= 0.10
                ) {
                hasWarning = true
            }
        } else {
            print("[WARNING] Can't check if acount is banned. Missing warning compare values.")
        }
        
        return hasWarning
    }
    
    func isTutorial(compareL: (x: Int, y: Int), compareR: (x: Int, y: Int), screenshot: XCUIScreenshot?=nil) -> Bool {
        
        var isTutorial = false
        let screenshotComp = screenshot ?? XCUIScreen.main.screenshot()
        if compareL.x != 0 && compareL.y != 0 && compareR.x != 0 && compareR.y != 0 {
            let colorL = screenshotComp.image.getPixelColor(pos: CGPoint(x: compareL.x, y: compareL.y))
            var redL: CGFloat = 0
            var greenL: CGFloat = 0
            var blueL: CGFloat = 0
            var alphaL: CGFloat = 0
            colorL.getRed(&redL, green: &greenL, blue: &blueL, alpha: &alphaL)
            
            let colorR = screenshotComp.image.getPixelColor(pos: CGPoint(x: compareR.x, y: compareR.y))
            var redR: CGFloat = 0
            var greenR: CGFloat = 0
            var blueR: CGFloat = 0
            var alphaR: CGFloat = 0
            colorR.getRed(&redR, green: &greenR, blue: &blueR, alpha: &alphaR)
            
            if (
                redL <= 0.4 && redR <= 0.4 &&
                    redL >= 0.3 && redR >= 0.3 &&
                    greenL <= 0.6 && greenR <= 0.6 &&
                    greenL >= 0.5 && greenR >= 0.5 &&
                    blueL <= 0.7 && blueR <= 0.7 &&
                    blueL >= 0.6 && blueR >= 0.6
                ) {
                isTutorial = true
            }
        } else {
            print("[WARNING] Can't check if is on tutorial. Missing warning compare values.")
        }
        
        return isTutorial
    }
    
    func findAndClickPokemon(app: XCUIApplication, screenshot: XCUIScreenshot?=nil) -> Bool {
        
        let screenshotComp = screenshot ?? XCUIScreen.main.screenshot()
        
        let normalized = app.coordinate(withNormalizedOffset: CGVector(dx: 0, dy: 0))
        
        print("[DEBUG] Searching Pokemon...")
        for x in 0...screenshotComp.image.cgImage!.width / 10  {
            for y in 0...screenshotComp.image.cgImage!.height / 10 {
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
                    print("[DEBUG] Pokemon Found!")
                    normalized.withOffset(CGVector(dx: x * 10, dy: y * 10)).tap()
                    return true
                }
                
            }
        }
        print("[DEBUG] No Pokemon Found!")
        
        return false
    }
    
    func freeScreen(app: XCUIApplication, comparePassenger: (x: Int, y: Int), compareWeather: (x: Int, y: Int), coordWeather1: XCUICoordinate, coordWeather2: XCUICoordinate, coordPassenger: XCUICoordinate, delayMultiplier: UInt32) {
        var screenshot = XCUIScreen.main.screenshot()
        screenshot = clickPassengerWarning(coord: coordPassenger, compare: comparePassenger, screenshot: screenshot, delayMultiplier: delayMultiplier)
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
                sleep(2 * delayMultiplier)
                coordWeather2.tap()
                sleep(2 * delayMultiplier)
                screenshot = XCUIScreen.main.screenshot()
                screenshot = clickPassengerWarning(coord: coordPassenger, compare: comparePassenger, screenshot: screenshot, delayMultiplier: delayMultiplier)
            }
        }
    }
    
    func clickPassengerWarning(coord: XCUICoordinate, compare: (x: Int, y: Int), screenshot: XCUIScreenshot?=nil, delayMultiplier: UInt32) -> XCUIScreenshot {
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
            sleep(1 * delayMultiplier)
        }
        if screenshot != nil {
            return XCUIScreen.main.screenshot()
        }
        else {
            return screenshotComp
        }
    }
    
    func logOut(app: XCUIApplication, closeMenuButton: XCUICoordinate, settingsButton: XCUICoordinate, dragStart: XCUICoordinate, dragEnd: XCUICoordinate, logoutButton: XCUICoordinate, logoutConfirmButton: XCUICoordinate, compareStartLoggedOut:  (x: Int, y: Int), delayMultiplier: UInt32) -> Bool {
        
        closeMenuButton.tap()
        sleep(2 * delayMultiplier)
        settingsButton.tap()
        sleep(2 * delayMultiplier)
        dragStart.press(forDuration: 0.1, thenDragTo: dragEnd)
        sleep(2 * delayMultiplier)
        logoutButton.tap()
        sleep(2 * delayMultiplier)
        logoutConfirmButton.tap()
        sleep(10 * delayMultiplier)
        let screenshotComp = XCUIScreen.main.screenshot()
        if compareStartLoggedOut.x != 0 && compareStartLoggedOut.y != 0 {
            let color = screenshotComp.image.getPixelColor(pos: CGPoint(x: compareStartLoggedOut.x, y: compareStartLoggedOut.y))
            var red: CGFloat = 0
            var green: CGFloat = 0
            var blue: CGFloat = 0
            var alpha: CGFloat = 0
            color.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
            if (red == 1 && green > 0.75 && green < 0.85 && blue < 0.1) {
                print("[DEBUG] Logged out sucesfully")
                return true
            } else {
                print("[ERROR] Logging out failed. Restarting...")
                app.terminate()
                sleep(1 * delayMultiplier)
                return false
            }
        }
        return false
        
    }
    
}
