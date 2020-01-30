//
//  FileLogger.swift
//  RDM-UIC-Manager
//
//  Created by Florian Kostenzer on 28.11.18.
//  Modified from: https://github.com/PerfectlySoft/Perfect-Logger/blob/master/Sources/PerfectLogger/FileLogger.swift
//

#if os(Linux)
import SwiftGlibc
import LinuxBridge
#else
import Darwin
#endif

import PerfectLib
import Foundation

class FileLogger: Logger {

    private var file: String
    private let fmt = DateFormatter()

    init(file: String, format: String!="yyyy-MM-dd HH:mm:ss ZZZZ") {
        self.file = file
        fmt.dateFormat = format
    }

    private func filelog(priority: String?, _ args: String) {
        let dateString = fmt.string(from: Date())
        let logFile = File(file)
        defer { logFile.close() }
        do {
            try logFile.open(.append)
            if priority != nil {
                try logFile.write(string: "\(priority!) [\(dateString)] \(args)\n")
            } else {
                try logFile.write(string: "[\(dateString)] \(args)\n")
            }
        } catch { }
    }

    func debug(message: String, _ even: Bool) {
        filelog(priority: even ? "[DEBUG]" : "[DEBUG]", message)
    }

    func info(message: String, _ even: Bool) {
        filelog(priority: even ? "[INFO] " : "[INFO]", message)
    }

    func warning(message: String, _ even: Bool) {
        filelog(priority: even ? "[WARN] " : "[WARNING]", message)
    }

    func error(message: String, _ even: Bool) {
        filelog(priority: even ? "[ERROR]" : "[ERROR]", message)
    }

    func critical(message: String, _ even: Bool) {
        filelog(priority: even ? "[CRIT] " : "[CRITICAL]", message)
    }

    func terminal(message: String, _ even: Bool) {
        filelog(priority: even ? "[EMERG]" : "[EMERG]", message)
    }

    func uic(message: String, all: Bool) {
        let lines = message.components(separatedBy: "\n")
        for line in lines {
            if all || line.starts(with: "[") {
               filelog(priority: nil, line)
            }
        }
    }
}
