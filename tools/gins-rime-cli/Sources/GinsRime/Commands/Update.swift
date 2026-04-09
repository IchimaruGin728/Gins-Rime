import ArgumentParser
import Foundation

struct Update: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "从云端同步配置与词库 (\(GinsSettings.licenseNotice))"
    )

    @Flag(name: .shortAndLong, help: "仅检查，不进行实际下载")
    var checkOnly: Bool = false

    @Flag(name: .long, help: "下载后自动重新部署鼠须管")
    var deploy: Bool = false

    @Flag(name: .long, help: "仅同步词库，不更新配置方案")
    var noScheme: Bool = false

    func run() async throws {
        try preflightCheck()
        print("正在检查更新...")

        let remote = try await fetchRemoteMetadata()
        var local = loadLocalVersions()
        var hasChanges = false

        // 1. 处理方案更新 (Scheme)
        if !noScheme, let remoteScheme = remote["scheme"] as? [String: Any],
           let remoteVer = remoteScheme["version"] as? String {
            let localVer = local["_scheme"] ?? ""
            
            if remoteVer > localVer {
                if checkOnly {
                    print("  [scheme]: 可更新 \(localVer.isEmpty ? "(未同步)" : localVer) → \(remoteVer)")
                } else {
                    print("  [scheme]: \(localVer.isEmpty ? "未同步" : localVer) → \(remoteVer)，正在下载...")
                    try await updateScheme()
                    local["_scheme"] = remoteVer
                    hasChanges = true
                }
            } else {
                print("  [scheme]: 已是最新 (\(localVer))")
            }
        }

        // 2. 处理语法模型更新 (Grammar Model)
        if let remoteModel = remote["model"] as? [String: Any],
           let remoteDate = remoteModel["date"] as? String {
            let localDate = local["_model"] ?? ""
            
            if remoteDate > localDate {
                if checkOnly {
                    print("  [model]: 可更新 \(localDate.isEmpty ? "(未安装)" : localDate) → \(remoteDate)")
                } else {
                    print("  [model]: \(localDate.isEmpty ? "未安装" : localDate) → \(remoteDate)，正在下载 (201MB)...")
                    try await updateModel()
                    local["_model"] = remoteDate
                    hasChanges = true
                }
            } else {
                print("  [model]: 已是最新 (\(localDate))")
            }
        }

        // 3. 处理词库更新 (Dicts)
        for dict in GinsSettings.managedDicts {
            guard let remoteInfo = remote[dict] as? [String: Any],
                  let remoteDate = remoteInfo["date"] as? String else {
                continue
            }
            let localDate = local[dict] ?? ""

            if remoteDate > localDate {
                if checkOnly {
                    print("  [\(dict)]: 可更新 \(localDate.isEmpty ? "(未安装)" : localDate) → \(remoteDate)")
                } else {
                    print("  [\(dict)]: \(localDate.isEmpty ? "未安装" : localDate) → \(remoteDate)，正在下载...")
                    try await downloadDict(dict)
                    local[dict] = remoteDate
                    hasChanges = true
                }
            } else {
                print("  [\(dict)]: 已是最新 (\(localDate))")
            }
        }

        if hasChanges {
            saveLocalVersions(local)
            if deploy {
                print("\n下载完成，正在执行物理部署...")
                var deployCmd = Deploy()
                deployCmd.remote = false
                deployCmd.copyOnly = false
                deployCmd.force = false
                try await deployCmd.run()
                Notifier.notify(title: "Gins-Rime 已更新", message: "配置与词库同步完成，方案已重新加载。")
            } else {
                Notifier.notify(title: "Gins-Rime 下载完成", message: "新配置已就绪，请手动重新部署。")
            }
        } else if !checkOnly {
            print("\n所有内容已是最新")
        }
    }

    private func preflightCheck() throws {
        let tarPath = "/usr/bin/tar"
        if !FileManager.default.fileExists(atPath: tarPath) {
            throw GinsRimeError.commandNotFound("tar")
        }
        
        let rimeDir = RimePaths.user
        if FileManager.default.fileExists(atPath: rimeDir.path) {
            if !FileManager.default.isWritableFile(atPath: rimeDir.path) {
                throw GinsRimeError.permissionDenied(rimeDir.path)
            }
        }
    }

    private func fetchRemoteMetadata() async throws -> [String: Any] {
        let url = URL(string: "\(GinsSettings.workerBase)/version")!
        let (data, _) = try await URLSession.shared.data(from: url)
        return (try? JSONSerialization.jsonObject(with: data) as? [String: Any]) ?? [:]
    }

    private func updateScheme() async throws {
        let url = URL(string: "\(GinsSettings.workerBase)/\(GinsSettings.schemeR2Key)")!
        let (tmp, _) = try await URLSession.shared.download(from: url)
        
        let rimeDir = RimePaths.user
        try FileManager.default.createDirectory(at: rimeDir, withIntermediateDirectories: true)
        
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/tar")
        task.arguments = ["-xzf", tmp.path, "-C", rimeDir.path, "--strip-components", "1"]
        try task.run()
        task.waitUntilExit()
    }

    private func updateModel() async throws {
        let url = URL(string: "\(GinsSettings.workerBase)/\(GinsSettings.modelR2Key)")!
        let dest = RimePaths.user.appendingPathComponent(GinsSettings.modelLocalName)
        let (tmp, response) = try await URLSession.shared.download(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw GinsRimeError.downloadFailed(url.absoluteString)
        }
        
        if FileManager.default.fileExists(atPath: dest.path) {
            try FileManager.default.removeItem(at: dest)
        }
        try FileManager.default.moveItem(at: tmp, to: dest)
    }

    private func downloadDict(_ name: String) async throws {
        let url = URL(string: "\(GinsSettings.workerBase)/dicts/\(name).dict.yaml")!
        let dictsDir = RimePaths.user.appendingPathComponent("dicts")
        try FileManager.default.createDirectory(at: dictsDir, withIntermediateDirectories: true)
        
        let dest = dictsDir.appendingPathComponent("\(name).dict.yaml")
        let (tmp, _) = try await URLSession.shared.download(from: url)
        if FileManager.default.fileExists(atPath: dest.path) {
            try FileManager.default.removeItem(at: dest)
        }
        try FileManager.default.moveItem(at: tmp, to: dest)
    }

    private func loadLocalVersions() -> [String: String] {
        guard let data = try? Data(contentsOf: RimePaths.versionsFile),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: String] else {
            return [:]
        }
        return json
    }

    private func saveLocalVersions(_ versions: [String: String]) {
        let data = try? JSONSerialization.data(withJSONObject: versions, options: .prettyPrinted)
        try? data?.write(to: RimePaths.versionsFile)
    }
}
