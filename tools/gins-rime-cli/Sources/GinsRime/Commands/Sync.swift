import ArgumentParser
import Foundation

struct Sync: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "将核心文件同步到 ~/Library/Rime"
    )

    @Flag(name: .shortAndLong, help: "仅显示将要同步的文件，不实际复制")
    var dryRun: Bool = false

    func run() async throws {
        let rimeDir = RimePaths.user
        print("同步核心文件到 \(rimeDir.path)\(dryRun ? "（dry-run）" : "")")

        // 1. 同步 YAML 配置文件 (Shared Core)
        let coreDir = try ProjectPaths.coreDir()
        let coreFiles = try collectFiles(in: coreDir)
        var count = 0

        for src in coreFiles {
            let relative = src.path.dropFirst(coreDir.path.count + 1)
            let dest = rimeDir.appendingPathComponent(String(relative))
            if try syncFile(src, to: dest, dryRun: dryRun) { count += 1 }
        }

        // 2. 同步 Lua 引擎 (lua/)
        let luaDir = try ProjectPaths.luaDir()
        if FileManager.default.fileExists(atPath: luaDir.path) {
            let luaFiles = try collectFiles(in: luaDir)
            for src in luaFiles {
                let relative = "lua/" + src.path.dropFirst(luaDir.path.count + 1)
                let dest = rimeDir.appendingPathComponent(String(relative))
                if try syncFile(src, to: dest, dryRun: dryRun) { count += 1 }
            }
        }

        // 3. 同步 rime.lua 入口
        let rimeLua = try ProjectPaths.rimeLuaFile()
        if FileManager.default.fileExists(atPath: rimeLua.path) {
            let dest = rimeDir.appendingPathComponent("rime.lua")
            if try syncFile(rimeLua, to: dest, dryRun: dryRun) { count += 1 }
        }

        print("\n\(count) 个文件\(dryRun ? "待同步" : "已同步")")
        
        if !dryRun {
            print("建议执行 gins-rime deploy --copy-only 后重新部署")
        }
    }

    private func syncFile(_ src: URL, to dest: URL, dryRun: Bool) throws -> Bool {
        if !dryRun {
            let destDir = dest.deletingLastPathComponent()
            try FileManager.default.createDirectory(at: destDir, withIntermediateDirectories: true)
            try? FileManager.default.removeItem(at: dest)
            try FileManager.default.copyItem(at: src, to: dest)
        }
        
        print("  \(dryRun ? "~" : "+") \(dest.path.replacingOccurrences(of: RimePaths.user.path + "/", with: ""))")
        return true
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
