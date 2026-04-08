import Foundation

enum ProjectPaths {
    static func projectRoot() -> URL? {
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
        return nil
    }

    static var isProjectMode: Bool {
        projectRoot() != nil
    }

    static func sharedSchemeDir() throws -> URL {
        guard let root = projectRoot() else { throw GinsRimeError.projectRootNotFound }
        return root.appendingPathComponent("scheme/shared")
    }

    static func squirrelDir() throws -> URL {
        guard let root = projectRoot() else { throw GinsRimeError.projectRootNotFound }
        return root.appendingPathComponent("scheme/squirrel")
    }

    static func coreDir() throws -> URL {
        guard let root = projectRoot() else { throw GinsRimeError.projectRootNotFound }
        return root.appendingPathComponent("scheme/shared/core")
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
    case commandNotFound(String)
    case permissionDenied(String)

    var description: String {
        switch self {
        case .projectRootNotFound:
            return "Could not locate Gins-Rime project root. Set GINS_RIME_ROOT or run from the project directory."
        case .commandNotFound(let cmd):
            return "Required command not found: \(cmd). Please ensure it is in your PATH."
        case .permissionDenied(let path):
            return "Permission denied: Cannot write to \(path). Please check your directory permissions."
        }
    }
}
