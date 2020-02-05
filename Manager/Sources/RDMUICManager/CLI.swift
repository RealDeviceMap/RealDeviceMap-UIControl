//
//  CLI.swift
//  RDM-UIC-Manager
//
//  Created by Florian Kostenzer on 27.11.18.
//
//  swiftlint:disable file_length type_body_length function_body_length cyclomatic_complexity
//

import Foundation
import PerfectThread

internal extension Bool {
    func toInt() -> Int {
        if self {
            return 1
        }
        return 0
    }
}

internal extension Int {
    func toBool() -> Bool {
        if self == 1 {
            return true
        }
        return false
    }
}

class CLI {

    public static var global = CLI()

    private var defaultDevice: Device!

    // swiftlint:disable force_try
    public func start() {
        clear()
        let defaultDevice = Device.get(uuid: "default")
        if defaultDevice == nil {
            let defaultDevice = Device()
            print("Welcome to RealDeviceMap - UIControl - Manager")
            print("Please specify the default values for devices (or leave empty)")
            let backendURL = askInput("Default Backend URL")
            print("More Default Values can be changed in \"Edit Defaults\"")
            defaultDevice.uuid = "default"
            defaultDevice.name = "deafult"
            defaultDevice.backendURL = backendURL
            self.defaultDevice = defaultDevice
            try! self.defaultDevice!.create()
            print()
        } else {
            self.defaultDevice = defaultDevice!
        }

        while menu() {
            // Run untill menu() == false
        }
    }
    // swiftlint:enable force_try

    // MARK: - Menus

    public func menu() -> Bool {

        let menu = """
        ================
        MENU
        ================
        1. Status
        2. List All
        3. Edit Defaults
        4. Add Device
        5. Edit Device
        6. Delete Device
        0. Exit
        ================
        """

        print(menu)
        let number = askInput("Please select an option", options: [0, 1, 2, 3, 4, 5, 6])
        print()
        switch number {
        case 1:
            status()
            return true
        case 2:
            listAll()
            return true
        case 3:
            editDefaults()
            return true
        case 4:
            addDevice()
            return true
        case 5:
            editDevice()
            return true
        case 6:
            deleteDevice()
            return true
        default:
            return false
        }

    }

    private func status() {
        clear()
        var run = true
        let queue = Threading.getQueue(name: "CLI-Status", type: .serial)
        queue.dispatch {
            while run {
                self.clear()
                let devices = Device.getAll()
                var rows = [[String]]()
                for device in devices {
                    let status = BuildController.global.getStatus(uuid: device.uuid) ?? "?"
                    rows.append([device.name, status])
                }
                self.printTable(headers: ["Name", "Status"], rows: rows)
                print("\nPress enter to exit...")
                Threading.sleep(seconds: 1)
            }
        }

        _ = readLine()
        run = false
        Threading.destroyQueue(queue)
        clear()
    }

    private func listAll() {
        clear()
        let devices = Device.getAll()

        for device in devices {

            clear()
            let row = """
            UUID: \(device.uuid)
            Name: \(device.name)
            Backend URL: \(device.backendURL)
            EnableAccountManager: \(device.enableAccountManager.toBool())
            Port: \(device.port)
            Pokemon Max Time: \(device.pokemonMaxTime)
            Raid Max Time: \(device.raidMaxTime)
            Max Warning Time Raid: \(device.maxWarningTimeRaid)
            Delay Multiplier: \(device.delayMultiplier)
            Jitter Value: \(device.jitterValue)
            Target Max Distance: \(device.targetMaxDistance)
            Item Full Count: \(device.itemFullCount)
            Quest Full Count: \(device.questFullCount)
            Items Per Stop: \(device.itemsPerStop)
            Min Delay Logout: \(device.minDelayLogout)
            Max NoQuest Count: \(device.maxNoQuestCount)
            Max Failed Count: \(device.maxFailedCount)
            Max Empty GMO: \(device.maxEmptyGMO)
            Startup Location Lat: \(device.startupLocationLat)
            Startup Location Lon: \(device.startupLocationLon)
            Encounter Max Wait: \(device.encounterMaxWait)
            Encounter Delay: \(device.encounterDelay)
            Fast IV: \(device.fastIV.toBool())
            Ultra IV: \(device.ultraIV.toBool())
            deployEggs: \(device.deployEggs.toBool())
            token: \(device.token)
            Ultra Quests: \(device.ultraQuests.toBool())
            Enabled: \(device.enabled.toBool())
            AttachScreenshots: \(device.attachScreenshots.toBool())
            """

            print(row + "\n")
            print("Press enter to continue...")
            _ = readLine()
        }
        clear()
    }

    private func editDefaults() {
        clear()
        print("Edit Defaults\n")
        let backendURL = askInput("Default Backend URL (empty = \(defaultDevice.backendURL))")
        if backendURL != "" {
            defaultDevice.backendURL = backendURL
        }

        let enableAccountManager = askBool(
            "Enable Account Manager (empty = \(defaultDevice.enableAccountManager.toBool()))"
        )
        if enableAccountManager != nil {
            defaultDevice.enableAccountManager = enableAccountManager!.toInt()
        }

        let port = askInt("Port (empty = \(defaultDevice.port))")
        if port != nil {
            defaultDevice.port = port!
        }

        let pokemonMaxTime = askDouble("Pokemon Max Time (empty = \(defaultDevice.pokemonMaxTime))")
        if pokemonMaxTime != nil {
            defaultDevice.pokemonMaxTime = pokemonMaxTime!
        }

        let raidMaxTime = askDouble("Raid Max Time (empty = \(defaultDevice.raidMaxTime))")
        if raidMaxTime  != nil {
            defaultDevice.raidMaxTime = raidMaxTime!
        }

        let maxWarningTimeRaid = askInt("Max Warning Time Raid (empty = \(defaultDevice.maxWarningTimeRaid))")
        if maxWarningTimeRaid  != nil {
            defaultDevice.maxWarningTimeRaid = maxWarningTimeRaid!
        }

        let delayMultiplier = askInt("Delay Multiplier (empty = \(defaultDevice.delayMultiplier))")
        if delayMultiplier  != nil {
            defaultDevice.delayMultiplier = delayMultiplier!
        }

        let jitterValue = askDouble("Jitter Value (empty = \(defaultDevice.jitterValue))")
        if jitterValue  != nil {
            defaultDevice.jitterValue = jitterValue!
        }

        let targetMaxDistance = askDouble("Target Max Distance (empty = \(defaultDevice.targetMaxDistance))")
        if targetMaxDistance  != nil {
            defaultDevice.targetMaxDistance = targetMaxDistance!
        }

        let itemFullCount = askInt("Item Full Count (empty = \(defaultDevice.itemFullCount))")
        if itemFullCount  != nil {
            defaultDevice.itemFullCount = itemFullCount!
        }

        let questFullCount = askInt("Quest Full Count (empty = \(defaultDevice.questFullCount))")
        if questFullCount  != nil {
            defaultDevice.questFullCount = questFullCount!
        }

        let itemsPerStop = askInt("Items Per Stop (empty = \(defaultDevice.itemsPerStop))")
        if itemsPerStop  != nil {
            defaultDevice.itemsPerStop = itemsPerStop!
        }

        let minDelayLogout = askDouble("Min Delay Logout (empty = \(defaultDevice.minDelayLogout))")
        if minDelayLogout  != nil {
            defaultDevice.minDelayLogout = minDelayLogout!
        }

        let maxNoQuestCount = askInt("Max No Quest Count (empty = \(defaultDevice.maxNoQuestCount))")
        if maxNoQuestCount  != nil {
            defaultDevice.maxNoQuestCount = maxNoQuestCount!
        }

        let maxFailedCount = askInt("Max Failed Count (empty = \(defaultDevice.maxFailedCount))")
        if maxFailedCount  != nil {
            defaultDevice.maxFailedCount = maxFailedCount!
        }

        let maxEmptyGMO = askInt("Max Empty GMO (empty = \(defaultDevice.maxEmptyGMO))")
        if maxEmptyGMO  != nil {
            defaultDevice.maxEmptyGMO = maxEmptyGMO!
        }

        let startupLocationLat = askDouble("Startup Location Lat (empty = \(defaultDevice.startupLocationLat))")
        if startupLocationLat  != nil {
            defaultDevice.startupLocationLat = startupLocationLat!
        }

        let startupLocationLon = askDouble("Startup Location Lon (empty = \(defaultDevice.startupLocationLon))")
        if startupLocationLon  != nil {
            defaultDevice.startupLocationLon = startupLocationLon!
        }

        let encounterMaxWait = askInt("Encounter Max Wait (empty = \(defaultDevice.encounterMaxWait))")
        if encounterMaxWait  != nil {
            defaultDevice.encounterMaxWait = encounterMaxWait!
        }

        let encounterDelay = askDouble("Encounter Delay (empty = \(defaultDevice.encounterDelay))")
        if encounterDelay  != nil {
            defaultDevice.encounterDelay = encounterDelay!
        }

        let fastIV = askBool("Fast IV (empty = \(defaultDevice.fastIV.toBool()))")
        if fastIV != nil {
            defaultDevice.fastIV = fastIV!.toInt()
        }

        let ultraIV = askBool("Ultra IV (empty = \(defaultDevice.ultraIV.toBool()))")
        if ultraIV != nil {
            defaultDevice.ultraIV = ultraIV!.toInt()
        }

        let deployEggs = askBool("Deploy Eggs (empy = \(defaultDevice.deployEggs.toBool()))")
        if deployEggs != nil {
            defaultDevice.deployEggs = deployEggs!.toInt()
        }

        let ultraQuests = askBool("Ultra Quests (empty = \(defaultDevice.ultraQuests.toBool()))")
        if ultraQuests != nil {
            defaultDevice.ultraQuests = ultraQuests!.toInt()
        }

        let token = askInput("Token (empy = \(defaultDevice.token))")
        if token != "" {
            defaultDevice.token = token
        }

        let enabled = askBool("Enabled (empty = \(defaultDevice.enabled.toBool()))")
        if enabled != nil {
            defaultDevice.enabled = enabled!.toInt()
        }

        let attachScreenshots = askBool("Attach Screenshots (empty = \(defaultDevice.attachScreenshots.toBool()))")
        if attachScreenshots != nil {
            defaultDevice.attachScreenshots = attachScreenshots!.toInt()
        }

        do {
            try defaultDevice.save()
            clear()
            print("Defaults updated.\n\n")
        } catch {
            print("Failed to update defaults.\n\n")
        }
    }

    private func addDevice() {
        clear()
        print("Add Device\n")
        let device = Device()
        let uuid = askInput("Device UUID (empty to cancel)")
        if uuid == "" {
            clear()
            return
        }
        let name = askInput("Device Name")
        var backendURL = askInput("Backend URL (empty = \(defaultDevice.backendURL))")
        if backendURL == "" {
            backendURL = defaultDevice.backendURL
        }
        var enableAccountManager = askBool(
            "Enable Account Manager (empty = \(defaultDevice.enableAccountManager.toBool()))"
        )?.toInt()
        if enableAccountManager == nil {
            enableAccountManager = defaultDevice.enableAccountManager
        }

        var port = askInt("Port (empty = \(defaultDevice.port))")
        if port == nil {
            port = defaultDevice.port
        }

        var pokemonMaxTime = askDouble("Pokemon Max Time (empty = \(defaultDevice.pokemonMaxTime))")
        if pokemonMaxTime == nil {
            pokemonMaxTime = defaultDevice.pokemonMaxTime
        }

        var raidMaxTime = askDouble("Raid Max Time (empty = \(defaultDevice.raidMaxTime))")
        if raidMaxTime == nil {
            raidMaxTime = defaultDevice.raidMaxTime
        }

        var maxWarningTimeRaid = askInt("Max Warning Time Raid (empty = \(defaultDevice.maxWarningTimeRaid))")
        if maxWarningTimeRaid == nil {
            maxWarningTimeRaid = defaultDevice.maxWarningTimeRaid
        }

        var delayMultiplier = askInt("Delay Multiplier (empty = \(defaultDevice.delayMultiplier))")
        if delayMultiplier == nil {
            delayMultiplier = defaultDevice.delayMultiplier
        }

        var jitterValue = askDouble("Jitter Value (empty = \(defaultDevice.jitterValue))")
        if jitterValue == nil {
            jitterValue = defaultDevice.jitterValue
        }

        var targetMaxDistance = askDouble("Target Max Distance (empty = \(defaultDevice.targetMaxDistance))")
        if targetMaxDistance == nil {
            targetMaxDistance = defaultDevice.targetMaxDistance
        }

        var itemFullCount = askInt("Item Full Count (empty = \(defaultDevice.itemFullCount))")
        if itemFullCount == nil {
            itemFullCount = defaultDevice.itemFullCount
        }

        var questFullCount = askInt("Quest Full Count (empty = \(defaultDevice.questFullCount))")
        if questFullCount == nil {
            questFullCount = defaultDevice.questFullCount
        }

        var itemsPerStop = askInt("Items Per Stop (empty = \(defaultDevice.itemsPerStop))")
        if itemsPerStop == nil {
            itemsPerStop = defaultDevice.itemsPerStop
        }

        var minDelayLogout = askDouble("Min Delay Logout (empty = \(defaultDevice.minDelayLogout))")
        if minDelayLogout == nil {
            minDelayLogout = defaultDevice.minDelayLogout
        }

        var maxNoQuestCount = askInt("Max No Quest Count (empty = \(defaultDevice.maxNoQuestCount))")
        if maxNoQuestCount == nil {
            maxNoQuestCount = defaultDevice.maxNoQuestCount
        }

        var maxFailedCount = askInt("Max Failed Count (empty = \(defaultDevice.maxFailedCount))")
        if maxFailedCount == nil {
            maxFailedCount = defaultDevice.maxFailedCount
        }

        var maxEmptyGMO = askInt("Max Empty GMO (empty = \(defaultDevice.maxEmptyGMO))")
        if maxEmptyGMO == nil {
            maxEmptyGMO = defaultDevice.maxEmptyGMO
        }

        var startupLocationLat = askDouble("Startup Location Lat (empty = \(defaultDevice.startupLocationLat))")
        if startupLocationLat == nil {
            startupLocationLat = defaultDevice.startupLocationLat
        }

        var startupLocationLon = askDouble("Startup Location Lon (empty = \(defaultDevice.startupLocationLon))")
        if startupLocationLon == nil {
            startupLocationLon = defaultDevice.startupLocationLon
        }

        var encounterMaxWait = askInt("Encounter Max Wait (empty = \(defaultDevice.encounterMaxWait))")
        if encounterMaxWait == nil {
            encounterMaxWait = defaultDevice.encounterMaxWait
        }

        var encounterDelay = askDouble("Encounter Delay (empty = \(defaultDevice.encounterDelay))")
        if encounterDelay == nil {
            encounterDelay = defaultDevice.encounterDelay
        }
        var fastIV = askBool("Fast IV (empty = \(defaultDevice.fastIV.toBool()))")?.toInt()
        if fastIV == nil {
            fastIV = defaultDevice.fastIV
        }

        var ultraIV = askBool("Ultra IV (empty = \(defaultDevice.ultraIV.toBool()))")?.toInt()
        if ultraIV == nil {
            ultraIV = defaultDevice.ultraIV
        }

        var deployEggs = askBool("Deploy Eggs (empty = \(defaultDevice.deployEggs.toBool()))")?.toInt()
        if deployEggs == nil {
            deployEggs = defaultDevice.deployEggs
        }

        var token = askInput("Token (empy = \(defaultDevice.token))")
        if token == "" {
            token = defaultDevice.token
        }

        var ultraQuests = askBool("Ultra Quests (empty = \(defaultDevice.ultraQuests.toBool()))")?.toInt()
        if ultraQuests == nil {
            ultraQuests = defaultDevice.ultraQuests
        }

        var enabled = askBool("Enabled (empty = \(defaultDevice.enabled.toBool()))")?.toInt()
        if enabled == nil {
            enabled = defaultDevice.enabled
        }

        var attachScreenshots = askBool(
            "Attach Screenshots (empty = \(defaultDevice.attachScreenshots.toBool()))"
        )?.toInt()
        if attachScreenshots == nil {
            attachScreenshots = defaultDevice.attachScreenshots
        }

        device.uuid = uuid
        device.name = name
        device.backendURL = backendURL
        device.enableAccountManager = enableAccountManager!
        device.port = port!
        device.pokemonMaxTime = pokemonMaxTime!
        device.raidMaxTime = raidMaxTime!
        device.maxWarningTimeRaid = maxWarningTimeRaid!
        device.delayMultiplier = delayMultiplier!
        device.jitterValue = jitterValue!
        device.targetMaxDistance = targetMaxDistance!
        device.itemFullCount = itemFullCount!
        device.questFullCount = questFullCount!
        device.itemsPerStop = itemsPerStop!
        device.minDelayLogout = minDelayLogout!
        device.maxNoQuestCount = maxNoQuestCount!
        device.maxFailedCount = maxFailedCount!
        device.maxEmptyGMO = maxEmptyGMO!
        device.startupLocationLat = startupLocationLat!
        device.startupLocationLon = startupLocationLon!
        device.encounterMaxWait = encounterMaxWait!
        device.encounterDelay = encounterDelay!
        device.fastIV = fastIV!
        device.ultraIV = ultraIV!
        device.deployEggs = deployEggs!
        device.token = token
        device.ultraQuests = ultraQuests!
        device.enabled = enabled!
        device.attachScreenshots = attachScreenshots!

        do {
            try device.create()
            clear()
            BuildController.global.addDevice(device: device)
            print("Device added.\n\n")
        } catch {
            print("Failed to add device.\n\n")
        }

    }

    private func editDevice() {
        clear()
        let devices = Device.getAll()
        print("=====================")
        print("Select Device to Edit")
        print("=====================")
        var i = 1
        for device in devices {
            print("\(i): \(device.name)")
            i += 1
        }
        print("0: Back")
        print("=====================")
        let index = askInput("Please select an option", options: Array(0...devices.count))
        print()
        if index == 0 {
            clear()
            return
        }
        let device = devices[index - 1]

        let name = askInput("Device Name (empty = \(device.name))")
        if name != "" {
            device.name = name
        }
        let backendURL = askInput("Backend URL (empty = \(device.backendURL))")
        if backendURL != "" {
            device.backendURL = backendURL
        }

        let enableAccountManager = askBool("Enable Account Manager (empty = \(device.enableAccountManager.toBool()))")
        if enableAccountManager != nil {
            device.enableAccountManager = enableAccountManager!.toInt()
        }

        let port = askInt("Port (empty = \(device.port))")
        if port != nil {
            device.port = port!
        }

        let pokemonMaxTime = askDouble("Pokemon Max Time (empty = \(device.pokemonMaxTime))")
        if pokemonMaxTime != nil {
            device.pokemonMaxTime = pokemonMaxTime!
        }

        let raidMaxTime = askDouble("Raid Max Time (empty = \(device.raidMaxTime))")
        if raidMaxTime  != nil {
            device.raidMaxTime = raidMaxTime!
        }

        let maxWarningTimeRaid = askInt("Max Warning Time Raid (empty = \(device.maxWarningTimeRaid))")
        if maxWarningTimeRaid  != nil {
            device.maxWarningTimeRaid = maxWarningTimeRaid!
        }

        let delayMultiplier = askInt("Delay Multiplier (empty = \(device.delayMultiplier))")
        if delayMultiplier  != nil {
            device.delayMultiplier = delayMultiplier!
        }

        let jitterValue = askDouble("Jitter Value (empty = \(device.jitterValue))")
        if jitterValue  != nil {
            device.jitterValue = jitterValue!
        }

        let targetMaxDistance = askDouble("Target Max Distance (empty = \(device.targetMaxDistance))")
        if targetMaxDistance  != nil {
            device.targetMaxDistance = targetMaxDistance!
        }

        let itemFullCount = askInt("Item Full Count (empty = \(device.itemFullCount))")
        if itemFullCount  != nil {
            device.itemFullCount = itemFullCount!
        }

        let questFullCount = askInt("Quest Full Count (empty = \(device.questFullCount))")
        if questFullCount  != nil {
            device.questFullCount = questFullCount!
        }

        let itemsPerStop = askInt("Items Per Stop (empty = \(device.itemsPerStop))")
        if itemsPerStop  != nil {
            device.itemsPerStop = itemsPerStop!
        }

        let minDelayLogout = askDouble("Min Delay Logout (empty = \(device.minDelayLogout))")
        if minDelayLogout  != nil {
            device.minDelayLogout = minDelayLogout!
        }

        let maxNoQuestCount = askInt("Max No Quest Count (empty = \(device.maxNoQuestCount))")
        if maxNoQuestCount  != nil {
            device.maxNoQuestCount = maxNoQuestCount!
        }

        let maxFailedCount = askInt("Max Failed Count (empty = \(device.maxFailedCount))")
        if maxFailedCount  != nil {
            device.maxFailedCount = maxFailedCount!
        }

        let maxEmptyGMO = askInt("Max Empty GMO (empty = \(device.maxEmptyGMO))")
        if maxEmptyGMO  != nil {
            device.maxEmptyGMO = maxEmptyGMO!
        }

        let startupLocationLat = askDouble("Startup Location Lat (empty = \(device.startupLocationLat))")
        if startupLocationLat  != nil {
            device.startupLocationLat = startupLocationLat!
        }

        let startupLocationLon = askDouble("Startup Location Lon (empty = \(device.startupLocationLon))")
        if startupLocationLon  != nil {
            device.startupLocationLon = startupLocationLon!
        }

        let encounterMaxWait = askInt("Encounter Max Wait (empty = \(device.encounterMaxWait))")
        if encounterMaxWait  != nil {
            device.encounterMaxWait = encounterMaxWait!
        }

        let encounterDelay = askDouble("Encounter Delay (empty = \(device.encounterDelay))")
        if encounterDelay  != nil {
            device.encounterDelay = encounterDelay!
        }

        let fastIV = askBool("Fast IV (empty = \(device.fastIV.toBool()))")
        if fastIV != nil {
            device.fastIV = fastIV!.toInt()
        }

        let ultraIV = askBool("Ultra IV (empty = \(device.ultraIV.toBool()))")
        if ultraIV != nil {
            device.ultraIV = ultraIV!.toInt()
        }

        let deployEggs = askBool("Deploy Eggs (empty = \(device.deployEggs.toBool()))")
        if deployEggs != nil {
            device.deployEggs = deployEggs!.toInt()
        }

        let token = askInput("Token (empy = \(defaultDevice.token))")
        if token != "" {
            device.token = token
        }

        let ultraQuests = askBool("Ultra Quests (empty = \(device.ultraQuests.toBool()))")
        if ultraQuests != nil {
            device.ultraQuests = ultraQuests!.toInt()
        }

        let enabled = askBool("Enabled (empty = \(device.enabled.toBool()))")
        if enabled != nil {
            device.enabled = enabled!.toInt()
        }

        let attachScreenshots = askBool("Attach Screenshots (empty = \(device.attachScreenshots.toBool()))")
        if attachScreenshots != nil {
            device.attachScreenshots = attachScreenshots!.toInt()
        }

        do {
            try device.save()
            clear()
            BuildController.global.removeDevice(device: device)
            let tmpQueue = Threading.getQueue(name: UUID().uuidString, type: .serial)
            tmpQueue.dispatch {
                Threading.sleep(seconds: 10.0)
                BuildController.global.addDevice(device: device)
                Threading.destroyQueue(tmpQueue)
            }
            print("Device updated.\n\n")
        } catch {
            print("Failed to update device.\n\n")
        }
    }

    private func deleteDevice() {
        clear()
        let devices = Device.getAll()
        print("=======================")
        print("Select Device to Delete")
        print("=======================")
        var i = 1
        for device in devices {
            print("\(i): \(device.name)")
            i += 1
        }
        print("0: Back")
        print("=====================")
        let index = askInput("Please select an option", options: Array(0...devices.count))
        print()
        if index == 0 {
            clear()
            return
        }
        let device = devices[index - 1]
        do {
            try device.delete()
            clear()
            BuildController.global.removeDevice(device: device)
            print("Device deleted.\n\n")
        } catch {
            print("Failed to delete device.\n\n")
        }
    }

    // MARK: - Helper Functions

    private func askInput(_ line: String) -> String {
        print("\(line): ", terminator: "")
        return (readLine() ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func askBool(_ line: String) -> Bool? {
        let input = askInput(line)
        if input == "" {
            return nil
        }
        guard let bool = Bool(input) else {
            print("Please enter \"true\", \"false\" or nothing")
            return askBool(line)
        }
        return bool
    }

    private func askDouble(_ line: String) -> Double? {
        let input = askInput(line)
        if input == "" {
            return nil
        }
        guard let double = Double(input) else {
            print("Please enter a valid double or nothing")
            return askDouble(line)
        }
        return double
    }

    private func askInt(_ line: String) -> Int? {
        let input = askInput(line)
        if input == "" {
            return nil
        }
        guard let int = Int(input) else {
            print("Please enter integer nothing")
            return askInt(line)
        }
        return int
    }

    private func askInput(_ line: String, options: [Int]) -> Int {
        let input = askInput(line)
        if let option = Int(input), options.contains(option) {
            return option
        } else {
            print("Please select an valid option.")
            return askInput(line, options: options)
        }
    }

    private func printTable(headers: [String], rows: [[String]]) {
        var table = [String: [String]]()
        for header in headers {
            table[header] = [String]()
        }

        for row in rows {
            var i = 0
            for header in headers {
                table[header]!.append(row[i])
                i += 1
            }

        }
        var tableSorted = [(header: String, rows: [String])]()
        for header in headers {
            if let column = table.first(where: { (column) -> Bool in
                return column.key == header
            }) {
                tableSorted.append((header: header, rows: column.value))
            }
        }

        printTable(tableSorted)
    }

    private func printTable(_ table: [(header: String, rows: [String])]) {

        var columnSizes = [Int]()
        for column in table {
            var maxSize = 0
            if column.header.count > maxSize {
                maxSize = column.header.count
            }
            for row in column.rows where row.count > maxSize {
                maxSize = row.count
            }
            columnSizes.append(maxSize)
        }

        var rows = [String]()
        var x = 0
        for column in table {
            if x == 0 {
                rows.append("")
                rows.append("")
            }
            rows[0] += getPrintFill(column.header, toCount: columnSizes[x], with: " ")
            rows[1] += getPrintFill("", toCount: columnSizes[x], with: "=")
            if x < table.count - 1 {
                rows[0] += "|"
                rows[1] += "|"
            }
            var i = 2
            for row in column.rows {
                if x == 0 {
                    rows.append("")
                }
                rows[i] += getPrintFill(row, toCount: columnSizes[x], with: " ")
                if x < table.count - 1 {
                    rows[i] += "|"
                }
                i += 1
            }
            x += 1
        }
        for row in rows {
            print(row)
        }
        print("\n")
    }

    private func getPrintFill(_ text: String, toCount: Int, with: Character) -> String {
        var row = text
        while row.count < toCount {
            row.append(with)
        }
        return row
    }

    private func clear() {
        print("\u{001B}[2J")
    }
}
