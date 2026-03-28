import ArgumentParser
import Foundation

struct Status: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "显示当前状态"
    )

    func run() throws {
        let rimeDir = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Rime")

        print("Gins-Rime 状态")
        print("══════════════════════════════════")
        print("版本: 0.1.0")
        print("RIME 目录: \(rimeDir.path)")
        print("")

        // Check Squirrel
        let squirrelPath = "/Library/Input Methods/Squirrel.app"
        let squirrelInstalled = FileManager.default.fileExists(atPath: squirrelPath)
        print("鼠须管: \(squirrelInstalled ? "✓ 已安装" : "✗ 未安装")")

        // Check deployed scheme
        let schemaPath = rimeDir.appendingPathComponent("wanxiang.schema.yaml")
        let schemaDeployed = FileManager.default.fileExists(atPath: schemaPath.path)
        print("万象方案: \(schemaDeployed ? "✓ 已部署" : "✗ 未部署")")

        // Check dict files
        let dicts = ["zhwiki.dict.yaml", "moegirl.dict.yaml", "melt_eng.dict.yaml"]
        print("")
        print("词库状态:")
        for dict in dicts {
            let dictPath = rimeDir.appendingPathComponent(dict)
            let exists = FileManager.default.fileExists(atPath: dictPath.path)
            let name = dict.replacingOccurrences(of: ".dict.yaml", with: "")
            print("  \(name): \(exists ? "✓" : "✗")")
        }
    }
}
