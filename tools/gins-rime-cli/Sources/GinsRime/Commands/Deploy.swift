import ArgumentParser
import Foundation

struct Deploy: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "部署方案到鼠须管 ~/Library/Rime"
    )

    @Flag(name: .shortAndLong, help: "强制覆盖已有文件")
    var force: Bool = false

    @Flag(name: .long, help: "仅复制文件，不触发重新部署")
    var copyOnly: Bool = false

    func run() async throws {
        let rimeDir = RimePaths.user
        print("部署 Gins-Rime 到 \(rimeDir.path)")

        try FileManager.default.createDirectory(at: rimeDir, withIntermediateDirectories: true)

        var copied = 0

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
