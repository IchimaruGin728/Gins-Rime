import ArgumentParser
import Foundation

struct Service: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "管理 macOS 自动化服务 (LaunchAgent, App, Service, Shortcuts)",
        subcommands: [Install.self, Uninstall.self, ExportApp.self, ExportService.self, SetupShortcut.self]
    )
    
    // MARK: - Install Daemon
    struct Install: AsyncParsableCommand {
        static let configuration = CommandConfiguration(abstract: "安装后台自动化更新任务 (每 6 小时)")
        
        func run() async throws {
            let binPath = RimePaths.user.appendingPathComponent("gins-rime").path
            guard FileManager.default.fileExists(atPath: binPath) else {
                print("❌ 错误: 未在 ~/Library/Rime/gins-rime 找到二进制文件。")
                print("请先运行: gins-rime self-install")
                return
            }
            
            let label = "dev.ichimarugin728.gins-rime"
            let plistContent = """
            <?xml version="1.0" encoding="UTF-8"?>
            <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
            <plist version="1.0">
            <dict>
                <key>Label</key>
                <string>\(label)</string>
                <key>ProgramArguments</key>
                <array>
                    <string>\(binPath)</string>
                    <string>update</string>
                    <string>--deploy</string>
                </array>
                <key>StartInterval</key>
                <integer>21600</integer>
                <key>RunAtLoad</key>
                <true/>
                <key>StandardOutPath</key>
                <string>/tmp/\(label).stdout.log</string>
                <key>StandardErrorPath</key>
                <string>/tmp/\(label).stderr.log</string>
            </dict>
            </plist>
            """
            
            let agentsDir = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Library/LaunchAgents")
            try FileManager.default.createDirectory(at: agentsDir, withIntermediateDirectories: true)
            
            let plistURL = agentsDir.appendingPathComponent("\(label).plist")
            try plistContent.write(to: plistURL, atomically: true, encoding: .utf8)
            
            // 激活任务
            let task = Process()
            task.executableURL = URL(fileURLWithPath: "/bin/launchctl")
            task.arguments = ["bootstrap", "gui/\(getuid())", plistURL.path]
            try? task.run()
            
            print("✅ 后台服务已安装并激活。")
            print("日志位置: /tmp/\(label).std*.log")
            Notifier.notify(title: "Gins-Rime", message: "后台自动化更新已激活 (每 6 小时)")
        }
    }
    
    // MARK: - Uninstall Daemon
    struct Uninstall: AsyncParsableCommand {
        static let configuration = CommandConfiguration(abstract: "卸载后台自动化任务")
        
        func run() async throws {
            let label = "dev.ichimarugin728.gins-rime"
            let agentsDir = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Library/LaunchAgents")
            let plistURL = agentsDir.appendingPathComponent("\(label).plist")
            
            let task = Process()
            task.executableURL = URL(fileURLWithPath: "/bin/launchctl")
            task.arguments = ["bootout", "gui/\(getuid())", plistURL.path]
            try? task.run()
            
            if FileManager.default.fileExists(atPath: plistURL.path) {
                try FileManager.default.removeItem(at: plistURL)
            }
            
            print("✅ 后台服务已成功清理。")
            Notifier.notify(title: "Gins-Rime", message: "自动化任务已解除")
        }
    }
    
    // MARK: - Export App
    struct ExportApp: AsyncParsableCommand {
        static let configuration = CommandConfiguration(abstract: "导出一个双击即可同步的 .app 应用程序")
        
        func run() async throws {
            let binPath = RimePaths.user.appendingPathComponent("gins-rime").path
            let appName = "Gins-Rime Update"
            let desktopURL = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Desktop/\(appName).app")
            
            let script = "do shell script \"\(binPath) update --deploy\""
            
            print("正在生成应用程序到桌面: \(appName).app")
            
            let task = Process()
            task.executableURL = URL(fileURLWithPath: "/usr/bin/osacompile")
            task.arguments = ["-o", desktopURL.path, "-e", script]
            try task.run()
            task.waitUntilExit()
            
            print("✅ 导出成功！你可以在桌面找到它。")
            Notifier.notify(title: "Gins-Rime", message: "桌面同步应用已生成")
        }
    }
    
    // MARK: - Export Service
    struct SetupShortcut: AsyncParsableCommand {
        static let configuration = CommandConfiguration(abstract: "生成用于『快捷指令』App 的 Shell 脚本代码")
        
        func run() async throws {
            let binPath = RimePaths.user.appendingPathComponent("gins-rime").path
            
            print("\n请在 macOS『快捷指令 (Shortcuts)』App 中新建一个动作：")
            print("1. 添加『运行 Shell 脚本』操作。")
            print("2. 粘贴以下代码：\n")
            print("----------------------------------------")
            print("\(binPath) update --deploy")
            print("----------------------------------------")
            print("\n完成后，你可以为这个指令设置声控触发（Siri）或放置在控制中心。")
        }
    }

    struct ExportService: AsyncParsableCommand {
        static let configuration = CommandConfiguration(abstract: "导出 Finder 快速操作 (Quick Action) 服务")
        
        func run() async throws {
             print("⚠️ 注意: macOS 快速操作服务需要 Automator 协助，目前建议使用 .app 或快捷指令。")
        }
    }
}
