//
//  Misc.swift
//  RealDeviceMap-UIControlUITests
//
//  Created by Florian Kostenzer on 28.09.18.
//

// DON'T EDIT!

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
    
    func rgbAtLocation(pos: (x: Int, y: Int), min: (red: CGFloat, green: CGFloat, blue: CGFloat), max: (red: CGFloat, green: CGFloat, blue: CGFloat)) -> Bool {

        let color = self.rgbAtLocation(pos: pos)
        
        return  color.red >= min.red && color.red <= max.red &&
                color.green >= min.green && color.green <= max.green &&
                color.blue >= min.blue && color.blue <= max.blue
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
                usleep(1000)
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
            
            print("[DEBUG] Warning Values Left:", redL, greenL, blueL)
            print("[DEBUG] Warning Values Right:", redR, greenR, blueR)

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
            print("[WARNING] Can't check if acount has a warning. Missing warning compare values.")
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
        print("[DEBUG] No Pokemon Found! ")
        
        return false
    }
    
    func freeScreen(app: XCUIApplication, comparePassenger: (x: Int, y: Int), compareWeather: (x: Int, y: Int), comparOverlay: (x: Int, y: Int), comparePokemonRun: (x: Int, y: Int), coordWeather1: XCUICoordinate, coordWeather2: XCUICoordinate, coordPassenger: XCUICoordinate, closeOverlay: XCUICoordinate, pokemonRun: XCUICoordinate, delayMultiplier: UInt32) {
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
                sleep(1 * delayMultiplier)
                coordWeather2.tap()
                sleep(1 * delayMultiplier)
                screenshot = XCUIScreen.main.screenshot()
                screenshot = clickPassengerWarning(coord: coordPassenger, compare: comparePassenger, screenshot: screenshot, delayMultiplier: delayMultiplier)
                sleep(1 * delayMultiplier)
                
            }
        }
        if comparOverlay.x != 0 && comparOverlay.y != 0 {
            if screenshot.rgbAtLocation(
                pos: comparOverlay,
                min: (red: 0.08, green: 0.50, blue: 0.55),
                max: (red: 0.13, green: 0.55, blue: 0.60)) {
                closeOverlay.tap()
                sleep(1 * delayMultiplier)
                screenshot = XCUIScreen.main.screenshot()
                screenshot = clickPassengerWarning(coord: coordPassenger, compare: comparePassenger, screenshot: screenshot, delayMultiplier: delayMultiplier)
                sleep(1 * delayMultiplier)
            }
        }
        if comparePokemonRun.x != 0 && comparePokemonRun.y != 0 {
            if screenshot.rgbAtLocation(
                pos: comparePokemonRun,
                min: (red: 0.98, green: 0.98, blue: 0.98),
                max: (red: 1.00, green: 1.00, blue: 1.00)) {
                pokemonRun.press(forDuration: 1)
                sleep(1 * delayMultiplier)
                screenshot = XCUIScreen.main.screenshot()
                screenshot = clickPassengerWarning(coord: coordPassenger, compare: comparePassenger, screenshot: screenshot, delayMultiplier: delayMultiplier)
                sleep(1 * delayMultiplier)
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
    
    func logOut(app: XCUIApplication, closeMenuButton: XCUICoordinate, settingsButton: XCUICoordinate, dragStart: XCUICoordinate, dragEnd: XCUICoordinate, logoutConfirmButton: XCUICoordinate, logoutCompareX: Int, compareStartLoggedOut:  (x: Int, y: Int), delayMultiplier: UInt32) -> Bool {
        
        let normalized = app.coordinate(withNormalizedOffset: CGVector(dx: 0, dy: 0))
        
        closeMenuButton.tap()
        sleep(2 * delayMultiplier)
        settingsButton.tap()
        sleep(2 * delayMultiplier)
        dragStart.press(forDuration: 0.1, thenDragTo: dragEnd)
        sleep(2 * delayMultiplier)
        
        let screenshot = XCUIScreen.main.screenshot()
        for y in 0...screenshot.image.cgImage!.height / 10 {
            if screenshot.rgbAtLocation(
                pos: (x: logoutCompareX, y: y * 10),
                min: (red: 0.60, green: 0.9, blue: 0.6),
                max: (red: 0.75, green: 1.0, blue: 0.7)) {
                normalized.withOffset(CGVector(dx: logoutCompareX, dy: y * 10)).tap()
                break
            }
        }
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
    
    func spin(app: XCUIApplication, open: XCUICoordinate, close: XCUICoordinate, delayMultiplier: UInt32) {
        open.tap()
        sleep(1 * delayMultiplier)
        app.swipeLeft()
        sleep(1 * delayMultiplier)
        close.tap()
        sleep(1 * delayMultiplier)
    }
    
    func clearQuest(app: XCUIApplication, open: XCUICoordinate, close: XCUICoordinate, questDelete: XCUICoordinate, confirm: XCUICoordinate, delayMultiplier: UInt32) {
        open.tap()
        sleep(1 * delayMultiplier)
        app.swipeRight()
        sleep(1 * delayMultiplier)
    
        questDelete.tap()
        sleep(1 * delayMultiplier)
        confirm.tap()
        sleep(1 * delayMultiplier)

        questDelete.tap()
        sleep(1 * delayMultiplier)
        confirm.tap()
        sleep(1 * delayMultiplier)
        
        questDelete.tap()
        sleep(1 * delayMultiplier)
        confirm.tap()
        sleep(1 * delayMultiplier)
        
        close.tap()
        sleep(1 * delayMultiplier)
    }
    
    func clearItems(app: XCUIApplication, open: XCUICoordinate, closeMenu: XCUICoordinate, deleteIncrease: XCUICoordinate, deleteConfirm: XCUICoordinate, itemDeleteX: Int, itemGiftX: Int, itemsY: [Int], delayMultiplier: UInt32) {
        
        let normalized = app.coordinate(withNormalizedOffset: CGVector(dx: 0, dy: 0))
        var index = 0
        var done = false
        
        closeMenu.tap()
        sleep(1 * delayMultiplier)
        open.tap()
        sleep(1 * delayMultiplier)

        while !done && !itemsY.isEmpty {
            let screenshot = XCUIScreen.main.screenshot()
            
            if itemHasDelete(screenshot, x: itemDeleteX, y: itemsY[index]) && !itemIsGift(screenshot, x: itemGiftX, y: itemsY[index]) {
                let delete = normalized.withOffset(CGVector(dx: itemDeleteX, dy: itemsY[index]))
                delete.tap()
                sleep(1 * delayMultiplier)
                deleteIncrease.press(forDuration: 3)
                deleteConfirm.tap()
                sleep(1 * delayMultiplier)
            } else if index + 1 < itemsY.count {
                index += 1
            } else {
                done = true
            }
        }
        
        closeMenu.tap()
        sleep(1 * delayMultiplier)
    }
    
    func itemHasDelete(_ screenshot: XCUIScreenshot, x: Int, y: Int) -> Bool {
        
        
        return screenshot.rgbAtLocation(
            pos: (x: x, y: y),
            min: (red: 0.60, green: 0.60, blue: 0.60),
            max: (red: 0.75, green: 0.75, blue: 0.75)
        )
    }
    
    func itemIsGift(_ screenshot: XCUIScreenshot, x: Int, y: Int) -> Bool {
        return screenshot.rgbAtLocation(
            pos: (x: x, y: y),
            min: (red: 0.6, green: 0.05, blue: 0.5),
            max: (red: 0.7, green: 0.15, blue: 0.6)
        )
    }
    
}
