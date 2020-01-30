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

if CommandLine.arguments.contains("--help") ||
   CommandLine.arguments.contains("-help") ||
   CommandLine.arguments.contains("-h") {
    print("""
    The following flags are available:
      `-path path` (default = "..") [The Path to the Folder where UIC is at.]
      `-derivedDataPath path` (default = "./DerivedData") [The Path to the DerivedData folder.]
      `-timeout seconds` (default = 300) [Restart after x seconds if a test doesn't print anything.]
      `-builds count` (default = 2) [Max synchronous builds.]
    """)
    exit(0)
}

let logsFolder = Dir("./logs")
if !logsFolder.exists {
    do {
        try logsFolder.create()
    } catch {
        Log.terminal(message: "Failed to create logs folder. \((error.localizedDescription))")
    }
}
Log.logger = FileLogger(file: "./logs/\(Int(Date().timeIntervalSince1970))-main.log")

SQLiteConnector.db = "./db.sqlite"

// Init Tables
let device = Device()
do {
    try device.setup()
} catch {
    Log.terminal(message: "Failed to setup ORM for Device. \((error.localizedDescription))")
}

let path: String
if let index = CommandLine.arguments.index(of: "-path"), CommandLine.arguments.count > index + 1 {
    path = CommandLine.arguments[index + 1]
} else {
    path = ".."
}
let derivedDataPath: String
if let index = CommandLine.arguments.index(of: "-derivedDataPath"), CommandLine.arguments.count > index + 1 {
    derivedDataPath = CommandLine.arguments[index + 1]
} else {
    derivedDataPath = "./DerivedData"
}
let timeout: Int
if let index = CommandLine.arguments.index(of: "-timeout"), CommandLine.arguments.count > index + 1,
   let number = Int(CommandLine.arguments[index + 1]) {
    timeout = number
} else {
    timeout = 300
}
let builds: Int
if let index = CommandLine.arguments.index(of: "-builds"), CommandLine.arguments.count > index + 1,
   let number = Int(CommandLine.arguments[index + 1]) {
    builds = number
} else {
    builds = 2
}
// Start BuildController
BuildController.global.start(path: path, derivedDataPath: derivedDataPath, timeout: timeout,
                             maxSimultaneousBuilds: builds)

// Start CLI
CLI.global.start()
