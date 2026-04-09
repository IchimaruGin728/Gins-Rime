import ArgumentParser
import Foundation

struct SelfInstall: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "将 gins-rime 工具安装到 ~/Library/Rime (推荐)"
    )

    func run() async throws {
        let sourceURL = URL(fileURLWithPath: CommandLine.arguments[0])
        let destURL = RimePaths.user.appendingPathComponent("gins-rime")
        
        print("正在安装 CLI 到: \(destURL.path)")
        
        // 确保目录存在
        try FileManager.default.createDirectory(at: RimePaths.user, withIntermediateDirectories: true)
        
        // 如果目标文件已存在，先删除
        if FileManager.default.fileExists(atPath: destURL.path) {
            try FileManager.default.removeItem(at: destURL)
        }
        
        // 复制二进制文件
        try FileManager.default.copyItem(at: sourceURL, to: destURL)
        
        // 确保可执行权限
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/bin/chmod")
        task.arguments = ["+x", destURL.path]
        try task.run()
        task.waitUntilExit()
        
        print("\n✅ 安装成功！")
        print("现在你可以使用路径 \(destURL.path) 来配置你的自动化工具了。")
        
        Notifier.notify(title: "Gins-Rime", message: "CLI 工具已成功安装到 Rime 目录")
    }
}
