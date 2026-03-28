import Foundation

enum ProjectPaths {
    /// Locate the Gins-Rime project root (walks up from executable)
    static func projectRoot() throws -> URL {
        // Try environment variable first
        if let envRoot = ProcessInfo.processInfo.environment["GINS_RIME_ROOT"] {
            return URL(fileURLWithPath: envRoot)
        }

        // Walk up from current directory looking for ARCHITECTURE.md
        var dir = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        for _ in 0..<10 {
            let marker = dir.appendingPathComponent("ARCHITECTURE.md")
            if FileManager.default.fileExists(atPath: marker.path) {
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

    static func hamsterDir() throws -> URL {
        try projectRoot().appendingPathComponent("scheme/hamster")
    }

    static func dictsDir() throws -> URL {
        try projectRoot().appendingPathComponent("dicts")
    }

    static func rimeUserDir() -> URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Rime")
    }
}

enum GinsRimeError: Error, CustomStringConvertible {
    case projectRootNotFound

    var description: String {
        switch self {
        case .projectRootNotFound:
            "Could not locate Gins-Rime project root. Set GINS_RIME_ROOT or run from project directory."
        }
    }
}
