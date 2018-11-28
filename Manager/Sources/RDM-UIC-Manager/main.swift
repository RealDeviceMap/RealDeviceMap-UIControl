//
//  main.swift
//  RealDeviceMap
//
//  Created by Florian Kostenzer on 18.09.18.
//

import Foundation
import PerfectLib
import PerfectThread
import SQLiteStORM

let logsFolder = Dir("./logs")
if !logsFolder.exists {
    try! logsFolder.create()
}
Log.logger = FileLogger(file: "./logs/\(Int(Date().timeIntervalSince1970))-main.log")

SQLiteConnector.db = "./db.sqlite"

// Init Tables
let device = Device()
try! device.setup()

let path: String
if let index = CommandLine.arguments.index(of: "-path"), CommandLine.arguments.count > index + 1 {
    path = CommandLine.arguments[index + 1]
} else {
    path = "."
}
let timeout: Int
if let index = CommandLine.arguments.index(of: "-timeout"), CommandLine.arguments.count > index + 1, let number = Int(CommandLine.arguments[index + 1]) {
    timeout = number
} else {
    timeout = 60
}
// Start BuildController
BuildController.global.start(path: path, timeout: timeout)

// Start CLI
CLI.global.start()

