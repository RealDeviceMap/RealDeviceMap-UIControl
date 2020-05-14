import Foundation
import Logging

if CommandLine.arguments.contains("--help") ||
   CommandLine.arguments.contains("-h") {
    print("""
    The following flags are available:
      `--frontend url` (required) [The URL of the RDM frontend]
      `--username username` (required) [The username of a RDM user with admin permission]
      `--password password` (required) [The password of a RDM user with admin permission]
      `--after time` (in seconds, default 120) [The time before an unseen device gets restarted]
      `--lockout time` (in seconds, default 300) [The time to wait after restart untill another restart]
    """)
    exit(0)
}

guard let frontendURLIndex = CommandLine.arguments.firstIndex(of: "--frontend"),
      CommandLine.arguments.count > frontendURLIndex + 1 else {
    fatalError("--frontend not set but is required")
}
let frontendURL = CommandLine.arguments[frontendURLIndex + 1]

guard let usernameIndex = CommandLine.arguments.firstIndex(of: "--username"),
      CommandLine.arguments.count > usernameIndex + 1 else {
    fatalError("--username not set but is required")
}
let username = CommandLine.arguments[usernameIndex + 1]

guard let passwordIndex = CommandLine.arguments.firstIndex(of: "--password"),
      CommandLine.arguments.count > passwordIndex + 1 else {
    fatalError("--password not set but is required")
}
let password = CommandLine.arguments[passwordIndex + 1]

let restartAfter: Int
if let index = CommandLine.arguments.firstIndex(of: "--after"),
   CommandLine.arguments.count > passwordIndex + 1,
   let after = Int(CommandLine.arguments[index + 1]) {
    restartAfter = after
} else {
    restartAfter = 120
}

let restartLockout: Int
if let index = CommandLine.arguments.firstIndex(of: "--lockout"),
   CommandLine.arguments.count > passwordIndex + 1,
   let lockout = Int(CommandLine.arguments[index + 1]) {
    restartLockout = lockout
} else {
    restartLockout = 300
}

let manager = MacLessManager(
    frontendURL: frontendURL,
    username: username,
    password: password,
    restartAfter: restartAfter,
    restartLockout: restartLockout
)
manager.start()

while true {
    sleep(UInt32.max)
}
