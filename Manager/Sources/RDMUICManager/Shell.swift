//
//  Shell.swift
//  RealDeviceMap
//
//  Created by Florian Kostenzer on 29.10.18.
//

import Foundation

class Shell {

    private var args: [String]

    init (_ args: String...) {
        self.args = args
    }

    func run(outputPipe: Any?=nil, errorPipe: Any?=nil, inputPipe: Any?=nil, wait: Bool=false) -> Process {
        let task = Process()
        task.launchPath = "/usr/bin/env"
        task.arguments = args
        if errorPipe != nil {
            task.standardError = errorPipe
        }
        if inputPipe != nil {
            task.standardInput = inputPipe
        }
        if outputPipe != nil {
            task.standardOutput = outputPipe
        }
        task.launch()
        if wait {
            task.waitUntilExit()
        }
        return task
    }

}
