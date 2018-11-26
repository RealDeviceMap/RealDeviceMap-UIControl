//
//  DeviceCoordinate.swift
//  RealDeviceMap-UIControlUITests
//
//  Created by Florian Kostenzer on 18.11.18.
//

import Foundation
import XCTest

struct DeviceCoordinate {
    
    public var x: Int
    public var y: Int
    public var imageScale: Double
    
    public init(x: Int, y: Int, imageScale: Double=1.0) {
        self.x = x
        self.y = y
        self.imageScale = imageScale
    }
    
    public init(x: Int, y: Int, scaler: DeviceCoordinateScaler, imageScale: Double=1.0) {
        self.x = scaler.scaleX(x: x)
        self.y = scaler.scaleY(y: y)
        self.imageScale = imageScale
    }
    
    public func toXCUICoordinate(app: XCUIApplication) -> XCUICoordinate {
        return app.coordinate(withNormalizedOffset: CGVector.zero).withOffset(CGVector(dx: x, dy: y))
    }
    
    public func toXY() -> (x: Int, y: Int) {
        if imageScale != 1.0 {
            return (Int(Double(x) * imageScale), Int(Double(y) * imageScale))
        } else {
            return (x, y)
        }
    }
    
}

struct DeviceCoordinateScaler {
    
    public var widthNow: Int
    public var heightNow: Int
    public var widthTarget: Int
    public var heightTarget: Int
    
    public func scaleX(x: Int, multiplier: Double=1.0) -> Int {
        if multiplier != 1.0 {
            return lround(Double(x) * Double(widthNow) / Double(widthTarget) * multiplier)
        } else {
            return lround(Double(x) * Double(widthNow) / Double(widthTarget))
        }
    }
    
    public func scaleY(y: Int, multiplier: Double=1.0) -> Int {
        if multiplier != 1.0 {
            return lround(Double(y) * Double(heightNow) / Double(heightTarget) * multiplier)
        } else {
            return lround(Double(y) * Double(heightNow) / Double(heightTarget))
        }
    }
    
}
