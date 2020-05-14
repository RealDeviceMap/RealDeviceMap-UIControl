import Foundation
import Logging
import ShellOut

class MacLessManager {

    let logger: Logger
    let id: String
    let backendURL: URL
    let username: String
    let password: String
    let restartAfter: Double
    let restartLockout: Double

    let queue: DispatchQueue

    let runningLock = NSLock()
    var running: Bool = false
    var deviceRestarts = [String: Date]()

    init(backendURL: String, username: String, password: String, restartAfter: Int, restartLockout: Int) {
        self.id = UUID().uuidString
        self.logger = Logger(label: "MacLessManager-\(id)")
        self.backendURL = URL(string: "\(backendURL)/api/get_data?show_devices=true")!
        self.password = password
        self.username = username
        self.restartAfter = Double(restartAfter)
        self.restartLockout = Double(restartLockout)
        self.queue = DispatchQueue(label: "MacLessManager-\(id)")
    }

    func start() {
        runningLock.lock()
        if !running {
            running = true
            runningLock.unlock()
            logger.notice("Starting Manager")
            queue.async {
                self.run()
            }
        } else {
            runningLock.unlock()
            logger.info("Already Started")
        }
    }

    func stop() {
        runningLock.lock()
        if running {
            logger.notice("Stopping Manager")
            running = false
        } else {
            logger.info("Already Stopped")
        }
        runningLock.unlock()
    }

    private func run() {
        runningLock.lock()
        while running {
            runningLock.unlock()
            guard let devices = try? getAllDevices(), !devices.isEmpty else {
                self.logger.error("Failed to laod devices (or none connected)")
                sleep(1)
                continue
            }
            self.logger.info("\(devices.count) devices connected")
            guard let statusse = try? getAllDeviceStatusse(), !statusse.isEmpty else {
                self.logger.error("Failed to laod statusse")
                sleep(1)
                continue
            }
            self.logger.info("Loaded \(statusse.count) statusse")
            for device in devices {
                guard let status = statusse[device.value] else {
                    self.logger.error("No status for: \(device.value)")
                    continue
                }
                if Date().timeIntervalSince(status) >= restartAfter {
                    if let lastRestart = deviceRestarts[device.key],
                       Date().timeIntervalSince(lastRestart) <= restartLockout {
                        continue
                    }
                    do {
                        self.logger.notice(
                            "Restarting \(device.value). Last seen: \(Int(Date().timeIntervalSince(status)))s ago."
                        )
                        try restart(uuid: device.key)
                        deviceRestarts[device.key] = Date()
                    } catch {
                        self.logger.error("No status for: \(device.value)")
                    }
                }
            }
            sleep(30)
            runningLock.lock()
        }
        runningLock.unlock()
    }

    private func getAllDeviceStatusse() throws -> [String: Date] {
        var request = URLRequest(url: backendURL)
        let token = "\(username):\(password)".data(using: .utf8)!.base64EncodedString()
        request.addValue("Basic \(token)", forHTTPHeaderField: "Authorization")
        let configuration = URLSessionConfiguration.default
        configuration.httpCookieStorage = .shared
        configuration.httpShouldSetCookies = true

        var statusse = [String: Date]()
        let semaphore = DispatchSemaphore(value: 0)
        let task = URLSession(configuration: configuration).dataTask(with: request) { data, _, _ in
            if let data = data,
               let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let jsonData = json["data"] as? [String: Any],
               let devices = jsonData["devices"] as? [[String: Any]] {
                for device in devices {
                    if let uuid = device["uuid"] as? String, let seen = device["last_seen"] as? UInt32 {
                        statusse[uuid] = Date(timeIntervalSince1970: Double(seen))
                    }
                }
            }
            semaphore.signal()
        }
        task.resume()
        semaphore.wait()
        return statusse
    }

    private func getAllDevices() throws -> [String: String] {
        var devices = [String: String]()
        let uuids = try getAllDeciceUUIDs()
        for uuid in uuids {
            let name = try shellOut(to: "idevicename", arguments: ["--udid", uuid])
            devices[uuid] = name
        }
        return devices
    }

    private func getAllDeciceUUIDs() throws -> [String] {
        let idString = try shellOut(to: "idevice_id", arguments: ["--list"])
        guard !idString.isEmpty else {
            return []
        }
        return idString.components(separatedBy: .newlines).map { (uuid) -> String in
            return uuid.trimmingCharacters(in: .whitespaces)
        }
    }

    private func restart(uuid: String) throws {
        try shellOut(to: "idevicediagnostics", arguments: ["restart", "--udid", uuid])
    }

}
