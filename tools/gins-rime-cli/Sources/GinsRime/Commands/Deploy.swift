import ArgumentParser
import Foundation

struct Deploy: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "部署方案到鼠须管 (~/Library/Rime)"
    )

    @Flag(name: .shortAndLong, help: "强制重新部署，忽略缓存")
    var force: Bool = false

    @Flag(name: .long, help: "仅复制文件，不触发鼠须管重新部署")
    var copyOnly: Bool = false

    func run() throws {
        let rimeDir = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Rime")

        print("📦 部署 Gins-Rime 方案到 \(rimeDir.path)")

        // Ensure target directory exists
        try FileManager.default.createDirectory(
            at: rimeDir,
            withIntermediateDirectories: true
        )

        // Copy shared scheme files
        let schemeFiles = try collectSchemeFiles()
        for file in schemeFiles {
            let dest = rimeDir.appendingPathComponent(file.lastPathComponent)
            if force || !FileManager.default.fileExists(atPath: dest.path) {
                try? FileManager.default.removeItem(at: dest)
                try FileManager.default.copyItem(at: file, to: dest)
                print("  ✓ \(file.lastPathComponent)")
            } else {
                print("  ⏭ \(file.lastPathComponent) (unchanged)")
            }
        }

        // Copy squirrel-specific files
        let squirrelFiles = try collectSquirrelFiles()
        for file in squirrelFiles {
            let dest = rimeDir.appendingPathComponent(file.lastPathComponent)
            try? FileManager.default.removeItem(at: dest)
            try FileManager.default.copyItem(at: file, to: dest)
            print("  ✓ \(file.lastPathComponent)")
        }

        if !copyOnly {
            // Trigger Squirrel redeploy
            print("\n🔄 触发鼠须管重新部署...")
            let task = Process()
            task.executableURL = URL(fileURLWithPath: "/usr/bin/env")
            task.arguments = [
                "/Library/Input Methods/Squirrel.app/Contents/MacOS/Squirrel",
                "--reload"
            ]
            try? task.run()
            task.waitUntilExit()
            print("✅ 部署完成")
        } else {
            print("\n✅ 文件复制完成（未触发重新部署）")
        }
    }

    private func collectSchemeFiles() throws -> [URL] {
        let schemeDir = try ProjectPaths.sharedSchemeDir()
        return try FileManager.default.contentsOfDirectory(
            at: schemeDir,
            includingPropertiesForKeys: nil
        ).filter { $0.pathExtension == "yaml" || $0.pathExtension == "lua" }
    }

    private func collectSquirrelFiles() throws -> [URL] {
        let squirrelDir = try ProjectPaths.squirrelDir()
        guard FileManager.default.fileExists(atPath: squirrelDir.path) else {
            return []
        }
        return try FileManager.default.contentsOfDirectory(
            at: squirrelDir,
            includingPropertiesForKeys: nil
        )
    }
}
