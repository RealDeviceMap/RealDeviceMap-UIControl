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
    public var tapx: Int
    public var tapy: Int

    public init(x: Int, y: Int, tapScaler: Double) {
        self.x = x
        self.y = y
        self.tapx = lround(Double(x) * tapScaler)
        self.tapy = lround(Double(y) * tapScaler)
    }

    public init(x: Int, y: Int, scaler: DeviceCoordinateScaler) {
        self.x = scaler.scaleX(x: x)
        self.y = scaler.scaleY(y: y)
        self.tapx = scaler.tapScaleX(x: x)
        self.tapy = scaler.tapScaleY(y: y)
    }

    public func toXCUICoordinate(app: XCUIApplication) -> XCUICoordinate {
        return app.coordinate(withNormalizedOffset: CGVector.zero).withOffset(CGVector(dx: tapx, dy: tapy))
    }

    public func toXY() -> (x: Int, y: Int) {
        return (x, y)
    }

}

struct DeviceCoordinateScaler {

    public var widthNow: Int
    public var heightNow: Int
    public var widthTarget: Int
    public var heightTarget: Int
    public var multiplier: Double
    public var tapMultiplier: Double

    public func scaleX(x: Int) -> Int {
        return lround(Double(x) * Double(widthNow) / Double(widthTarget) * multiplier)
    }

    public func scaleY(y: Int) -> Int {
        return lround(Double(y) * Double(heightNow) / Double(heightTarget) * multiplier)
    }

    public func tapScaleX(x: Int) -> Int {
        return lround(Double(x) * Double(widthNow) / Double(widthTarget) * multiplier * tapMultiplier )
    }

    public func tapScaleY(y: Int) -> Int {
        return lround(Double(y) * Double(heightNow) / Double(heightTarget) * multiplier * tapMultiplier )
    }

}
