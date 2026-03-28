import ArgumentParser
import Foundation

struct Sync: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "同步用户词典和配置"
    )

    @Option(name: .long, help: "同步方向 (push/pull/both)")
    var direction: String = "both"

    func run() throws {
        let rimeDir = FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Rime")

        print("🔄 同步用户数据...")
        print("  RIME 目录: \(rimeDir.path)")
        print("  方向: \(direction)")

        // TODO: Implement user dict sync (user.db)
        // TODO: Implement custom phrase sync
        // TODO: iCloud / Git sync for cross-device

        print("⚠️  同步功能开发中")
    }
}
