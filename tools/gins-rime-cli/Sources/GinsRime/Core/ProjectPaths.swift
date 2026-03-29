import Foundation

enum ProjectPaths {
    static func projectRoot() throws -> URL {
        if let envRoot = ProcessInfo.processInfo.environment["GINS_RIME_ROOT"] {
            return URL(fileURLWithPath: envRoot)
        }
        var dir = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        for _ in 0..<10 {
            if FileManager.default.fileExists(atPath: dir.appendingPathComponent("README.md").path),
               FileManager.default.fileExists(atPath: dir.appendingPathComponent("scheme").path) {
                return dir
            }
            dir = dir.deletingLastPathComponent()
        }
        throw GinsRimeError.projectRootNotFound
    }

    static func sharedSchemeDir() throws -> URL {
        try projectRoot().appendingPathComponent("scheme/shared")
    }

    static func squirrelDir() throws -> URL {
        try projectRoot().appendingPathComponent("scheme/squirrel")
    }

    static func upstreamDir() throws -> URL {
        try projectRoot().appendingPathComponent("scheme/shared/upstream")
    }
}

enum RimePaths {
    static let user = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent("Library/Rime")

    static let versionsFile = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent("Library/Rime/.gins-versions")
}

enum Squirrel {
    static let appPath = "/Library/Input Methods/Squirrel.app"

    static var isInstalled: Bool {
        FileManager.default.fileExists(atPath: appPath)
    }

    static func reload() {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "\(appPath)/Contents/MacOS/Squirrel")
        task.arguments = ["--reload"]
        try? task.run()
        task.waitUntilExit()
    }
}

enum GinsRimeError: Error, CustomStringConvertible {
    case projectRootNotFound

    var description: String {
        "Could not locate Gins-Rime project root. Set GINS_RIME_ROOT or run from the project directory."
    }
}
