import ArgumentParser
import Foundation

private let workerBase = "https://rime.ichimarugin728.dev"

struct Update: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "从 Worker 检查并下载最新词库"
    )

    @Flag(name: .shortAndLong, help: "仅检查，不下载")
    var checkOnly: Bool = false

    @Flag(name: .long, help: "下载后自动重新部署")
    var deploy: Bool = false

    func run() async throws {
        print("检查词库更新...")

        let remote = try await fetchRemoteVersions()
        let local = loadLocalVersions()

        let dicts = ["zhwiki", "tone_moe", "gins-shici"]
        var updated = 0

        for dict in dicts {
            let remoteDate = remote[dict] ?? ""
            let localDate = local[dict] ?? ""

            if remoteDate.isEmpty {
                print("  \(dict): 远程无版本信息")
                continue
            }

            if !checkOnly && (localDate.isEmpty || remoteDate > localDate) {
                print("  \(dict): \(localDate.isEmpty ? "未安装" : localDate) → \(remoteDate)，下载中...")
                try await downloadDict(dict)
                updated += 1
            } else if remoteDate > localDate {
                print("  \(dict): 可更新 \(localDate.isEmpty ? "(未安装)" : localDate) → \(remoteDate)")
            } else {
                print("  \(dict): 已是最新 (\(localDate))")
            }
        }

        if updated > 0 {
            var versions = local
            for dict in dicts {
                if let d = remote[dict] { versions[dict] = d }
            }
            saveLocalVersions(versions)
            print("\n\(updated) 个词库已更新")

            if deploy {
                print("触发鼠须管重新部署...")
                Squirrel.reload()
                print("完成")
            }
        } else if !checkOnly {
            print("\n所有词库已是最新")
        }
    }

    // MARK: - Worker API

    private func fetchRemoteVersions() async throws -> [String: String] {
        let url = URL(string: "\(workerBase)/version")!
        let (data, _) = try await URLSession.shared.data(from: url)
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return [:]
        }
        var versions: [String: String] = [:]
        for (key, value) in json {
            if let info = value as? [String: Any], let date = info["date"] as? String {
                versions[key] = date
            }
        }
        return versions
    }

    private func downloadDict(_ name: String) async throws {
        let url = URL(string: "\(workerBase)/dicts/\(name)")!
        let dest = RimePaths.user.appendingPathComponent("\(name).dict.yaml")
        let (tmp, _) = try await URLSession.shared.download(from: url)
        try? FileManager.default.removeItem(at: dest)
        try FileManager.default.moveItem(at: tmp, to: dest)
    }

    // MARK: - Local version store

    private func loadLocalVersions() -> [String: String] {
        guard let data = try? Data(contentsOf: RimePaths.versionsFile),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: String] else {
            return [:]
        }
        return json
    }

    private func saveLocalVersions(_ versions: [String: String]) {
        guard let data = try? JSONSerialization.data(withJSONObject: versions, options: .prettyPrinted) else { return }
        try? data.write(to: RimePaths.versionsFile)
    }
}
