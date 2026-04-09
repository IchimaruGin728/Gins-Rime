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
            var update = Update()
            update.deploy = !copyOnly
            try await update.run()
            return
        }

        print("部署本地 Gins-Rime 到 \(rimeDir.path)")
        try FileManager.default.createDirectory(at: rimeDir, withIntermediateDirectories: true)
        
        var copiedCount = 0

        // 1. 部署核心方案 (scheme/shared) -> ~/Library/Rime/
        let sharedDir = try ProjectPaths.sharedSchemeDir()
        copiedCount += try deployDirectory(sharedDir, to: rimeDir)
        
        // 1.1 针对核心子目录进行打平部署 (解决方案引用 __include 需要在根目录的问题)
        let coreSchemaDir = sharedDir.appendingPathComponent("core")
        if FileManager.default.fileExists(atPath: coreSchemaDir.path) {
            copiedCount += try deployDirectory(coreSchemaDir, to: rimeDir, flatten: true)
            // 清理掉冗余的 core 文件夹以保持整洁
            let staleCoreDir = rimeDir.appendingPathComponent("core")
            try? FileManager.default.removeItem(at: staleCoreDir)
        }

        // 2. 部署核心词库 (打平到 ~/Library/Rime/dicts/)
        let coreDictsDir = sharedDir.appendingPathComponent("core/dicts")
        if FileManager.default.fileExists(atPath: coreDictsDir.path) {
            let rimeDictsDir = rimeDir.appendingPathComponent("dicts")
            copiedCount += try deployDirectory(coreDictsDir, to: rimeDictsDir, flatten: true)
        }

        // 3. 部署外挂词库 (打平到 ~/Library/Rime/dicts/)
        guard let projRoot = try? ProjectPaths.projectRoot() else {
            throw GinsRimeError.projectRootNotFound
        }
        let thematicDictsDir = projRoot.appendingPathComponent("dicts")
        if FileManager.default.fileExists(atPath: thematicDictsDir.path) {
            let rimeDictsDir = rimeDir.appendingPathComponent("dicts")
            copiedCount += try deployDirectory(thematicDictsDir, to: rimeDictsDir, flatten: true)
        }

        // 4. 部署平台特定配置 (scheme/squirrel) -> ~/Library/Rime/
        let squirrelDir = try ProjectPaths.squirrelDir()
        copiedCount += try deployDirectory(squirrelDir, to: rimeDir)

        // 5. 部署 Lua 引擎 (lua) -> ~/Library/Rime/lua/
        let luaSrcDir = try ProjectPaths.luaDir()
        let luaDestDir = rimeDir.appendingPathComponent("lua")
        copiedCount += try deployDirectory(luaSrcDir, to: luaDestDir)

        // 6. 部署 rime.lua 入口
        let rimeLuaSrc = try ProjectPaths.rimeLuaFile()
        let rimeLuaDest = rimeDir.appendingPathComponent("rime.lua")
        if FileManager.default.fileExists(atPath: rimeLuaSrc.path) {
            try? FileManager.default.removeItem(at: rimeLuaDest)
            try FileManager.default.copyItem(at: rimeLuaSrc, to: rimeLuaDest)
            print("  + rime.lua")
            copiedCount += 1
        }

        print("\n\(copiedCount) 个文件已部署")

        guard !copyOnly else { return }

        guard Squirrel.isInstalled else {
            print("鼠须管未安装，跳过重新部署")
            return
        }
        print("触发鼠须管重新部署...")
        Squirrel.reload()
        print("完成")
    }

    private func deployDirectory(_ src: URL, to dest: URL, flatten: Bool = false) throws -> Int {
        var count = 0
        let contents = try FileManager.default.contentsOfDirectory(
            at: src, includingPropertiesForKeys: [.isDirectoryKey]
        )

        if !flatten {
            try FileManager.default.createDirectory(at: dest, withIntermediateDirectories: true)
        } else {
            // Flattened mode: ensure the top-level destination exists
            try FileManager.default.createDirectory(at: dest, withIntermediateDirectories: true)
        }

        for item in contents {
            let isDir = (try? item.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) == true
            let destItem = flatten ? dest.appendingPathComponent(item.lastPathComponent) : dest.appendingPathComponent(item.lastPathComponent)

            if isDir {
                if flatten {
                    // Even in flatten mode, we walk subdirectories but keep the target destination flat
                    count += try deployDirectory(item, to: dest, flatten: true)
                } else {
                    count += try deployDirectory(item, to: destItem)
                }
            } else {
                // 仅同步特定类型文件
                let ext = item.pathExtension.lowercased()
                guard ["yaml", "lua", "txt", "conf"].contains(ext) else { continue }

                try? FileManager.default.removeItem(at: destItem)
                try FileManager.default.copyItem(at: item, to: destItem)
                
                let relPath = destItem.path.replacingOccurrences(of: RimePaths.user.path + "/", with: "")
                print("  + \(relPath)")
                count += 1
            }
        }
        return count
    }
}
