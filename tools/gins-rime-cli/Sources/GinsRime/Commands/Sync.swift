import ArgumentParser
import Foundation

struct Sync: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "将核心文件同步到 ~/Library/Rime"
    )

    @Flag(name: .shortAndLong, help: "仅显示将要同步的文件，不实际复制")
    var dryRun: Bool = false

    func run() async throws {
        let coreDir = try ProjectPaths.coreDir()
        let rimeDir = RimePaths.user

        guard FileManager.default.fileExists(atPath: coreDir.path) else {
            print("core 目录不存在：\(coreDir.path)")
            print("请运行 git pull 确保本地仓库已更新")
            return
        }

        print("同步核心文件到 \(rimeDir.path)\(dryRun ? "（dry-run）" : "")")

        let files = try collectFiles(in: coreDir)
        var count = 0

        for src in files {
            let relative = src.path.dropFirst(coreDir.path.count + 1)
            let dest = rimeDir.appendingPathComponent(String(relative))

            let destDir = dest.deletingLastPathComponent()
            if !dryRun {
                try FileManager.default.createDirectory(at: destDir, withIntermediateDirectories: true)
                try? FileManager.default.removeItem(at: dest)
                try FileManager.default.copyItem(at: src, to: dest)
            }

            print("  \(dryRun ? "~" : "+") \(relative)")
            count += 1
        }

        print("\n\(count) 个文件\(dryRun ? "待同步" : "已同步")")

        if !dryRun {
            print("建议执行 gins-rime deploy --copy-only 后重新部署")
        }
    }

    private func collectFiles(in dir: URL) throws -> [URL] {
        var result: [URL] = []
        let contents = try FileManager.default.contentsOfDirectory(
            at: dir, includingPropertiesForKeys: [.isDirectoryKey]
        )
        for item in contents.sorted(by: { $0.path < $1.path }) {
            let isDir = (try? item.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) == true
            if isDir {
                result += try collectFiles(in: item)
            } else {
                result.append(item)
            }
        }
        return result
    }
}
