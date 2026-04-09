import ArgumentParser
import Foundation

struct Deploy: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "部署方案到鼠须管 ~/Library/Rime"
    )

    @Flag(name: .long, help: "从云端同步最新方案（不使用本地文件）")
    var remote: Bool = false

    @Flag(name: .shortAndLong, help: "仅同步文件，不触发鼠须管重新部署")
    var copyOnly: Bool = false

    @Flag(name: .shortAndLong, help: "强制覆盖已存在的文件")
    var force: Bool = false

    func run() async throws {
        let rimeDir = RimePaths.user
        
        if !ProjectPaths.isProjectMode || remote {
            print("进入远程同步模式...")
            // Delegate to Update for remote sync
            var update = Update()
            update.deploy = !copyOnly
            try await update.run()
            return
        }

        print("部署本地 Gins-Rime 到 \(rimeDir.path)")
        try FileManager.default.createDirectory(at: rimeDir, withIntermediateDirectories: true)
        
        var copied = 0
        // ... (rest of the local copy logic from previous view_file)

        // scheme/shared — gins.*.yaml + gins_eng.dict.yaml
        let sharedDir = try ProjectPaths.sharedSchemeDir()
        for file in try yamlFiles(in: sharedDir) {
            let dest = rimeDir.appendingPathComponent(file.lastPathComponent)
            if force || !FileManager.default.fileExists(atPath: dest.path) {
                try? FileManager.default.removeItem(at: dest)
                try FileManager.default.copyItem(at: file, to: dest)
                print("  + \(file.lastPathComponent)")
                copied += 1
            }
        }

        // scheme/squirrel — squirrel.custom.yaml, default.custom.yaml
        let squirrelDir = try ProjectPaths.squirrelDir()
        for file in try yamlFiles(in: squirrelDir) {
            let dest = rimeDir.appendingPathComponent(file.lastPathComponent)
            try? FileManager.default.removeItem(at: dest)
            try FileManager.default.copyItem(at: file, to: dest)
            print("  + \(file.lastPathComponent)")
            copied += 1
        }

        print("\(copied) 个文件已复制")

        guard !copyOnly else { return }

        guard Squirrel.isInstalled else {
            print("鼠须管未安装，跳过重新部署")
            return
        }
        print("触发鼠须管重新部署...")
        Squirrel.reload()
        print("完成")
    }

    private func yamlFiles(in dir: URL) throws -> [URL] {
        try FileManager.default.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil)
            .filter { $0.pathExtension == "yaml" }
            .sorted { $0.lastPathComponent < $1.lastPathComponent }
    }
}
