import ArgumentParser
import Foundation

struct Update: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "更新词库和方案到最新版本"
    )

    @Flag(name: .shortAndLong, help: "检查更新但不下载")
    var checkOnly: Bool = false

    @Flag(name: .long, help: "更新后自动重新部署鼠须管")
    var deploy: Bool = false

    func run() throws {
        print("🔍 检查 Gins-Rime 更新...")

        // ── 1. 检查万象语法模型 ──
        try checkAndUpdate(
            name: "万象语法模型",
            localPath: RimePaths.user.appendingPathComponent("wanxiang-lts-zh-hans.gram"),
            remoteURL: "https://api.github.com/repos/amzxyz/RIME-LMDG/releases/tags/LTS",
            assetName: "wanxiang-lts-zh-hans.gram"
        )

        // ── 2. 检查萌娘百科词库 ──
        try checkAndUpdate(
            name: "萌娘百科词库",
            localPath: RimePaths.user.appendingPathComponent("tone_moe.dict.yaml"),
            remoteURL: "https://api.github.com/repos/suiginko/moetype/releases/latest",
            assetName: "tone_moe.dict.yaml"
        )

        // ── 3. 检查 zhwiki 词库 ──
        try checkAndUpdate(
            name: "zhwiki 词库",
            localPath: RimePaths.user.appendingPathComponent("zhwiki.dict.yaml"),
            remoteURL: "https://api.github.com/repos/ichimarugin728/Gins-Rime/releases/latest",
            assetNamePrefix: "zhwiki"
        )

        if deploy && !checkOnly {
            print("\n🔄 重新部署鼠须管...")
            Squirrel.reload()
            print("✅ 部署完成")
        }
    }

    // MARK: - Helpers

    private func checkAndUpdate(
        name: String,
        localPath: URL,
        remoteURL: String,
        assetName: String? = nil,
        assetNamePrefix: String? = nil
    ) throws {
        let localExists = FileManager.default.fileExists(atPath: localPath.path)
        let localDate = localExists ? (try? localPath.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) : nil

        // Fetch release info
        guard let releaseInfo = fetchJSON(from: remoteURL),
              let assets = releaseInfo["assets"] as? [[String: Any]] else {
            print("  ⚠️  \(name): 无法获取远程信息")
            return
        }

        let asset = assets.first {
            if let name = assetName { return ($0["name"] as? String) == name }
            if let prefix = assetNamePrefix { return ($0["name"] as? String)?.hasPrefix(prefix) == true }
            return false
        }

        guard let asset,
              let downloadURL = asset["browser_download_url"] as? String,
              let remoteUpdatedAt = asset["updated_at"] as? String else {
            if !localExists {
                print("  ✗ \(name): 未找到远程文件")
            } else {
                print("  ✓ \(name): 已安装（无法获取远程版本）")
            }
            return
        }

        let remoteDate = ISO8601DateFormatter().date(from: remoteUpdatedAt)

        if !localExists {
            print("  ↓ \(name): 未安装，下载中...")
        } else if let local = localDate, let remote = remoteDate, remote <= local {
            print("  ✓ \(name): 已是最新")
            return
        } else {
            print("  ↑ \(name): 发现更新，下载中...")
        }

        if checkOnly {
            print("    远程: \(remoteUpdatedAt)")
            return
        }

        download(from: downloadURL, to: localPath)
        print("  ✅ \(name): 更新完成")
    }

    private func fetchJSON(from urlString: String) -> [String: Any]? {
        guard let url = URL(string: urlString) else { return nil }
        var request = URLRequest(url: url, timeoutInterval: 15)
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.setValue("2022-11-28", forHTTPHeaderField: "X-GitHub-Api-Version")

        let sema = DispatchSemaphore(value: 0)
        var result: [String: Any]?
        URLSession.shared.dataTask(with: request) { data, _, _ in
            if let data { result = try? JSONSerialization.jsonObject(with: data) as? [String: Any] }
            sema.signal()
        }.resume()
        sema.wait()
        return result
    }

    private func download(from urlString: String, to dest: URL) {
        guard let url = URL(string: urlString) else { return }
        let sema = DispatchSemaphore(value: 0)
        URLSession.shared.downloadTask(with: url) { tmp, _, _ in
            if let tmp { try? FileManager.default.moveItem(at: tmp, to: dest) }
            sema.signal()
        }.resume()
        sema.wait()
    }
}

// MARK: -

enum RimePaths {
    static let user = FileManager.default.homeDirectoryForCurrentUser
        .appendingPathComponent("Library/Rime")
}

enum Squirrel {
    static func reload() {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/Library/Input Methods/Squirrel.app/Contents/MacOS/Squirrel")
        task.arguments = ["--reload"]
        try? task.run()
        task.waitUntilExit()
    }
}
