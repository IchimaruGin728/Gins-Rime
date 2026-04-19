import Foundation

struct GinsSettings {
    /// Worker 基础地址
    static let workerBase =
        ProcessInfo.processInfo.environment["GINS_RIME_WORKER"]
        ?? "https://rime.ichimarugin728.dev"
    
    /// 默认管理的词库列表
    static let managedDicts = ["zhwiki", "tone_moe", "gins-shici"]
    
    /// 方案包在 R2 中的路径
    static let schemeR2Key = "releases/scheme.tar.gz"

    /// 万象语法模型配置
    static let modelR2Key = "models/wanxiang-lts-zh-hans.gram"
    static let modelLocalName = "wanxiang-lts-zh-hans.gram"
    
    /// 版权与协议声明
    static let licenseNotice = "Gins-Rime: 个人定制分发版 (GPL v3)."
}
