import ArgumentParser
import Foundation

struct Status: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "显示当前状态"
    )

    func run() async throws {
        let rimeDir = RimePaths.user
        let fm = FileManager.default

        print("Gins-Rime 1.0.0")
        print("RIME 目录: \(rimeDir.path)")
        print("")

        // 鼠须管
        let squirrelStatus = Squirrel.isInstalled ? "已安装" : "未安装"
        print("鼠须管:   \(squirrelStatus)")

        // 方案
        let schemaDeployed = fm.fileExists(atPath: rimeDir.appendingPathComponent("gins.schema.yaml").path)
        print("Gins方案: \(schemaDeployed ? "已部署" : "未部署（运行 gins-rime deploy）")")
        print("")

        // 词库
        let builtinDicts: [(String, String)] = [
            ("dicts/jichu.dict.yaml",    "jichu    核心词汇"),
            ("dicts/shici.dict.yaml",    "shici    诗词"),
            ("dicts/diming.dict.yaml",   "diming   地名"),
            ("dicts/renming.dict.yaml",  "renming  人名"),
            ("dicts/wuzhong.dict.yaml",  "wuzhong  物种"),
        ]
        let externalDicts: [(String, String)] = [
            ("tone_moe.dict.yaml",   "tone_moe  萌娘百科"),
            ("zhwiki.dict.yaml",     "zhwiki    维基百科标题"),
            ("gins-shici.dict.yaml", "gins-shici 古诗词补充"),
        ]

        print("万象内置词库:")
        for (file, label) in builtinDicts {
            let exists = fm.fileExists(atPath: rimeDir.appendingPathComponent(file).path)
            print("  \(exists ? "✓" : "✗") \(label)")
        }

        print("\n外挂词库:")
        let versions = loadVersions()
        for (file, label) in externalDicts {
            let exists = fm.fileExists(atPath: rimeDir.appendingPathComponent(file).path)
            let dictName = file.replacingOccurrences(of: ".dict.yaml", with: "")
            let ver = versions[dictName].map { " (\($0))" } ?? ""
            print("  \(exists ? "✓" : "✗") \(label)\(ver)")
        }

        // 上游版本
        print("\n上游同步:")
        let upstreamFiles: [(String, String)] = [
            (".upstream/wanxiang.tag",       "万象拼音"),
            (".upstream/moetype.tag",        "萌娘百科"),
            (".upstream/rime-ice-melt.sha",  "雾凇 melt_eng"),
            (".upstream/chinese-poetry.sha", "古诗词"),
        ]
        if let root = try? ProjectPaths.projectRoot() {
            for (file, label) in upstreamFiles {
                let path = root.appendingPathComponent(file)
                if let tag = try? String(contentsOf: path, encoding: .utf8).trimmingCharacters(in: .whitespacesAndNewlines) {
                    print("  \(label): \(tag)")
                } else {
                    print("  \(label): —")
                }
            }
        }
    }

    private func loadVersions() -> [String: String] {
        guard let data = try? Data(contentsOf: RimePaths.versionsFile),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: String] else {
            return [:]
        }
        return json
    }
}
