import ArgumentParser
import Foundation

struct Customize: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "自定义方案配置"
    )

    @Option(name: .long, help: "切换主题 (light/dark/auto)")
    var theme: String?

    @Option(name: .long, help: "开关词库 (zhwiki/moegirl/melt_eng)")
    var toggleDict: String?

    @Flag(name: .long, help: "列出当前配置")
    var list: Bool = false

    func run() throws {
        if list {
            printCurrentConfig()
            return
        }

        if let theme {
            print("🎨 切换主题: \(theme)")
            // TODO: Modify squirrel.custom.yaml
        }

        if let dict = toggleDict {
            print("📚 切换词库: \(dict)")
            // TODO: Modify wanxiang.dict.yaml import_tables
        }

        if theme == nil && toggleDict == nil {
            print("使用 --list 查看当前配置")
            print("使用 --theme <theme> 切换主题")
            print("使用 --toggle-dict <dict> 开关词库")
        }
    }

    private func printCurrentConfig() {
        print("📋 当前 Gins-Rime 配置:")
        print("  方案: 万象拼音 (wanxiang)")
        print("  词库:")
        print("    ✓ jichu (核心)")
        print("    ✓ renming (人名)")
        print("    ✓ wuzhong (物种)")
        print("    ✓ zhwiki (维基百科)")
        print("    ✓ moegirl (萌娘百科)")
        print("    ✓ melt_eng (中英混输)")
        // TODO: Read actual config from yaml
    }
}
