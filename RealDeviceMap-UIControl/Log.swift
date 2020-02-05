//
//  Log.swift
//  RealDeviceMap-UIControlUITests
//
//  Created by Florian Kostenzer on 18.11.18.
//

import Foundation

class Log {

    private init() {}

    public static func error(_ message: String) {
        print("[ERROR] \(message)")
    }

    public static func info(_ message: String) {
        print("[INFO] \(message)")
    }

    public static func debug(_ message: String) {
        print("[DEBUG] \(message)")
    }

    public static func test(_ message: String) {
        print("[Verbose] \(message)")
    }

    public static func startup(_ message: String) {
        print("[Startup] \(message)")
    }

	public static func tutorial(_ message: String) {
        print("[Tutorial] \(message)")
    }
}
